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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _PillLabel(text: '🪙 $coins'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Shop',
                      icon: const Icon(Icons.storefront, color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.shop),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Text(
                  'SKY HOPPER',
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to fly. Don\'t crash.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(flex: 3),
                PrimaryButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.game),
                ),
                const SizedBox(height: 12),
                Center(child: _PillLabel(text: 'Best: $best')),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
