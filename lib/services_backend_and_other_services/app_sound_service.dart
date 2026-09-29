import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  /// The decelerating ratchet while a skin case rolls.
  caseRoll,

  // one per rarity. rarity comes across as harmonic richness + how long the
  // tail rings, not as a different tune — so its the same figure getting
  // brighter and hanging around longer. thats what makes an upgrade *feel*
  // like an upgrade without you having to read the label
  unboxCommon,
  unboxRare,
  unboxEpic,
  unboxLegendary,
}

/// Lightweight sound service that persists user preference.
/// Uses bundled audio assets where available and system sounds as a safe
/// fallback.
class AppSoundService {
  AppSoundService._();

  static const String _soundEnabledKey = 'budget_buddy_sound_enabled';
  static const String _musicEnabledKey = 'budget_buddy_music_enabled';
  static const String _musicAsset = 'audio/ambient_loop.wav';
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
        AppSoundEffect.caseRoll: 'audio/case_roll.wav',
        AppSoundEffect.unboxCommon: 'audio/unbox_common.wav',
        AppSoundEffect.unboxRare: 'audio/unbox_rare.wav',
        AppSoundEffect.unboxEpic: 'audio/unbox_epic.wav',
        AppSoundEffect.unboxLegendary: 'audio/unbox_legendary.wav',
      };

  /// Playback level per effect, 0..1.
  ///
  /// A second lever on top of the per-file peaks baked in by
  /// `tool/make_sounds.py`, and worth having separately: the file levels are
  /// the *mix* — how these sounds sit against each other — while this is the
  /// app's overall loudness.
  ///
  /// **These are all about 30% down from where they were**, against a music
  /// loop that went up by nearly the same factor (see [_musicVolume]). The
  /// brief was "the background sound louder and the other sounds toned down
  /// a bit", and the two halves of that have to move together: turning the
  /// loop up on its own would just make the app louder, and turning the
  /// effects down on its own would make it quieter. What actually changes is
  /// the *ratio* — the loop stops being something you have to listen for
  /// under a layer of clicks.
  ///
  /// The order within the table is unchanged, because it was right: it is
  /// the frequency each sound fires at, inverted. Navigation is the quietest
  /// because it goes off on every tab switch, dozens of times a session, and
  /// anything that frequent has to be texture rather than an announcement.
  /// A legendary unbox is the loudest because most players will never hear
  /// one.
  static const Map<AppSoundEffect, double> _volumes = <AppSoundEffect, double>{
    AppSoundEffect.navigation: 0.15,
    AppSoundEffect.tap: 0.24,
    AppSoundEffect.selection: 0.24,
    AppSoundEffect.needPickup: 0.30,
    AppSoundEffect.wantHit: 0.32,
    AppSoundEffect.error: 0.32,
    AppSoundEffect.shutdown: 0.30,
    AppSoundEffect.notification: 0.38,
    AppSoundEffect.success: 0.40,
    AppSoundEffect.celebration: 0.46,
    AppSoundEffect.caseRoll: 0.36,
    AppSoundEffect.unboxCommon: 0.40,
    AppSoundEffect.unboxRare: 0.43,
    AppSoundEffect.unboxEpic: 0.46,
    AppSoundEffect.unboxLegendary: 0.50,
  };

  /// The ambient loop's level.
  ///
  /// Was 0.18, which put it about 5dB under the quietest *effect* in the
  /// table above — so on a phone, with the app's own clicks over the top, it
  /// was inaudible in practice and read as "the music is not playing". It is
  /// still the quietest thing in the app by design, because it is under
  /// everything else for minutes at a time rather than for 60ms, but it is
  /// now within reach of the effects instead of beneath them.
  static const double _musicVolume = 0.34;

  /// Anything not listed above. Middle of the range rather than full, so a
  /// newly added effect is quiet by default and gets turned up on purpose.
  static const double _defaultVolume = 0.4;

  static final Map<AppSoundEffect, AudioPlayer> _players =
      <AppSoundEffect, AudioPlayer>{};

  /// The audio session every player in this app uses.
  ///
  /// **This is the fix for sounds cutting each other off.** `audioplayers`
  /// defaults to `AndroidAudioFocus.gain`, which in Android's own words means
  /// "your application is now the sole source of audio that the user is
  /// listening to" — and every player requests it separately. So sixteen
  /// effect players plus the music loop spent their time revoking each
  /// other: the device log showed `onAudioFocusChange(-1)` — AUDIOFOCUS_LOSS
  /// — on essentially every sound, which is a tab switch killing the music,
  /// or a reward chime killing the ratchet under it.
  ///
  /// A UI click has no business taking audio focus at all. `none` requests
  /// none, so nothing here can stop anything else — including the player's own
  /// music from another app, which `gain` was also silencing every time
  /// somebody changed tabs.
  ///
  /// `sonification` / `assistanceSonification` is what Android calls exactly
  /// this: short interface feedback rather than media. It also routes
  /// correctly on a call and respects the silent switch.
  static final AudioContext _uiAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    // `ambient` mixes with other audio by default and honours the ring/silent
    // switch. It also cannot take `mixWithOthers` explicitly — the platform
    // interface asserts against it, because for this category it is implied.
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// The music loop's session.
  ///
  /// Same refusal to take focus, for the same reason, but declared as media
  /// rather than sonification because that is what it is — a device that
  /// routes UI beeps and background music differently should be allowed to.
  static final AudioContext _musicAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static DateTime? _lastPlayedAt;
  static AppSoundEffect? _lastEffect;
  static SharedPreferences? _preferences;
  static bool _playersReady = false;

  /// The one in-flight [initialize] call.
  ///
  /// **This is a fix, not tidying.** The old code set `_playersReady = true`
  /// as its *first* statement and then spent a dozen `await`s applying the
  /// audio context and the player mode to sixteen players. Any `play()` that
  /// arrived during that window saw the flag, skipped initialisation, and
  /// used a player that had not been configured yet — which means a player
  /// still on the package's default `AndroidAudioFocus.gain`. That is the
  /// exact "sole source of audio" default the context above exists to avoid,
  /// and one player holding it will silence every other sound in the app
  /// (and the user's own music) until something rebuilds it. The
  /// focus-stealing bug could come back through a race even though the value
  /// it depends on never changed.
  ///
  /// Holding the future means every caller awaits the *same* setup and
  /// nobody proceeds on a half-built player.
  static Future<void>? _initFuture;

  // on by default now theres actually something worth hearing.
  //
  // used to be off because the old effects sounded harsh — except there were
  // no files behind the asset paths at all, so the setting did nothing
  // anyway. make_sounds.py generates the whole lot now with soft attacks and
  // exponential decays specifically so it isnt harsh. toggle in Profile
  // still kills everything if you want silence
  static bool enabled = true;

  /// Background music is a separate switch from the effects.
  ///
  /// They are genuinely different preferences: plenty of people want the
  /// click when they tap a button and do not want a loop playing under it,
  /// and someone listening to their own music wants the opposite of what a
  /// single toggle would give them.
  static bool musicEnabled = true;

  /// The two sessions, for the regression test.
  ///
  /// The fix here is a *value*, not a behavior — nothing about the code stops
  /// working if `audioFocus` goes back to `gain`, it just quietly starts
  /// cutting sounds off on a real phone again, which is invisible on a
  /// desktop and invisible in review. So the values are asserted directly.
  @visibleForTesting
  static AudioContext get debugUiAudioContext => _uiAudioContext;

  @visibleForTesting
  static AudioContext get debugMusicAudioContext => _musicAudioContext;

  /// The mix, for the regression test. See [_volumes] and [_musicVolume].
  @visibleForTesting
  static Map<AppSoundEffect, double> get debugEffectVolumes => _volumes;

  @visibleForTesting
  static double get debugMusicVolume => _musicVolume;

  static AudioPlayer? _music;
  static bool _musicWanted = false;

  /// Whether the app is on screen.
  ///
  /// **The bug this exists for:** close the app on a phone, press a volume
  /// button, and the music is playing. Nothing on the way to a play call
  /// checked whether the app was still visible, and several paths could
  /// start the loop *after* the app had gone to the background:
  ///
  ///  * [handleAppPaused] disposed sixteen effect players one at a time and
  ///    only then stopped the music, so the loop kept running for that whole
  ///    stretch — and if the process was suspended part-way, it never stopped.
  ///  * [handleAppResumed] rebuilt the same sixteen players before restarting
  ///    the loop. Leave the app during that and the restart still ran,
  ///    starting music in a backgrounded app.
  ///  * [startMusic] assigns its player only after `play()` returns. A pause
  ///    arriving during that await found no player to stop, and the one
  ///    being built went on to play.
  ///  * `AppLifecycleState.hidden` was not treated as backgrounded at all.
  ///
  /// So every start now refuses while this is false, and re-checks it after
  /// each await.
  static bool _inForeground = true;

  /// Bumped on every trip to the foreground or background, so an async start
  /// that began before one can tell it is stale and back out.
  static int _lifecycleEpoch = 0;

  static bool _staleSince(int epoch) =>
      !_inForeground || epoch != _lifecycleEpoch;

  @visibleForTesting
  static bool get debugInForeground => _inForeground;

  @visibleForTesting
  static bool get debugHasMusicPlayer => _music != null;

  @visibleForTesting
  static bool get debugMusicWanted => _musicWanted;

  /// Drives the lifecycle handling exactly as the platform would.
  @visibleForTesting
  static void debugLifecycleChanged(AppLifecycleState state) =>
      _AudioLifecycleObserver().didChangeAppLifecycleState(state);

  static bool get _canUseAssetPlayers => true;

  /// Starts the ambient loop, or does nothing if it is already running.
  ///
  /// **"Already running" used to mean "the object exists", and that was the
  /// bug behind "the sound sometimes just would not play and I had to toggle
  /// the music button off and on".** The guard was `if (_music != null)
  /// return;`. An `AudioPlayer` that exists and an `AudioPlayer` that is
  /// playing are not the same thing: the OS can stop it while the app is
  /// backgrounded, an interruption can leave it paused, and `play()` can fail
  /// after the object is already assigned. In every one of those cases the
  /// field stayed non-null forever, so every later call to this — and it is
  /// called from a lot of screen entry points — returned immediately and the
  /// loop never came back.
  ///
  /// The only code path in the whole app that could recover was
  /// [setMusicEnabled], because it *disposes* the player on the way down and
  /// builds a new one on the way up. Which is precisely the off-and-on-again
  /// the player had to do by hand, and it is the reason that workaround
  /// worked when nothing else did.
  ///
  /// So the guard now asks the player what state it is in, and a player that
  /// exists but is not playing gets resumed or replaced.
  static Future<void> startMusic() async {
    _musicWanted = true;
    if (!musicEnabled || !enabled) return;
    // Remembered, not started: [handleAppResumed] starts it on the way back.
    if (!_inForeground) return;
    final epoch = _lifecycleEpoch;

    final existing = _music;
    if (existing != null) {
      if (existing.state == PlayerState.playing) return;
      // Present but not playing. Try the cheap recovery first — resuming a
      // paused player keeps its position, which matters for a 48-second loop
      // somebody has been half-hearing for ten minutes.
      try {
        await existing.resume();
        if (_staleSince(epoch)) {
          await _disposeMusic();
          return;
        }
        if (existing.state == PlayerState.playing) return;
      } catch (error) {
        debugPrint('Music resume failed, rebuilding: $error');
      }
      await _disposeMusic();
    }

    try {
      final player = AudioPlayer(playerId: 'budget_buddy_music');
      if (!kIsWeb) {
        try {
          await player.setAudioContext(_musicAudioContext);
        } catch (error) {
          debugPrint('Music audio context not applied: $error');
        }
      }
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_musicVolume);
      if (_staleSince(epoch)) {
        await player.dispose();
        return;
      }
      await player.play(AssetSource(_musicAsset));
      // The app may have left while `play` was in flight, and a pause during
      // that await could not see this player to stop it.
      if (_staleSince(epoch)) {
        await player.stop();
        await player.dispose();
        return;
      }
      _music = player;
    } catch (error) {
      debugPrint('Background music unavailable: $error');
      _music = null;
    }
  }

  static Future<void> stopMusic() async {
    _musicWanted = false;
    await _disposeMusic();
  }

  static Future<void> _disposeMusic() async {
    // Deliberately does *not* clear `_musicWanted`. This is the teardown half
    // of several different intentions — muting, rebuilding a stalled player,
    // switching music off — and only one of them means "nobody wants music
    // any more". That one is [stopMusic], which clears the flag itself.
    final player = _music;
    _music = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (error) {
      debugPrint('Background music teardown: $error');
    }
  }

  static Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_musicEnabledKey, value);
    if (value) {
      // Unconditional, because switching the toggle on *is* the request —
      // `startMusic` sets `_musicWanted` itself. The old `if (_musicWanted)`
      // guard meant flipping the switch on did nothing at all unless some
      // screen had already asked for music earlier in the session.
      await startMusic();
    } else {
      await _disposeMusic();
    }
  }

  static Future<void> initialize() => _initFuture ??= _initialize();

  static Future<void> _initialize() async {
    // First, not after the players are built: a player who backgrounds the
    // app while it is still starting up has to be heard.
    _attachLifecycleObserver();
    _preferences ??= await SharedPreferences.getInstance();
    // `?? enabled` rather than `?? false`. Hardcoding the fallback here is
    // what made the field default above meaningless: a fresh install has no
    // stored key, so every launch reset sound to off no matter what the
    // declaration said.
    enabled = _preferences?.getBool(_soundEnabledKey) ?? enabled;
    musicEnabled = _preferences?.getBool(_musicEnabledKey) ?? musicEnabled;

    if (!_canUseAssetPlayers) {
      _playersReady = true;
      return;
    }

    for (final effect in AppSoundEffect.values) {
      _players[effect] = AudioPlayer(playerId: 'budget_buddy_${effect.name}');
    }

    // Set globally as well as per player: a player created later (or by a
    // package that makes its own) inherits this rather than the focus-grabbing
    // default.
    try {
      await AudioPlayer.global.setAudioContext(_uiAudioContext);
    } catch (error) {
      debugPrint('Global audio context not applied: $error');
    }

    for (final effect in _players.keys.toList()) {
      await _configurePlayer(_players[effect]!);
    }

    // Last, not first. See [_initFuture].
    _playersReady = true;
  }

  static Future<void> _configurePlayer(AudioPlayer player) async {
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      if (!kIsWeb) {
        await player.setAudioContext(_uiAudioContext);
        await player.setPlayerMode(PlayerMode.lowLatency);
      }
    } catch (error) {
      debugPrint('Audio player setup fallback: $error');
    }
  }

  static _AudioLifecycleObserver? _lifecycleObserver;

  /// Watches for the app coming back to the foreground.
  ///
  /// Nothing in `audioplayers` reacts to the Android lifecycle — the plugin
  /// only hears about the engine detaching. Meanwhile the low-latency path is
  /// a `SoundPool`, whose loaded samples the system is free to reclaim while
  /// the app is in the background. When that happens `SoundPool.play()`
  /// returns 0 and plays nothing, and it does not throw — so the
  /// try/catch in [play] never fires and the effect is simply silent from
  /// then on, for the rest of the process.
  ///
  /// That is unprovable from Dart, which is why the recovery is
  /// unconditional: on every resume the effect players are rebuilt (cheap —
  /// they are empty objects until something plays) and the music is asked to
  /// confirm it is actually still running.
  static void _attachLifecycleObserver() {
    if (_lifecycleObserver != null) return;
    final binding = WidgetsBinding.instance;
    final observer = _AudioLifecycleObserver();
    binding.addObserver(observer);
    _lifecycleObserver = observer;
    final current = binding.lifecycleState;
    if (current != null && _isBackground(current)) {
      _inForeground = false;
    }
  }

  /// Rebuilds the effect players and restarts the loop after a resume.
  static Future<void> handleAppResumed() async {
    _inForeground = true;
    final epoch = ++_lifecycleEpoch;
    if (_playersReady) {
      for (final effect in _players.keys.toList()) {
        // Left again part-way through: stop, and do not start the music.
        if (epoch != _lifecycleEpoch) return;
        await _rebuildPlayer(effect);
      }
    }
    if (_musicWanted && epoch == _lifecycleEpoch) {
      await startMusic();
    }
  }

  /// Silences everything when the app is hidden, backgrounded or closed.
  ///
  /// The music is stopped **first**, before any effect player is touched.
  /// Keeps `_musicWanted` so a resume can restart the loop.
  static Future<void> handleAppPaused() async {
    _inForeground = false;
    _lifecycleEpoch++;
    await _disposeMusic();
    if (!_playersReady) return;
    for (final effect in _players.keys.toList()) {
      final old = _players.remove(effect);
      if (old != null) {
        try {
          await old.stop();
          await old.dispose();
        } catch (error) {
          debugPrint('Could not dispose ${effect.name} on pause: $error');
        }
      }
    }
  }

  /// Every state in which the app is not on screen.
  ///
  /// `inactive` is left out on purpose: it is the notification shade or an
  /// incoming-call banner over a still-visible app, and cutting the music for
  /// that would stop it every time somebody checks a notification.
  static bool _isBackground(AppLifecycleState state) =>
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached;

  /// Throws away one effect's player and builds a configured replacement.
  static Future<void> _rebuildPlayer(AppSoundEffect effect) async {
    final old = _players.remove(effect);
    if (old != null) {
      try {
        await old.stop();
        await old.dispose();
      } catch (error) {
        debugPrint('Could not dispose ${effect.name}: $error');
      }
    }
    final player = AudioPlayer(playerId: 'budget_buddy_${effect.name}');
    await _configurePlayer(player);
    _players[effect] = player;
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_soundEnabledKey, value);
    // Sound off means *silence*, music included — otherwise the mute switch
    // leaves a loop playing and reads as broken.
    if (!value) {
      await _disposeMusic();
    } else if (_musicWanted) {
      await startMusic();
    }
  }

  static Future<void> play(AppSoundEffect effect) async {
    if (!enabled || !_inForeground) {
      return;
    }

    // Awaits the single in-flight setup rather than racing past a flag.
    await initialize();

    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastEffect == effect &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 40)) {
      return;
    }

    _lastPlayedAt = now;
    _lastEffect = effect;

    final assetPath = _assetPaths[effect];
    if (assetPath == null) {
      return _playSystemFallback(effect);
    }

    if (await _tryPlay(effect, assetPath)) return;

    // One heal-and-retry before giving up.
    //
    // Previously a failure here was permanent: the error was printed, the
    // system click played instead, and the broken player stayed in the map
    // for the life of the process — so one transient fault meant that effect
    // was gone until the app was restarted. Rebuilding costs a few
    // milliseconds and only happens on a path that has already failed.
    await _rebuildPlayer(effect);
    if (await _tryPlay(effect, assetPath)) return;

    await _playSystemFallback(effect);
  }

  static Future<bool> _tryPlay(AppSoundEffect effect, String assetPath) async {
    final player = _players[effect];
    if (player == null) return false;
    try {
      await player.stop();
      // Set before playing, not after: in low-latency mode the volume is only
      // handed to the platform when the stream starts, so a `setVolume` after
      // `play` applies from the *next* one onward.
      await player.setVolume(_volumes[effect] ?? _defaultVolume);
      await player.play(AssetSource(assetPath));
      return true;
    } catch (error) {
      debugPrint('Asset sound failed for ${effect.name}: $error');
      return false;
    }
  }

  /// Cuts an effect off part-way through.
  ///
  /// Only meaningful for the long ones. [AppSoundEffect.caseRoll] runs for
  /// 4.2 seconds in lockstep with the reel animation, so a player who taps
  /// *Skip* has to have the ratchet stop with the picture — otherwise the
  /// reward chime lands on top of ticks for a reel that is no longer moving,
  /// which reads as the app having lost track of itself.
  static Future<void> stop(AppSoundEffect effect) async {
    final player = _players[effect];
    if (player == null) return;
    try {
      await player.stop();
    } catch (error) {
      debugPrint('Could not stop ${effect.name}: $error');
    }
  }

  static Future<void> _playSystemFallback(AppSoundEffect effect) async {
    switch (effect) {
      case AppSoundEffect.tap:
      case AppSoundEffect.navigation:
      case AppSoundEffect.selection:
      case AppSoundEffect.success:
      case AppSoundEffect.needPickup:
        return SystemSound.play(SystemSoundType.click);
      case AppSoundEffect.notification:
      case AppSoundEffect.error:
      case AppSoundEffect.wantHit:
      case AppSoundEffect.celebration:
      case AppSoundEffect.shutdown:
      case AppSoundEffect.unboxCommon:
      case AppSoundEffect.unboxRare:
      case AppSoundEffect.unboxEpic:
      case AppSoundEffect.unboxLegendary:
        return SystemSound.play(SystemSoundType.alert);
      case AppSoundEffect.caseRoll:
        // No system fallback. The ratchet is four seconds of rhythm; a
        // single system click in its place would fire once and read as a
        // misfire rather than as a shortened version of the same thing.
        return;
    }
  }
}

/// Rebuilds the audio players when the app comes back to the foreground.
///
/// See [AppSoundService._attachLifecycleObserver] for why this is needed and
/// why the recovery is unconditional rather than conditional on some check.
class _AudioLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AppSoundService.handleAppResumed());
    } else if (AppSoundService._isBackground(state)) {
      unawaited(AppSoundService.handleAppPaused());
    }
  }
}
