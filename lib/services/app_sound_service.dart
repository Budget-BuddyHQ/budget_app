import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSoundEffect {
  tap,
  navigation,
  selection,
  notification,
  success,
  error,
  needPickup,
  wantHit,
  celebration,
  shutdown,
}

/// Lightweight sound service that persists user preference.
/// Uses system sounds as a safe fallback and avoids optional native audio
/// packages to keep compatibility across platforms.
class AppSoundService {
  AppSoundService._();

  static DateTime? _lastPlayedAt;
  static AppSoundEffect? _lastEffect;
  static SharedPreferences? _preferences;
  static const String _soundEnabledKey = 'sound_enabled';
  static bool enabled = true;

  static Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    enabled = _preferences?.getBool(_soundEnabledKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_soundEnabledKey, value);
  }

  static Future<void> play(AppSoundEffect effect) async {
    if (!enabled) return;

    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastEffect == effect &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 40)) {
      return;
    }

    _lastPlayedAt = now;
    _lastEffect = effect;

    // Use system sounds as a safe universal fallback.
    await _playSystemFallback(effect);
  }

  static Future<void> _playSystemFallback(AppSoundEffect effect) async {
    switch (effect) {
      case AppSoundEffect.tap:
      case AppSoundEffect.navigation:
      case AppSoundEffect.selection:
        return SystemSound.play(SystemSoundType.click);
      case AppSoundEffect.notification:
      case AppSoundEffect.success:
      case AppSoundEffect.error:
      case AppSoundEffect.needPickup:
      case AppSoundEffect.wantHit:
      case AppSoundEffect.celebration:
      case AppSoundEffect.shutdown:
        return SystemSound.play(SystemSoundType.alert);
    }
  }
}
