class RunResult {
  const RunResult({
    required this.score,
    required this.coinsCollected,
    required this.isNewBest,
  });

  final int score;
  final int coinsCollected;
  final bool isNewBest;

  static const RunResult empty = RunResult(
    score: 0,
    coinsCollected: 0,
    isNewBest: false,
  );
}
