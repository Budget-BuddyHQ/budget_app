/// Bottom-tab positions.
///
/// **Home sits in the middle on purpose** (index 2 of 5) — it is the tab
/// people return to most, and the centre is the easiest slot to hit
/// one-handed. The order here *is* the on-screen order, and it must stay in
/// lockstep with `MainNavigation`'s `IndexedStack` children and
/// `PopNavBar.appTabs`.
///
/// Arcade and Style are deliberately **not** tabs. Five tabs leaves room for
/// readable labels; those two are reached from Home's objective card
/// instead, which is where players were already finding them.
abstract final class AppTabIndex {
  static const int adventure = 0;
  static const int academy = 1;
  static const int dashboard = 2;
  static const int daily = 3;
  static const int profile = 4;

  static const int count = 5;
}
