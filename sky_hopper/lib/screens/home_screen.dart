import 'package:flutter/material.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

import '../app/app_routes.dart';
import '../game/game_config.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage, required this.audio});

  final LocalStorageService storage;
  final AudioService audio;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.storage.addListener(_onStorageChanged);
    widget.audio.applyMusicPreference(widget.storage.musicEnabled);
  }

  @override
  void dispose() {
    widget.storage.removeListener(_onStorageChanged);
    widget.audio.stopMusic();
    super.dispose();
  }

  void _onStorageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final best = widget.storage.bestScore;
    final coins = widget.storage.coinBank;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameConfig.skyTop, GameConfig.skyBottom],
          ),
        ),
        child: Stack(
          children: [
            // --- Decorative Background Clouds ---
            Positioned(
              top: 100,
              left: -50,
              child: _BackgroundCloud(scale: 1.5, opacity: 0.3),
            ),
            Positioned(
              top: 250,
              right: -20,
              child: _BackgroundCloud(scale: 1.0, opacity: 0.2),
            ),
            Positioned(
              bottom: 150,
              left: 20,
              child: _BackgroundCloud(scale: 0.8, opacity: 0.15),
            ),

            // --- Main Content ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top Bar (Coins, Shop, Settings) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GlassPill(
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _CircleIconButton(
                              icon: Icons.storefront_rounded,
                              tooltip: 'Shop',
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRoutes.shop),
                            ),
                            const SizedBox(width: 12),
                            _CircleIconButton(
                              icon: Icons.settings_rounded,
                              tooltip: 'Settings',
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.settings,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // --- Title ---
                    Column(
                      children: [
                        Text(
                          'SKY HOPPER',
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                            shadows: [
                              const Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                              Shadow(
                                color: GameConfig.skyTop.withOpacity(0.5),
                                offset: const Offset(0, -2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tap to fly. Don\'t crash.',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 3),

                    // --- Play Button & Best Score ---
                    PrimaryButton(
                      label: 'PLAY',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.game),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: _GlassPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Best: $best',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable glassmorphism pill container.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A reusable circular icon button with a glass effect.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 26,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

/// A simple custom painter to draw fluffy background clouds.
class _BackgroundCloud extends StatelessWidget {
  const _BackgroundCloud({required this.scale, required this.opacity});
  final double scale;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 150,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}
