import 'package:flutter/material.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LocalStorageService storage;
  try {
    storage = await LocalStorageService.load();
  } catch (e) {
    debugPrint('LocalStorageService load failed: $e — using in-memory');
    storage = LocalStorageService.inMemory();
  }

  final audio = AudioService(
    musicEnabled: storage.musicEnabled,
    soundEnabled: storage.soundEnabled,
  );
  // Non-blocking — audio init won't hold up first frame.
  audio.init();

  runApp(SkyHopperApp(storage: storage, audio: audio));
}
