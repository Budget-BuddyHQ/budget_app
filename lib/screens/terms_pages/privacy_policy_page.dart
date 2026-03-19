import 'dart:ui';
import 'package:flutter/material.dart';
import '../goals_setup_page.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPage();
}

class _PrivacyPolicyPage extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AnimationController _animController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  
  late final Animation<double> _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handlePrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy tapped (not implemented yet).'),
      ),
    );
  }

  void _handleTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms & Conditions tapped (not implemented yet).'),
      ),
    );
  }

  void _handleGoToLogin() {
    Navigator.pop(context); // assumes you came here from LoginPage
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer: Deep Forest Green
          Container(color: const Color(0xFF2E7D32)),
          
          // Background Animation Layer (Subtle moving circles or "Mana" particles)
          _buildBackgroundParticles(),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield, color: Colors.yellowAccent, size: 60),
                          const SizedBox(height: 10),
                          const Text(
                            "CREATE HERO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Text Fields
                          _buildGameField(_emailController, "Email Address", Icons.email),
                          const SizedBox(height: 15),
                          _buildGameField(_passwordController, "Password", Icons.lock, obscure: _obscurePassword),
                          
                          const SizedBox(height: 15),

                          // Checkbox for Terms
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                side: const BorderSide(color: Colors.white),
                                checkColor: Colors.black,
                                activeColor: Colors.yellowAccent,
                                onChanged: (val) => setState(() => _agreeToTerms = val!),
                              ),
                              const Expanded(
                                child: Text(
                                  "I accept the Kingdom's Terms",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Start Adventure Button
                          ElevatedButton(
                            onPressed: _agreeToTerms ? () => Navigator.pushNamed(context, '/town') : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellowAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("START ADVENTURE", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.yellowAccent),
        ),
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticlePainter(),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 150, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
