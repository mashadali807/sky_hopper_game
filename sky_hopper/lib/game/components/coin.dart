import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';

/// A collectible coin in the world. Moves left, animates (spin), and when
/// its circle overlaps the player's circle, it flags itself collected and
/// notifies the game. Exactly once.
class CoinComponent extends PositionComponent {
  CoinComponent({required Vector2 startPosition})
    : super(
        position: startPosition,
        size: Vector2.all(GameConfig.coinRadius * 2),
        anchor: Anchor.center,
      );

  /// Set once, when collected. Never read‑and‑written from outside.
  bool _collected = false;

  double _spinTimer = 0;

  /// Public read for collision test and tests.
  bool get isCollected => _collected;
  Vector2 get colliderCenter => position.clone();
  double get colliderRadius => GameConfig.coinRadius;

  /// Called by the game when the player circle overlaps this coin's circle.
  /// Idempotent — collecting twice does nothing.
  void collect() {
    if (_collected) return;
    _collected = true;
    // Fade out then remove. Simple and visually satisfying.
    removeFromParent(); // module 9 may replace with a small tween — for now instant.
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move left at world scroll speed.
    position.x -= GameConfig.scrollSpeed * dt;

    // Spin animation (cosmetic).
    _spinTimer += dt;

    // Despawn past left edge.
    if (!isRemoving && position.x + size.x < -GameConfig.coinRadius) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final r = GameConfig.coinRadius;

    // Squash horizontally over time to fake a spinning coin.
    // Period = 1.2s; squashFactor oscillates between 0.35 and 1.0.
    final squash = 0.35 + 0.65 * (0.5 + 0.5 * math.cos(_spinTimer * 5.0));
    final rX = r * squash;

    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 2),
        width: rX * 2,
        height: r * 2,
      ),
      Paint()..color = Colors.black.withOpacity(0.15),
    );

    // Coin body (ellipse to fake spin).
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [GameConfig.coinColor, GameConfig.coinShadowColor],
        center: Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rX * 2, height: r * 2),
      bodyPaint,
    );

    // Rim outline.
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rX * 2, height: r * 2),
      Paint()
        ..color = GameConfig.coinShadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
