import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services_backend_and_other_services/app_sound_service.dart';

/// The app's own mix, and the two ways it used to fall silent.
///
/// Separate from `audio_quality_test.dart` on purpose. That file measures the
/// **files** — what `tool/make_sounds.py` renders, and how the sounds sit
/// against each other inside the bundle. This one is about the **runtime**:
/// the volume the app plays each of them at, and whether the players survive
/// long enough to play anything at all.
///
/// Both halves are value / source assertions rather than behavior tests, and
/// that is a deliberate limitation rather than laziness. `audioplayers` has no
/// usable fake — every method goes straight to a platform channel that does
/// not exist under `flutter test` — so a "does the music restart" test would
/// be testing a no-op. What can be pinned is the *shape of the code that got
/// it wrong*, which is what these do.
void main() {
  /// The service's source, with line endings normalised to `\n`.
  ///
  /// **The normalisation is the point, not tidiness.** This file is checked
  /// out with CRLF endings on Windows, so every `\n` in it is really `\r\n`.
  /// A single-line `contains` is unaffected, which is why most of the checks
  /// below passed — but any pattern spanning a line break can never match,
  /// and `indexOf` answers -1 rather than failing in a way that points at the
  /// cause. The "_playersReady is set last" test was reporting the ordering
  /// bug it was written to catch, on a file where the ordering was correct.
  ///
  /// A test that only works on one line-ending convention is worse than no
  /// test: it fails on a machine where the code is fine, and the obvious
  /// reading of the failure is that the code is broken.
  String serviceSource() => File(
    'lib/services_backend_and_other_services/app_sound_service.dart',
  ).readAsStringSync().replaceAll('\r\n', '\n');

  group('the mix', () {
    test('the loop is audible against the effects, not underneath them', () {
      // The brief: "I want the background sound to be louder and the other
      // sounds toned down a bit."
      //
      // The failure this pins is subtler than "the music is too quiet". At
      // 0.18 the loop sat *below the quietest effect in the app* — quieter
      // than the navigation blip that fires on every single tab switch. A
      // background track that loses to the interface's own punctuation is
      // not background, it is inaudible, and that is what "I can't hear the
      // music" actually meant.
      //
      // It is still allowed to be quiet. It is not allowed to be the
      // quietest thing in the app.
      final quietestEffect = AppSoundService.debugEffectVolumes.values.reduce(
        (a, b) => a < b ? a : b,
      );
      expect(
        AppSoundService.debugMusicVolume,
        greaterThan(quietestEffect),
        reason:
            'the ambient loop plays at '
            '${AppSoundService.debugMusicVolume}, under the quietest effect '
            'at $quietestEffect — it will not be heard',
      );
    });

    test('no effect is loud enough to be startling', () {
      // Every one of these came down by about 30%. The ceiling is here so
      // that adding a sound later cannot quietly undo it: a new effect
      // declared at 0.8 would be nearly twice the loudest thing in the app.
      for (final entry in AppSoundService.debugEffectVolumes.entries) {
        expect(
          entry.value,
          lessThanOrEqualTo(0.5),
          reason:
              '${entry.key.name} plays at ${entry.value}, which is louder '
              'than anything in this app should be',
        );
      }
    });

    test('navigation is still the quietest thing, and by a margin', () {
      // Turning everything down uniformly would have preserved this by
      // accident. It is asserted because it is the actual rule — loudness is
      // the inverse of how often a sound fires — and the table is easy to
      // edit one line at a time without noticing the shape it had.
      final volumes = AppSoundService.debugEffectVolumes;
      final navigation = volumes[AppSoundEffect.navigation]!;
      for (final entry in volumes.entries) {
        if (entry.key == AppSoundEffect.navigation) continue;
        expect(
          navigation,
          lessThan(entry.value),
          reason: 'navigation is no longer quieter than ${entry.key.name}',
        );
      }
      expect(
        navigation,
        lessThan(volumes[AppSoundEffect.celebration]! * 0.5),
        reason:
            'a tab switch and a celebration are within 6dB of each other, '
            'which is what makes an interface feel like it is shouting',
      );
    });
  });

  group('the music can come back', () {
    test('startMusic checks the player state, not just its existence', () {
      // **The bug behind "the sound sometimes just would not play and I had
      // to toggle the music button off and on".**
      //
      // The guard was `if (_music != null) return;`. An AudioPlayer that
      // exists and an AudioPlayer that is playing are different things: the
      // OS can stop it in the background, an interruption can leave it
      // paused, and `play()` can fail after the field is already assigned.
      // In all of those the field stayed non-null, so every subsequent
      // startMusic() — and it is called from most screen entry points —
      // returned immediately and the loop never restarted.
      //
      // `setMusicEnabled` was the only path in the entire app that disposed
      // the player, which is exactly why toggling it off and on was the only
      // thing that worked.
      final source = serviceSource();
      expect(
        source,
        isNot(contains('if (_music != null) return;')),
        reason:
            'startMusic is back to treating a non-null player as a playing '
            'one, so a stalled loop can never restart on its own',
      );
      expect(
        source,
        contains('existing.state == PlayerState.playing'),
        reason: 'startMusic no longer asks the player what state it is in',
      );
    });

    test('something reacts to the app being resumed', () {
      // Nothing in audioplayers reacts to the Android lifecycle, and the
      // low-latency path is a SoundPool whose samples the system may reclaim
      // while the app is backgrounded. When that happens SoundPool.play()
      // returns 0 and plays nothing *without throwing*, so no amount of
      // error handling inside play() can notice.
      final source = serviceSource();
      expect(
        source,
        contains('AppLifecycleState.resumed'),
        reason:
            'nothing rebuilds the players after a resume, so a reclaimed '
            'SoundPool stays silent for the rest of the process',
      );
      expect(source, contains('handleAppResumed'));
    });

    test('a failed play rebuilds its player instead of giving up on it', () {
      // Previously a failure was permanent: it printed, fell back to a system
      // click, and left the broken player in the map for the life of the
      // process. One transient fault meant that effect was gone until the app
      // was restarted.
      expect(
        serviceSource(),
        contains('await _rebuildPlayer(effect);'),
        reason: 'play() no longer heals a player that failed',
      );
    });

    test('initialize is a single shared future, not a flag set early', () {
      // The old code set `_playersReady = true` as its first statement and
      // then spent a dozen awaits configuring sixteen players. A play() in
      // that window used an unconfigured player — meaning one still on
      // audioplayers' default AndroidAudioFocus.gain, the "sole source of
      // audio" setting that `audio_focus_test.dart` exists to keep out. The
      // focus bug could return through a race without the value ever
      // changing.
      final source = serviceSource();
      expect(
        source,
        contains('static Future<void> initialize() => _initFuture ??='),
        reason: 'concurrent callers can race past a half-finished setup again',
      );
      // The flag is now the *last* thing set, so it can only ever mean
      // "finished" rather than "started".
      final assignment = source.indexOf('_playersReady = true;\n  }');
      expect(
        assignment,
        greaterThan(source.indexOf('_attachLifecycleObserver();')),
        reason: '_playersReady is set before the setup it is supposed to gate',
      );
    });
  });
}
