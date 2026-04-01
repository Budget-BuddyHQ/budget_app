import 'package:flutter/material.dart';

import 'dashboard_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(initialIndex: activeTabIndex);
  }
}
