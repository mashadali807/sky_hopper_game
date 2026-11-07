import 'dart:math' as Math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';
import '../models/chracter_skin.dart'; // Import PlayerShape

class PlayerComponent extends PositionComponent with HasGameReference {
  PlayerComponent({
    required Vector2 startPosition,
    this.bodyColor = GameConfig.playerColor,
    this.accentColor = Colors.black87,
    this.shape = PlayerShape.circle,
  }) : super(
         position: startPosition,
         size: Vector2.all(GameConfig.playerRadius * 2),
         anchor: Anchor.center,
       );

  final Color bodyColor;
  final Color accentColor;
  final PlayerShape shape;

  double _velocityY = 0;

  double get velocityY => _velocityY;
  Vector2 get colliderCenter => position.clone();
  double get colliderRadius => GameConfig.playerRadius;

  bool get isOnGround =>
      position.y + GameConfig.playerRadius >=
      (game.size.y - GameConfig.groundHeight);

  void applyJump() {
    _velocityY = GameConfig.jumpVelocity;
  }

  void reset() {
    position.setValues(
      game.size.x * GameConfig.playerStartXFraction,
      game.size.y / 2,
    );
    _velocityY = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _velocityY += GameConfig.gravity * dt;
    if (_velocityY > GameConfig.maxFallSpeed) {
      _velocityY = GameConfig.maxFallSpeed;
    }

    position.y += _velocityY * dt;

    // Ceiling clamp.
    final minY = GameConfig.playerEdgePadding + size.y / 2;
    if (position.y < minY) {
      position.y = minY;
      if (_velocityY < 0) _velocityY = 0;
    }

    // Ground clamp.
    final groundY =
        game.size.y - GameConfig.groundHeight - GameConfig.playerRadius;
    if (position.y > groundY) {
      position.y = groundY;
      if (_velocityY > 0) _velocityY = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    final bodyPaint = Paint()..color = bodyColor;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.15);
    final accentPaint = Paint()..color = accentColor;

    // Draw shadow
    canvas.drawCircle(center + const Offset(0, 4), radius, shadowPaint);

    final path = Path();

    // Draw Body based on shape
    switch (shape) {
      case PlayerShape.circle:
        canvas.drawCircle(center, radius, bodyPaint);
        break;
      case PlayerShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: radius * 1.8,
              height: radius * 1.8,
            ),
            Radius.circular(radius * 0.2),
          ),
          bodyPaint,
        );
        break;
      case PlayerShape.triangle:
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius, center.dy + radius * 0.8);
        path.lineTo(center.dx - radius, center.dy + radius * 0.8);
        path.close();
        canvas.drawPath(path, bodyPaint);
        break;
      case PlayerShape.star:
        final points = 5;
        final angle = Math.pi / points;
        for (int i = 0; i < points * 2; i++) {
          final r = i.isEven ? radius : radius * 0.4;
          final x = center.dx + r * Math.sin(i * angle);
          final y = center.dy - r * Math.cos(i * angle);
          if (i == 0)
            path.moveTo(x, y);
          else
            path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, bodyPaint);
        break;
      case PlayerShape.hexagon:
        for (int i = 0; i < 6; i++) {
          final a = Math.pi / 3 * i;
          final x = center.dx + radius * Math.cos(a);
          final y = center.dy + radius * Math.sin(a);
          if (i == 0)
            path.moveTo(x, y);
          else
            path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, bodyPaint);
        break;
    }

    // Draw eye / accent
    canvas.drawCircle(
      Offset(size.x * 0.65, size.y * 0.4),
      radius * 0.18,
      accentPaint,
    );
  }
}
