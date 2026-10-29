import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';

class ObstaclePair extends PositionComponent {
  ObstaclePair._({
    required Vector2 startPosition,
    required double scrollSpeed,
    required this.gapHeight,
    required this.gapCenterY,
    required this.worldHeight,
  }) : _scrollSpeed = scrollSpeed,
       super(
         position: startPosition,
         size: Vector2(GameConfig.pipeWidth, worldHeight),
         anchor: Anchor.topLeft,
       );

  factory ObstaclePair({
    required Vector2 startPosition,
    required double scrollSpeed,
    required double gapMin,
    required double gapMax,
    required double worldHeight,
  }) {
    final lo = gapMin <= gapMax ? gapMin : gapMax;
    final hi = gapMin <= gapMax ? gapMax : gapMin;

    final gapHeight = lo + _rng.nextDouble() * (hi - lo);

    final minCenter = GameConfig.obstacleVerticalMargin + gapHeight / 2;
    final maxCenter =
        worldHeight - GameConfig.obstacleVerticalMargin - gapHeight / 2;
    final gapCenterY = minCenter + _rng.nextDouble() * (maxCenter - minCenter);

    return ObstaclePair._(
      startPosition: startPosition,
      scrollSpeed: scrollSpeed,
      gapHeight: gapHeight,
      gapCenterY: gapCenterY,
      worldHeight: worldHeight,
    );
  }

  final double _scrollSpeed;
  final double gapHeight;
  final double gapCenterY;
  final double worldHeight;

  bool hasBeenPassed = false;

  static final Random _rng = Random();

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= _scrollSpeed * dt;
    if (!isRemoving && position.x + size.x < -GameConfig.pipeWidth) {
      removeFromParent();
    }
  }

  Vector2 get coinSpawnPosition {
    final gapTop = gapCenterY - gapHeight / 2;
    final y = gapTop + gapHeight * GameConfig.coinGapVerticalFraction;
    final x = position.x + GameConfig.pipeWidth / 2;
    return Vector2(x, y);
  }

  Rect get topPipeWorldRect {
    final gapTop = gapCenterY - gapHeight / 2;
    return Rect.fromLTWH(position.x, position.y, size.x, gapTop - position.y);
  }

  Rect get bottomPipeWorldRect {
    final gapBottom = gapCenterY + gapHeight / 2;
    return Rect.fromLTWH(
      position.x,
      position.y + gapBottom,
      size.x,
      worldHeight - (position.y + gapBottom),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..color = GameConfig.pipeColor;
    final outline = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final gapTop = gapCenterY - gapHeight / 2;
    final gapBottom = gapCenterY + gapHeight / 2;

    final topRect = Rect.fromLTWH(0, 0, size.x, gapTop);
    canvas.drawRect(topRect, paint);
    canvas.drawRect(topRect, outline);

    final bottomRect = Rect.fromLTWH(0, gapBottom, size.x, size.y - gapBottom);
    canvas.drawRect(bottomRect, paint);
    canvas.drawRect(bottomRect, outline);

    final lipHeight = 12.0;
    final lipOverhang = 6.0;
    final topLip = Rect.fromLTWH(
      -lipOverhang,
      gapTop - lipHeight,
      size.x + lipOverhang * 2,
      lipHeight,
    );
    final bottomLip = Rect.fromLTWH(
      -lipOverhang,
      gapBottom,
      size.x + lipOverhang * 2,
      lipHeight,
    );
    canvas.drawRect(topLip, paint);
    canvas.drawRect(topLip, outline);
    canvas.drawRect(bottomLip, paint);
    canvas.drawRect(bottomLip, outline);
  }
}
