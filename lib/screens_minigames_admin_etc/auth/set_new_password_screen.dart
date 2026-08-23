import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_assets.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../themes_colors/app_theme.dart';
import '../../widgets_custom_lotties/custom_button.dart';
import '../../widgets_custom_lotties/game_toast.dart';

/// Where the password-reset flow finally lands.
///
/// Tapping the emailed recovery link signs the player in on a short-lived
/// recovery session — this screen is what turns that session into an actual
/// new password. Before it existed the flow dead-ended: the email sent, the
/// link signed you in, and nothing ever asked for a new password.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text;
    final confirm = _confirm.text;

    if (password.length < 6) {
      _toast('Too short', 'Use at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _toast('They do not match', 'Both fields need the same password.');
      return;
    }

    setState(() => _saving = true);
    final result = await context.read<UserStatsController>().updatePassword(
      password,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    GameToast.show(
      context,
      title: result.success ? 'Password updated' : 'Could not update',
      message: result.message,
      icon: result.success
          ? Icons.lock_reset_rounded
          : Icons.error_outline_rounded,
      accent: result.success
          ? const Color(0xFF85EFAC)
          : const Color(0xFFFF8A80),
    );
    // On success the recovery session becomes a normal one, so the auth gate
    // in main.dart drops through to the dashboard on its own — nothing to
    // pop or push here.
  }

  void _toast(String title, String message) {
    GameToast.show(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      accent: const Color(0xFFFFC36B),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.villageMapBackground,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF071711).withValues(alpha: 0.82),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF85EFAC),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Set a new password',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.baloo2(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick something you have not used here before. '
                        'You are already signed in from the email link.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PasswordField(
                        controller: _password,
                        label: 'New password',
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: _confirm,
                        label: 'Confirm new password',
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 22),
                      CustomButton(
                        label: 'Save password',
                        isLoading: _saving,
                        onPressed: _saving ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF85EFAC),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
