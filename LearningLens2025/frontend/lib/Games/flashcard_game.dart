import 'package:flutter/material.dart';

class FlashcardGame extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final VoidCallback onComplete;
  final bool previewMode;

  const FlashcardGame({
    super.key,
    required this.questions,
    required this.onComplete,
    this.previewMode = false,
  });

  @override
  State<FlashcardGame> createState() => _FlashcardGameState();
}

class _FlashcardGameState extends State<FlashcardGame> {
  late final List<Map<String, dynamic>> _limitedQuestions;

  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _limitedQuestions = widget.questions.take(5).toList();
  }

  void _goTo(int index) {
    if (index >= 0 && index < _limitedQuestions.length) {
      setState(() {
        _currentIndex = index;
        _showAnswer = false;
      });
      if (!_completionReported && index == _limitedQuestions.length - 1) {
        _markComplete(auto: true);
      }
    }
  }

  void _markComplete({bool auto = false}) {
    if (_completionReported) return;
    setState(() {
      _completionReported = true;
    });
    if (!widget.previewMode) {
      widget.onComplete();
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcards completed!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _limitedQuestions[_currentIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Flashcard ${_currentIndex + 1} of ${_limitedQuestions.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (widget.previewMode)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Tap the card to flip and view the definition.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _showAnswer = !_showAnswer),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Center(
                child: Text(
                  _showAnswer
                      ? current['definition'] ?? 'No definition'
                      : current['term'] ?? 'No term',
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed:
                  _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: _currentIndex < _limitedQuestions.length - 1
                  ? () => _goTo(_currentIndex + 1)
                  : () => _markComplete(auto: true),
              child: const Text('Next'),
            ),
          ],
        ),
        if (!widget.previewMode)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: _completionReported ? null : _markComplete,
              child: Text(_completionReported ? 'Completed' : 'Mark Complete'),
            ),
          ),
      ],
    );
  }
}
