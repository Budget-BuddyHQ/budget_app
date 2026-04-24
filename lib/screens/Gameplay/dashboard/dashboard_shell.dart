import 'package:flutter/material.dart';

import 'main_navigation.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return MainNavigation(initialIndex: initialIndex);
  }
}
