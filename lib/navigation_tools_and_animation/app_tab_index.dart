/// Bottom-tab / top-icon positions.
///
/// The bar was seven wide for one round and got crowded fast — Learn and
/// Profile moved to a small top strip instead (see `_TopIconBar` in
/// `main_navigation.dart`), leaving the bottom bar at five: **Life, Arcade,
/// Home, Daily, Style**, with Home in the middle (index 2 of 5). The order
/// here *is* the on-screen order for the bottom five, and it must stay in
/// lockstep with `MainNavigation`'s `IndexedStack` children and
/// `PopNavBar.appTabs`. `PopNavBar` renders the middle slot (index
/// `length ~/ 2`) as a circular badge instead of the usual rounded pill, so
/// Home reads as the anchor of the bar — see `pop_navbar.dart`.
///
/// `academy` and `profile` still get real slots in the `IndexedStack` (so
/// switching to them works exactly like any other tab) — they are just not
/// listed in `PopNavBar.appTabs`, so the bottom bar never highlights either
/// of them; the top strip highlights instead.
abstract final class AppTabIndex {
  static const int adventure = 0;
  static const int minigames = 1;
  static const int dashboard = 2;
  static const int daily = 3;
  static const int customize = 4;
  static const int academy = 5;
  static const int profile = 6;

  static const int count = 7;
}
