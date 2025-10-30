
import 'dart:convert';
import 'dart:io';

import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';

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

class GamificationView extends StatefulWidget {
  const GamificationView({super.key});

  @override
  State<GamificationView> createState() => _GamificationViewState();
}

class _GamificationViewState extends State<GamificationView> {

  List<AssignedGame> assignedGames = [];
  final String _localAssignedGamesKey = 'assigned_games_json';
  PlatformFile? _selectedFile;
  String? _selectedGameType;
  String? _selectedDifficulty;
  bool isTeacher = true;
  bool _isGameCreated = false;
  List<Map<String, dynamic>>? _generatedGameData;
  LlmType? _selectedLLM;
  bool _gameNeedsRefresh = false;
  String? _currentGameId;

  @override
  void initState() {
    super.initState();
    _selectedLLM = LlmType.values
        .firstWhereOrNull((llm) => LocalStorageService.userHasLlmKey(llm));
    _loadAssignedGamesFromLocal();
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
                  enabled: LocalStorageService.userHasLlmKey(llm),
                  child: Text(
                    llm.displayName,
                    style: TextStyle(
                      color: LocalStorageService.userHasLlmKey(llm)
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList()),
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
                  final Uint8List? bytes;
                  if (kIsWeb) {
                    bytes = _selectedFile!.bytes;
                  } else {
                    bytes = File(_selectedFile!.path!).readAsBytesSync();
                  }

                  if (bytes == null) throw Exception("No file content found");

                    final text = await AIFileService.extractTextFromPDF(bytes);
                    late final List<Map<String, dynamic>> response;

                    LLM aiModel;
                    if (_selectedLLM == LlmType.CHATGPT) {
                      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
                    } else if (_selectedLLM == LlmType.GROK) {
                      aiModel = GrokLLM(LocalStorageService.getGrokKey());
                    } else if (_selectedLLM == LlmType.DEEPSEEK) {
                      aiModel = DeepseekLLM(LocalStorageService.getDeepseekKey());
                    } else {
                      aiModel =
                          PerplexityLLM(LocalStorageService.getPerplexityKey());
                    }

                    if (_selectedLLM == LlmType.CHATGPT ||
                        _selectedLLM == LlmType.DEEPSEEK ||
                        _selectedLLM == LlmType.PERPLEXITY ||
                        _selectedLLM == LlmType.GROK) {
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

                    final gameId = DateTime.now().millisecondsSinceEpoch.toString();
                    setState(() {
                      _generatedGameData = response;
                      _isGameCreated = true;
                      _gameNeedsRefresh = false;
                      _currentGameId = gameId;
                    });

                    // Assign game to all students after creation
                    final lmsService = LmsFactory.getLmsService();
                    final teacherCourses = await lmsService.getUserCourses();

                    if (teacherCourses.isEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No courses found for this teacher.')),
                      );
                      return;
                    }

                    final courseId = teacherCourses.first.id; // Or show a dropdown for course selection if needed
                    _saveGameContent(gameId, _selectedGameType!, List<Map<String, dynamic>>.from(response));
                    await assignGameToAllStudents(
                      gameId,
                      'Generated Game: $_selectedGameType',
                      _selectedGameType!,
                      courseId,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Game Created!')),
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
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard),
              label: const Text('View Student Scores'),
              onPressed: _showScoreboardDialog,
            ),
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
          child: Text(
            '👋 Welcome back, ready to play?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: assignedGames.length,
            itemBuilder: (context, index) {
              final game = assignedGames[index];
              // Choose emoji based on game type
              String emoji;
              if (game.gameType == 'Quiz Game') {
                emoji = '🧩';
              } else if (game.gameType == 'Matching') {
                emoji = '🔗';
              } else if (game.gameType == 'Flashcards') {
                emoji = '🃏';
              } else {
                emoji = '🕹️';
              }
              final formattedDate = DateFormat.yMMMd().format(game.assignedDate);
              return Card(
                color: Colors.deepPurple[50],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: Text(emoji, style: TextStyle(fontSize: 30)),
                  title: Text(
                    game.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('📅 Assigned: $formattedDate'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final content = _loadGameContent(game.gameData);
                      if (content == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No content found for this game. Ask your teacher to reassign it.')),
                        );
                        return;
                      }

                      final type = content['gameType']?.toString() ?? game.gameType;
                      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(content['data'] ?? const []);

                      if (data.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Game content is empty. Ask your teacher to regenerate it.')),
                        );
                        return;
                      }

                      Widget gameView;
                      switch (type) {
                        case 'Quiz Game':
                          gameView = QuizGame(
                            questions: data,
                            onComplete: (result) {
                              _recordGameResult(game, result);
                            },
                            previewMode: false,
                          );
                          break;
                        case 'Matching':
                          gameView = MatchingGame(
                            pairs: data,
                            onComplete: (result) {
                              _recordGameResult(game, result);
                            },
                            previewMode: false,
                          );
                          break;
                        case 'Flashcards':
                          gameView = FlashcardGame(questions: data, onComplete: () {}, previewMode: false);
                          break;
                        default:
                          gameView = const Text('Game type not supported.');
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
    String gameId,
    String title,
    String gameType,
    int courseId, {
    Set<int>? specificStudentIds,
  }) async {
    final lmsService = LmsFactory.getLmsService();
    final students = await lmsService.getCourseParticipants(courseId.toString());
    final targetStudents = specificStudentIds == null
        ? students
        : students.where((student) => specificStudentIds.contains(student.id)).toList();

    if (targetStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students selected for this assignment.')),
      );
      return false;
    }

    final now = DateTime.now();

    // Create a unique assignment list for this course and gameId
    final List<Map<String, dynamic>> newAssignments = [];

    for (final student in targetStudents) {
      // Save to student-specific local storage
      final studentKey = 'assigned_games_student_${student.id}';
      final existingData = LocalStorageService.getString(studentKey);
      List<dynamic> studentList = existingData != null ? jsonDecode(existingData) : [];

      // Only add if not already assigned
      final alreadyExists = studentList.any((item) => item['gameId'] == gameId);
      if (!alreadyExists) {
        final assignmentPayload = {
          'gameId': gameId,
          'studentId': student.id,
          'courseId': courseId,
          'gameType': gameType,
          'title': title,
          'assignedDate': now.toIso8601String(),
        };
        studentList.add(assignmentPayload);
        LocalStorageService.setString(studentKey, jsonEncode(studentList));
        newAssignments.add(assignmentPayload);
      }
    }

    if (newAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game "$title" is already assigned to the selected students.')),
      );
      _loadAssignedGamesFromLocal();
      return false;
    }

    // Update global assignments without duplicates
    const globalKey = 'assigned_games_global';
    final globalExisting = LocalStorageService.getString(globalKey);
    List<dynamic> globalList = globalExisting != null ? jsonDecode(globalExisting) : [];
    for (final assignment in newAssignments) {
      final duplicate = globalList.any((g) =>
          g['gameId'] == assignment['gameId'] && g['studentId'] == assignment['studentId']);
      if (!duplicate) {
        globalList.add(assignment);
      }
    }
    LocalStorageService.setString(globalKey, jsonEncode(globalList));

    _loadAssignedGamesFromLocal();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Game "$title" assigned to ${newAssignments.length} student${newAssignments.length > 1 ? 's' : ''}.')),
    );
    return true;
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
    void refresh(void Function() fn) {
      // ignore: invalid_use_of_protected_member
      (context as Element).markNeedsBuild();
      fn();
    }

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
                              selectedStudentIds =
                                  students!.map((student) => student.id).toSet();
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

                          final currentGameId = _currentGameId;
                          if (currentGameId == null) {
                            setState(() {
                              isAssigning = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please create a game before assigning it.')),
                            );
                            return;
                          }

                          final title = 'Generated Game: $selectedGameType';
                          final gameType = selectedGameType ?? 'Unknown';
                          final courseId = selectedCourseId!;
                          final didAssign = await assignGameToAllStudents(
                            currentGameId,
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

  List<Map<String, dynamic>> _getResultList(String key) {
    final raw = LocalStorageService.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void _recordGameResult(AssignedGame game, GamePlayResult result) {
    if (!mounted) return;
    final username = LocalStorageService.getUsername();
    final entry = {
      'gameId': game.uuid,
      'studentId': game.studentId,
      'courseId': game.courseId,
      'title': game.title,
      'gameType': game.gameType,
      'score': result.score,
      'maxScore': result.maxScore,
      'completedAt': result.completedAt.toIso8601String(),
      'studentName': username.isNotEmpty
          ? username
          : 'Student ${game.studentId}',
    };

    final studentKey = 'game_results_student_${game.studentId}';
    final studentResults = _getResultList(studentKey)
      ..removeWhere((item) => item['gameId'] == game.uuid);
    studentResults.add(entry);
    LocalStorageService.setString(studentKey, jsonEncode(studentResults));

    const globalKey = 'game_results_global';
    final globalResults = _getResultList(globalKey)
      ..removeWhere((item) =>
          item['gameId'] == game.uuid &&
          item['studentId'].toString() == game.studentId.toString());
    globalResults.add(entry);
    LocalStorageService.setString(globalKey, jsonEncode(globalResults));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Score saved: ${result.score}/${result.maxScore}',
        ),
      ),
    );
  }

  void _showScoreboardDialog() {
    const globalKey = 'game_results_global';
    final raw = LocalStorageService.getString(globalKey);
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No game results recorded yet.')),
      );
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No game results recorded yet.')),
      );
      return;
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final gameId = map['gameId']?.toString() ?? 'unknown';
      grouped.putIfAbsent(gameId, () => []).add(map);
    }

    if (grouped.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No game results recorded yet.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final List<MapEntry<String, List<Map<String, dynamic>>>> games =
            grouped.entries.toList()
              ..sort((a, b) => b.value.length.compareTo(a.value.length));

        return AlertDialog(
          title: const Text('Student Scores'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: games.map((entry) {
                  final scores = entry.value
                    ..sort((a, b) {
                      final scoreCompare =
                          (b['score'] ?? 0).compareTo(a['score'] ?? 0);
                      if (scoreCompare != 0) return scoreCompare;
                      final aTime =
                          DateTime.tryParse(a['completedAt']?.toString() ?? '') ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                      final bTime =
                          DateTime.tryParse(b['completedAt']?.toString() ?? '') ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                      return aTime.compareTo(bTime);
                    });
                  final gameTitle = scores.first['title']?.toString() ?? 'Game';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...scores.asMap().entries.map((scoreEntry) {
                          final data = scoreEntry.value;
                          final rank = scoreEntry.key + 1;
                          final studentName =
                              data['studentName']?.toString() ??
                                  'Student ${data['studentId']}';
                          final completedAt =
                              DateTime.tryParse(data['completedAt']?.toString() ?? '');
                          final formattedTime = completedAt != null
                              ? DateFormat.yMMMd().add_jm().format(completedAt)
                              : '—';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '$rank. $studentName — ${data['score']}/${data['maxScore']} (Completed: $formattedTime)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
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
  }

  void _saveAssignedGamesToLocal() {
    final encoded = assignedGames.map((game) => {
      'gameId': game.uuid,
      'studentId': game.studentId,
      'courseId': game.courseId,
      'gameType': game.gameType,
      'title': game.title,
      'assignedDate': game.assignedDate.toIso8601String(),
    }).toList();
    LocalStorageService.setString(_localAssignedGamesKey, jsonEncode(encoded));
  }

  void _loadAssignedGamesFromLocal() {
    final currentUserId = LocalStorageService.getUserId();
    final currentUserIdStr = currentUserId?.toString();

    // 1️⃣ Try per-student assignments first
    if (currentUserIdStr != null) {
      final userKey = 'assigned_games_student_$currentUserIdStr';
      final raw = LocalStorageService.getString(userKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          assignedGames = decoded.map((item) {
            return AssignedGame(
              uuid: item['gameId'],
              gameData: "",
              assignedBy: 0,
              studentId: int.tryParse(item['studentId'].toString()) ?? 0,
              courseId: int.tryParse(item['courseId'].toString()) ?? 0,
              gameType: item['gameType'],
              title: item['title'],
              assignedDate: DateTime.parse(item['assignedDate']),
            );
          }).toList();
        });
        print('📂 Loaded ${assignedGames.length} games for student key $userKey');
        return;
      }
    }

    // 2️⃣ Fallback: try global assignments
    print('⚠️ No assigned games found for user ID ${currentUserIdStr ?? 'null'} — attempting global fallback');
    const globalKey = 'assigned_games_global';
    final globalRaw = LocalStorageService.getString(globalKey);
    if (globalRaw != null) {
      final List<dynamic> globalDecoded = jsonDecode(globalRaw);

      // Filter by studentId if possible; otherwise show all (demo-safe)
      final List<dynamic> filtered = currentUserIdStr != null
          ? globalDecoded
              .where((item) => item['studentId'].toString() == currentUserIdStr)
              .toList()
          : globalDecoded;

      if (filtered.isNotEmpty) {
        setState(() {
          assignedGames = filtered.map((item) {
            return AssignedGame(
              uuid: item['gameId'],
                            gameData: "",
              assignedBy: 0,
              studentId: int.tryParse(item['studentId'].toString()) ?? 0,
              courseId: int.tryParse(item['courseId'].toString()) ?? 0,
              gameType: item['gameType'],
              title: item['title'],
              assignedDate: DateTime.parse(item['assignedDate']),
            );
          }).toList();
        });
        print('📦 Restored ${assignedGames.length} games from global for user ${currentUserIdStr ?? 'null'}');
        return;
      }
    }

    // 3️⃣ Nothing found
    print('🚫 Global fallback also empty for user ${currentUserIdStr ?? 'null'}');
    setState(() {
      assignedGames = [];
    });
  }

  void _saveGameContent(String gameId, String gameType, List<Map<String, dynamic>> data) {
    final payload = {
      'gameType': gameType,
      'data': data,
    };
    LocalStorageService.setString('game_content_$gameId', jsonEncode(payload));
    print('💾 Saved content for gameId=$gameId (type=$gameType, items=${data.length})');
  }

  Map<String, dynamic>? _loadGameContent(String gameId) {
    final raw = LocalStorageService.getString('game_content_$gameId');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      print('⚠️ Could not decode content for gameId=$gameId');
      return null;
    }
  }

  void _appendToGlobalAssignments(Map<String, dynamic> item) {
    const globalKey = 'assigned_games_global';
    final existing = LocalStorageService.getString(globalKey);
    List<dynamic> list = existing != null ? jsonDecode(existing) : [];

    final alreadyExists = list.any((existingItem) =>
        existingItem['gameId'] == item['gameId'] &&
        existingItem['studentId'] == item['studentId']);
    if (!alreadyExists) {
      list.add(item);
      LocalStorageService.setString(globalKey, jsonEncode(list));
      print('✅ Added new assignment to global storage.');
    } else {
      print('⚠️ Duplicate assignment skipped for studentId ${item['studentId']}');
    }
  }
}
