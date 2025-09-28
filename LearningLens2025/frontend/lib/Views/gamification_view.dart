import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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

  @override
  Widget build(BuildContext context) {
    bool isTeacher = true; // TEMP: Change to logic check later

    return Scaffold(
      appBar: AppBar(title: const Text('Gamification')),
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
          'Gamify a Lesson',
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Game Created!')),
              );
            },
          ),
        )
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
      child: Text('Gamification for Students Coming Soon'),
    );
  }
}
