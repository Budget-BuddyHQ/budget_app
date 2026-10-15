import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

/// Sound in a browser, played on plain `<audio>` elements.
///
/// **Reported as:** *"on a web it doesn't have the background music, and the
/// sound effects."* Two browser rules, and `audioplayers` met neither:
///
/// * **Nothing plays before the player has touched the page.** The music was
///   asked for as the home screen opened, the browser refused, and nothing
///   asked again, so the web build never had music at all.
/// * **On iPhone, each sound has to be started inside a tap the first time.**
///   `audioplayers` loads the file first and plays it once that finishes,
///   by which point the tap is over, so Safari refused the effects too.
///
/// So this listens for the first touch, click or key anywhere on the page
/// and, inside that same event, starts the music and plays every effect once,
/// muted. After that the browser treats them all as allowed, and a sound
/// asked for later plays straight away. The listener stays, so music that a
/// backgrounded tab paused comes back on the next touch.
///
/// Plain `<audio>` rather than the Web Audio API on purpose: iPhones mute Web
/// Audio when the ring switch is on silent, and do not mute media elements.
class WebAudio {
  WebAudio._();

  static final Map<String, web.HTMLAudioElement> _effects =
      <String, web.HTMLAudioElement>{};
  static web.HTMLAudioElement? _music;
  static bool _musicWanted = false;
  static bool _effectsUnlocked = false;

  /// Effects asked for since the unlock started, which the unlock must not
  /// pause again when it finishes.
  static final Set<String> _requested = <String>{};

  static void init({
    required Map<String, String> effects,
    required String music,
    required double musicVolume,
  }) {
    if (_music != null) return;
    for (final entry in effects.entries) {
      _effects[entry.key] = web.HTMLAudioElement()
        ..src = _url(entry.value)
        ..preload = 'auto';
    }
    _music = web.HTMLAudioElement()
      ..src = _url(music)
      ..loop = true
      ..preload = 'auto'
      ..volume = musicVolume;

    final listener = ((web.Event _) => _unlock()).toJS;
    for (final type in const ['pointerdown', 'touchend', 'click', 'keydown']) {
      web.document.addEventListener(
        type,
        listener,
        web.AddEventListenerOptions(capture: true),
      );
    }
  }

  /// Where the built app serves an asset, by its pubspec key.
  static String _url(String assetKey) =>
      ui_web.assetManager.getAssetUrl(assetKey);

  /// Runs inside the touch, which is the whole point. See the class comment.
  static void _unlock() {
    final music = _music;
    if (_musicWanted && music != null && music.paused) _playMusic();
    if (_effectsUnlocked) return;
    _effectsUnlocked = true;
    for (final entry in _effects.entries) {
      final el = entry.value..muted = true;
      el.play().toDart.then(
        (_) {
          el.muted = false;
          // A sound asked for during this same touch keeps playing.
          if (_requested.contains(entry.key)) return;
          el
            ..pause()
            ..currentTime = 0;
        },
        onError: (_) {
          el.muted = false;
          _effectsUnlocked = false;
        },
      );
    }
  }

  static void playEffect(String name, double volume) {
    final el = _effects[name];
    if (el == null) return;
    _requested.add(name);
    el
      ..muted = false
      ..volume = volume
      ..currentTime = 0;
    el.play().toDart.then((_) {}, onError: (_) {});
  }

  static void stopEffect(String name) {
    final el = _effects[name];
    if (el == null) return;
    el
      ..pause()
      ..currentTime = 0;
  }

  static void startMusic() {
    _musicWanted = true;
    _playMusic();
  }

  static void stopMusic() {
    _musicWanted = false;
    _music?.pause();
  }

  /// Refused before the first touch, which is fine: [_unlock] tries again.
  static void _playMusic() {
    _music?.play().toDart.then((_) {}, onError: (_) {});
  }
}
