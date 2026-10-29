import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameConfig {
  GameConfig._();

  // --- Visual theme ---
  static const Color skyTop = Color(0xFF4FC3F7);
  static const Color skyBottom = Color(0xFFB3E5FC);
  static const Color playerColor = Color(0xFFFFC107); // amber placeholder
  static const Color pipeColor = Color(0xFF43A047); // green placeholder
  static const Color cloudColor = Color(0xFFFFFFFF);
  static const Color hillFarColor = Color(0xFF90CAF9);
  static const Color hillNearColor = Color(0xFF64B5F6);

  // --- Camera / world ---
  static Vector2 designResolution = Vector2(360, 640);

  // --- Player physics ---
  static const double gravity = 1400;
  static const double jumpVelocity = -420;
  static const double maxFallSpeed = 700;
  static const double playerRadius = 18;
  static const double playerStartXFraction = 0.28;
  static const double playerEdgePadding = 8;

  // --- World scrolling ---
  /// Horizontal speed of obstacles and background layers, in units/sec.
  static const double scrollSpeed = 120;

  /// How often (seconds) a new obstacle pair appears.
  static const double obstacleSpawnInterval = 1.8;

  static const double startInterval =
      2.3; // was 1.8  → +0.5s more space at start
  static const double peakInterval =
      1.55; // was 1.15 → +0.4s more space at max difficulty

  // --- Obstacles ---
  static const double pipeWidth = 70;

  /// Randomized gap height in [minGap, maxGap].
  static const double minGap = 150;
  static const double maxGap = 200;

  /// Vertical margin at the top/bottom of the world that the gap center
  /// must stay away from, so a visible pipe always exists above and below.
  static const double obstacleVerticalMargin = 60;
  static const double groundHeight = 40;

  /// Y of the ground surface (player's bottom touching this = death).
  static double get groundSurfaceY => designResolution.y - groundHeight;

  // --- Coins ---
  static const double coinRadius = 10;
  static const Color coinColor = Color(0xFFFFD54F); // amber gold
  static const Color coinShadowColor = Color(0xFFFFB300);

  /// Probability that an obstacle pair spawns a coin in its gap [0..1].
  static const double coinSpawnProbability = 0.6;

  /// Coin sits this fraction down the gap from the gap's top.
  /// 0.25 = upper quarter, which is where the player naturally flies.
  static const double coinGapVerticalFraction = 0.25;

  // --- Audio assets ---
  // --- Audio assets ---
  static const String sfxJump = 'jump.wav';
  static const String sfxCoin = 'coin.wav';
  static const String sfxHit = 'hit.wav';
  static const String musicBackground = 'bg_music.wav';

  /// Volume multipliers (0.0 to 1.0). Music is quieter than SFX.
  static const double sfxVolume = 0.8;
  static const double musicVolume = 0.4;
}
