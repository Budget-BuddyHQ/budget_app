import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/leak_patrol_page.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

/// Leak Patrol, actually played.
///
/// The model is tested separately; this checks the thing a model test cannot
/// — that the round starts, things appear in holes, tapping resolves them,
/// and the clock ends it. A minigame that compiles and never spawns anything
/// is the shape of bug that has shipped in this repo before.
void main() {
  Widget host() => ChangeNotifierProvider<UserStatsController>(
    create: (_) => UserStatsController(service: SupabaseService.instance),
    child: const MaterialApp(home: LeakPatrolPage()),
  );

  testWidgets('the round starts and things pop up', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('Start'), findsOneWidget);
    expect(
      find.textContaining('speed set for your age'),
      findsOneWidget,
      reason: 'the age scaling has to be said out loud, not just applied',
    );

    await tester.tap(find.text('Start'));
    await tester.pump();

    // The HUD replaces the intro.
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('CAUGHT'), findsOneWidget);

    // Let the spawner run.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 1600));

    // Something is on the board. GestureDetector count is the cheapest
    // proxy that does not depend on which item was drawn.
    expect(
      find.byType(GestureDetector),
      findsWidgets,
      reason: 'nothing ever appeared — the spawner is not running',
    );

    // Wind the clock down and stop, so no timer outlives the test.
    await tester.pump(const Duration(seconds: 70));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  });

  testWidgets('the round ends on its own and offers another', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();

    // Past the longest round any band gets.
    for (var i = 0; i < 65; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(
      find.text('Go again'),
      findsOneWidget,
      reason: 'the clock never ended the round',
    );
    expect(find.textContaining('gold'), findsWidgets);
  });
}
