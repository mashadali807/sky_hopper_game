import 'dart:math';

import 'package:flame/components.dart';

import '../game_config.dart';
import '../difficulty_curve.dart';
import '../sky_hopper_game.dart';
import '../components/obstacle_pair.dart';
import '../components/coin.dart';

class ObstacleSpawner extends Component with HasGameReference<SkyHopperGame> {
  double _accumulator = 0;

  final Random _coinRng = Random();

  void resetTimer() {
    _accumulator = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final difficulty = game.currentDifficulty;

    _accumulator += dt;
    if (_accumulator >= difficulty.spawnInterval) {
      _accumulator -= difficulty.spawnInterval;
      _spawnObstacle(difficulty);
    }
  }

  void _spawnObstacle(DifficultyParams difficulty) {
    // Spawn off the RIGHT edge of the current world, not the design size.
    final pair = ObstaclePair(
      startPosition: Vector2(game.size.x + GameConfig.pipeWidth, 0),
      scrollSpeed: difficulty.scrollSpeed,
      gapMin: difficulty.gapMin,
      gapMax: difficulty.gapMax,
      worldHeight: game.size.y,
    );
    game.world.add(pair);

    if (_coinRng.nextDouble() < GameConfig.coinSpawnProbability) {
      game.world.add(CoinComponent(startPosition: pair.coinSpawnPosition));
    }
  }
}
