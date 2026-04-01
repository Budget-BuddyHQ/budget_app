import 'package:flutter/material.dart';

import 'home_screen.dart';

class MainGamePage extends StatelessWidget {
  const MainGamePage({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
