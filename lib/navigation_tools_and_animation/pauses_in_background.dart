import 'package:flutter/widgets.dart';

/// A screen that stops doing things while the app is not on screen.
///
/// # The bug this fixes
///
/// Reported as the app carrying on after you leave it, and as an input that
/// sticks when you hold it down. Both are the same gap. Nothing in this app's
/// game screens watched the app lifecycle, so
///
///  * a `Timer.periodic` keeps firing while the app is in the background.
///    Leak Patrol's round ran out, Coin Cascade's bills kept dropping, and the
///    player came back to a game they had already lost without playing it.
///  * the Market Board kept polling the network every two seconds while the
///    phone was in somebody's pocket, which is battery and data spent on a
///    screen nobody is looking at.
///  * a held key or a thumb on the joystick never gets its release event when
///    the app goes away mid-press, so the character keeps running forever.
///
/// Flutter stops *animations* on its own, because it stops producing frames.
/// Timers and held input state are not animations, and this is the part that
/// has to be handled by hand.
///
/// # Using it
///
/// Mix it into a `State` and implement [onAppBackgrounded]. The observer is
/// added and removed for you.
///
/// ```dart
/// class _MyGameState extends State<MyGame> with PausesInBackground {
///   @override
///   void onAppBackgrounded() => _clock?.cancel();
///
///   @override
///   void onAppForegrounded() => _startClock();
/// }
/// ```
mixin PausesInBackground<T extends StatefulWidget> on State<T> {
  late final _BackgroundWatcher _watcher = _BackgroundWatcher(
    backgrounded: () {
      if (mounted) onAppBackgrounded();
    },
    foregrounded: () {
      if (mounted) onAppForegrounded();
    },
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_watcher);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_watcher);
    super.dispose();
  }

  /// The app has left the screen. Cancel clocks and release held input.
  void onAppBackgrounded();

  /// The app is back. Restart whatever [onAppBackgrounded] stopped.
  void onAppForegrounded() {}
}

class _BackgroundWatcher with WidgetsBindingObserver {
  _BackgroundWatcher({required this.backgrounded, required this.foregrounded});

  final VoidCallback backgrounded;
  final VoidCallback foregrounded;

  /// Every state in which the app is not on screen.
  ///
  /// `inactive` is deliberately not one of them. It fires for the
  /// notification shade and for an incoming call banner over a still-visible
  /// app, and pausing a game for those would be its own bug. It matches the
  /// rule the audio service uses.
  static bool isBackground(AppLifecycleState state) =>
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      foregrounded();
    } else if (isBackground(state)) {
      backgrounded();
    }
  }
}
