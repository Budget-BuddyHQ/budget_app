import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services_backend_and_other_services/app_sound_service.dart';

class AppSettingsController extends ChangeNotifier {
  static const String _notificationsEnabledKey =
      'budget_buddy_notifications_enabled';
  static const String _lastFeedbackPromptKey =
      'budget_buddy_last_feedback_prompt';

  /// How long to wait before asking again after the prompt is shown —
  /// dismissed or not. Deliberately not "every launch"; that reads as
  /// nagging rather than occasionally checking in.
  static const Duration _feedbackPromptCooldown = Duration(days: 4);

  bool _soundEnabled = AppSoundService.enabled;
  bool _notificationsEnabled = true;
  bool _initialized = false;
  SharedPreferences? _preferences;
  DateTime? _lastFeedbackPromptShown;

  bool get soundEnabled => _soundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _initialized;

  /// Whether enough time has passed since the feedback prompt was last shown
  /// (or this is the first time) that it's due again. Callers still need to
  /// apply their own conditions on top (onboarding finished, feature flag
  /// on, etc.) — this only tracks the cooldown.
  bool get isFeedbackPromptDue {
    final last = _lastFeedbackPromptShown;
    if (last == null) {
      return true;
    }
    return DateTime.now().difference(last) >= _feedbackPromptCooldown;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await AppSoundService.initialize();
    _soundEnabled = AppSoundService.enabled;

    _preferences ??= await SharedPreferences.getInstance();
    _notificationsEnabled =
        _preferences?.getBool(_notificationsEnabledKey) ?? true;
    final lastPromptRaw = _preferences?.getString(_lastFeedbackPromptKey);
    _lastFeedbackPromptShown = lastPromptRaw == null
        ? null
        : DateTime.tryParse(lastPromptRaw);

    _initialized = true;
    notifyListeners();
  }

  /// Records "just showed the feedback prompt" so [isFeedbackPromptDue]
  /// waits out the cooldown again — called whether the player answers it or
  /// dismisses it, since either way this isn't the moment to ask again.
  Future<void> recordFeedbackPromptShown() async {
    _lastFeedbackPromptShown = DateTime.now();
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setString(
      _lastFeedbackPromptKey,
      _lastFeedbackPromptShown!.toIso8601String(),
    );
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
