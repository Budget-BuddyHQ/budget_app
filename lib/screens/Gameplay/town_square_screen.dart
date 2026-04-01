import 'package:flutter/material.dart';

import 'town_square.dart';

class TownSquareScreen extends StatelessWidget {
  const TownSquareScreen({
    super.key,
    this.activeTabIndex = 2,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return TownSquare(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
