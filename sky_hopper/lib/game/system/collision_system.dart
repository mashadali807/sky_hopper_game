import 'dart:ui';

import 'package:flame/components.dart';

/// Pure, side-effect-free collision helpers. No Flame state, no game
/// reference — trivially unit-testable.
class CollisionSystem {
  CollisionSystem._();

  static bool circleVsRect(Vector2 circleCenter, double radius, Rect rect) {
    final cx = circleCenter.x.clamp(rect.left, rect.right);
    final cy = circleCenter.y.clamp(rect.top, rect.bottom);
    final dx = circleCenter.x - cx;
    final dy = circleCenter.y - cy;
    return dx * dx + dy * dy <= radius * radius;
  }

  static bool circleVsCircle(
    Vector2 aCenter,
    double aRadius,
    Vector2 bCenter,
    double bRadius,
  ) {
    final dx = aCenter.x - bCenter.x;
    final dy = aCenter.y - bCenter.y;
    final sumR = aRadius + bRadius;
    return dx * dx + dy * dy <= sumR * sumR;
  }

  static bool playerHitsAnyPipe(
    Vector2 playerCenter,
    double playerRadius,
    Iterable<Rect> pipeRects,
  ) {
    for (final r in pipeRects) {
      if (circleVsRect(playerCenter, playerRadius, r)) return true;
    }
    return false;
  }
}
