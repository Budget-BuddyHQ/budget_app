import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/turnstile_config.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../navigation_tools_and_animation/fade_page_route.dart';
import '../../constants/app_assets.dart';
import '../../constants/privacy_policy.dart';
import '../../services_backend_and_other_services/supabase_service.dart';
import '../../services_backend_and_other_services/turnstile_challenge_server.dart';
import 'windows_turnstile_view.dart';
import '../../widgets_custom_lotties/custom_button.dart';
import '../../widgets_custom_lotties/game_toast.dart';
import '../Gameplay/dashboard/dashboard_shell.dart';
import '../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../themes_colors/app_theme.dart';

enum AuthMode { login, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.mode});

  final AuthMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // age band, asked at signup now instead of buried in profile settings.
  // used to be almost nobody set it so the app had no idea who it was
  // teaching. null default + "rather not say" option so its still opt-out
  AgeBand? _ageBand;
  final TurnstileChallengeServer _turnstileServer = TurnstileChallengeServer();

  late AuthMode _mode;
  late final AnimationController _heroController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;
  bool _acceptedTerms = false;
  bool _isConfiguringTurnstile = false;
  String? _captchaToken;

  // Set once sign-up succeeds but needs email confirmation. Non-null keeps
  // the player on this screen with a "check your email" card and a resend
  // option, instead of the previous dead end of a single toast and the same
  // blank form. Cleared on mode switch so it can't linger onto a later
  // sign-in attempt.
  String? _pendingConfirmationEmail;
  bool _resendingConfirmation = false;
  DateTime? _confirmationResendCooldownUntil;

  // true when turnstile just cant produce a token (render fail, script
  // didnt load etc). without this "no token yet" and "never coming" look
  // the same and the app just hangs on "still checking" forever. supabase
  // does the real security check server side anyway, so if this is broken
  // we just let the request through and let the server reject it
  bool _captchaUnavailable = false;
  WebViewController? _turnstileController;

  bool get _isLogin => _mode == AuthMode.login;
  bool get _isTurnstileConfigured => turnstileSiteKey != 'YOUR_SITE_KEY';
  // platforms webview_flutter actually works on. windows isnt one of them,
  // it gets webview2 instead, see _usesWindowsWebView below
  bool get _supportsEmbeddedWebView {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  // windows w/ webview2 working. false if webview2 couldnt init, then
  // it falls back to the old browser popup instead
  bool get _usesWindowsWebView =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.windows &&
      !_windowsWebViewFailed;

  bool _windowsWebViewFailed = false;

  // bump this to force a fresh windows challenge, tokens are single use
  int _windowsChallengeToken = 0;

  // browser popup fallback, only hit when webview2 doesnt work
  bool get _usesExternalSecurityCheck =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.windows &&
      _windowsWebViewFailed;

  // any in-app challenge, whatever platform. web gets its own branch here
  // because it needs neither webview_flutter (not supported on web) nor
  // webview2 (windows-only) -- the browser can just embed Cloudflare's
  // widget directly.
  bool get _hasEmbeddedChallenge =>
      _supportsEmbeddedWebView || _usesWindowsWebView || kIsWeb;

  // True in exactly the window where tapping submit used to produce the
  // "Still checking, please wait" toast: an embedded challenge is in play,
  // it hasn't produced a token yet, and the unavailable-fallback hasn't
  // kicked in either. Disabling the button for this window instead of
  // reacting to the premature tap means that toast is now unreachable --
  // the button simply isn't tappable until there is something to submit.
  // Doesn't apply to the Windows browser-popup fallback, which is meant to
  // be interactive at submit time.
  bool get _turnstileStillLoading =>
      _hasEmbeddedChallenge &&
      !_usesExternalSecurityCheck &&
      _isTurnstileConfigured &&
      (_captchaToken == null || _captchaToken!.isEmpty) &&
      !_captchaUnavailable;

  String get _turnstileHtml =>
      '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoad" async defer></script>
  <style>
    html, body {
      height: 100%;
      margin: 0;
      background: transparent;
      color-scheme: dark;
      overflow: hidden;
    }
    body {
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
  </style>
</head>
<body>
  <div id="turnstile-widget"></div>

  <script>
    let widgetId;

    function onTurnstileLoad() {
      // has to be 'flexible' not 'invisible', cloudflare moved invisible
      // to a dashboard setting. passing it here threw and broke login
      // for literally everyone, learned that one the hard way
      try {
        widgetId = turnstile.render('#turnstile-widget', {
          sitekey: '$turnstileSiteKey',
          size: 'flexible',
          theme: 'dark',
          callback: onSuccess,
          'expired-callback': onExpired,
          'error-callback': onFailed
        });
      } catch (e) {
        // Tell Dart, rather than dying silently inside a WebView nobody can
        // see. This is exactly how the bug above stayed hidden.
        StatusChannel.postMessage('render-failed: ' + e);
        return;
      }
    }

    function onSuccess(token) {
      TokenChannel.postMessage(token);
    }

    function onExpired() {
      TokenChannel.postMessage('');
    }

    // Distinct from expiry. Expiry means "fetch another one"; a failure means
    // the challenge cannot be completed here at all, and the app has to stop
    // waiting for a token that is never going to arrive.
    function onFailed(code) {
      StatusChannel.postMessage('error: ' + code);
    }
  </script>
</body>
</html>
''';

  // same challenge page as everywhere else but posts the token back to
  // the loopback server instead of a js channel (webview2's bridge is
  // different). failures also post to /status so it doesnt hang forever
  String get _embeddedWindowsTurnstileHtml => _turnstileHtml
      .replaceFirst(
        'TokenChannel.postMessage(token);',
        "fetch('/token', { method: 'POST', body: token });",
      )
      .replaceAll(
        RegExp(r"StatusChannel\.postMessage\(([^;]+)\);"),
        "fetch('/status', { method: 'POST', body: \$1 });",
      );

  String get _externalTurnstileHtml => _turnstileHtml.replaceFirst(
    'TokenChannel.postMessage(token);',
    "fetch('/token', { method: 'POST', body: token }).then(function () { document.body.innerHTML = '<p style=\"color:#0f5132;font:16px system-ui;text-align:center;margin-top:40px;\">Security check complete. You can return to Budget Buddy.</p>'; });",
  );

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    // webview2 render failures come over the loopback server not a js
    // channel, wired here so a broken widget doesnt just hang forever
    _turnstileServer.onStatus = (detail) {
      debugPrint('Windows Turnstile status: $detail');
      if (mounted) setState(() => _captchaUnavailable = true);
    };

    if (_supportsEmbeddedWebView) {
      unawaited(_configureTurnstile());
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameController.dispose();
    unawaited(_turnstileServer.stop());
    super.dispose();
  }

  // opens privacy policy in the real device browser, not a webview,
  // so people can actually see the url in the address bar
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      // Web ignores `mode` entirely and always opens external links via
      // `window.open` in a new tab -- which desktop Chrome/Edge/Firefox
      // block unless it fires perfectly synchronously with the click.
      // Mobile browsers are far more lenient about it, which is exactly the
      // split that was reported: worked on phone, dead on desktop with a
      // mouse. `_self` makes it navigate the current tab instead, which no
      // browser's popup blocker touches. Harmless on non-web platforms --
      // this parameter is a no-op there.
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) {
      GameToast.show(
        context,
        title: 'Could not open the policy',
        message: kPrivacyPolicyUrl,
        icon: Icons.link_off_rounded,
        accent: const Color(0xFFFFC36B),
      );
    }
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      GameToast.show(
        context,
        title: 'Check your details',
        message: 'Please fix the highlighted fields and try again.',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFFFC36B),
      );
      return;
    }

    if (!_isLogin && !_acceptedTerms) {
      GameToast.show(
        context,
        title: 'One quick step',
        message:
            'Please read and accept the Privacy Policy to create your '
            'account.',
        icon: Icons.rule_folder_outlined,
        accent: const Color(0xFFFFC36B),
      );
      return;
    }

    if (!_isTurnstileConfigured) {
      GameToast.show(
        context,
        title: 'Security setup needed',
        message: 'Add your Cloudflare Turnstile site key before continuing.',
        icon: Icons.key_rounded,
        accent: const Color(0xFFFFC36B),
      );
      return;
    }

    if (!_hasEmbeddedChallenge && !_usesExternalSecurityCheck) {
      GameToast.show(
        context,
        title: 'Security check unavailable',
        message: 'This platform cannot run the required security check.',
        icon: Icons.web_asset_off_rounded,
        accent: const Color(0xFFFFC36B),
      );
      return;
    }

    if (_captchaToken == null || _captchaToken!.isEmpty) {
      if (_usesExternalSecurityCheck) {
        final token = await _requestExternalSecurityToken();
        if (!mounted) {
          return;
        }
        if (token == null || token.isEmpty) {
          GameToast.show(
            context,
            title: 'Security check incomplete',
            message:
                'Please complete the browser security check and try again.',
            icon: Icons.hourglass_empty_rounded,
            accent: const Color(0xFFFFC36B),
          );
          return;
        }
        setState(() {
          _captchaToken = token;
        });
      } else if (!_captchaUnavailable) {
        // Still working on it -- ask them to wait. This is the only case
        // where waiting is the right advice, because a token really is on
        // its way.
        debugPrint('Turnstile: no token yet, asking the user to wait.');
        GameToast.show(
          context,
          title: 'Still checking',
          message: 'Please wait a moment and try again.',
          icon: Icons.hourglass_empty_rounded,
          accent: const Color(0xFFFFC36B),
        );
        return;
      } else {
        // The challenge is broken, so go without a token and let Supabase
        // decide.
        //
        // Refusing here was a permanent lockout: "Still checking" forever,
        // with no way past it and nothing on screen explaining why. And it
        // protected nothing — Supabase enforces captcha server-side, so a
        // request with no token is rejected *there* if the project requires
        // one. All the client block did was replace a clear server error with
        // an inaccurate client one.
        debugPrint(
          'Turnstile unavailable; continuing without a token and letting '
          'the server decide.',
        );
      }
    }

    setState(() {
      _submitting = true;
    });

    final controller = context.read<UserStatsController>();
    debugPrint(
      'Submitting auth request. isNewAccount=${!_isLogin}, '
      'captchaTokenPresent=${_captchaToken != null}, '
      'captchaTokenLength=${_captchaToken?.length ?? 0}',
    );

    final result = await controller.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _isLogin ? null : _usernameController.text.trim(),
      isNewAccount: !_isLogin,
      captchaToken: _captchaToken,
    );

    // Record the consent against the account it belongs to, as soon as there
    // is an account to record it against. Before sign-up there is no row to
    // write to, and after this point the checkbox state is gone -- so this is
    // the only moment the two exist together.
    if (result.success && !_isLogin) {
      // Straight after sign-up, for the same reason consent is recorded
      // here: before this point there is no row to write to, and after it
      // the form state is gone.
      final band = _ageBand;
      if (band != null) {
        await controller.updatePersonalDetails(ageBand: band);
      }
      await controller.recordPrivacyAcceptance();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    GameToast.show(
      context,
      title: result.success
          ? (_isLogin ? 'Welcome back' : 'Account ready')
          : 'Could not continue',
      message: result.message,
      icon: result.success
          ? Icons.verified_rounded
          : Icons.warning_amber_rounded,
      accent: result.success
          ? const Color(0xFF85EFAC)
          : const Color(0xFFFF8A80),
    );

    if (!result.success) {
      _resetTurnstile();
      return;
    }

    if (result.requiresEmailConfirmation) {
      setState(() {
        _pendingConfirmationEmail = _emailController.text.trim();
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      FadePageRoute<void>(builder: (_) => const DashboardShell()),
    );
  }

  bool get _canResendConfirmation {
    final until = _confirmationResendCooldownUntil;
    return !_resendingConfirmation &&
        (until == null || DateTime.now().isAfter(until));
  }

  Future<void> _resendConfirmationEmail() async {
    final email = _pendingConfirmationEmail;
    if (email == null || !_canResendConfirmation) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _resendingConfirmation = true);

    final error = await SupabaseService.instance.resendConfirmationEmail(
      email,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _resendingConfirmation = false;
      // A 60s client-side cooldown regardless of outcome -- Supabase's own
      // resend limit is roughly this order of magnitude per address, so
      // this mostly just stops the button from re-triggering the exact rate
      // limit it's meant to help avoid.
      _confirmationResendCooldownUntil = DateTime.now().add(
        const Duration(seconds: 60),
      );
    });

    GameToast.show(
      context,
      title: error == null ? 'Email sent' : 'Could not resend',
      message: error ?? 'Check $email for a new confirmation link.',
      icon: error == null
          ? Icons.mark_email_read_rounded
          : Icons.warning_amber_rounded,
      accent: error == null
          ? const Color(0xFF85EFAC)
          : const Color(0xFFFF8A80),
    );
  }

  Future<void> _submitPasswordReset() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      GameToast.show(
        context,
        title: 'Enter your email',
        message: 'Add your email address first so we can send a reset link.',
        icon: Icons.alternate_email_rounded,
        accent: const Color(0xFFFFC36B),
      );
      return;
    }

    // Supabase enforces captcha on the recover endpoint too, so a reset
    // request without a Turnstile token is rejected with captcha_failed.
    var token = _captchaToken;
    if (token == null || token.isEmpty) {
      if (_usesExternalSecurityCheck) {
        token = await _requestExternalSecurityToken();
      }
      if (!mounted) {
        return;
      }
      if ((token == null || token.isEmpty) && !_captchaUnavailable) {
        GameToast.show(
          context,
          title: 'Still checking',
          message:
              'Complete the security check, then tap the reset link again.',
          icon: Icons.hourglass_empty_rounded,
          accent: const Color(0xFFFFC36B),
        );
        return;
      }
    }

    final controller = context.read<UserStatsController>();
    final result = await controller.sendPasswordReset(
      email: email,
      captchaToken: token,
    );

    if (!mounted) {
      return;
    }

    // Turnstile tokens are single-use; get a fresh one for the next action.
    _resetTurnstile();

    GameToast.show(
      context,
      title: result.success ? 'Password Recovery' : 'Reset failed',
      message: result.message,
      icon: result.success ? Icons.key_rounded : Icons.warning_amber_rounded,
      accent: result.success
          ? const Color(0xFF85EFAC)
          : const Color(0xFFFF8A80),
    );
  }

  void _toggleMode(AuthMode nextMode) {
    if (_mode == nextMode) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _mode = nextMode;
      _submitting = false;
      _captchaToken = null;
      _pendingConfirmationEmail = null;
    });
    if (!_usesExternalSecurityCheck) {
      unawaited(_configureTurnstile());
    }
  }

  Future<void> _configureTurnstile() async {
    if (_isConfiguringTurnstile || _turnstileController != null) {
      return;
    }

    debugPrint(
      'Configuring Turnstile. configured=$_isTurnstileConfigured, '
      'supported=$_supportsEmbeddedWebView, platform=$defaultTargetPlatform',
    );

    if (!_isTurnstileConfigured || !_supportsEmbeddedWebView) {
      debugPrint('Turnstile setup skipped.');
      return;
    }

    _isConfiguringTurnstile = true;

    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('Turnstile page started: $url');
          },
          onPageFinished: (url) {
            debugPrint('Turnstile page finished: $url');
          },
          onWebResourceError: (error) {
            debugPrint('Turnstile WebView error: ${error.description}');
            // The challenge HTML is served from a local origin, so a resource
            // error here means the Cloudflare script could not be reached —
            // no network, a blocked domain, a captive portal. Whatever the
            // cause, no token is coming and the sign-in must not hang on one.
            if (mounted) setState(() => _captchaUnavailable = true);
          },
        ),
      )
      ..addJavaScriptChannel(
        'StatusChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted) return;
          debugPrint('Turnstile status: ${message.message}');
          setState(() => _captchaUnavailable = true);
        },
      )
      ..addJavaScriptChannel(
        'TokenChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted) {
            return;
          }
          final token = message.message.trim();
          debugPrint(
            token.isEmpty
                ? 'Turnstile token cleared or expired.'
                : 'Turnstile token received. length=${token.length}',
          );
          setState(() {
            _captchaToken = token.isEmpty ? null : token;
            if (token.isNotEmpty) _captchaUnavailable = false;
          });
        },
      );

    if (!mounted) {
      return;
    }
    setState(() {
      _turnstileController = controller;
      _captchaToken = null;
    });

    try {
      await _loadTurnstile(controller);
    } catch (error) {
      debugPrint('Turnstile load failed: $error');
      if (mounted) setState(() => _captchaUnavailable = true);
    } finally {
      _isConfiguringTurnstile = false;
    }
  }

  void _resetTurnstile() {
    setState(() {
      _captchaToken = null;
      _captchaUnavailable = false;
      // Windows re-arms by rebuilding with a new token; the WebView2 view
      // watches this in `didUpdateWidget`. Nothing happens on the other
      // platforms, where the counter is simply never read.
      _windowsChallengeToken++;
    });
    final controller = _turnstileController;
    if (controller != null) {
      unawaited(_loadTurnstile(controller));
    }
  }

  Future<void> _loadTurnstile(WebViewController controller) async {
    await controller.loadHtmlString(
      _turnstileHtml,
      baseUrl: turnstileChallengeHost,
    );
  }

  // token from the webview2 challenge. null = finished with no token
  // (expired or errored out), either way stop waiting
  // shared by every embedded-challenge platform (windows, web) -- nothing
  // about this handler is windows-specific, it just sets what came back
  void _onTurnstileToken(String? token) {
    if (!mounted) return;
    setState(() {
      _captchaToken = (token == null || token.isEmpty) ? null : token;
      if (_captchaToken != null) _captchaUnavailable = false;
    });
  }

  // webview2 failed to init, usually a missing runtime. rare but happens
  // on stripped/offline images. falls back to the browser popup
  void _onWindowsWebViewFailed() {
    if (!mounted || _windowsWebViewFailed) return;
    debugPrint('WebView2 unusable; reverting to the browser security check.');
    setState(() => _windowsWebViewFailed = true);
  }

  Future<String?> _requestExternalSecurityToken() async {
    setState(() {
      _submitting = true;
    });

    try {
      final uri = await _turnstileServer.startTokenRequest(
        html: _externalTurnstileHtml,
      );
      debugPrint('Opening Turnstile browser check at $uri');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return null;
      }

      return await _turnstileServer.waitForToken();
    } catch (error) {
      debugPrint('External Turnstile check failed: $error');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.villageMapBackground,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          // Matches the welcome screen's treatment rather than the old
          // 0.86/0.90 wash: a light flat dim so the village art still reads,
          // plus a soft green glow so it feels lit instead of murky.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0C2418).withValues(alpha: 0.55),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.3, -0.4),
                  radius: 0.95,
                  colors: [
                    const Color(0xFF78E08F).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 760;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                // Pop back to wherever we came from; if this is
                                // the first route (cold start straight into
                                // login/signup), fall back to the welcome page
                                // so the back arrow is never a dead end.
                                onPressed: () {
                                  final navigator = Navigator.of(context);
                                  if (navigator.canPop()) {
                                    navigator.pop();
                                  } else {
                                    navigator.pushReplacementNamed('/welcome');
                                  }
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _heroController,
                                curve: Curves.easeOut,
                              ),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _heroController,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: _AuthHero(isCompact: isCompact),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ModeSwitch(mode: _mode, onChanged: _toggleMode),
                            const SizedBox(height: 22),
                            Text(
                              _isLogin
                                  ? 'Log back into your kingdom'
                                  : 'Build your financial hero profile',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.quicksand(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_pendingConfirmationEmail != null) ...[
                              _PendingConfirmationCard(
                                email: _pendingConfirmationEmail!,
                                resending: _resendingConfirmation,
                                canResend: _canResendConfirmation,
                                onResend: _resendConfirmationEmail,
                              ),
                              const SizedBox(height: 20),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Column(
                                key: ValueKey<AuthMode>(_mode),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!_isLogin) ...[
                                    _AuthField(
                                      controller: _usernameController,
                                      label: 'Wizard Name',
                                      hintText:
                                          'How should Budget Buddy greet you?',
                                      keyboardType: TextInputType.name,
                                      prefixIcon: Icons.person_rounded,
                                      validator: (value) {
                                        if (_isLogin) {
                                          return null;
                                        }
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return 'Please choose a display name.';
                                        }
                                        if (trimmed.length < 3) {
                                          return 'Use at least 3 characters.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _AgeBandField(
                                      selected: _ageBand,
                                      onChanged: (band) =>
                                          setState(() => _ageBand = band),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _AuthField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hintText: 'wizard@budgetbuddy.app',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.alternate_email_rounded,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Enter your email.';
                                      }
                                      if (!RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(email)) {
                                        return 'Use a valid email address.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _AuthField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: _isLogin
                                        ? 'Enter your password'
                                        : 'Create a strong password',
                                    keyboardType: TextInputType.visiblePassword,
                                    prefixIcon: Icons.lock_rounded,
                                    obscureText: _obscurePassword,
                                    suffix: _PasswordToggleButton(
                                      isObscured: _obscurePassword,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      final password = value ?? '';
                                      if (password.isEmpty) {
                                        return 'Enter your password.';
                                      }
                                      if (!_isLogin && password.length < 8) {
                                        return 'Use at least 8 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (!_isLogin) ...[
                                    const SizedBox(height: 16),
                                    _AuthField(
                                      controller: _confirmController,
                                      label: 'Confirm Password',
                                      hintText: 'Repeat your password',
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      prefixIcon: Icons.verified_user_rounded,
                                      obscureText: _obscureConfirmPassword,
                                      suffix: _PasswordToggleButton(
                                        isObscured: _obscureConfirmPassword,
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (_isLogin) {
                                          return null;
                                        }
                                        if ((value ?? '').isEmpty) {
                                          return 'Confirm your password.';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _TermsCard(
                                      onOpenPolicy: _openPrivacyPolicy,
                                      accepted: _acceptedTerms,
                                      onChanged: (value) {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _acceptedTerms = value;
                                        });
                                      },
                                    ),
                                  ],
                                  if (kIsWeb && _isTurnstileConfigured)
                                    CloudFlareTurnstile(
                                      // Stable identity across rebuilds.
                                      // This widget sits after the
                                      // conditionally-shown confirm-password
                                      // field and terms card, so switching
                                      // Log In <-> Sign Up shifts its index
                                      // in the children list. Without a key,
                                      // Flutter can't tell it's the same
                                      // widget that moved rather than a
                                      // different one now sitting here, so it
                                      // tore the whole challenge (iframe and
                                      // all) down and rebuilt it from scratch
                                      // on every toggle -- which is why the
                                      // widget appeared to just vanish.
                                      key: const ValueKey('web_turnstile'),
                                      // real browser, real origin -- pass it
                                      // straight through rather than
                                      // hardcoding one like the windows html
                                      // does, so this works on localhost, a
                                      // preview URL, or the real domain
                                      // without editing code each time.
                                      baseUrl: Uri.base.origin,
                                      siteKey: turnstileSiteKey,
                                      onTokenRecived: _onTurnstileToken,
                                      onTokenExpired: () =>
                                          _onTurnstileToken(null),
                                      onError: (error) {
                                        // Cloudflare's own error code (e.g. a
                                        // domain not on the widget's allowed
                                        // list) -- logged rather than shown
                                        // raw to the player, but visible in
                                        // the browser console for whoever's
                                        // debugging a broken web deploy.
                                        debugPrint(
                                          'Web Turnstile error: $error',
                                        );
                                        if (mounted) {
                                          setState(
                                            () => _captchaUnavailable = true,
                                          );
                                        }
                                      },
                                    )
                                  else if (_usesWindowsWebView &&
                                      _isTurnstileConfigured)
                                    WindowsTurnstileView(
                                      // Same positional-shift risk as the web
                                      // widget above -- keep its state alive
                                      // across a Log In <-> Sign Up toggle.
                                      key: const ValueKey('windows_turnstile'),
                                      server: _turnstileServer,
                                      html: _embeddedWindowsTurnstileHtml,
                                      reloadToken: _windowsChallengeToken,
                                      onToken: _onTurnstileToken,
                                      onUnavailable: () {
                                        if (mounted) {
                                          setState(
                                            () => _captchaUnavailable = true,
                                          );
                                        }
                                      },
                                      onNeedsBrowserFallback:
                                          _onWindowsWebViewFailed,
                                    )
                                  else
                                    _HiddenTurnstileView(
                                      controller: _turnstileController,
                                      isConfigured: _isTurnstileConfigured,
                                      isSupported: _supportsEmbeddedWebView,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            CustomButton(
                              label: _turnstileStillLoading
                                  ? 'Verifying...'
                                  : _isLogin
                                  ? 'Enter Budget Buddy'
                                  : 'Create Account',
                              isLoading: _submitting || _turnstileStillLoading,
                              onPressed: _turnstileStillLoading
                                  ? null
                                  : _submit,
                              prefixIcon: Icon(
                                _isLogin
                                    ? Icons.login_rounded
                                    : Icons.auto_awesome_rounded,
                                color: const Color(0xFF1A4D3D),
                                size: 18,
                              ),
                              style: const CustomButtonStyle.primary(),
                            ),
                            const SizedBox(height: 12),
                            if (_isLogin)
                              Opacity(
                                // Same reasoning as the main button above:
                                // this used to stay tappable through the
                                // whole Turnstile load, so a tap while it was
                                // still loading produced the exact "Still
                                // checking, tap again" toast the main button
                                // was fixed to make unreachable -- just on
                                // this link instead. Disabling it for the
                                // same window closes that gap.
                                opacity: _turnstileStillLoading ? 0.5 : 1,
                                child: TextButton(
                                  onPressed: _turnstileStillLoading
                                      ? null
                                      : _submitPasswordReset,
                                  child: const Text(
                                    'Forgot your password?',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(18, isCompact ? 18 : 24, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Hero(
                tag: 'budget-buddy-logo',
                child: Container(
                  width: isCompact ? 96 : 112,
                  height: isCompact ? 96 : 112,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF85EFAC).withValues(alpha: 0.96),
                        const Color(0xFF45D388).withValues(alpha: 0.92),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF85EFAC).withValues(alpha: 0.26),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  // The 3D turtle, matching the welcome screen — the pixel
                  // logo read as a different brand between the two screens.
                  child: Image.asset(
                    AppAssets.coolTurtle,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 42,
                      color: Color(0xFF103225),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'BUDGET BUDDY',
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A polished, game-first finance coach that feels great on mobile.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown after sign-up succeeds but needs email confirmation. Replaces what
/// used to be a single toast and a dead end -- the form stays filled in
/// behind this, and there is finally a way to ask for a second email.
class _PendingConfirmationCard extends StatelessWidget {
  const _PendingConfirmationCard({
    required this.email,
    required this.resending,
    required this.canResend,
    required this.onResend,
  });

  final String email;
  final bool resending;
  final bool canResend;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF85EFAC);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Check your email',
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a confirmation link to $email. Open it to finish '
            'creating your account.',
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: canResend ? onResend : null,
              style: TextButton.styleFrom(foregroundColor: accent),
              child: Text(
                resending
                    ? 'Sending...'
                    : canResend
                    ? 'Resend confirmation email'
                    : 'Sent -- you can resend again shortly',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  decoration: canResend
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSwitchChip(
              label: 'Log In',
              active: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeSwitchChip(
              label: 'Sign Up',
              active: mode == AuthMode.signUp,
              onTap: () => onChanged(AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitchChip extends StatelessWidget {
  const _ModeSwitchChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF85EFAC), Color(0xFF64DDA1)],
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              color: active ? const Color(0xFF103225) : Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.quicksand(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        labelStyle: GoogleFonts.quicksand(
          color: Colors.white.withValues(alpha: 0.84),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.quicksand(
          color: const Color(0xFF85EFAC),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: GoogleFonts.quicksand(
          color: Colors.white.withValues(alpha: 0.42),
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF85EFAC)),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF85EFAC), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.8),
        ),
        errorStyle: GoogleFonts.quicksand(
          color: const Color(0xFFFFB2AB),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PasswordToggleButton extends StatelessWidget {
  const _PasswordToggleButton({
    required this.isObscured,
    required this.onPressed,
  });

  final bool isObscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      splashRadius: 22,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.82, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          key: ValueKey<bool>(isObscured),
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({
    required this.accepted,
    required this.onChanged,
    required this.onOpenPolicy,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPolicy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            activeColor: const Color(0xFF85EFAC),
            checkColor: const Color(0xFF103225),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
            onChanged: (value) => onChanged(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              // A link, not a mention. The old copy said "I agree to Budget
              // Buddy storing my learning progress" with nothing to read and
              // nothing recorded -- which is not consent, it is a checkbox.
              // Play wants the policy reachable from the point of agreement,
              // and somebody agreeing to a document they cannot open has not
              // agreed to anything.
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(
                      text: 'I have read and agree to the Budget Buddy ',
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFF85EFAC),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF85EFAC),
                        fontWeight: FontWeight.w800,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onOpenPolicy,
                    ),
                    const TextSpan(
                      text:
                          ' ($kPrivacyPolicyDate). It explains what is '
                          'stored, what is never collected, and how to delete '
                          'your account.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenTurnstileView extends StatelessWidget {
  const _HiddenTurnstileView({
    required this.controller,
    required this.isConfigured,
    required this.isSupported,
  });

  final WebViewController? controller;
  final bool isConfigured;
  final bool isSupported;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !isConfigured || !isSupported) {
      return const SizedBox.shrink();
    }

    // **On screen, and touchable.**
    //
    // This used to be wrapped in an `IgnorePointer` and shoved ten thousand
    // pixels off the top-left corner, which was fine while the widget was
    // configured `size: 'invisible'` and completed itself. It stopped being
    // fine the moment that parameter became invalid: Cloudflare now renders a
    // real widget, and a real widget that is off-screen and cannot be tapped
    // is a challenge nobody can ever pass.
    //
    // Managed widgets still usually resolve on their own in a second or two,
    // so most people will see a box that ticks itself. The ones who get an
    // interactive challenge can now actually complete it.
    return SizedBox(
      height: 76,
      width: double.infinity,
      child: WebViewWidget(controller: controller!),
    );
  }
}


// age question, asked once at signup. chips instead of a dob picker,
// we only need the band not an exact birthday, and chips are easier
// to tap for a little kid's parent than scrolling a dropdown
class _AgeBandField extends StatelessWidget {
  const _AgeBandField({required this.selected, required this.onChanged});

  final AgeBand? selected;
  final ValueChanged<AgeBand> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How old are you?',
          style: GoogleFonts.pixelifySans(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // Says what it is for. A personal question with no stated purpose
          // reads as data collection; the same question with a reason reads
          // as setup.
          'It picks the questions you get — nothing else, and nobody sees it.',
          style: AppTheme.numeric(
            color: AppTheme.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final band in AgeBand.values)
              _AgeChip(
                band: band,
                isSelected: band == selected,
                onTap: () => onChanged(band),
              ),
          ],
        ),
      ],
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({
    required this.band,
    required this.isSelected,
    required this.onTap,
  });

  final AgeBand band;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? AppTheme.greenPrimary
        : Colors.white.withValues(alpha: 0.22);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isSelected ? 0.18 : 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent, width: isSelected ? 1.8 : 1),
          ),
          child: Text(
            band.label,
            style: AppTheme.numeric(
              color: isSelected ? AppTheme.greenPrimary : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
