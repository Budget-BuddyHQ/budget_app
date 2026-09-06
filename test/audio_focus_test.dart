import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services_backend_and_other_services/app_sound_service.dart';

/// Sounds cut each other off on a real phone, and this pins the reason shut.
///
/// Reported as "the sound would randomly cut off if I switched tabs or play
/// another sound". The device log said it outright, once per sound:
///
///     I/AudioManager: dispatching onAudioFocusChange(-1)
///
/// `-1` is `AUDIOFOCUS_LOSS`. The app was not losing focus to some other app —
/// it was losing it to *itself*. `audioplayers` defaults every player to
/// `AndroidAudioFocus.gain`, which its own documentation describes as "your
/// application is now the sole source of audio that the user is listening
/// to", and this app builds a separate player per effect. Sixteen effects plus
/// a music loop, each one declaring itself the sole source of audio, so every
/// new sound revoked the focus of the one before it — and on the Kotlin side
/// `AUDIOFOCUS_LOSS` calls `pause()` on the player that lost it. A tab change
/// played the navigation sound, which paused the music; a reward chime paused
/// the ratchet underneath it.
///
/// `none` requests no focus at all, so `hasAudioFocusRequest()` is false and
/// playback is granted without anything being taken from anyone.
///
/// This is a *value* test rather than a behaviour test on purpose. Nothing
/// breaks if these flip back — the app builds, the tests pass, the sounds play
/// on a desktop — and it is only wrong on a device, which is the least likely
/// place for it to be noticed before release.
void main() {
  group('audio focus', () {
    test('UI effects never take audio focus', () {
      final android = AppSoundService.debugUiAudioContext.android;

      expect(
        android.audioFocus,
        AndroidAudioFocus.none,
        reason: 'Anything else lets one UI sound stop another. `gain` in '
            'particular means "sole source of audio", which is how this '
            'broke: every effect revoked the previous one and Android '
            'paused it.',
      );
    });

    test('UI effects are declared as interface sounds, not media', () {
      final android = AppSoundService.debugUiAudioContext.android;

      // This pair is what Android calls short interface feedback. It is not
      // cosmetic: it is what makes a tap route sensibly during a call and
      // stops a click being treated as a media stream.
      expect(android.contentType, AndroidContentType.sonification);
      expect(android.usageType, AndroidUsageType.assistanceSonification);
    });

    test('the music loop does not take focus either', () {
      final android = AppSoundService.debugMusicAudioContext.android;

      expect(
        android.audioFocus,
        AndroidAudioFocus.none,
        reason: 'The loop taking focus is the other half of the bug — it '
            'silences whatever the player already had going, and a '
            'background loop in a kids app has no business stopping '
            "someone's music.",
      );
      // The loop *is* media, unlike the effects, so a device that routes the
      // two differently is allowed to.
      expect(android.contentType, AndroidContentType.music);
      expect(android.usageType, AndroidUsageType.media);
    });

    test('both sessions mix on iOS instead of interrupting', () {
      // `ambient` is the one output category documented as "Interrupts
      // nonmixable app's audio = No". `playback`, the audioplayers default,
      // interrupts — the same bug wearing a different platform.
      expect(
        AppSoundService.debugUiAudioContext.iOS.category,
        AVAudioSessionCategory.ambient,
      );
      expect(
        AppSoundService.debugMusicAudioContext.iOS.category,
        AVAudioSessionCategory.ambient,
      );
    });

    test('the iOS options stay empty, or the category assert trips', () {
      // `AudioContextIOS` asserts that `mixWithOthers` is only set on
      // playback / playAndRecord / multiRoute. With `ambient` the mixing is
      // already implied, so adding the option would throw at construction —
      // this is here so that gets caught in a test rather than on a device.
      expect(AppSoundService.debugUiAudioContext.iOS.options, isEmpty);
      expect(AppSoundService.debugMusicAudioContext.iOS.options, isEmpty);
    });
  });
}
