import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';

class ScrollingBackground extends PositionComponent {
  ScrollingBackground()
    : super(
        position: Vector2.zero(),
        size: GameConfig.designResolution.clone(),
        priority: -10,
      );

  final List<_Cloud> _clouds = [];
  double _hillOffsetFar = 0;
  double _hillOffsetNear = 0;

  static final Random _rng = Random(42);

  @override
  void onLoad() {
    super.onLoad();
    for (int i = 0; i < 6; i++) {
      _clouds.add(
        _Cloud(
          x: _rng.nextDouble() * size.x * 2,
          y: 40 + _rng.nextDouble() * 300,
          scale: 0.7 + _rng.nextDouble() * 0.6,
          speedFactor: 0.3 + _rng.nextDouble() * 0.3,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _hillOffsetFar += GameConfig.scrollSpeed * 0.2 * dt;
    _hillOffsetNear += GameConfig.scrollSpeed * 0.4 * dt;

    final w = size.x;
    for (final c in _clouds) {
      c.x -= GameConfig.scrollSpeed * c.speedFactor * dt;
      if (c.x < -80) {
        c.x += w + 160;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [GameConfig.skyTop, GameConfig.skyBottom],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    _drawHillLayer(
      canvas,
      h * 0.72,
      60,
      _hillOffsetFar,
      GameConfig.hillFarColor,
    );
    _drawHillLayer(
      canvas,
      h * 0.82,
      80,
      _hillOffsetNear,
      GameConfig.hillNearColor,
    );

    for (final c in _clouds) {
      _drawCloud(canvas, c.x, c.y, c.scale);
    }
  }

  void _drawHillLayer(
    Canvas canvas,
    double baseY,
    double amplitude,
    double offset,
    Color color,
  ) {
    final w = size.x;
    final h = size.y;
    final path = Path()..moveTo(0, baseY);

    const step = 20.0;
    final period = 180.0;
    for (double x = 0; x <= w + step; x += step) {
      final phase = (x + offset) / period * 2 * pi;
      final y = baseY - (sin(phase) * amplitude * 0.5 + amplitude * 0.5);
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCloud(Canvas canvas, double x, double y, double scale) {
    final paint = Paint()..color = GameConfig.cloudColor.withOpacity(0.85);
    canvas.drawCircle(Offset(x, y), 14 * scale, paint);
    canvas.drawCircle(Offset(x + 14 * scale, y - 4 * scale), 18 * scale, paint);
    canvas.drawCircle(Offset(x + 32 * scale, y), 13 * scale, paint);
    canvas.drawRect(Rect.fromLTWH(x, y, 32 * scale, 13 * scale), paint);
  }
}

class _Cloud {
  _Cloud({
    required this.x,
    required this.y,
    required this.scale,
    required this.speedFactor,
  });

  double x;
  final double y;
  final double scale;
  final double speedFactor;
}
