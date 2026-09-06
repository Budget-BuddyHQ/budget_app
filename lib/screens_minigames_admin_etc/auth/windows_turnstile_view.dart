import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import '../../services_backend_and_other_services/turnstile_challenge_server.dart';

/// The Cloudflare challenge, rendered inside the app on Windows.
///
/// **What this replaces.** Windows was the one platform without an embedded
/// challenge. `_supportsEmbeddedWebView` returned false for it, so signing in
/// opened the *system browser*, made the player solve a captcha on a
/// `localhost` page in Edge or Chrome, and then asked them to alt-tab back to
/// a Flutter window that had been sitting on "Still checking" the whole time.
///
/// That is not a sign-in flow, it is a detour, and it is the kind that loses
/// people: a browser tab opening unprompted during a login looks like
/// something has gone wrong even when everything is working. On a desktop it
/// also means the app loses focus at the exact moment it is asking for
/// credentials.
///
/// **Why WebView2 rather than porting the mobile path.** `webview_flutter`
/// has no Windows implementation and is not going to grow one — its federated
/// platform packages are Android, iOS and macOS. `webview_windows` wraps
/// Microsoft's WebView2, which ships with Windows 10 and 11 and is already on
/// essentially every machine this app would run on.
///
/// **Why it keeps the local HTTP server.** The obvious approach —
/// `loadStringContent(html)` — hands the page an `about:blank` origin, and
/// Turnstile validates the page's hostname against the site key's allowed
/// domains. It would fail, and fail in the least debuggable way: a widget
/// that renders and then silently refuses to issue a token.
///
/// Serving the same HTML from the loopback server that already exists puts
/// the page on `http://localhost`, which is the origin the Android path
/// already uses through `baseUrl` and which the site key already allows. It
/// also reuses the tested `/token` POST, so no JavaScript bridge, no message
/// channel, and one delivery path for both Windows flows instead of two.
///
/// **The browser flow is still there**, reached through
/// [onNeedsBrowserFallback]. If WebView2 is missing or its initialisation
/// throws, falling back is strictly better than failing — the detour is worse
/// than this, and it is much better than nobody being able to sign in.
class WindowsTurnstileView extends StatefulWidget {
  const WindowsTurnstileView({
    super.key,
    required this.server,
    required this.html,
    required this.reloadToken,
    required this.onToken,
    required this.onUnavailable,
    required this.onNeedsBrowserFallback,
  });

  /// The loopback server that serves [html] and receives the token.
  ///
  /// Owned by the auth screen rather than by this widget, because the browser
  /// fallback uses the same one and only one of them can hold the port.
  final TurnstileChallengeServer server;

  /// The challenge page. Must POST its token to `/token` — see
  /// `AuthScreen._embeddedWindowsTurnstileHtml`.
  final String html;

  /// Bumped by the parent to demand a fresh challenge.
  ///
  /// Turnstile tokens are single-use, so every submit needs a new one. An
  /// `int` rather than a callback because the parent already tracks this as
  /// state, and a widget that reloads on `didUpdateWidget` cannot get out of
  /// step with it the way an imperative `reset()` can.
  final int reloadToken;

  final ValueChanged<String?> onToken;

  /// The challenge cannot be completed here — a render failure or a page that
  /// could not load. Distinct from "no token yet": the app must stop waiting.
  final VoidCallback onUnavailable;

  /// WebView2 is not usable on this machine. Go back to the browser.
  final VoidCallback onNeedsBrowserFallback;

  @override
  State<WindowsTurnstileView> createState() => _WindowsTurnstileViewState();
}

class _WindowsTurnstileViewState extends State<WindowsTurnstileView> {
  final WebviewController _controller = WebviewController();
  StreamSubscription<WebErrorStatus>? _errors;
  bool _ready = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void didUpdateWidget(WindowsTurnstileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadToken != oldWidget.reloadToken && _ready) {
      unawaited(_arm());
    }
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      if (_disposed) return;
      await _controller.setBackgroundColor(Colors.transparent);
      _errors = _controller.onLoadError.listen((error) {
        // The page itself is served from loopback, so a load error here means
        // the Cloudflare script could not be fetched — no network, a blocked
        // domain, a captive portal. No token is coming, and the sign-in must
        // not hang waiting for one.
        debugPrint('Windows Turnstile load error: $error');
        if (!_disposed) widget.onUnavailable();
      });
    } catch (error) {
      // WebView2 runtime absent, or the environment failed to create. Both
      // are machine configuration rather than anything the player did, and
      // both are recoverable by going back to the browser.
      debugPrint('WebView2 unavailable, falling back to the browser: $error');
      if (!_disposed) widget.onNeedsBrowserFallback();
      return;
    }

    if (_disposed) return;
    setState(() => _ready = true);
    await _arm();
  }

  /// Serves a fresh challenge and waits for its token.
  Future<void> _arm() async {
    try {
      final uri = await widget.server.startTokenRequest(html: widget.html);
      if (_disposed) return;
      await _controller.loadUrl(uri.toString());

      final token = await widget.server.waitForToken();
      if (_disposed) return;
      widget.onToken(token);
    } catch (error) {
      debugPrint('Windows Turnstile challenge failed: $error');
      if (!_disposed) widget.onUnavailable();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_errors?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 74,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    // The same height the mobile widget gets. Turnstile's `flexible` size
    // fills the width it is given and is about 65px tall; the extra is so a
    // challenge that expands into an interactive puzzle has somewhere to go
    // rather than being clipped inside its own frame.
    return SizedBox(height: 120, child: Webview(_controller));
  }
}
