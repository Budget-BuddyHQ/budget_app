
import '../ui/widgets/pop_navbar.dart';

/// Thin adapter over [PopNavBar] so call sites don't need to reference the
/// shared tab list directly.
    this.onSelected,
  final int activeIndex;
  final ValueChanged<int>? onSelected;

    return PopNavBar(
      items: PopNavBar.appTabs,
      activeIndex: activeIndex,
      onSelected: onSelected,
