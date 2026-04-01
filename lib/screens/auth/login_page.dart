import 'package:flutter/material.dart';

import 'auth_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(mode: AuthMode.login);
  }
}
