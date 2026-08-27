import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services_backend_and_other_services/app_sound_service.dart';

class AppSettingsController extends ChangeNotifier {
  static const String _notificationsEnabledKey =
      'budget_buddy_notifications_enabled';
  static const String _lastFeedbackPromptKey =
      'budget_buddy_last_feedback_prompt';
  static const String _launchCountKey = 'budget_buddy_launch_count';
  static const String _tutorialSeenKey = 'budget_buddy_tutorial_seen';

  /// How long to wait before asking again after the prompt is shown —
  /// dismissed or not. Deliberately not "every launch"; that reads as
  /// nagging rather than occasionally checking in.
  static const Duration _feedbackPromptCooldown = Duration(days: 4);

  /// Don't ask someone for feedback the first time they ever open the app —
  /// they have nothing to say yet. This replaced an earlier "wait until
  /// they've finished the age/gender onboarding sheet" gate, which looked
  /// equivalent but silently made the prompt *unreachable* without Supabase
  /// keys: that sheet only shows when authenticated, so in local-only mode
  /// the flag it set was never written and the prompt could never fire.
  /// A launch counter means the same thing and works in both modes.
  static const int _minLaunchesBeforeFeedbackPrompt = 3;

  bool _soundEnabled = AppSoundService.enabled;
  bool _musicEnabled = AppSoundService.musicEnabled;
  bool _notificationsEnabled = true;
  bool _initialized = false;
  bool _tutorialSeen = false;
  SharedPreferences? _preferences;
  DateTime? _lastFeedbackPromptShown;
  int _launchCount = 0;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _initialized;

  /// How many times the app has been opened, counting this session.
  int get launchCount => _launchCount;

  /// Whether the guided tour has been completed *or* deliberately skipped.
  ///
  /// Skipping counts: someone who dismissed the tour has told us they don't
  /// want it, and re-offering it on the next launch would be the same
  /// nagging the feedback prompt's cooldown exists to avoid.
  ///
  /// This only gates the *automatic* first-run opening. Profile's "Replay
  /// Tutorial" row pushes the tour directly, so watching it again never
  /// needs the flag cleared.
  bool get tutorialSeen => _tutorialSeen;

  /// Whether to auto-open the tour. Only on a genuine first run — a player
  /// who has been here before gets their app, not an interruption.
  ///
  /// Reads [isInitialized] so a caller cannot act on the default `false`
  /// before SharedPreferences has been read back, which would show the tour
  /// to an existing player for one frame on every cold start.
  bool get isTutorialDue => _initialized && !_tutorialSeen;

  /// Whether the occasional feedback prompt is due: the player has opened the
  /// app a few times, and enough time has passed since it was last shown.
  /// Callers still apply their own conditions on top (the `kFeedbackEnabled`
  /// flag) — this owns the "is now a reasonable moment" part.
  bool get isFeedbackPromptDue {
    if (_launchCount < _minLaunchesBeforeFeedbackPrompt) {
      return false;
    }
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
    _musicEnabled = AppSoundService.musicEnabled;

    _preferences ??= await SharedPreferences.getInstance();
    _notificationsEnabled =
        _preferences?.getBool(_notificationsEnabledKey) ?? true;
    final lastPromptRaw = _preferences?.getString(_lastFeedbackPromptKey);
    _lastFeedbackPromptShown = lastPromptRaw == null
        ? null
        : DateTime.tryParse(lastPromptRaw);

    _launchCount = (_preferences?.getInt(_launchCountKey) ?? 0) + 1;
    await _preferences?.setInt(_launchCountKey, _launchCount);

    _tutorialSeen = _preferences?.getBool(_tutorialSeenKey) ?? false;

    _initialized = true;
    notifyListeners();
  }

  /// Records that the tour is done with — finished or skipped, same result.
  Future<void> markTutorialSeen() async {
    if (_tutorialSeen) {
      return;
    }
    _tutorialSeen = true;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setBool(_tutorialSeenKey, true);
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

  /// Background music, separate from the effects — see [AppSoundService]
  /// for why the two are not one switch.
  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled && _initialized) {
      return;
    }

    _musicEnabled = enabled;
    notifyListeners();
    await AppSoundService.setMusicEnabled(enabled);
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
