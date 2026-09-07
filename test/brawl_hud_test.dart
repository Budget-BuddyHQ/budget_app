import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

/// The two Finance Brawl HUD panels have to be the same size.
///
/// Reported as "the header box sizes in finance brawl are all different
/// sizes, making it visually jarring". The cause was structural rather than
/// spacing: the wave panel drew a progress bar and a caption where the
/// net-worth panel drew a single line of flavour text, so two boxes with
/// identical borders sat side by side at visibly different heights — and the
/// gap changed with the layout, because the wave panel drops its bar at
/// narrow widths.
///
/// **Two fixes were tried and rejected first, and both are worth recording
/// because the reasons generalise.**
///
/// `IntrinsicHeight` + `CrossAxisAlignment.stretch` is the textbook answer
/// and throws here: `FittedLabel`, `_PixelPanel` and `PixelProgressBar` all
/// use `LayoutBuilder` internally, and Flutter asserts that a LayoutBuilder
/// cannot report intrinsic dimensions. That rules `IntrinsicHeight` out of
/// essentially this entire app, not just this screen.
///
/// `stretch` on its own then forces an infinite height, because the HUD row
/// sits inside a top-aligned `Align` and has no bounded height to stretch to.
///
/// What works is giving both panels the *same widgets*, so the heights match
/// by construction and no number anywhere states a height. This test pins
/// that, because the tempting future edit — dropping the bar from the
/// net-worth panel as redundant with the balance figure above it — silently
/// restores the bug.
void main() {
  Future<Size> panelSize(WidgetTester tester, Finder finder) async =>
      tester.getSize(finder);

  testWidgets('both HUD panels render at the same size', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // The screen reads the player's stats. Never initialising Supabase is
    // deliberate and is what `responsive_layout_test` does too: the service
    // reads through a nullable client, so an uninitialised one yields
    // signed-out defaults instead of throwing.
    await tester.pumpWidget(
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
        child: const MaterialApp(
          home: Scaffold(body: FinanceBrawlScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // The two panels are the only widgets carrying these labels.
    final wave = find.text('WAVE');
    final worth = find.text('NET WORTH');

    // No silent skip here. An earlier version bailed out with
    // `markTestSkipped` when the labels were missing, which would have let
    // this test report success while comparing nothing at all — the same
    // shape of fault as the layout sweep that filtered its own exceptions
    // and stayed green for months. If the HUD is not on screen, that is a
    // failure worth seeing.
    expect(wave, findsOneWidget, reason: 'the WAVE panel is not on screen');
    expect(worth, findsOneWidget, reason: 'the NET WORTH panel is missing');

    // Walk up from each label to the panel box that wraps it. Both panels
    // are `Expanded` children of the same row, so comparing the boxes that
    // contain their labels compares the panels.
    final wavePanel = find
        .ancestor(of: wave, matching: find.byType(Padding))
        .last;
    final worthPanel = find
        .ancestor(of: worth, matching: find.byType(Padding))
        .last;

    final a = await panelSize(tester, wavePanel);
    final b = await panelSize(tester, worthPanel);

    expect(
      a.height,
      moreOrLessEquals(b.height, epsilon: 0.5),
      reason:
          'the two HUD panels are different heights again — the usual cause '
          'is one of them losing its progress bar, which is what made them '
          'mismatch in the first place',
    );
  });

  test('a progress bar can carry a label instead of current / total', () {
    // The net-worth panel prints its balance as the headline number, so a
    // caption reading "8400 / 10000" would be the same figure twice in one
    // small box. It says what the bar means instead.
    const plain = HudProgress(current: 3, total: 12);
    const labelled = HudProgress(
      current: 8400,
      total: 10000,
      label: "Don't hit zero",
    );

    expect(plain.caption, '3 / 12');
    expect(labelled.caption, "Don't hit zero");
    expect(labelled.fraction, closeTo(0.84, 0.001));
  });

  test('a zero total does not blank the bar with NaN', () {
    const p = HudProgress(current: 5, total: 0);
    expect(p.fraction, 0);
    expect(p.fraction.isNaN, isFalse);
  });

  test('the bar never overfills', () {
    // Balance can exceed the starting figure after a good wave, and a
    // fraction above 1 would draw the fill outside its own track.
    const p = HudProgress(current: 14000, total: 10000);
    expect(p.fraction, 1.0);
  });
}
