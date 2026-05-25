import 'package:flutter/foundation.dart';

import '../services_backend_and_other_services/app_sound_service.dart';

class AppSettingsController extends ChangeNotifier {
  bool _soundEnabled = AppSoundService.enabled;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await AppSoundService.initialize();
    _soundEnabled = AppSoundService.enabled;
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
}

