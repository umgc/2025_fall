import 'package:flutter/material.dart';

import 'game_result.dart';

class MatchingGame extends StatefulWidget {
  final List<Map<String, dynamic>> pairs;
  final void Function(GamePlayResult result) onComplete;
  final bool previewMode;

  const MatchingGame({
    super.key,
    required this.pairs,
    required this.onComplete,
    this.previewMode = false,
  });

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
  bool _completionReported = false;

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

  String? _matchedTermForDefinition(String definition) {
    for (final entry in userMatches.entries) {
      if (entry.value == definition) {
        return entry.key;
      }
    }
    return null;
  }

  void _reportCompletion() {
    if (_completionReported || widget.previewMode) return;
    _completionReported = true;
    widget.onComplete(
      GamePlayResult(
        score: score,
        maxScore: leftItems.length,
      ),
    );
  }

  bool isGameComplete() {
    return userMatches.length == leftItems.length &&
        userMatches.entries
            .every((entry) => correctMatches[entry.key] == entry.value);
  }

  @override
  Widget build(BuildContext context) {
    if (gameFinished) {
      _reportCompletion();
      return SingleChildScrollView(
        child: Column(
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
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Drag a term to its matching definition.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Match the terms with the correct definitions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: Row(
              children: [
                // Left side: draggable terms
                Expanded(
                  child: ListView.builder(
                    itemCount: leftItems.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final term = leftItems[index];
                      final isMatched = userMatches.containsKey(term);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Draggable<String>(
                          data: term,
                          feedback: Material(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.blueAccent,
                              child: Text(term,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: _MatchChip(
                              label: term,
                              color: Colors.blue.shade50,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isMatched
                                  ? Colors.greenAccent.withOpacity(0.6)
                                  : Colors.blue.shade50,
                              border: Border.all(
                                color: isMatched
                                    ? Colors.green.shade700
                                    : Colors.blue.shade200,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                term,
                                style: TextStyle(
                                  fontWeight: isMatched
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const VerticalDivider(),

                // Right side: drop targets for definitions
                Expanded(
                  child: ListView.builder(
                    itemCount: rightItems.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final definition = rightItems[index];
                      final matchedTerm = _matchedTermForDefinition(definition);
                      return DragTarget<String>(
                        builder: (context, candidateData, rejectedData) {
                          final isDropping = candidateData.isNotEmpty;
                          final hasMatch = matchedTerm != null;
                          return GestureDetector(
                            onTap: hasMatch
                                ? () {
                                    setState(() {
                                      userMatches.remove(matchedTerm);
                                    });
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: hasMatch
                                    ? Colors.greenAccent
                                    : isDropping
                                        ? Colors.blue.shade100
                                        : Colors.grey.shade200,
                                border: Border.all(
                                  color: hasMatch
                                      ? Colors.green.shade700
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: Text(
                                hasMatch
                                    ? '$matchedTerm → $definition'
                                    : definition,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                        onAccept: (term) {
                          setState(() {
                            final existingTerm =
                                _matchedTermForDefinition(definition);
                            if (existingTerm != null) {
                              userMatches.remove(existingTerm);
                            }
                            userMatches.remove(term);
                            userMatches[term] = definition;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!gameFinished)
            ElevatedButton(
              onPressed: () {
                if (gameFinished) return;

                score = 0;
                results.clear();

                for (var entry in userMatches.entries) {
                  final correct = correctMatches[entry.key] == entry.value;
                  if (!widget.previewMode && correct) score++;
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
                _reportCompletion();
              },
              child: const Text('Submit Answers'),
            ),
        ],
      ),
    );
  }
}

class _MatchChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MatchChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color,
      ),
      padding: const EdgeInsets.all(8),
      child: Text(label),
    );
  }
}
