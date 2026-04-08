import 'package:flutter/material.dart';

import 'game_hub_screen.dart';

class TownSquare extends StatelessWidget {
  const TownSquare({
    super.key,
    this.activeTabIndex = 1,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return GameHubScreen(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
