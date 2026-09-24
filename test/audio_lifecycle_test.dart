import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services_backend_and_other_services/app_sound_service.dart';

/// Nothing plays while the app is not on screen.
///
/// **Reported as:** close the app on a phone, press a volume button, and the
/// music is playing. The loop could be started — or left running — after the
/// app had gone to the background: the pause handler stopped the music last,
/// after disposing sixteen effect players; a resume that was interrupted
/// still restarted it; `hidden` was not treated as backgrounded; and a pause
/// arriving while `play()` was in flight could not see the player to stop it.
///
/// These drive the lifecycle the way the platform does and check that a
/// backgrounded app refuses to start sound. Music is switched off where a
/// test would otherwise build a real player, which needs the platform plugin.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // Back to a foreground app, without letting the resume build a player.
    final music = AppSoundService.musicEnabled;
    AppSoundService.musicEnabled = false;
    AppSoundService.debugLifecycleChanged(AppLifecycleState.resumed);
    AppSoundService.musicEnabled = music;
  });

  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    test('music will not start once the app is ${state.name}', () async {
      AppSoundService.debugLifecycleChanged(state);
      expect(AppSoundService.debugInForeground, isFalse);

      AppSoundService.enabled = true;
      AppSoundService.musicEnabled = true;
      await AppSoundService.startMusic();

      expect(
        AppSoundService.debugHasMusicPlayer,
        isFalse,
        reason:
            'a screen asked for music while the app was ${state.name}, '
            'and got it',
      );
      expect(
        AppSoundService.debugMusicWanted,
        isTrue,
        reason:
            'the request should be remembered so the loop comes back '
            'when the app does',
      );
    });
  }

  test('a notification shade over the app does not stop the music', () {
    // `inactive` is a still-visible app with something on top of it.
    AppSoundService.debugLifecycleChanged(AppLifecycleState.inactive);
    expect(AppSoundService.debugInForeground, isTrue);
  });

  test('coming back to the app lets sound play again', () {
    AppSoundService.musicEnabled = false;
    AppSoundService.debugLifecycleChanged(AppLifecycleState.paused);
    expect(AppSoundService.debugInForeground, isFalse);
    AppSoundService.debugLifecycleChanged(AppLifecycleState.resumed);
    expect(AppSoundService.debugInForeground, isTrue);
  });

  test('effects are silent in the background too', () async {
    AppSoundService.debugLifecycleChanged(AppLifecycleState.paused);
    AppSoundService.enabled = true;
    // Returns before touching any player or preference; if it did not, this
    // would fail on the missing platform plugin.
    await AppSoundService.play(AppSoundEffect.tap);
  });
}
