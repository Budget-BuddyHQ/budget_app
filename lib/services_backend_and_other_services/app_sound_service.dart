import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
  /// app's overall loudness, which is the thing that turned out to be wrong
  /// ("the sound is kind of high right now"). Changing one number here is
  /// also something that can happen without regenerating sixteen files.
  ///
  /// Navigation is deliberately the quietest: it fires on every tab switch,
  /// dozens of times a session, and anything that frequent has to be texture
  /// rather than an announcement.
  static const Map<AppSoundEffect, double> _volumes = <AppSoundEffect, double>{
    AppSoundEffect.navigation: 0.22,
    AppSoundEffect.tap: 0.34,
    AppSoundEffect.selection: 0.34,
    AppSoundEffect.needPickup: 0.42,
    AppSoundEffect.wantHit: 0.46,
    AppSoundEffect.error: 0.46,
    AppSoundEffect.shutdown: 0.42,
    AppSoundEffect.notification: 0.55,
    AppSoundEffect.success: 0.58,
    AppSoundEffect.celebration: 0.66,
    AppSoundEffect.caseRoll: 0.50,
    AppSoundEffect.unboxCommon: 0.58,
    AppSoundEffect.unboxRare: 0.62,
    AppSoundEffect.unboxEpic: 0.66,
    AppSoundEffect.unboxLegendary: 0.70,
  };

  /// Anything not listed above. Middle of the range rather than full, so a
  /// newly added effect is quiet by default and gets turned up on purpose.
  static const double _defaultVolume = 0.5;

  static final Map<AppSoundEffect, AudioPlayer> _players =
      <AppSoundEffect, AudioPlayer>{};

  static DateTime? _lastPlayedAt;
  static AppSoundEffect? _lastEffect;
  static SharedPreferences? _preferences;
  static bool _playersReady = false;

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

  static AudioPlayer? _music;
  static bool _musicWanted = false;

  static bool get _canUseAssetPlayers => true;

  /// Starts the ambient loop, or does nothing if it is already running.
  ///
  /// Idempotent on purpose — this is called from screen entry points, and a
  /// tab switch that restarted the track from the top would be worse than
  /// no music at all.
  static Future<void> startMusic() async {
    _musicWanted = true;
    if (!musicEnabled || !enabled) return;
    if (_music != null) return;
    try {
      final player = AudioPlayer(playerId: 'budget_buddy_music');
      // loop, and quiet enough to sit under speech + effects instead of
      // fighting them. 0.28 picked by ear against tap.wav
      await player.setReleaseMode(ReleaseMode.loop);
      // Under the effects, which are themselves turned down — see [_volumes].
      await player.setVolume(0.18);
      await player.play(AssetSource(_musicAsset));
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
      if (_musicWanted) await startMusic();
    } else {
      await _disposeMusic();
    }
  }

  static Future<void> initialize() async {
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

    if (_playersReady) {
      return;
    }

    _playersReady = true;
    for (final effect in AppSoundEffect.values) {
      _players[effect] = AudioPlayer(playerId: 'budget_buddy_${effect.name}');
    }

    for (final player in _players.values) {
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        if (!kIsWeb) {
          await player.setPlayerMode(PlayerMode.lowLatency);
        }
      } catch (error) {
        debugPrint('Audio player setup fallback: $error');
      }
    }
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
    if (!enabled) {
      return;
    }

    if (!_playersReady) {
      await initialize();
    }

    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastEffect == effect &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 40)) {
      return;
    }

    _lastPlayedAt = now;
    _lastEffect = effect;

    final assetPath = _assetPaths[effect];
    final player = _players[effect];

    if (assetPath != null && player != null) {
      try {
        await player.stop();
        await player.setVolume(_volumes[effect] ?? _defaultVolume);
        await player.play(AssetSource(assetPath));
        return;
      } catch (error) {
        debugPrint('Asset sound fallback for ${effect.name}: $error');
      }
    }

    await _playSystemFallback(effect);
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
