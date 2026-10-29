import 'package:flutter/material.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

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
        title: const Text('Reset all data?'),
        content: const Text(
          'This will delete your best score, coin bank, unlocked skins, and preferences. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Data reset')));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.storage;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(label: 'Audio'),
          SwitchListTile(
            title: const Text('Music'),
            subtitle: const Text('Background music'),
            value: s.musicEnabled,
            onChanged: _onMusicChanged,
          ),
          SwitchListTile(
            title: const Text('Sound effects'),
            subtitle: const Text('Coins, jumps, collisions'),
            value: s.soundEnabled,
            onChanged: _onSoundChanged,
          ),
          const Divider(),
          _SectionHeader(label: 'Feedback'),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Haptic feedback on interactions'),
            value: s.vibrationEnabled,
            onChanged: (v) => s.setVibrationEnabled(v),
          ),
          const Divider(),
          _SectionHeader(label: 'Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Reset all data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Deletes scores, coins, skins, preferences'),
            onTap: _confirmReset,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Sky Hopper • v0.1.0',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
