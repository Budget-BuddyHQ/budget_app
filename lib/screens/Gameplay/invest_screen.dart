import 'package:flutter/material.dart';

import 'invest_tab.dart';

class InvestScreen extends StatelessWidget {
  const InvestScreen({
    super.key,
    this.activeTabIndex = 2,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return InvestTab(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
