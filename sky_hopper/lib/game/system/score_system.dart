import '../components/obstacle_pair.dart';
import '../components/player.dart';

/// Pure, stateless scoring rules. No Flame state beyond reading component
/// positions. Trivially testable.
class ScoreSystem {
  ScoreSystem._();

  /// Iterate all live obstacle pairs and increment the running score for
  /// each that has just been cleared by the player.
  ///
  /// "Cleared" = the pair's right edge is now strictly to the left of the
  /// player's left edge, AND the pair hasn't already been counted.
  ///
  /// Returns the number of pairs cleared this tick (0 or, rarely, 1 — but
  /// we return int to stay honest if two pairs are cleared in one tick
  /// during a lag spike).
  static int scoreNewlyPassedPipes({
    required Iterable<ObstaclePair> obstacles,
    required PlayerComponent player,
  }) {
    final playerLeftEdge = player.colliderCenter.x - player.colliderRadius;
    int newlyPassed = 0;

    for (final o in obstacles) {
      if (o.hasBeenPassed) continue;
      final pairRightEdge = o.position.x + o.size.x;
      if (pairRightEdge < playerLeftEdge) {
        o.hasBeenPassed = true;
        newlyPassed++;
      }
    }
    return newlyPassed;
  }
}
