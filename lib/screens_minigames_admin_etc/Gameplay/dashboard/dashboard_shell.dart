import 'package:budget_app/navigation_tools_and_animation/main_navigation.dart';
import 'package:flutter/material.dart';


class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return MainNavigation(initialIndex: initialIndex);
  }
}
