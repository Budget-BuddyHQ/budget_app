// lib/screens/signup_page.dart
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  void _handleSignUp() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign up pressed (not implemented yet).')),
    );
  }

  void _handlePrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Policy tapped (not implemented yet).')),
    );
  }

  void _handleTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms & Conditions tapped (not implemented yet).')),
    );
  }

  void _handleGoToLogin() {
    Navigator.pop(context); // assumes you came here from LoginPage
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color.fromARGB(255, 96, 170, 36);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 25, 210, 155),
              Color.fromARGB(255, 96, 170, 36),
              Color.fromARGB(255, 161, 236, 64),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      const Text(
                        'Sign up to Budget Buddy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Create your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Retype password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Agree to terms + privacy policy
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            activeColor: brandGreen,
                            onChanged: (v) {
                              setState(() => _agreeToTerms = v ?? false);
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('I agree to the '),
                                  InkWell(
                                    onTap: _handleTerms,
                                    child: const Text(
                                      'Terms & Conditions',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Text(' and '),
                                  InkWell(
                                    onTap: _handlePrivacyPolicy,
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Text('.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Primary button (dark, to contrast with green theme)
                      ElevatedButton(
                        onPressed: _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Already have account? Log in
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: _handleGoToLogin,
                            child: const Text('Log in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
