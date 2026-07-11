import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/turnstile_config.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../navigation_tools_and_animation/fade_page_route.dart';
import '../../constants/app_assets.dart';
import '../../services_backend_and_other_services/turnstile_challenge_server.dart';
import '../../widgets_custom_lotties/custom_button.dart';
import '../../widgets_custom_lotties/game_toast.dart';
import '../Gameplay/dashboard/dashboard_shell.dart';

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
  final TurnstileChallengeServer _turnstileServer = TurnstileChallengeServer();

  late AuthMode _mode;
  late final AnimationController _heroController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;
  bool _acceptedTerms = false;
  bool _isConfiguringTurnstile = false;
  String? _captchaToken;
  WebViewController? _turnstileController;

  bool get _isLogin => _mode == AuthMode.login;
  bool get _isTurnstileConfigured => turnstileSiteKey != 'YOUR_SITE_KEY';
  bool get _supportsEmbeddedWebView {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool get _usesExternalSecurityCheck =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

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
      widgetId = turnstile.render('#turnstile-widget', {
        sitekey: '$turnstileSiteKey',
        size: 'invisible',
        theme: 'dark',
        callback: onSuccess,
        'expired-callback': onExpired,
        'error-callback': onExpired
      });
      turnstile.execute(widgetId);
    }

    function onSuccess(token) {
      TokenChannel.postMessage(token);
    }

    function onExpired() {
      TokenChannel.postMessage('');
    }
  </script>
</body>
</html>
''';

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
    if (!_usesExternalSecurityCheck) {
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
        message: 'Please accept the terms to create your account.',
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

    if (!_supportsEmbeddedWebView && !_usesExternalSecurityCheck) {
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
      } else {
        debugPrint('Turnstile submit blocked: captcha token is null.');
        GameToast.show(
          context,
          title: 'Still checking',
          message: 'Please wait a moment and try again.',
          icon: Icons.hourglass_empty_rounded,
          accent: const Color(0xFFFFC36B),
        );
        return;
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
      return;
    }

    Navigator.of(context).pushReplacement(
      FadePageRoute<void>(builder: (_) => const DashboardShell()),
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

    final controller = context.read<UserStatsController>();
    final result = await controller.sendPasswordReset(email: email);

    if (!mounted) {
      return;
    }

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
          },
        ),
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
    } finally {
      _isConfiguringTurnstile = false;
    }
  }

  void _resetTurnstile() {
    setState(() {
      _captchaToken = null;
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
    const deepForest = Color(0xFF0B241C);
    const emerald = Color(0xFF173C2F);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.villageMapBackground,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  deepForest.withValues(alpha: 0.86),
                  emerald.withValues(alpha: 0.80),
                  const Color(0xFF0A1C16).withValues(alpha: 0.90),
                ],
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
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
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
                                      accepted: _acceptedTerms,
                                      onChanged: (value) {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _acceptedTerms = value;
                                        });
                                      },
                                    ),
                                  ],
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
                              label: _isLogin
                                  ? 'Enter Budget Buddy'
                                  : 'Create Account',
                              isLoading: _submitting,
                              onPressed: _submit,
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
                              TextButton(
                                onPressed: _submitPasswordReset,
                                child: const Text(
                                  'Forgot your password?',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
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
                  child: Image.asset(
                    AppAssets.logo,
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
                style: GoogleFonts.baloo2(
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
  const _TermsCard({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool> onChanged;

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
              child: Text(
                'I agree to Budget Buddy storing my learning progress and cloud syncing my rewards.',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  height: 1.45,
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

    return IgnorePointer(
      child: SizedBox(
        height: 76,
        width: double.infinity,
        child: Transform.translate(
          offset: const Offset(-10000, -10000),
          child: WebViewWidget(controller: controller!),
        ),
      ),
    );
  }
}
