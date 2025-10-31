import 'package:flutter/material.dart';

import 'game_result.dart';

class QuizGame extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final void Function(GamePlayResult result) onComplete;
  final bool previewMode;

  const QuizGame({
    super.key,
    required this.questions,
    required this.onComplete,
    this.previewMode = false,
  });

  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  int currentIndex = 0;
  int score = 0;
  bool showResult = false;
  bool? wasCorrect;
  List<Map<String, String>> userAnswers = [];
  String? previewSelected;
  bool _completionReported = false;

  void checkAnswer(String selected) {
    final correctAnswerIndex = widget.questions[currentIndex]['answer'] as int;
    final correctAnswerText = widget.questions[currentIndex]['options']
            [correctAnswerIndex]
        .toString();
    final correct = correctAnswerText == selected;

    userAnswers.add({
      'question': widget.questions[currentIndex]['question'],
      'selected': selected,
      'correct': correctAnswerText,
    });

    if (widget.previewMode) {
      setState(() {
        previewSelected = selected;
        showResult = true;
      });
    } else {
      setState(() {
        wasCorrect = correct;
        if (correct) score++;
        showResult = true;
      });
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) nextQuestion();
    });
  }

  void nextQuestion() {
    final questions = widget.questions.take(5).toList();
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        showResult = false;
        wasCorrect = null;
        previewSelected = null;
      });
    } else {
      setState(() {
        currentIndex++;
        showResult = true;
      });
      _reportCompletion(questions.length);
    }
  }

  void _reportCompletion(int totalQuestions) {
    if (_completionReported || widget.previewMode) return;
    _completionReported = true;
    widget.onComplete(
      GamePlayResult(
        score: score,
        maxScore: totalQuestions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions.take(5).toList();
    if (currentIndex >= questions.length) {
      _reportCompletion(questions.length);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Completed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Score: $score / ${questions.length}'),
          const SizedBox(height: 20),
          ...userAnswers.map((answer) {
            final isCorrect = answer['selected'] == answer['correct'];
            return ListTile(
              title: Text(answer['question'] ?? 'No question'),
              subtitle: Text(
                isCorrect
                    ? '✅ You answered correctly'
                    : '❌ Your answer: ${answer['selected']} | Correct: ${answer['correct']}',
              ),
            );
          }),
        ],
      );
    }
    final question = questions[currentIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Question ${widget.previewMode ? currentIndex + 1 : currentIndex + 1}/${questions.length}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          question['question'] ?? 'No question',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          question['options']?.length ?? 0,
          (index) {
            final option = question['options'][index].toString();
            return ListTile(
              title: Text(option),
              leading: Radio<String>(
                value: option,
                groupValue: widget.previewMode
                    ? previewSelected
                    : (showResult
                        ? question['options'][question['answer'] as int]
                            .toString()
                        : null),
                onChanged: showResult ? null : (_) => checkAnswer(option),
              ),
            );
          },
        ),
        if (showResult && !widget.previewMode)
          Column(
            children: [
              Text(
                wasCorrect! ? '✅ Correct!' : '❌ Incorrect',
                style: TextStyle(
                  fontSize: 18,
                  color: wasCorrect! ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        if (widget.previewMode)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Preview Mode',
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
