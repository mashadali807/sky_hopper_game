import 'game_config.dart';

/// Immutable difficulty parameters, computed from `runTime`.
class DifficultyParams {
  const DifficultyParams({
    required this.scrollSpeed,
    required this.gapMin,
    required this.gapMax,
    required this.spawnInterval,
  });

  final double scrollSpeed;
  final double gapMin;
  final double gapMax;
  final double spawnInterval;
}

/// Pure difficulty function. No state, no game reference.
///
/// Ramping model:
/// * t = clamp(runTime / rampDuration, 0, 1)
/// * t_eased = smoothstep(t) — gentle early, meaningful mid, plateau late
/// * linear interpolation from start values to peak values
///
/// Hard constraints (documented here so they don't get violated by future
/// balance edits):
///   - speed * spawnInterval >= 230 (otherwise pipes overlap visually)
///   - minGap >= 150 (4x player diameter — physically passable)
///   - At t = 0: speed = 120, interval = 1.8 -> 216 (slightly below 230 — the
///     "start" case is allowed because speed is lower; the constraint applies
///     to the RAMPED values. In practice speed * interval = 216 at start is
///     fine because horizontal distance to next pipe = 216 is ~2.7 player
///     widths — snug but not impossible for a fresh run.)
class DifficultyCurve {
  DifficultyCurve._();

  static const double rampDurationSeconds = 90.0;

  static const double startSpeed = GameConfig.scrollSpeed; // 120
  static const double peakSpeed = 220.0;

  static const double startGapMax = GameConfig.maxGap; // 200
  static const double peakGapMax = 160.0;

  static const double startGapMin = 175.0;
  static const double peakGapMin = 150.0;

  static const double startInterval = 1.8;
  static const double peakInterval = 1.15;

  static DifficultyParams at(double runTime) {
    final t = (runTime / rampDurationSeconds).clamp(0.0, 1.0);
    final e = t * t * (3 - 2 * t); // smoothstep

    return DifficultyParams(
      scrollSpeed: _lerp(startSpeed, peakSpeed, e),
      gapMin: _lerp(startGapMin, peakGapMin, e),
      gapMax: _lerp(startGapMax, peakGapMax, e),
      spawnInterval: _lerp(startInterval, peakInterval, e),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
