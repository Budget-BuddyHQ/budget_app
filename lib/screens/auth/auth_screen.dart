import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../navigation/fade_page_route.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';
import '../Gameplay/dashboard_shell.dart';

enum AuthMode { login, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.mode,
  });

  final AuthMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  late AuthMode _mode;
  late final AnimationController _heroController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;
  bool _acceptedTerms = false;

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameController.dispose();
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

    setState(() {
      _submitting = true;
    });

    final controller = context.read<UserStatsController>();
    final result = await controller.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _isLogin ? null : _usernameController.text.trim(),
      isNewAccount: !_isLogin,
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
      icon: result.success ? Icons.verified_rounded : Icons.warning_amber_rounded,
      accent: result.success
          ? const Color(0xFF85EFAC)
          : const Color(0xFFFF8A80),
    );

    if (!result.success) {
      return;
    }

    Navigator.of(context).pushReplacement(
      FadePageRoute<void>(
        builder: (_) => const DashboardShell(),
      ),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    const deepForest = Color(0xFF0B241C);
    const emerald = Color(0xFF173C2F);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, emerald, Color(0xFF0A1C16)],
          ),
        ),
        child: SafeArea(
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
                              onPressed: () => Navigator.of(context).maybePop(),
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
                              position: Tween<Offset>(
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
                          _ModeSwitch(
                            mode: _mode,
                            onChanged: _toggleMode,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _isLogin
                                ? 'Log back into your kingdom'
                                : 'Build your financial hero profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                                    hintText: 'How should Budget Buddy greet you?',
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
                                    keyboardType: TextInputType.visiblePassword,
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          CustomButton(
                            label: _isLogin ? 'Enter Budget Buddy' : 'Create Account',
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
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                GameToast.show(
                                  context,
                                  title: 'Password Recovery',
                                  message:
                                      'Password reset can be wired next through Supabase Auth.',
                                  icon: Icons.key_rounded,
                                  accent: const Color(0xFF85EFAC),
                                );
                              },
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
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.isCompact,
  });

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
                    'assets/images/logo.png',
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
              const Text(
                'BUDGET BUDDY',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                style: TextStyle(
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
  const _ModeSwitch({
    required this.mode,
    required this.onChanged,
  });

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
            style: TextStyle(
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
      style: const TextStyle(
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
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.84),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF85EFAC),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
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
        errorStyle: const TextStyle(
          color: Color(0xFFFFB2AB),
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
  });

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
                style: TextStyle(
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

