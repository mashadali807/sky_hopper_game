import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:sky_hopper/game/models/chracter_skin.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.storage.addListener(_onStorageChanged);
  }

  @override
  void dispose() {
    widget.storage.removeListener(_onStorageChanged);
    super.dispose();
  }

  void _onStorageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleBuy(CharacterSkin skin) async {
    if (_busy) return;
    final owned = widget.storage.ownedSkins.contains(skin.id);
    if (owned) {
      await _handleSelect(skin);
      return;
    }

    setState(() => _busy = true);
    try {
      final ok = await widget.storage.spendCoins(skin.price);
      if (!ok) {
        _showSnack('Not enough coins');
        return;
      }
      await widget.storage.addOwnedSkin(skin.id);
      await widget.storage.selectSkin(skin.id);
      _showSnack('Unlocked ${skin.name}!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSelect(CharacterSkin skin) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.storage.selectSkin(skin.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final coins = widget.storage.coinBank;
    final owned = widget.storage.ownedSkins;
    final selected = widget.storage.selectedSkin;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'CHARACTERS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)], // Sky gradient
          ),
        ),
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: kCharacterSkins.length,
            itemBuilder: (context, index) {
              final skin = kCharacterSkins[index];
              return _SkinCard(
                skin: skin,
                isOwned: owned.contains(skin.id),
                isSelected: selected == skin.id,
                canAfford: coins >= skin.price,
                onTap: () => _handleBuy(skin),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.isOwned,
    required this.isSelected,
    required this.canAfford,
    required this.onTap,
  });

  final CharacterSkin skin;
  final bool isOwned;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: isSelected ? 8 : 4,
      shadowColor: isSelected ? Colors.amber.withOpacity(0.5) : Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Center(child: _SkinPreview(skin: skin)),
              ),
              const SizedBox(height: 8),
              Text(
                skin.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    if (isSelected) {
      return const _Badge(
        label: 'SELECTED',
        color: Colors.green,
        textColor: Colors.white,
      );
    }
    if (isOwned) {
      return const _Badge(
        label: 'TAP TO USE',
        color: Color(0xFFE0E0E0),
        textColor: Colors.black87,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.monetization_on,
          color: canAfford ? Colors.amber : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '${skin.price}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: canAfford ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _SkinPreview extends StatelessWidget {
  const _SkinPreview({required this.skin});
  final CharacterSkin skin;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _PlayerPreviewPainter(
          bodyColor: skin.bodyColor,
          accentColor: skin.accentColor,
          shape: skin.shape, // Pass shape to painter
        ),
      ),
    );
  }
}

class _PlayerPreviewPainter extends CustomPainter {
  _PlayerPreviewPainter({
    required this.bodyColor,
    required this.accentColor,
    required this.shape,
  });

  final Color bodyColor;
  final Color accentColor;
  final PlayerShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    final bodyPaint = Paint()..color = bodyColor;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.15);
    final accentPaint = Paint()..color = accentColor;

    // Draw shadow
    canvas.drawCircle(
      center + Offset(0, radius * 0.1),
      radius * 0.95,
      shadowPaint,
    );

    final path = Path();

    // Draw Body based on shape
    switch (shape) {
      case PlayerShape.circle:
        canvas.drawCircle(center, radius, bodyPaint);
        break;
      case PlayerShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: radius * 1.8,
              height: radius * 1.8,
            ),
            Radius.circular(radius * 0.2),
          ),
          bodyPaint,
        );
        break;
      case PlayerShape.triangle:
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius, center.dy + radius * 0.8);
        path.lineTo(center.dx - radius, center.dy + radius * 0.8);
        path.close();
        canvas.drawPath(path, bodyPaint);
        break;
      case PlayerShape.star:
        // Simple 5-point star
        final points = 5;
        final angle = 3.14159 / points;
        for (int i = 0; i < points * 2; i++) {
          final r = i.isEven ? radius : radius * 0.4;
          final x = center.dx + r * Math.sin(i * angle);
          final y = center.dy - r * Math.cos(i * angle);
          if (i == 0)
            path.moveTo(x, y);
          else
            path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, bodyPaint);
        break;
      case PlayerShape.hexagon:
        for (int i = 0; i < 6; i++) {
          final a = 3.14159 / 3 * i;
          final x = center.dx + radius * Math.cos(a);
          final y = center.dy + radius * Math.sin(a);
          if (i == 0)
            path.moveTo(x, y);
          else
            path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, bodyPaint);
        break;
    }

    // Draw the "eye" (accent)
    canvas.drawCircle(
      center + Offset(radius * 0.35, -radius * 0.2),
      radius * 0.18,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_PlayerPreviewPainter old) =>
      old.bodyColor != bodyColor ||
      old.accentColor != accentColor ||
      old.shape != shape;
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
