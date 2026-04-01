import 'dart:ui';
import 'package:flutter/material.dart';

import '../../widgets/game_toast.dart';
import 'verification_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (_emailController.text.isEmpty) {
      GameToast.show(
        context,
        title: 'Enter your email',
        message: 'Please enter your email address.',
        icon: Icons.email_outlined,
        accent: const Color(0xFFFFC36B),
      );
      return;
    }

    // Navigate to Verification Code Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VerificationCodePage(initialEmail: _emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const deepForest = Color(0xFF1B3329);
    const limeAccent = Color(0xFF76FF03);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, Color(0xFF2E4A3D), Color(0xFF0F2018)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Icon
                    _buildAnimatedItem(
                      0,
                      const Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Title
                    _buildAnimatedItem(
                      1,
                      const Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Description
                    _buildAnimatedItem(
                      2,
                      Text(
                        "Don't worry! It happens. Please enter the address associated with your account.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 4. Email Input
                    _buildAnimatedItem(
                      3,
                      _buildGlassTextField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 5. Send Button
                    _buildAnimatedItem(
                      4,
                      ElevatedButton(
                        onPressed: _handleSendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeAccent,
                          foregroundColor: deepForest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: limeAccent.withValues(alpha: 0.5),
                        ),
                        child: const Text(
                          'Send Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animController,
              curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
