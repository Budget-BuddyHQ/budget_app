import 'package:flutter/material.dart';

import '../screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart'
    as leaderboard_impl;

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const leaderboard_impl.LeaderboardScreen();
  }
}
