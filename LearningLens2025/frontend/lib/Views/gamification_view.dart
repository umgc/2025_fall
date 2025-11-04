import 'dart:convert';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/services/gamification_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Games/quiz_game.dart';
import 'package:learninglens_app/Games/matching_game.dart';
import 'package:learninglens_app/Games/flashcard_game.dart';
import 'package:learninglens_app/Games/game_result.dart';
import 'package:learninglens_app/services/ai_file_service.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/local_llm_service.dart'; // local llm

class GamificationView extends StatefulWidget {
  const GamificationView({super.key});

  @override
  State<GamificationView> createState() => _GamificationViewState();
}

class _GamificationViewState extends State<GamificationView> {
  List<AssignedGame> assignedGames = [];
  PlatformFile? _selectedFile;
  String? _selectedGameType;
  String? _selectedDifficulty;
  bool _isGameCreated = false;
  List<Map<String, dynamic>>? _generatedGameData;
  LlmType? _selectedLLM;
  bool _gameNeedsRefresh = false;
  bool _localLlmAvail = !kIsWeb;
  bool _isLoadingAssignments = false;
  final GamificationService _gamificationService = GamificationService();
  String? _assignmentsError;
  int _studentCompletedCount = 0;
  bool _hasStudentScores = false;
  final Map<int, String> _courseNameCache = {};
  final Map<int, String> _studentNameCache = {};
  bool _isClearingAssignments = false;
  bool _coursesLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedLLM = LlmType.values
        .firstWhereOrNull((llm) => LocalStorageService.userHasLlmKey(llm));
    _refreshAssignments();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Generating game..."),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAssignments() async {
    final userIdStr = LocalStorageService.getUserId();
    final role = LocalStorageService.getUserRole();
    if (userIdStr == null || userIdStr.isEmpty) {
      setState(() {
        assignedGames = [];
        _assignmentsError = 'User id not available.';
      });
      return;
    }

    final userId = int.tryParse(userIdStr);
    if (userId == null) {
      setState(() {
        assignedGames = [];
        _assignmentsError = 'Unable to parse user id.';
      });
      return;
    }

    setState(() {
      _isLoadingAssignments = true;
      _assignmentsError = null;
    });

    try {
      List<AssignedGame> games;
      if (role == UserRole.teacher) {
        games = await _gamificationService.getGamesForTeacher(userId);
        await _ensureCourseNames();
        setState(() {
          assignedGames = games;
          _isLoadingAssignments = false;
        });
      } else {
        games = await _gamificationService.getGamesForStudent(userId);
        final completed = games.where((g) => g.score!.score != null).toList();
        final pending = games.where((g) => g.score!.score == null).toList();
        await _ensureCourseNames();
        setState(() {
          assignedGames = pending;
          _studentCompletedCount = completed.length;
          _hasStudentScores = completed.isNotEmpty;
          _isLoadingAssignments = false;
        });
      }
    } catch (e) {
      setState(() {
        assignedGames = [];
        _assignmentsError = e.toString();
        _isLoadingAssignments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = LocalStorageService.getUserRole() ==
        UserRole.teacher; // TEMP: Change to logic check later

    return Scaffold(
      appBar: isTeacher
          ? AppBar(title: const Text('Generate a Game'))
          : AppBar(
              title: const Text('🎮 My Games'),
              backgroundColor: Colors.deepPurpleAccent,
              centerTitle: true,
            ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isTeacher ? _buildTeacherUI(context) : _buildStudentUI(),
      ),
    );
  }

  Widget _buildTeacherUI(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate a Game from a Lesson: ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload File or Slide Deck'),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                withData: true,
              );

              if (result != null) {
                final file = result.files.single;
                setState(() {
                  _selectedFile = file;
                  _gameNeedsRefresh = true;
                  _isGameCreated = false;
                });
                // For now, just show a snackbar with the file name
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: ${file.name}')),
                );
              } else {
                // User canceled the picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No file selected.')),
                );
              }
            },
          ),
          if (_selectedFile != null) ...[
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Selected File: ${_selectedFile!.name}')),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 30),
          const Text('Select Game Type:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _gameType('Quiz Game', Icons.quiz),
              _gameType('Matching', Icons.compare_arrows),
              _gameType('Flashcards', Icons.memory),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Difficulty Level:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['Easy', 'Medium', 'Hard'].map((level) {
              return ChoiceChip(
                label: Text(level),
                selected: _selectedDifficulty == level,
                onSelected: (_) {
                  setState(() {
                    _selectedDifficulty = level;
                    _gameNeedsRefresh = true;
                    _isGameCreated = false;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          const Text('Select LLM Model:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          DropdownButton<LlmType>(
              value: _selectedLLM,
              onChanged: (LlmType? newValue) {
                setState(() {
                  _selectedLLM = newValue;
                });
              },
              items: LlmType.values.map((LlmType llm) {
                return DropdownMenuItem<LlmType>(
                  value: llm,
                  enabled: (llm == LlmType.LOCAL &&
                          LocalStorageService.getLocalLLMPath() != "" &&
                          _localLlmAvail) ||
                      LocalStorageService.userHasLlmKey(llm),
                  child: Text(
                    llm.displayName,
                    style: TextStyle(
                      color: (llm == LlmType.LOCAL &&
                                  LocalStorageService.getLocalLLMPath() != "" &&
                                  _localLlmAvail) ||
                              LocalStorageService.userHasLlmKey(llm)
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList()),
          if (_selectedLLM == LlmType.LOCAL) ...[
            const SizedBox(height: 6),
            const Text(
              "Running a Large Language Model (LLM) locally typically requires substantial hardware resources.\nWe recommend using 7B or higher thinking (Qwen) models to create the game. \nFor best results, we recommend using external LLM.\nPlease use the local LLM responsibly and independently verify any critical information.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              child: const Text('Create Game'),
              onPressed: () async {
                if (_selectedFile == null || _selectedGameType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please upload a file and select a game type.')),
                  );
                  return;
                }
                if (_selectedLLM == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select an LLM model.')),
                  );
                  return;
                }

                showLoadingDialog(context);

                try {
                  final Uint8List? bytes = _selectedFile!.bytes;
                  if (bytes == null) {
                    throw Exception("No file content found");
                  }

                  final text = await AIFileService.extractTextFromPDF(bytes);
                  late final List<Map<String, dynamic>> response;

                  LLM aiModel;
                  if (_selectedLLM == LlmType.CHATGPT) {
                    aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
                  } else if (_selectedLLM == LlmType.GROK) {
                    aiModel = GrokLLM(LocalStorageService.getGrokKey());
                  } else if (_selectedLLM == LlmType.DEEPSEEK) {
                    aiModel = DeepseekLLM(LocalStorageService.getDeepseekKey());
                  } else if (_selectedLLM == LlmType.LOCAL) {
                    aiModel = LocalLLMService();
                  } else {
                    aiModel =
                        PerplexityLLM(LocalStorageService.getPerplexityKey());
                  }

                  if (_selectedLLM == LlmType.CHATGPT ||
                      _selectedLLM == LlmType.DEEPSEEK ||
                      _selectedLLM == LlmType.PERPLEXITY ||
                      _selectedLLM == LlmType.GROK ||
                      _selectedLLM == LlmType.LOCAL) {
                    if (_selectedGameType == 'Quiz Game') {
                      response = await generateGameFromText(text, aiModel);
                    } else if (_selectedGameType == 'Matching') {
                      response =
                          await generateMatchingPairsFromText(text, aiModel);
                    } else if (_selectedGameType == 'Flashcards') {
                      response =
                          await generateFlashcardsFromText(text, aiModel);
                    } else {
                      throw Exception("Unknown game type: $_selectedGameType");
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                              '${_selectedLLM!.name} is not yet supported.')),
                    );
                    return;
                  }

                  setState(() {
                    _generatedGameData = response;
                    _isGameCreated = true;
                    _gameNeedsRefresh = false;
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Game generated! Preview or assign it when ready.')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ),
          if (_isGameCreated) ...[
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                child: const Text('Preview Game'),
                onPressed: () {
                  if (_gameNeedsRefresh || _generatedGameData == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Please click "Create Game" before previewing.')),
                    );
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (context) {
                      Widget previewContent;

                      final List<Map<String, dynamic>> gameData =
                          _generatedGameData ?? [];

                      switch (_selectedGameType) {
                        case 'Quiz Game':
                          previewContent = QuizGame(
                            questions: gameData,
                            onComplete: (_) {},
                            previewMode: true,
                          );
                        case 'Matching':
                          previewContent = MatchingGame(
                            pairs: gameData,
                            onComplete: (_) {},
                            previewMode: true,
                          );
                        case 'Flashcards':
                          previewContent = FlashcardGame(
                            questions: gameData,
                            onComplete: () {},
                            previewMode: true,
                          );
                        default:
                          previewContent = const Text('No game type selected.');
                      }

                      return AlertDialog(
                        title: const Text('Game Preview'),
                        content: SizedBox(width: 600, child: previewContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                child: const Text('Assign Game to Students'),
                onPressed: () {
                  _showAssignPopup(context);
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.leaderboard),
                label: const Text('View Student Scores'),
                onPressed: _showScoreboardDialog,
              ),
              if (LocalStorageService.getUserRole() == UserRole.teacher)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: OutlinedButton.icon(
                    icon: _isClearingAssignments
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever),
                    label: Text(
                      _isClearingAssignments
                          ? 'Clearing...'
                          : 'Clear All Assigned Games',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: _isClearingAssignments
                        ? null
                        : _confirmAndClearAssignments,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameType(String label, IconData icon) {
    final isSelected = _selectedGameType == label;
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : null,
      ),
      onPressed: () {
        setState(() {
          _selectedGameType = label;
          _gameNeedsRefresh = true;
          _isGameCreated = false;
        });
      },
    );
  }

  Widget _buildStudentUI() {
    print('🧠 Student UI loading with ${assignedGames.length} assigned games.');
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assignmentsError != null) {
      return Center(
        child: Text(
          _assignmentsError!,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (assignedGames.isEmpty) {
      return const Center(
        child: Text('No games assigned yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👋 Welcome back, ready to play?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              if (_hasStudentScores)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Completed $_studentCompletedCount game${_studentCompletedCount == 1 ? '' : 's'}.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: assignedGames.length,
            itemBuilder: (context, index) {
              final game = assignedGames[index];
              final emoji = _emojiForGameType(game.gameType);
              final formattedDate =
                  DateFormat.yMMMd().format(game.assignedDate);
              final courseName = _courseNameCache[game.courseId];
              final gameTypeLabel = _labelForGameType(game.gameType);
              final titleText = courseName != null && courseName.isNotEmpty
                  ? '$courseName: $gameTypeLabel'
                  : '${game.title}: $gameTypeLabel';
              final subtitleParts = <String>[];
              if (courseName == null || courseName.isEmpty) {
                subtitleParts.add('Course ID: ${game.courseId}');
              } else if (!game.title
                  .toLowerCase()
                  .contains(courseName.toLowerCase())) {
                subtitleParts.add(game.title);
              }
              subtitleParts.add('📅 Assigned: $formattedDate');
              return Card(
                color: Colors.deepPurple[50],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: Text(emoji, style: TextStyle(fontSize: 30)),
                  title: Text(
                    titleText,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitleParts.join('\n')),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final content = _decodeGameData(game.gameData);
                      if (content == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No content found for this game. Ask your teacher to reassign it.')),
                        );
                        return;
                      }

                      final type =
                          _parseGameType(content['gameType'] ?? game.gameType);
                      final List<Map<String, dynamic>> data =
                          List<Map<String, dynamic>>.from(
                              content['data'] ?? const []);

                      if (data.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Game content is empty. Ask your teacher to regenerate it.')),
                        );
                        return;
                      }

                      Widget gameView;
                      switch (type) {
                        case GameType.QUIZ:
                          gameView = QuizGame(
                            questions: data,
                            onComplete: (result) {
                              _recordGameResult(game, result);
                            },
                            previewMode: false,
                          );
                        case GameType.MATCHING:
                          gameView = MatchingGame(
                            pairs: data,
                            onComplete: (result) {
                              _recordGameResult(game, result);
                            },
                            previewMode: false,
                          );
                        case GameType.FLASHCARD:
                          gameView = FlashcardGame(
                            questions: data,
                            onComplete: () {
                              _recordGameResult(
                                game,
                                GamePlayResult(
                                  score: data.length,
                                  maxScore: data.length,
                                ),
                              );
                            },
                            previewMode: false,
                          );
                      }

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Play Game'),
                          content: SizedBox(width: 600, child: gameView),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('▶️ Play'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Generate multiple choice quiz questions. Returns list of maps:
  /// { "question": "...", "options": ["A","B","C","D"], "answer": <index> }
  Future<List<Map<String, dynamic>>> generateGameFromText(
      String text, LLM aiModel,
      {int questionCount = 5}) async {
    final systemPrompt =
        'You are an educational game designer. From the given text, generate exactly $questionCount multiple-choice questions. '
        'Respond with a VALID JSON ARRAY ONLY (no extra text) where each item has: '
        '{"question": "...", "options": ["optA", "optB", "optC", "optD"], "answer": <index>} '
        'The "answer" should be the index (0-3) of the correct option.\n\n'
        'Input: $text';

    final raw = await aiModel.postToLlm(systemPrompt);
    // Clean and isolate valid JSON from AI output
    String cleaned = raw
        .replaceAll(RegExp(r'```json', multiLine: true), '')
        .replaceAll(RegExp(r'```', multiLine: true), '')
        .trim();

    // Extract only the first valid JSON array to avoid extra text
    final match = RegExp(r'\[\s*{[\s\S]*?}\s*\]').firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(0)!;
    }

    try {
      final parsedList = _parseJsonList<Map<String, dynamic>>(cleaned, (item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        throw Exception('Item is not an object');
      });
      print('✅ Game generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'Response was not valid JSON (generateGameFromText). $e\nResponse:\n$cleaned');
    }
  }

  /// Generate flashcards: returns List<Map<String,String>> with {"term","definition"}
  Future<List<Map<String, String>>> generateFlashcardsFromText(
      String text, LLM aiModel,
      {int cardCount = 5}) async {
    final systemPrompt = '''
You are an educational assistant. Analyze the following input content and generate exactly $cardCount educational flashcards.

Each flashcard must contain:
- "term": a keyword or phrase that will be on side A
- "definition": a sentence or explanation that will be on side B

Return a valid JSON array ONLY. Do not include any extra text, explanation, or formatting outside the JSON. Ensure all values are strings.

Example format:
[
  {"term": "Gravity", "definition": "The force that pulls objects toward the Earth."},
  {"term": "Friction", "definition": "The resistance force between two surfaces in contact."}
]

Input:
$text
''';

    final raw = await aiModel.postToLlm(systemPrompt);
    print('🧪 RAW Flashcard JSON: $raw');
    // Extract only the first valid JSON array to avoid malformed multi-array issues
    final match = RegExp(r'\[\s*{[\s\S]*?}\s*\]').firstMatch(raw);
    final safeJson = match?.group(0);
    if (safeJson == null) {
      throw Exception("Failed to extract JSON array from response:\n$raw");
    }

    try {
      final parsedList = _parseJsonList<Map<String, String>>(safeJson, (item) {
        if (item is Map) {
          return Map<String, String>.from(
              item.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
        throw Exception('Item is not an object');
      });
      print('✅ Flashcards generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'Response was not valid JSON (generateFlashcardsFromText). $e\nResponse:\n$raw');
    }
  }

  /// Generate matching pairs: returns List<Map<String,String>> with {"term","match"}
  Future<List<Map<String, String>>> generateMatchingPairsFromText(
      String text, LLM aiModel,
      {int pairCount = 5}) async {
    final systemPrompt = '''
You are an educational assistant. From the given lesson text, extract exactly $pairCount concept-definition pairs as a matching game.

Each item must be a JSON object with:
- "term": a keyword or concept
- "match": a short explanation or definition

Return a single JSON array with exactly $pairCount objects and no other text.

Example:
[
  {"term": "Gravity", "match": "A force that pulls objects toward Earth."},
  {"term": "Friction", "match": "A force that resists motion between surfaces."}
]

Input:
$text
''';

    final raw = await aiModel.postToLlm(systemPrompt);
    // Extract only the first valid JSON array to avoid malformed multi-array issues
    final match = RegExp(r'\[\s*{[\s\S]*?}\s*\]').firstMatch(raw);
    final safeJson = match?.group(0);
    if (safeJson == null) {
      throw Exception("Failed to extract JSON array from response:\n$raw");
    }

    try {
      final parsedList = _parseJsonList<Map<String, String>>(safeJson, (item) {
        if (item is Map) {
          final term = item['term']?.toString();
          final match = item['match']?.toString();
          return {
            'term': term ?? '⚠️ No term',
            'match': match ?? '⚠️ No match'
          };
        }
        throw Exception('Item is not an object');
      });
      print('✅ Matching pairs generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'Response was not valid JSON (generateMatchingPairsFromText). $e\nResponse:\n$raw');
    }
  }

  /// Generate math questions: returns List<Map<String,String>> with {"question","answer"}
  Future<List<Map<String, String>>> generateMathQuestionsFromText(
      String text, LLM aiModel,
      {int questionCount = 5}) async {
    final systemPrompt =
        'You are a math teacher assistant. From the given input text, generate exactly $questionCount math problems. '
        'Each item should have {"question":"...","answer":"..."} and you must respond with a VALID JSON ARRAY ONLY.\n\nInput: $text';

    final raw = await aiModel.postToLlm(systemPrompt);

    try {
      final parsedList = _parseJsonList<Map<String, String>>(raw, (item) {
        if (item is Map) {
          return Map<String, String>.from(
              item.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
        throw Exception('Item is not an object');
      });
      print('✅ Math questions generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'OpenAI response was not valid JSON (generateMathQuestionsFromText). $e\nResponse:\n$raw');
    }
  }

  List<T> _parseJsonList<T>(String content, T Function(dynamic) mapper) {
    String normalizedResult = content.trim();
    // Remove markdown code block wrappers if present.
    if (normalizedResult.startsWith("```json")) {
      normalizedResult = normalizedResult.substring(7);
    }
    if (normalizedResult.endsWith("```")) {
      normalizedResult =
          normalizedResult.substring(0, normalizedResult.length - 3);
    }
    normalizedResult = normalizedResult.trim();
    final decoded = jsonDecode(normalizedResult);
    if (decoded is List) {
      return decoded.map(mapper).toList();
    }
    throw Exception(
        'Expected JSON array from model but got: ${decoded.runtimeType}');
  }

  // Assign game to all students in a course, preventing duplicate global assignments
  Future<bool> assignGameToAllStudents(
    String title,
    String gameType,
    int courseId, {
    Set<int>? specificStudentIds,
  }) async {
    if (_generatedGameData == null || _generatedGameData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please generate the game content before assigning.')),
      );
      return false;
    }
    final lmsService = LmsFactory.getLmsService();
    final students =
        await lmsService.getCourseParticipants(courseId.toString());
    final targetStudents = specificStudentIds == null
        ? students
        : students
            .where((student) => specificStudentIds.contains(student.id))
            .toList();

    if (targetStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No students selected for this assignment.')),
      );
      return false;
    }

    final teacherIdStr = LocalStorageService.getUserId();
    final teacherId = int.tryParse(teacherIdStr ?? '');
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine teacher id.')),
      );
      return false;
    }

    final now = DateTime.now();
    final gameTypeEnum = _gameTypeFromLabel(gameType);
    final contentPayload = jsonEncode({
      'gameType': gameType,
      'data': _generatedGameData ?? [],
    });

    try {
      final assignedGame = AssignedGame(
        uuid: null,
        courseId: courseId,
        gameType: gameTypeEnum,
        title: title,
        gameData: contentPayload,
        assignedDate: now,
        assignedBy: teacherId,
      );
      final gameResponse = await _gamificationService.createGame(assignedGame);
      final responseBody = jsonDecode(gameResponse.body);
      final gameId = responseBody[0]["game_id"];

      await Future.wait(targetStudents.map((student) {
        return _gamificationService
            .assignGame(AssignedGameScore(studentId: student.id, game: gameId));
      }));

      await _refreshAssignments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Game "$title" assigned to ${targetStudents.length} student${targetStudents.length > 1 ? 's' : ''}.'),
        ),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign game: $e')),
      );
      return false;
    }
  }

  // Show a popup/modal to assign game to students in a course
  void _showAssignPopup(BuildContext context) async {
    final selectedGameType = _selectedGameType;
    final lmsService = LmsFactory.getLmsService();
    List<Course>? courses;
    int? selectedCourseId;
    List<Participant>? students;
    Set<int> selectedStudentIds = {};
    bool isLoadingCourses = true;
    bool isLoadingStudents = false;
    bool isAssigning = false;

    // Helper to refresh state in the dialog
    // void refresh(void Function() fn) {
    //   // ignore: invalid_use_of_protected_member
    //   (context as Element).markNeedsBuild();
    //   fn();
    // }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder for local state
        return StatefulBuilder(
          builder: (context, setState) {
            // On first build, load courses
            if (isLoadingCourses) {
              lmsService.getUserCourses().then((fetchedCourses) {
                setState(() {
                  courses = fetchedCourses;
                  isLoadingCourses = false;
                  if (courses != null && courses!.isNotEmpty) {
                    selectedCourseId = courses!.first.id;
                    isLoadingStudents = true;
                    lmsService
                        .getCourseParticipants(selectedCourseId.toString())
                        .then((fetchedStudents) {
                      setState(() {
                        students = fetchedStudents;
                        isLoadingStudents = false;
                        selectedStudentIds.clear();
                      });
                    });
                  }
                });
              });
            }

            return AlertDialog(
              title: const Text('Assign Game to Students'),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoadingCourses)
                      const Center(child: CircularProgressIndicator())
                    else if (courses == null || courses!.isEmpty)
                      const Text('No courses found.')
                    else ...[
                      const Text('Select Course:'),
                      DropdownButton<int>(
                        value: selectedCourseId,
                        isExpanded: true,
                        items: courses!
                            .map((course) => DropdownMenuItem<int>(
                                  value: course.id,
                                  child: Text(course.fullName),
                                ))
                            .toList(),
                        onChanged: (int? value) {
                          if (value == null) return;
                          setState(() {
                            selectedCourseId = value;
                            isLoadingStudents = true;
                            students = null;
                            selectedStudentIds.clear();
                          });
                          lmsService
                              .getCourseParticipants(value.toString())
                              .then((fetchedStudents) {
                            setState(() {
                              students = fetchedStudents;
                              isLoadingStudents = false;
                              selectedStudentIds.clear();
                            });
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Students:'),
                      // "Select All Students" checkbox
                      CheckboxListTile(
                        title: const Text('Select All Students'),
                        value: students != null &&
                            students!.isNotEmpty &&
                            selectedStudentIds.length == students!.length,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedStudentIds = students!
                                  .map((student) => student.id)
                                  .toSet();
                            } else {
                              selectedStudentIds.clear();
                            }
                          });
                        },
                      ),
                      if (isLoadingStudents)
                        const Center(child: CircularProgressIndicator())
                      else if (students == null || students!.isEmpty)
                        const Text('No students found for this course.')
                      else
                        SizedBox(
                          height: 200,
                          child: Scrollbar(
                            child: ListView(
                              children: students!
                                  .map((student) => CheckboxListTile(
                                        value: selectedStudentIds
                                            .contains(student.id),
                                        title: Text(
                                            '${student.firstname} ${student.lastname}'),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              selectedStudentIds
                                                  .add(student.id);
                                            } else {
                                              selectedStudentIds
                                                  .remove(student.id);
                                            }
                                          });
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (isAssigning ||
                          isLoadingCourses ||
                          isLoadingStudents ||
                          selectedStudentIds.isEmpty ||
                          selectedCourseId == null)
                      ? null
                      : () async {
                          setState(() {
                            isAssigning = true;
                          });

                          if (_gameNeedsRefresh || _generatedGameData == null) {
                            setState(() {
                              isAssigning = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please regenerate the game before assigning.')),
                            );
                            return;
                          }

                          final title = 'Generated Game: $selectedGameType';
                          final gameType = selectedGameType ?? 'Unknown';
                          final courseId = selectedCourseId!;
                          final didAssign = await assignGameToAllStudents(
                            title,
                            gameType,
                            courseId,
                            specificStudentIds: selectedStudentIds,
                          );
                          setState(() {
                            isAssigning = false;
                          });
                          if (didAssign) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: isAssigning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assign Game'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // String _serializeGameType(GameType type) {
  //   switch (type) {
  //     case GameType.QUIZ:
  //       return 'Quiz Game';
  //     case GameType.MATCHING:
  //       return 'Matching';
  //     case GameType.FLASHCARD:
  //       return 'Flashcards';
  //   }
  // }

  Future<void> _confirmAndClearAssignments() async {
    final role = LocalStorageService.getUserRole();
    if (role != UserRole.teacher) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only teachers can clear assignments.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Assigned Games'),
            content: const Text(
              'This will remove all games you have assigned from the database. '
              'Students will no longer see them. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final teacherIdStr = LocalStorageService.getUserId();
    final teacherId = int.tryParse(teacherIdStr ?? '');
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine teacher id.')),
      );
      return;
    }

    setState(() {
      _isClearingAssignments = true;
    });

    try {
      final games = await _gamificationService.getGamesForTeacher(teacherId);
      final deletions = games
          .where((game) => game.uuid != null)
          .map((game) => _gamificationService.deleteGame(game.uuid!));
      await Future.wait(deletions);
      await _refreshAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cleared ${games.length} assigned game${games.length == 1 ? '' : 's'}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear assignments: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClearingAssignments = false;
        });
      }
    }
  }

  GameType _parseGameType(dynamic value) {
    if (value is GameType) return value;
    if (value is int) {
      if (value >= 0 && value < GameType.values.length) {
        return GameType.values[value];
      }
    }
    final raw = value?.toString().toLowerCase() ?? '';
    if (raw.contains('match')) return GameType.MATCHING;
    if (raw.contains('flash')) return GameType.FLASHCARD;
    return GameType.QUIZ;
  }

  GameType _gameTypeFromLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('match')) return GameType.MATCHING;
    if (normalized.contains('flash')) return GameType.FLASHCARD;
    return GameType.QUIZ;
  }

  Map<String, dynamic>? _decodeGameData(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Failed to decode game data: $e');
      return null;
    }
  }

  String _emojiForGameType(GameType type) {
    switch (type) {
      case GameType.QUIZ:
        return '🧩';
      case GameType.MATCHING:
        return '🔗';
      case GameType.FLASHCARD:
        return '🃏';
    }
  }

  String _labelForGameType(GameType type) {
    switch (type) {
      case GameType.QUIZ:
        return 'Quiz Game';
      case GameType.MATCHING:
        return 'Matching Game';
      case GameType.FLASHCARD:
        return 'Flashcards';
    }
  }

  // double _scorePercentFromGame(AssignedGame game) {
  //   if (game.maxScore != null &&
  //       game.maxScore! > 0 &&
  //       game.rawCorrect != null) {
  //     return (game.rawCorrect! / game.maxScore!) * 100.0;
  //   }
  //   final raw = game.score ?? 0;
  //   final percent = raw <= 1 ? raw * 100 : raw;
  //   return percent;
  // }

  Future<void> _recordGameResult(
      AssignedGame game, GamePlayResult result) async {
    if (!mounted || game.uuid == null) return;
    final normalizedScore =
        result.maxScore == 0 ? 0.0 : result.score / result.maxScore;
    try {
      final response = await _gamificationService.completeGame(
        game.uuid!,
        game.score!.studentId,
        normalizedScore,
        rawCorrect: result.score,
        maxScore: result.maxScore,
      );
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      await _refreshAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Score saved: ${(normalizedScore * 100).toStringAsFixed(0)}%',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save score: $e')),
      );
    }
  }

  Future<Map<int, String>> _buildStudentNameMap(
      List<AssignedGame> games) async {
    final names = Map<int, String>.from(_studentNameCache);
    final lmsService = LmsFactory.getLmsService();
    final uniqueCourseIds = games.map((g) => g.courseId).toSet();

    for (final courseId in uniqueCourseIds) {
      try {
        final participants =
            await lmsService.getCourseParticipants(courseId.toString());
        for (final participant in participants) {
          final fullName =
              '${participant.firstname} ${participant.lastname}'.trim();
          if (fullName.isNotEmpty) {
            names[participant.id] = fullName;
          }
        }
      } catch (_) {
        // Ignore failures; we'll fall back to the student id label.
      }
    }

    if (mounted) {
      setState(() {
        _studentNameCache.addAll(names);
      });
    }
    return names;
  }

  Future<void> _ensureCourseNames() async {
    if (_coursesLoaded) return;
    final lmsService = LmsFactory.getLmsService();
    try {
      final courses = await lmsService.getUserCourses();
      for (final course in courses) {
        _courseNameCache[course.id] = course.fullName;
      }
      _coursesLoaded = true;
    } catch (e) {
      debugPrint('⚠️ Failed to load course names: $e');
    }
  }

  void _showScoreboardDialog() {
    if (LocalStorageService.getUserRole() != UserRole.teacher) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only teachers can view the scoreboard.')),
      );
      return;
    }

    final teacherIdStr = LocalStorageService.getUserId();
    final teacherId = int.tryParse(teacherIdStr ?? '');
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine teacher id.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return FutureBuilder<List<AssignedGame>>(
          future: _gamificationService.getGamesForTeacher(teacherId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Student Scores'),
                content: Text('Failed to load scores: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final games = snapshot.data ?? [];
            if (games.isEmpty) {
              return AlertDialog(
                title: const Text('Student Scores'),
                content: const Text('No assignments found yet.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            return FutureBuilder<Map<int, String>>(
              future: _buildStudentNameMap(games),
              builder: (context, nameSnapshot) {
                if (nameSnapshot.connectionState == ConnectionState.waiting) {
                  return const AlertDialog(
                    content: SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final nameMap = nameSnapshot.data ??
                    Map<int, String>.from(_studentNameCache);

                final groupedByStudent = <int, List<AssignedGame>>{};
                for (final game in games) {
                  groupedByStudent
                      .putIfAbsent(game.score!.studentId, () => [])
                      .add(game);
                }

                final rows = <_ScoreRow>[];
                for (final entry in groupedByStudent.entries) {
                  final studentId = entry.key;
                  final studentName =
                      nameMap[studentId] ?? 'Student $studentId';
                  final studentGames = entry.value
                    ..sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
                  for (final game in studentGames) {
                    final hasRaw = game.score!.rawCorrect != null &&
                        game.score!.maxScore != null &&
                        game.score!.maxScore! > 0;
                    final isCompleted = game.score!.score != null;
                    final statusText = isCompleted
                        ? hasRaw
                            ? 'Completed ${game.score!.rawCorrect}/${game.score!.maxScore}'
                            : 'Completed'
                        : 'Pending';
                    rows.add(
                      _ScoreRow(
                        studentName: studentName,
                        gameTitle: game.title,
                        gameType: _labelForGameType(game.gameType),
                        statusText: statusText,
                        assignedDate: game.assignedDate,
                        isCompleted: isCompleted,
                      ),
                    );
                  }
                }

                return AlertDialog(
                  title: const Text('Student Scores'),
                  content: SizedBox(
                    width: 560,
                    child: rows.isEmpty
                        ? const Text('No scored assignments yet.')
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 16,
                              headingRowHeight: 36,
                              dataRowHeight: 40,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Student',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Game',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Type',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Assigned',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                              rows: rows
                                  .map(
                                    (row) => DataRow(
                                      cells: [
                                        DataCell(Text(row.studentName)),
                                        DataCell(Text(row.gameTitle)),
                                        DataCell(Text(row.gameType)),
                                        DataCell(
                                          Text(
                                            row.statusText,
                                            style: TextStyle(
                                              color: row.isCompleted
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            DateFormat.yMMMd()
                                                .format(row.assignedDate),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ScoreRow {
  final String studentName;
  final String gameTitle;
  final String gameType;
  final String statusText;
  final DateTime assignedDate;
  final bool isCompleted;

  const _ScoreRow({
    required this.studentName,
    required this.gameTitle,
    required this.gameType,
    required this.statusText,
    required this.assignedDate,
    required this.isCompleted,
  });
}
