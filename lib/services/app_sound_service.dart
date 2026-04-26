import 'package:audioplayers/audioplayers.dart';
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

class AppSoundService {
  AppSoundService._();

  static DateTime? _lastPlayedAt;
  static AppSoundEffect? _lastEffect;
  static SharedPreferences? _preferences;
  static const String _soundEnabledKey = 'sound_enabled';
  static bool enabled = true;
  static final Map<AppSoundEffect, AudioPlayer> _players =
      <AppSoundEffect, AudioPlayer>{
        for (final effect in AppSoundEffect.values)
          effect: AudioPlayer(playerId: 'budget_buddy_${effect.name}'),
      };

  static const Map<AppSoundEffect, List<String>> _assetCandidates =
      <AppSoundEffect, List<String>>{
        AppSoundEffect.tap: <String>[
          'audio/tap.wav',
          'assets/audio/tap.wav',
        ],
        AppSoundEffect.navigation: <String>[
          'audio/navigation.wav',
          'assets/audio/navigation.wav',
        ],
        AppSoundEffect.selection: <String>[
          'audio/selection.wav',
          'assets/audio/selection.wav',
        ],
        AppSoundEffect.notification: <String>[
          'audio/notification.wav',
          'assets/audio/notification.wav',
        ],
        AppSoundEffect.success: <String>[
          'audio/success.wav',
          'assets/audio/success.wav',
        ],
        AppSoundEffect.error: <String>[
          'audio/error.wav',
          'assets/audio/error.wav',
        ],
        AppSoundEffect.needPickup: <String>[
          'audio/need_pickup.wav',
          'assets/audio/need_pickup.wav',
        ],
        AppSoundEffect.wantHit: <String>[
          'audio/want_hit.wav',
          'assets/audio/want_hit.wav',
        ],
        AppSoundEffect.celebration: <String>[
          'audio/celebration.wav',
          'assets/audio/celebration.wav',
        ],
        AppSoundEffect.shutdown: <String>[
          'audio/shutdown.wav',
          'assets/audio/shutdown.wav',
        ],
      };

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
    if (!enabled) {
      return;
    }

    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastEffect == effect &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 40)) {
      return;
    }

    _lastPlayedAt = now;
    _lastEffect = effect;

    final player = _players[effect]!;
    for (final assetPath in _assetCandidates[effect]!) {
      try {
        await player.stop();
        await player.play(
          AssetSource(assetPath),
          volume: _volumeFor(effect),
        );
        return;
      } catch (_) {
        continue;
      }
    }

    return _playSystemFallback(effect);
  }

  static double _volumeFor(AppSoundEffect effect) {
    switch (effect) {
      case AppSoundEffect.tap:
      case AppSoundEffect.selection:
        return 0.45;
      case AppSoundEffect.navigation:
      case AppSoundEffect.notification:
        return 0.55;
      case AppSoundEffect.success:
        return 0.72;
      case AppSoundEffect.error:
        return 0.68;
      case AppSoundEffect.needPickup:
        return 0.60;
      case AppSoundEffect.wantHit:
        return 0.62;
      case AppSoundEffect.celebration:
        return 0.78;
      case AppSoundEffect.shutdown:
        return 0.74;
    }
  }

  static Future<void> _playSystemFallback(AppSoundEffect effect) {
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
