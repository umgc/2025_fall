import 'package:flutter/material.dart';

class MatchingGame extends StatefulWidget {
  final List<Map<String, dynamic>> pairs;
  final VoidCallback onComplete;
  final bool previewMode;

  const MatchingGame({
    Key? key,
    required this.pairs,
    required this.onComplete,
    this.previewMode = false,
  }) : super(key: key);

  @override
  _MatchingGameState createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  List<String> leftItems = [];
  List<String> rightItems = [];
  Map<String, String> correctMatches = {};
  Map<String, String> userMatches = {};
  int score = 0;
  bool gameFinished = false;
  List<Map<String, String>> results = [];

  @override
  void initState() {
    super.initState();
    debugPrint('📦 MatchingGame received pairs: ${widget.pairs}');
    initializeGame();
  }

  void initializeGame() {
    if (widget.pairs.isEmpty) {
      debugPrint('⚠️ No pairs received.');
      return;
    }

    for (final pair in widget.pairs) {
      final term = pair['term'];
      final definition = pair['definition'] ?? pair['match'];

      if (term == null || definition == null) {
        debugPrint('⚠️ Skipping incomplete pair: $pair');
        continue;
      }

      final termStr = term.toString();
      final defStr = definition.toString();

      leftItems.add(termStr);
      rightItems.add(defStr);
      correctMatches[termStr] = defStr;
    }

    debugPrint('✅ Loaded ${leftItems.length} valid pairs: $correctMatches');
    rightItems.shuffle();
  }

  bool isGameComplete() {
    return userMatches.length == leftItems.length &&
        userMatches.entries
            .every((entry) => correctMatches[entry.key] == entry.value);
  }

  @override
  Widget build(BuildContext context) {
    if (gameFinished) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Complete!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Score: $score / ${leftItems.length}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          ...results.map((r) => ListTile(
                title: Text(r['term'] ?? ''),
                subtitle: Text(
                    'Your Match: ${r['selected']}\nCorrect: ${r['correct']}'),
                trailing: Text(r['status'] ?? ''),
              )),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onComplete,
            child: const Text('Close'),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (widget.previewMode)
          Container(
            width: double.infinity,
            color: Colors.yellow.shade100,
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Preview Mode - Answers not interactive',
              style: TextStyle(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        const Text(
          'Match the terms with the correct definitions:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              // Left side: draggable terms
              Expanded(
                child: Column(
                  children: leftItems.map((term) {
                    return Draggable<String>(
                      data: term,
                      feedback: Material(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.blueAccent,
                          child: Text(term,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                      childWhenDragging:
                          Opacity(opacity: 0.5, child: Text(term)),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(term),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const VerticalDivider(),

              // Right side: drop targets for definitions
              Expanded(
                child: Column(
                  children: rightItems.map((definition) {
                    final matchedTerm = userMatches.entries
                        .firstWhere((e) => e.value == definition,
                            orElse: () => MapEntry('', ''))
                        .key;
                    return DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(8),
                          color: matchedTerm.isNotEmpty
                              ? Colors.greenAccent
                              : Colors.grey.shade200,
                          child: Text(
                            matchedTerm.isNotEmpty
                                ? '$matchedTerm → $definition'
                                : definition,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      },
                      onAccept: (term) {
                        setState(() {
                          userMatches[term] = definition;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!widget.previewMode && !gameFinished)
          ElevatedButton(
            onPressed: () {
              if (gameFinished) return;

              score = 0;
              results.clear();

              for (var entry in userMatches.entries) {
                final correct = correctMatches[entry.key] == entry.value;
                if (correct) score++;
                results.add({
                  'term': entry.key,
                  'selected': entry.value,
                  'correct': correctMatches[entry.key] ?? '',
                  'status': correct ? '✅ Correct' : '❌ Incorrect'
                });
              }

              setState(() {
                gameFinished = true;
              });
            },
            child: const Text('Submit Answers'),
          ),
      ],
    );
  }
}
