import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../profile/profile_screen.dart';
import 'budget_ledger.dart';
import 'challenges_screen.dart';
import 'invest_tab.dart';
import 'main_game_page.dart';

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
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        MainGamePage(
          activeTabIndex: 0,
          onNavSelected: _selectTab,
        ),
        BudgetLedger(
          activeTabIndex: 1,
          onNavSelected: _selectTab,
        ),
        InvestTab(
          activeTabIndex: 2,
          onNavSelected: _selectTab,
        ),
        ChallengesScreen(
          activeTabIndex: 3,
          onNavSelected: _selectTab,
        ),
        ProfileScreen(
          activeTabIndex: 4,
          onNavSelected: _selectTab,
        ),
      ],
    );
  }
}
