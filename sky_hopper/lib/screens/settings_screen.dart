import 'package:flutter/material.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

import '../game/game_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.storage, required this.audio});

  final LocalStorageService storage;
  final AudioService audio;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  Future<void> _onMusicChanged(bool v) async {
    await widget.storage.setMusicEnabled(v);
    widget.audio.soundEnabled = widget.storage.soundEnabled;
    await widget.audio.applyMusicPreference(v);
  }

  Future<void> _onSoundChanged(bool v) async {
    await widget.storage.setSoundEnabled(v);
    widget.audio.soundEnabled = v;
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset all data?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete your best score, coin bank, unlocked skins, and preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.storage.resetAll();
    widget.audio.soundEnabled = widget.storage.soundEnabled;
    widget.audio.musicEnabled = widget.storage.musicEnabled;
    await widget.audio.applyMusicPreference(widget.storage.musicEnabled);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data reset successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.storage;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameConfig.skyTop, GameConfig.skyBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // --- AUDIO CARD ---
              _SettingsCard(
                title: 'AUDIO',
                icon: Icons.music_note_rounded,
                children: [
                  _CustomSwitchTile(
                    title: 'Music',
                    subtitle: 'Background soundtrack',
                    value: s.musicEnabled,
                    onChanged: _onMusicChanged,
                    icon: Icons.audiotrack_rounded,
                  ),
                  const Divider(height: 1, indent: 60),
                  _CustomSwitchTile(
                    title: 'Sound Effects',
                    subtitle: 'Jumps, coins, and collisions',
                    value: s.soundEnabled,
                    onChanged: _onSoundChanged,
                    icon: Icons.volume_up_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- FEEDBACK CARD ---
              _SettingsCard(
                title: 'FEEDBACK',
                icon: Icons.gamepad_rounded,
                children: [
                  _CustomSwitchTile(
                    title: 'Vibration',
                    subtitle: 'Haptic feedback on interactions',
                    value: s.vibrationEnabled,
                    onChanged: (v) => s.setVibrationEnabled(v),
                    icon: Icons.vibration_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- DANGER ZONE CARD ---
              _SettingsCard(
                title: 'DANGER ZONE',
                icon: Icons.warning_rounded,
                iconColor: Colors.red,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Reset All Data',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: const Text('Deletes scores, coins, and skins'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.red,
                    ),
                    onTap: _confirmReset,
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Sky Hopper • v0.1.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A beautiful white card to group settings.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor = const Color(0xFF1E3C72),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// A stylized switch tile that looks like a real game setting.
class _CustomSwitchTile extends StatelessWidget {
  const _CustomSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3C72).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1E3C72)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF4A90E2),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }
}
