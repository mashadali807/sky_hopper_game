import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sky_hopper/game/models/chracter_skin.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

import '../game/game_config.dart';
import '../game/game_state.dart';
import '../game/sky_hopper_game.dart';

import '../widgets/coin_display.dart';
import '../widgets/score_display.dart';
import 'game_over_overlay.dart';
import 'pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.storage, required this.audio});

  final LocalStorageService storage;
  final AudioService audio;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _Overlay { none, pause, gameOver }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  SkyHopperGame? _game;
  _Overlay _overlay = _Overlay.none;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    final skin = skinById(widget.storage.selectedSkin);

    final game = SkyHopperGame(
      previousBest: widget.storage.bestScore,
      bodyColor: skin.bodyColor,
      accentColor: skin.accentColor,
    );

    _game = game;

    game.onRunEnded = _handleRunEnded;
    game.stateNotifier.addListener(_handleStateChange);
    game.audio = widget.audio;
    game.vibrationEnabled = widget.storage.vibrationEnabled;

    widget.audio.applyMusicPreference(widget.storage.musicEnabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    final game = _game;

    if (game != null) {
      game.onRunEnded = null;
      game.stateNotifier.removeListener(_handleStateChange);
    }

    widget.audio.stopMusic();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.audio.onAppPaused();

        if (_game?.isPlaying == true) {
          setState(() {
            _overlay = _Overlay.pause;
          });

          _game?.pauseRun();
        }
        break;

      case AppLifecycleState.resumed:
        widget.audio.onAppResumed();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _handleRunEnded() async {
    final game = _game;
    if (game == null) return;

    widget.audio.playHit();

    if (widget.storage.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }

    try {
      await widget.storage.addCoins(game.lastRunResult.coinsCollected);

      await widget.storage.recordScore(game.lastRunResult.score);
    } catch (e) {
      debugPrint('Persistence failed at game over: $e');
    }

    if (!mounted) return;

    setState(() {
      _overlay = _Overlay.gameOver;
    });
  }

  void _handleStateChange() {
    if (!mounted) return;

    if (_game?.state == GameState.playing &&
        !widget.storage.hasSeenOnboardingHint) {
      widget.storage.markOnboardingHintSeen();
    }

    if (_game?.state != GameState.gameOver && _overlay == _Overlay.gameOver) {
      setState(() {
        _overlay = _Overlay.none;
      });
    }
  }

  void _onPausePressed() {
    setState(() {
      _overlay = _Overlay.pause;
    });

    _game?.pauseRun();
    widget.audio.stopMusic();
  }

  void _onResumePressed() {
    setState(() {
      _overlay = _Overlay.none;
    });

    _game?.resumeRun();

    widget.audio.applyMusicPreference(widget.storage.musicEnabled);
  }

  void _onRestartPressed() {
    setState(() {
      _overlay = _Overlay.none;
    });

    _game?.restartRun();

    widget.audio.applyMusicPreference(widget.storage.musicEnabled);
  }

  void _onHomePressed() {
    _game?.stopAndClear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;

    if (game == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: _overlay != _Overlay.none,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (game.isPlaying) {
          _onPausePressed();
        }
      },
      child: AnimatedBuilder(
        animation: game.stateNotifier,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: GameConfig.skyBottom,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => game.handleTap(),
              child: Stack(
                children: [
                  // Game fills the available screen area.
                  Positioned.fill(
                    child: GameWidget<SkyHopperGame>(
                      game: game,
                      errorBuilder: (context, error) {
                        debugPrint('GAME CRASHED: $error');

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Game error:\n$error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Score, coins, and pause button.
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: game.scoreNotifier,
                                    builder: (_, score, __) {
                                      return ScoreDisplay(score: score);
                                    },
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: game.coinsNotifier,
                                builder: (_, coins, __) {
                                  return CoinDisplay(coins: coins);
                                },
                              ),
                            ],
                          ),

                          const Spacer(),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: FloatingActionButton.small(
                              heroTag: 'pause',
                              backgroundColor: Colors.white.withOpacity(0.8),
                              onPressed: game.isPlaying
                                  ? _onPausePressed
                                  : null,
                              child: const Icon(
                                Icons.pause,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // First-run onboarding hint.
                  if (game.state == GameState.ready &&
                      !widget.storage.hasSeenOnboardingHint)
                    const Positioned.fill(child: _OnboardingHint()),

                  // Pause overlay.
                  if (_overlay == _Overlay.pause)
                    Positioned.fill(
                      child: PauseOverlay(
                        onResume: _onResumePressed,
                        onRestart: _onRestartPressed,
                        onHome: _onHomePressed,
                      ),
                    ),

                  // Game-over overlay.
                  if (_overlay == _Overlay.gameOver)
                    Positioned.fill(
                      child: GameOverOverlay(
                        result: game.lastRunResult,
                        bestScore: widget.storage.bestScore,
                        onPlayAgain: _onRestartPressed,
                        onHome: _onHomePressed,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingHint extends StatefulWidget {
  const _OnboardingHint();

  @override
  State<_OnboardingHint> createState() => _OnboardingHintState();
}

class _OnboardingHintState extends State<_OnboardingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_controller),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 64,
                color: Colors.white.withOpacity(0.9),
                shadows: const [Shadow(color: Colors.black26, blurRadius: 8)],
              ),
              const SizedBox(height: 12),
              Text(
                'TAP TO FLY',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
