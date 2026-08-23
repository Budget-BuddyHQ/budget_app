import 'package:budget_app/navigation_tools_and_animation/app_tab_index.dart';
import 'package:budget_app/navigation_tools_and_animation/main_navigation.dart';
import 'package:flutter/material.dart';

class DashboardShell extends StatelessWidget {
  // Home, not tab 0 (Adventure) — a bare DashboardShell() is what every
  // fresh sign-in and the '/game' route land on, and that should be Home,
  // not straight into the Bonfire game world.
  const DashboardShell({super.key, this.initialIndex = AppTabIndex.dashboard});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return MainNavigation(initialIndex: initialIndex);
  }
}
