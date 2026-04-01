import 'package:flutter/material.dart';

import 'main_game_page.dart';

class MainGameScreen extends StatelessWidget {
  const MainGameScreen({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return MainGamePage(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
