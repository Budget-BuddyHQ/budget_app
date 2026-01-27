// lib/screens/login_page.dart
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login pressed (authentication not implemented yet).'),
      ),
    );
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot password tapped (not implemented yet).'),
      ),
    );
  }

  void _handleAppleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple sign-in tapped (not implemented yet).'),
      ),
    );
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google sign-in tapped (not implemented yet).'),
      ),
    );
  }

  void _handleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign up tapped (not implemented yet).'),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color.fromARGB(255, 96, 170, 36);

        return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Log In'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        ),

      // Gradient background + centered "card" to match the rest of the app
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

                // Card container for the form
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

                      // Title
                      const Text(
                        'Log in to Budget Buddy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Enter account details below',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email address field
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

                      // Password field + show/hide toggle
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Forgot password link (right aligned)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Primary Login button (green)
                      ElevatedButton(
                        onPressed: _handleLogin,
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
                          'Log in',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // "OR" divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Continue with Apple
                      OutlinedButton.icon(
                        onPressed: _handleAppleSignIn,
                        icon: const Icon(Icons.apple),
                        label: const Text('Continue with Apple'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Continue with Google
                      OutlinedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // New user + Sign up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New to Budget Buddy? ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _handleSignUp,
                            child: const Text('Sign up'),
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