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
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final coins = widget.storage.coinBank;
    final owned = widget.storage.ownedSkins;
    final selected = widget.storage.selectedSkin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Characters'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(999),
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
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
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
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
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
                  fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

class _PlayerPreviewPainter extends CustomPainter {
  _PlayerPreviewPainter({required this.bodyColor, required this.accentColor});

  final Color bodyColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center + Offset(0, radius * 0.08),
      radius * 0.98,
      Paint()..color = Colors.black.withOpacity(0.15),
    );
    canvas.drawCircle(center, radius, Paint()..color = bodyColor);
    canvas.drawCircle(
      center + Offset(radius * 0.35, -radius * 0.2),
      radius * 0.18,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(_PlayerPreviewPainter old) =>
      old.bodyColor != bodyColor || old.accentColor != accentColor;
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
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
