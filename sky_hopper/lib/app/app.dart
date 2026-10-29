import 'package:flutter/material.dart';
import 'package:sky_hopper/service/audio_service.dart';
import 'package:sky_hopper/service/local_storage_service.dart';

import '../screens/home_screen.dart';
import '../screens/game_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/settings_screen.dart';

import 'app_routes.dart';

class SkyHopperApp extends StatelessWidget {
  const SkyHopperApp({super.key, required this.storage, required this.audio});

  final LocalStorageService storage;
  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Hopper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        scaffoldBackgroundColor: const Color(0xFF87CEEB),
      ),
      initialRoute: AppRoutes.home,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeScreen(storage: storage, audio: audio),
        );
      case AppRoutes.game:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GameScreen(storage: storage, audio: audio),
        );
      case AppRoutes.shop:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShopScreen(storage: storage),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SettingsScreen(storage: storage, audio: audio),
        );
      default:
        return null;
    }
  }
}
