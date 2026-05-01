import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

class AppSettingsController extends ChangeNotifier {
  static const _soundEnabledKey = 'budget_buddy_sound_enabled';

  bool _soundEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    _soundEnabled = preferences.getBool(_soundEnabledKey) ?? true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled && _initialized) {
      return;
    }

    _soundEnabled = enabled;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_soundEnabledKey, enabled);
  }

  Future<void> playTap() async {
    if (!_soundEnabled) {
      return;
    }
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playReward() async {
    if (!_soundEnabled) {
      return;
    }
    await SystemSound.play(SystemSoundType.alert);
  }
}
