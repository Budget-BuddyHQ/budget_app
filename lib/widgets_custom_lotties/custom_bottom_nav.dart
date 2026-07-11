import 'package:flutter/material.dart';

import '../ui/widgets/pop_navbar.dart';

/// Thin adapter over [PopNavBar] so call sites don't need to reference the
/// shared tab list directly.
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.activeIndex,
    this.onSelected,
  });

  final int activeIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopNavBar(
      items: PopNavBar.appTabs,
      activeIndex: activeIndex,
      onSelected: onSelected,
    );
  }
}
