import 'package:flutter/material.dart';

import 'budget_ledger.dart';

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
    return BudgetLedger(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
