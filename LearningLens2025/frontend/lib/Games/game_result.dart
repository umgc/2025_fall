class GamePlayResult {
  final int score;
  final int maxScore;
  final DateTime completedAt;

  GamePlayResult({
    required this.score,
    required this.maxScore,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();
}
