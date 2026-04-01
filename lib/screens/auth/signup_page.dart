import 'package:flutter/material.dart';

import 'auth_screen.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(mode: AuthMode.signUp);
  }
}
