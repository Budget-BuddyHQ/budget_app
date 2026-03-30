import 'package:flutter/material.dart';

import '../profile/user_profile_screen.dart';
import 'budget_screen.dart';
import 'challenges_screen.dart';
import 'dashboard_screen.dart';
import 'invest_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        DashboardScreen(
          activeTabIndex: 0,
          onNavSelected: _selectTab,
        ),
        BudgetScreen(
          activeTabIndex: 1,
          onNavSelected: _selectTab,
        ),
        InvestScreen(
          activeTabIndex: 2,
          onNavSelected: _selectTab,
        ),
        ChallengesScreen(
          activeTabIndex: 3,
          onNavSelected: _selectTab,
        ),
        UserProfileScreen(
          activeTabIndex: 4,
          onNavSelected: _selectTab,
        ),
      ],
    );
  }
}
