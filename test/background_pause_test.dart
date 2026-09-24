import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/navigation_tools_and_animation/pauses_in_background.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/leak_patrol_page.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

/// The app stops playing itself once you leave it.
///
/// **Reported as:** leaving the app and coming back to find it had carried on
/// without you. Nothing in the game screens watched the lifecycle, so a
/// `Timer.periodic` kept firing in the background. A Leak Patrol round could
/// run out, and Coin Cascade's bills kept dropping, while the phone was in
/// somebody's pocket. Flutter pauses animations by itself, which is why this
/// only ever showed up in the parts driven by timers.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('the mixin', () {
    testWidgets('fires for hidden, paused and detached, never for inactive', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: _Watched(
            onBackground: () => log.add('bg'),
            onForeground: () => log.add('fg'),
          ),
        ),
      );

      // An incoming call banner or the notification shade. Still on screen.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(log, isEmpty);

      for (final state in const [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        log.clear();
        tester.binding.handleAppLifecycleStateChanged(state);
        expect(log, ['bg'], reason: '$state should pause the screen');
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        expect(log, ['bg', 'fg']);
      }
    });

    testWidgets('stops listening once the screen is gone', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: _Watched(
            onBackground: () => log.add('bg'),
            onForeground: () {},
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(
        log,
        isEmpty,
        reason: 'a disposed screen is still being told to pause',
      );
    });
  });

  testWidgets('a Leak Patrol round does not run out in the background', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
        child: const MaterialApp(home: LeakPatrolPage()),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    String clock() => (tester.widget<Text>(
      find
          .descendant(
            of: find.byType(Column),
            matching: find.textContaining('s'),
          )
          .first,
    )).data!;

    final beforeLeaving = _secondsLeft(tester);
    expect(beforeLeaving, lessThan(60));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(
      _secondsLeft(tester),
      beforeLeaving,
      reason: 'twenty seconds of the round were spent while the app was away',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(
      _secondsLeft(tester),
      lessThan(beforeLeaving),
      reason: 'the clock did not restart when the app came back',
    );

    // Wind down so no timer outlives the test.
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(clock(), isNotEmpty);
  });
}

/// Reads the HUD's TIME tile, which is the round clock.
int _secondsLeft(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => RegExp(r'^\d+s$').hasMatch(s))
      .toList();
  expect(texts, isNotEmpty, reason: 'no clock on screen');
  return int.parse(texts.first.replaceAll('s', ''));
}

class _Watched extends StatefulWidget {
  const _Watched({required this.onBackground, required this.onForeground});

  final VoidCallback onBackground;
  final VoidCallback onForeground;

  @override
  State<_Watched> createState() => _WatchedState();
}

class _WatchedState extends State<_Watched> with PausesInBackground {
  @override
  void onAppBackgrounded() => widget.onBackground();

  @override
  void onAppForegrounded() => widget.onForeground();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
