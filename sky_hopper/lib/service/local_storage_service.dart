import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central persistence for the game.
///
/// * All reads return safe defaults (0, false, 'default') if the key is
///   missing or corrupt.
/// * All writes notify listeners so [ChangeNotifier]-based widgets can
///   rebuild reactively — no manual refresh plumbing.
/// * Every write is idempotent: writing the same value twice is harmless.
/// * [resetAll] deletes only our own keys, never the whole store.
class LocalStorageService extends ChangeNotifier {
  LocalStorageService._(this._prefs);

  final SharedPreferences? _prefs;

  /// Load the persistent store. Throws if `SharedPreferences` cannot be
  /// initialized — callers should catch and fall back to [inMemory].
  static Future<LocalStorageService> load() async {
    final prefs = await SharedPreferences.getInstance();
    final svc = LocalStorageService._(prefs);
    await svc._ensureDefaults();
    return svc;
  }

  /// Fallback when persistent storage is unavailable. Reads return defaults,
  /// writes are silent no-ops. App still runs, nothing is saved.
  factory LocalStorageService.inMemory() => LocalStorageService._(null);

  // ------------------------------------------------------------------
  // Keys — grouped so future additions are obvious.
  // ------------------------------------------------------------------
  static const String _kBestScore = 'best_score';
  static const String _kCoinBank = 'coin_bank';
  static const String _kOwnedSkins = 'owned_skins';
  static const String _kSelectedSkin = 'selected_skin';
  static const String _kMusicEnabled = 'music_enabled';
  static const String _kSoundEnabled = 'sound_enabled';
  static const String _kVibrationEnabled = 'vibration_enabled';

  /// Must contain every key we might ever write. Used by [resetAll] and
  /// by a Module 11 test that ensures new keys get added here.
  static const String _kOnboardingSeen = 'has_seen_onboarding_hint';

  // Add to _allKeys list:
  static const List<String> _allKeys = [
    _kBestScore,
    _kCoinBank,
    _kOwnedSkins,
    _kSelectedSkin,
    _kMusicEnabled,
    _kSoundEnabled,
    _kVibrationEnabled,
    _kOnboardingSeen, // ← new
  ];

  bool get hasSeenOnboardingHint => _prefs?.getBool(_kOnboardingSeen) ?? false;

  Future<void> markOnboardingHintSeen() async {
    if (hasSeenOnboardingHint) return;
    await _prefs?.setBool(_kOnboardingSeen, true);
    notifyListeners();
  }

  static const String defaultSkinId = 'default';

  /// Populate keys with sensible defaults on first launch so reads later
  /// don't have to special-case "key missing".
  Future<void> _ensureDefaults() async {
    final p = _prefs;
    if (p == null) return;
    if (!p.containsKey(_kOwnedSkins)) {
      await p.setStringList(_kOwnedSkins, [defaultSkinId]);
    }
    if (!p.containsKey(_kSelectedSkin)) {
      await p.setString(_kSelectedSkin, defaultSkinId);
    }
    // Ints and bools have natural defaults (0, false); no need to prefill.
  }

  // ------------------------------------------------------------------
  // Best score
  // ------------------------------------------------------------------
  int get bestScore => _prefs?.getInt(_kBestScore) ?? 0;

  /// Save [score] only if it beats the current best. Idempotent.
  Future<void> recordScore(int score) async {
    final current = bestScore;
    if (score > current) {
      await _prefs?.setInt(_kBestScore, score);
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Coin bank
  // ------------------------------------------------------------------
  int get coinBank => _prefs?.getInt(_kCoinBank) ?? 0;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    final next = coinBank + amount;
    await _prefs?.setInt(_kCoinBank, next);
    notifyListeners();
  }

  /// Deduct [amount] from bank. Returns true on success, false if insufficient.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    final current = coinBank;
    if (current < amount) return false;
    await _prefs?.setInt(_kCoinBank, current - amount);
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------------
  // Skins
  // ------------------------------------------------------------------
  Set<String> get ownedSkins {
    final list = _prefs?.getStringList(_kOwnedSkins);
    if (list == null || list.isEmpty) return {defaultSkinId};
    return list.toSet();
  }

  String get selectedSkin => _prefs?.getString(_kSelectedSkin) ?? defaultSkinId;

  Future<void> addOwnedSkin(String skinId) async {
    final current = ownedSkins;
    if (current.contains(skinId)) return;
    current.add(skinId);
    await _prefs?.setStringList(_kOwnedSkins, current.toList());
    notifyListeners();
  }

  /// Returns false if [skinId] is not owned.
  Future<bool> selectSkin(String skinId) async {
    if (!ownedSkins.contains(skinId)) return false;
    await _prefs?.setString(_kSelectedSkin, skinId);
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------------
  // Preferences (audio, vibration)
  // ------------------------------------------------------------------
  bool get musicEnabled => _prefs?.getBool(_kMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool v) async {
    await _prefs?.setBool(_kMusicEnabled, v);
    notifyListeners();
  }

  bool get soundEnabled => _prefs?.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool v) async {
    await _prefs?.setBool(_kSoundEnabled, v);
    notifyListeners();
  }

  bool get vibrationEnabled => _prefs?.getBool(_kVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool v) async {
    await _prefs?.setBool(_kVibrationEnabled, v);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Reset
  // ------------------------------------------------------------------
  Future<void> resetAll() async {
    for (final k in _allKeys) {
      await _prefs?.remove(k);
    }
    await _ensureDefaults();
    notifyListeners();
  }
}
