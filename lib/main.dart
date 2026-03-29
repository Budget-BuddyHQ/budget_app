import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/Gameplay/bill_dodger_game.dart';
import 'screens/Gameplay/game_hub_screen.dart';
import 'screens/Gameplay/town_square_screen.dart';

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
        '/game': (context) => const TownSquareScreen(),
        '/dashboard': (context) => const MainGameScreen(),
        '/town': (context) => const TownSquareScreen(),
        '/hub': (context) => const GameHubScreen(),
        '/bill-dodger': (context) => const BillDodgerGameScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}
