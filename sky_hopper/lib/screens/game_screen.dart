import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sky_hopper/game/models/chracter_skin.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

import '../game/game_config.dart';
import '../game/game_state.dart';
import '../game/sky_hopper_game.dart';
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

    _game = SkyHopperGame(
      previousBest: widget.storage.bestScore,
      bodyColor: skin.bodyColor,
      accentColor: skin.accentColor,
      playerShape: skin.shape,
    );
    _game!.onRunEnded = _handleRunEnded;
    _game!.stateNotifier.addListener(_handleStateChange);
    _game!.audio = widget.audio;
    _game!.vibrationEnabled = widget.storage.vibrationEnabled;

    widget.audio.applyMusicPreference(widget.storage.musicEnabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game?.onRunEnded = null;
    _game?.stateNotifier.removeListener(_handleStateChange);
    widget.audio.stopMusic();
    _game = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.audio.onAppPaused();
        if (_game?.isPlaying == true) {
          setState(() => _overlay = _Overlay.pause);
          _game?.pauseRun();
        }
      case AppLifecycleState.resumed:
        widget.audio.onAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _handleRunEnded() async {
    final game = _game;
    if (game == null) return;

    widget.audio.playHit();
    if (widget.storage.vibrationEnabled) HapticFeedback.mediumImpact();

    try {
      await widget.storage.addCoins(game.lastRunResult.coinsCollected);
      await widget.storage.recordScore(game.lastRunResult.score);
    } catch (e) {
      debugPrint('Persistence failed at game over: $e');
    }

    if (!mounted) return;
    setState(() => _overlay = _Overlay.gameOver);
  }

  void _handleStateChange() {
    if (!mounted) return;

    // Removed the "markOnboardingHintSeen" logic so the hint shows every time.

    if (_game?.state != GameState.gameOver && _overlay == _Overlay.gameOver) {
      setState(() => _overlay = _Overlay.none);
    }
  }

  void _onPausePressed() {
    setState(() => _overlay = _Overlay.pause);
    _game?.pauseRun();
    widget.audio.stopMusic();
  }

  void _onResumePressed() {
    setState(() => _overlay = _Overlay.none);
    _game?.resumeRun();
    widget.audio.applyMusicPreference(widget.storage.musicEnabled);
  }

  void _onRestartPressed() {
    setState(() => _overlay = _Overlay.none);
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
        if (game.isPlaying) _onPausePressed();
      },
      child: AnimatedBuilder(
        animation: game.stateNotifier,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: GameConfig.skyBottom,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => game.handleTap(),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // --- The Game Canvas ---
                    Positioned.fill(
                      child: GameWidget<SkyHopperGame>(
                        game: game,
                        errorBuilder: (context, error) {
                          debugPrint('GAME CRASHED: $error');
                          return Center(
                            child: Text(
                              'Game error: $error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),

                    // --- The HUD (Heads Up Display) ---
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- SCORE (Top Center) ---
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: game.scoreNotifier,
                                        builder: (_, score, __) => Text(
                                          '$score',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // --- COINS (Top Right) ---
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: game.coinsNotifier,
                                    builder: (_, coins, __) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.monetization_on,
                                            color: Colors.amber,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$coins',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // --- PAUSE BUTTON (Bottom Right) ---
                            Align(
                              alignment: Alignment.bottomRight,
                              child: GestureDetector(
                                onTap: game.isPlaying ? _onPausePressed : null,
                                child: AnimatedOpacity(
                                  opacity: game.isPlaying ? 1.0 : 0.5,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.pause_rounded,
                                      color: Color(0xFF1E3C72),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Onboarding Hint ---
                    // Changed condition to ONLY check if the game is ready.
                    // This guarantees it shows on every new run.
                    if (game.state == GameState.ready)
                      const Positioned.fill(child: _OnboardingHint()),

                    // --- Overlays ---
                    if (_overlay == _Overlay.pause)
                      Positioned.fill(
                        child: PauseOverlay(
                          onResume: _onResumePressed,
                          onRestart: _onRestartPressed,
                          onHome: _onHomePressed,
                        ),
                      ),
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
      duration: const Duration(milliseconds: 1000),
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
          opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 56, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'TAP TO FLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
