import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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

  static const String _soundEnabledKey = 'budget_buddy_sound_enabled';
  static const Map<AppSoundEffect, String> _assetPaths =
      <AppSoundEffect, String>{
        AppSoundEffect.tap: 'audio/tap.wav',
        AppSoundEffect.navigation: 'audio/navigation.wav',
        AppSoundEffect.selection: 'audio/selection.wav',
        AppSoundEffect.notification: 'audio/notification.wav',
        AppSoundEffect.success: 'audio/success.wav',
        AppSoundEffect.error: 'audio/error.wav',
        AppSoundEffect.needPickup: 'audio/need_pickup.wav',
        AppSoundEffect.wantHit: 'audio/want_hit.wav',
        AppSoundEffect.celebration: 'audio/celebration.wav',
        AppSoundEffect.shutdown: 'audio/shutdown.wav',
      };
  static final Map<AppSoundEffect, AudioPlayer> _players =
      <AppSoundEffect, AudioPlayer>{
        for (final effect in AppSoundEffect.values)
          effect: AudioPlayer(playerId: 'budget_buddy_${effect.name}'),
      };

  static DateTime? _lastPlayedAt;
  static AppSoundEffect? _lastEffect;
  static SharedPreferences? _preferences;
  static bool _playersReady = false;
  static bool enabled = true;

  static Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    enabled = _preferences?.getBool(_soundEnabledKey) ?? true;

    if (_playersReady) {
      return;
    }

    _playersReady = true;
    for (final player in _players.values) {
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        if (!kIsWeb) {
          await player.setPlayerMode(PlayerMode.lowLatency);
        }
      } catch (error) {
        debugPrint('Audio player setup fallback: $error');
      }
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_soundEnabledKey, value);
  }

  static Future<void> play(AppSoundEffect effect) async {
    if (!enabled) {
      return;
    }

    if (!_playersReady) {
      await initialize();
    }

    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastEffect == effect &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 40)) {
      return;
    }

    _lastPlayedAt = now;
    _lastEffect = effect;

    final assetPath = _assetPaths[effect];
    final player = _players[effect];

    if (assetPath != null && player != null) {
      try {
        await player.stop();
        await player.play(AssetSource(assetPath));
        return;
      } catch (error) {
        debugPrint('Asset sound fallback for ${effect.name}: $error');
      }
    }

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
