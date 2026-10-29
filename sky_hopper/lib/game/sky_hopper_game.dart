import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sky_hopper/game/system/collision_system.dart';
import 'package:sky_hopper/game/system/obstacle_spawner.dart';
import 'package:sky_hopper/game/system/score_system.dart';
import 'package:sky_hopper/service/audio_service.dart';

import 'game_config.dart';
import 'game_state.dart';
import 'difficulty_curve.dart';
import 'components/player.dart';
import 'components/obstacle_pair.dart';
import 'components/coin.dart';
import 'components/scrolling_background.dart';
import 'models/run_result.dart';

class SkyHopperGame extends FlameGame with TapCallbacks {
  SkyHopperGame({
    this.previousBest = 0,
    this.bodyColor = GameConfig.playerColor,
    this.accentColor = Colors.black87,
  });

  final int previousBest;
  final Color bodyColor;
  final Color accentColor;

  AudioService? audio;
  bool vibrationEnabled = true;

  late final PlayerComponent _player;
  late final ScrollingBackground _background;
  late final ObstacleSpawner _spawner;

  GameState _state = GameState.ready;

  int _score = 0;
  int _coinsCollected = 0;
  double _runTime = 0;

  RunResult _lastRunResult = RunResult.empty;

  final ValueNotifier<GameState> stateNotifier = ValueNotifier<GameState>(
    GameState.ready,
  );

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> coinsNotifier = ValueNotifier<int>(0);

  PlayerComponent get player => _player;
  ScrollingBackground get background => _background;
  ObstacleSpawner get spawner => _spawner;

  GameState get state => _state;

  bool get isPlaying => _state == GameState.playing;
  bool get isGameOver => _state == GameState.gameOver;
  bool get isPaused => _state == GameState.paused;

  int get score => _score;
  int get coinsCollected => _coinsCollected;

  RunResult get lastRunResult => _lastRunResult;

  DifficultyParams get currentDifficulty => DifficultyCurve.at(_runTime);

  VoidCallback? onRunEnded;

  bool _loaded = false;

  @override
  Color backgroundColor() => GameConfig.skyBottom;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Make the camera viewport occupy all available game space.
    camera.viewport = MaxViewport();

    // IMPORTANT:
    // Place the world origin at the top-left corner.
    // Your game components use screen-style coordinates
    // beginning at (0, 0).
    camera.viewfinder.anchor = Anchor.topLeft;

    _background = ScrollingBackground();
    _background.size.setValues(size.x, size.y);

    world.add(_background);

    _player = PlayerComponent(
      startPosition: Vector2(
        size.x * GameConfig.playerStartXFraction,
        size.y / 2,
      ),
      bodyColor: bodyColor,
      accentColor: accentColor,
    );

    world.add(_player);

    _spawner = ObstacleSpawner();
    world.add(_spawner);

    _loaded = true;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    // onGameResize can run before onLoad completes.
    if (!_loaded) return;

    if (_state == GameState.ready) {
      _player.position.setValues(
        newSize.x * GameConfig.playerStartXFraction,
        newSize.y / 2,
      );
    }

    _background.size.setValues(newSize.x, newSize.y);
  }

  @override
  void onTapDown(TapDownEvent event) {
    handleTap();
  }

  void handleTap() {
    if (_state == GameState.ready) {
      _setState(GameState.playing);
      _player.applyJump();
      audio?.playJump();
      return;
    }

    if (_state == GameState.playing) {
      _player.applyJump();
      audio?.playJump();
    }
  }

  void pauseRun() {
    if (_state != GameState.playing) return;

    _setState(GameState.paused);
    paused = true;
  }

  void resumeRun() {
    if (_state != GameState.paused) return;

    _setState(GameState.playing);
    paused = false;
  }

  void restartRun() {
    _clearWorldEntities();
    _spawner.resetTimer();
    _player.reset();

    _score = 0;
    _coinsCollected = 0;
    _runTime = 0;

    _lastRunResult = RunResult.empty;

    scoreNotifier.value = 0;
    coinsNotifier.value = 0;

    paused = false;
    _setState(GameState.playing);
  }

  void stopAndClear() {
    _clearWorldEntities();
    _spawner.resetTimer();
    _player.reset();

    _score = 0;
    _coinsCollected = 0;
    _runTime = 0;

    _lastRunResult = RunResult.empty;

    scoreNotifier.value = 0;
    coinsNotifier.value = 0;

    paused = false;
    _setState(GameState.ready);
  }

  void _clearWorldEntities() {
    final obstacles = world.children.whereType<ObstaclePair>().toList();

    for (final obstacle in obstacles) {
      obstacle.removeFromParent();
    }

    final coins = world.children.whereType<CoinComponent>().toList();

    for (final coin in coins) {
      coin.removeFromParent();
    }
  }

  void _setState(GameState newState) {
    if (_state == newState) return;

    _state = newState;
    stateNotifier.value = newState;
  }

  @override
  void update(double dt) {
    if (_state != GameState.playing) return;

    _runTime += dt;

    super.update(dt);

    if (_player.isOnGround) {
      _endRun();
      return;
    }

    for (final obstacle in world.children.whereType<ObstaclePair>()) {
      if (CollisionSystem.playerHitsAnyPipe(
        _player.colliderCenter,
        _player.colliderRadius,
        [obstacle.topPipeWorldRect, obstacle.bottomPipeWorldRect],
      )) {
        _endRun();
        return;
      }
    }

    final newPoints = ScoreSystem.scoreNewlyPassedPipes(
      obstacles: world.children.whereType<ObstaclePair>(),
      player: _player,
    );

    if (newPoints > 0) {
      _score += newPoints;
      scoreNotifier.value = _score;
    }

    for (final coin in world.children.whereType<CoinComponent>()) {
      if (coin.isCollected) continue;

      if (CollisionSystem.circleVsCircle(
        coin.colliderCenter,
        coin.colliderRadius,
        _player.colliderCenter,
        _player.colliderRadius,
      )) {
        coin.collect();

        _coinsCollected++;
        coinsNotifier.value = _coinsCollected;

        audio?.playCoin();

        if (vibrationEnabled) {
          HapticFeedback.lightImpact();
        }
      }
    }
  }

  void _endRun() {
    if (_state == GameState.gameOver) return;

    _lastRunResult = RunResult(
      score: _score,
      coinsCollected: _coinsCollected,
      isNewBest: _score > previousBest,
    );

    paused = false;
    _setState(GameState.gameOver);

    onRunEnded?.call();
  }

  @override
  void onRemove() {
    stateNotifier.dispose();
    scoreNotifier.dispose();
    coinsNotifier.dispose();

    super.onRemove();
  }
}
