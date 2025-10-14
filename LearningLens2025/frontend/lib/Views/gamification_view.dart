import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Games/quiz_game.dart';
import 'package:learninglens_app/Games/matching_game.dart';
import 'package:learninglens_app/Games/flashcard_game.dart';
import 'package:learninglens_app/services/ai_file_service.dart';

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
    return Column(
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
            final result = await FilePicker.platform.pickFiles();

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
            _gameType('Quiz Hero', Icons.quiz),
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
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            child: const Text('Create Game'),
            onPressed: () async {
              if (_selectedFile == null || _selectedGameType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Please upload a file and select a game type.')),
                );
                return;
              }

              showLoadingDialog(context);

              try {
                final bytes = _selectedFile!.bytes;
                if (bytes == null) throw Exception("No file content found");

                final text = await AIFileService.extractTextFromPDF(bytes);
                late final List<Map<String, dynamic>> response;

                if (_selectedGameType == 'Quiz Hero') {
                  response = await AIFileService.generateGameFromText(text);
                } else if (_selectedGameType == 'Matching') {
                  response =
                      await AIFileService.generateMatchingPairsFromText(text);
                } else if (_selectedGameType == 'Flashcards') {
                  response =
                      await AIFileService.generateFlashcardsFromText(text);
                } else {
                  throw Exception("Unknown game type: $_selectedGameType");
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
        if (_isGameCreated)
          Center(
            child: ElevatedButton(
              child: const Text('Preview Game'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    Widget previewContent;

                    final List<Map<String, dynamic>> _gameData =
                        _generatedGameData ?? [];

                    switch (_selectedGameType) {
                      case 'Quiz Hero':
                        previewContent = QuizGame(
                          questions: _gameData,
                          onComplete: () {},
                          previewMode: true,
                        );
                        break;
                      case 'Matching':
                        previewContent = MatchingGame(
                          pairs: _gameData,
                          onComplete: () {},
                          previewMode: true,
                        );
                        break;
                      case 'Flashcards':
                        previewContent = FlashcardGame(
                          questions: _gameData,
                          onComplete: () {},
                          previewMode: true,
                        );
                        break;
                      default:
                        previewContent = const Text('No game type selected.');
                    }

                    return AlertDialog(
                      title: const Text('Game Preview'),
                      content: previewContent,
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
      ],
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
}
