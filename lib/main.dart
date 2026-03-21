import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/login_page.dart';
import 'screens/main_game_screen.dart';
import 'screens/signup_page.dart';
import 'screens/welcome_screen.dart';

void main() async {


}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Buddy',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/game': (context) => const MainGameScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}
