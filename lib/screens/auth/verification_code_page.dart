// lib/screens/verification_code_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class VerificationCodePage extends StatefulWidget {
  const VerificationCodePage({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  late AnimationController _animController;

  bool _showTipBox = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail; // prefill from Forgot Password
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  void _handleVerify() {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and verification code.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verify pressed (not implemented yet).')),
    );
  }

  void _handleSendNewCode() {
    setState(() {
      _showTipBox = true; // show the tip box only after clicking
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New code requested (not implemented yet).'),
      ),
    );
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const deepForest = Color(0xFF1B3329);
    const limeAccent = Color(0xFF76FF03);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    const SizedBox(height: 20),
                    _buildAnimatedItem(
                      0,
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildAnimatedItem(
                      1,
                      const Text(
                        'We emailed you a code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildAnimatedItem(
                      2,
                      Text(
                        'Enter the verification code sent to',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Editable email
                    _buildAnimatedItem(
                      3,
                      _buildGlassTextField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.email,
                        isReadOnly: true, // Assuming we just want to show it
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Verification code input
                    _buildAnimatedItem(
                      4,
                      _buildGlassTextField(
                        controller: _codeController,
                        label: 'Enter 6-digit code',
                        icon: Icons.lock_clock,
                        isNumber: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      5,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Didn't get the code? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleSendNewCode,
                              child: const Text(
                                'Send a new code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: limeAccent,
                                  decoration: TextDecoration.underline,
                                  decorationColor: limeAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showTipBox) ...[
                      const SizedBox(height: 14),
                      _buildAnimatedItem(
                        6,
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: limeAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            "Sent! Tip: If you still can't see the email, check your spam folder or contact budgetbuddy@gmail.com.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Verify button
                    _buildAnimatedItem(
                      7,
                      ElevatedButton(
                        onPressed: _handleVerify,
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
                          'Verify',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Back button
                    _buildAnimatedItem(
                      8,
                      TextButton(
                        onPressed: _handleBack,
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
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
    bool isNumber = false,
    bool isReadOnly = false,
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
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            readOnly: isReadOnly,
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
