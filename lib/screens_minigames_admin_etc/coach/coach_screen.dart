import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation_tools_and_animation/app_tab_index.dart';
import '../../themes_colors/app_theme.dart';
import '../../widgets_custom_lotties/custom_bottom_nav.dart';
import 'coach_report_view.dart';

/// The Coach, as a destination of its own.
///
/// **Why it was promoted out of a tab strip.** This is the only part of the
/// app that reads a player's whole history at once — habits, lessons, quiz
/// accuracy, lives played, and how they actually divide a board in Coin
/// Cascade — and looks for the places those disagree. It produces findings no
/// individual screen can, of which the sharpest is: *you score 90% on needs
/// versus wants, and across four runs wants took 42% of your board.* The
/// Academy only sees the score. The arcade only sees the run.
///
/// It lived as the **sixth tab of a scrollable strip** inside Money Habits,
/// behind Today, Week, Find, Challenges and Jar. Reaching it required knowing
/// it existed, opening the right screen, and scrolling a tab bar sideways.
/// That is a worse fate than being missing, because the work is all there and
/// nothing about the app suggests it.
///
/// **Why the top strip rather than the bottom bar.** The bottom bar was seven
/// wide once and "got crowded fast" (see [AppTabIndex]); it is deliberately
/// five now, with Home as the middle anchor. Adding a sixth would undo a
/// decision that was already made once for good reasons. Daily and Profile
/// already live in the top strip with real `IndexedStack` slots, so this
/// follows a pattern that exists rather than inventing one.
///
/// The report itself is [CoachReportView], which Money Habits still shows as
/// its own tab — one widget, two entry points, so the two can never drift.
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key, this.activeTabIndex, this.onNavSelected});

  final int? activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Only when pushed as a route. Inside the IndexedStack there is
        // nothing to pop back to, and a back arrow that does nothing is
        // worse than no arrow.
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(
          'Your Coach',
          style: GoogleFonts.pixelifySans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: activeTabIndex ?? AppTabIndex.dashboard,
              onSelected: onNavSelected!,
            ),
      body: SafeArea(top: false, child: const CoachReportView()),
    );
  }
}
