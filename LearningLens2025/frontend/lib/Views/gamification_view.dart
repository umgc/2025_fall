import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Games/quiz_game.dart';
import 'package:learninglens_app/Games/matching_game.dart';
import 'package:learninglens_app/Games/flashcard_game.dart';
import 'package:learninglens_app/services/ai_file_service.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';

class GamificationView extends StatefulWidget {
  const GamificationView({super.key});

  @override
  State<GamificationView> createState() => _GamificationViewState();
}

class _GamificationViewState extends State<GamificationView> {
  PlatformFile? _selectedFile;
  String? _selectedGameType;
  String? _selectedDifficulty;
  bool isTeacher = true;
  bool _isGameCreated = false;
  List<Map<String, dynamic>>? _generatedGameData;
  LlmType? _selectedLLM;

  @override
  void initState() {
    super.initState();
    _selectedLLM = LlmType.values
        .firstWhereOrNull((llm) => LocalStorageService.userHasLlmKey(llm));
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
      appBar: AppBar(title: const Text('Generate a Game')),
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
                  final bytes = _selectedFile!.bytes;
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

                  setState(() {
                    _generatedGameData = response;
                    _isGameCreated = true;
                  });

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
                            onComplete: () {},
                            previewMode: true,
                          );
                        case 'Matching':
                          previewContent = MatchingGame(
                            pairs: gameData,
                            onComplete: () {},
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
            const Divider(),
          ],
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
        });
      },
    );
  }

  Widget _buildStudentUI() {
    return const Center(
      child: Text('Game for kids Here'),
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

    try {
      final parsedList = _parseJsonList<Map<String, dynamic>>(raw, (item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        throw Exception('Item is not an object');
      });
      print('✅ Game generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'Response was not valid JSON (generateGameFromText). $e\nResponse:\n$raw');
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
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded.map(mapper).toList();
    }
    throw Exception(
        'Expected JSON array from model but got: ${decoded.runtimeType}');
  }
}
