import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services_backend_and_other_services/app_sound_service.dart';

class AppSettingsController extends ChangeNotifier {
  static const String _notificationsEnabledKey =
      'budget_buddy_notifications_enabled';

  bool _soundEnabled = AppSoundService.enabled;
  bool _notificationsEnabled = true;
  bool _initialized = false;
  SharedPreferences? _preferences;

  bool get soundEnabled => _soundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await AppSoundService.initialize();
    _soundEnabled = AppSoundService.enabled;

    _preferences ??= await SharedPreferences.getInstance();
    _notificationsEnabled =
        _preferences?.getBool(_notificationsEnabledKey) ?? true;

    _initialized = true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled && _initialized) {
      return;
    }

    _soundEnabled = enabled;
    notifyListeners();
    await AppSoundService.setEnabled(enabled);
  }

  /// Persists the player's preference so it survives a restart. There is no
  /// notification delivery system wired up yet — this only remembers the
  /// choice for when one is added, the same way the setting would behave once
  /// real reminders exist.
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled && _initialized) {
      return;
    }

    _notificationsEnabled = enabled;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setBool(_notificationsEnabledKey, enabled);
  }
}
