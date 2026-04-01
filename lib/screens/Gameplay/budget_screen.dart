import 'package:flutter/material.dart';

import 'budget_page.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({
    super.key,
    this.activeTabIndex = 1,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return BudgetPage(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
