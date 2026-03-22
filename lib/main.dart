import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
