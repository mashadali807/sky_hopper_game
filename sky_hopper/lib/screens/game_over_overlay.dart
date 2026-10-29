import 'package:flutter/material.dart';

import '../game/models/run_result.dart';
import '../widgets/coin_display.dart';
import '../widgets/primary_button.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.result,
    required this.bestScore,
    required this.onPlayAgain,
    required this.onHome,
  });

  final RunResult result;
  final int bestScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'GAME OVER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
              _StatLine(label: 'Score', value: '${result.score}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Coins earned',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  CoinDisplay(coins: result.coinsCollected),
                ],
              ),
              const SizedBox(height: 8),
              _StatLine(label: 'Best', value: '$bestScore'),
              if (result.isNewBest) ...[
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'NEW BEST!',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'PLAY AGAIN',
                icon: Icons.refresh_rounded,
                onPressed: onPlayAgain,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onHome,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('HOME'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
