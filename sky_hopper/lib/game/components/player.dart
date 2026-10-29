import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';

class PlayerComponent extends PositionComponent with HasGameReference {
  PlayerComponent({
    required Vector2 startPosition,
    this.bodyColor = GameConfig.playerColor,
    this.accentColor = Colors.black87,
  }) : super(
         position: startPosition,
         size: Vector2.all(GameConfig.playerRadius * 2),
         anchor: Anchor.center,
       );

  final Color bodyColor;
  final Color accentColor;

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
    // Compute spawn from the CURRENT world size, not from a captured value.
    // This makes restart work correctly after screen resize.
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

    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()..color = Colors.black.withOpacity(0.15),
    );
    canvas.drawCircle(center, radius, Paint()..color = bodyColor);
    canvas.drawCircle(
      Offset(size.x * 0.65, size.y * 0.4),
      radius * 0.18,
      Paint()..color = accentColor,
    );
  }
}
