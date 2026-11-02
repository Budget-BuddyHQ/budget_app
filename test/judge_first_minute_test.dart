import 'dart:io';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/widgets_custom_lotties/phone_width_frame.dart';
import 'package:budget_app/widgets_custom_lotties/start_here_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A judge's first minute on the website: a loading screen instead of a blank
/// one, a phone-width column on a laptop, and a clear place to start.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StartHereProgress.instance.debugReset();
  });

  test('the website shows a loading screen until the app draws', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('id="bb-loading"'));
    expect(html, contains('Loading Budget Buddy'));
    expect(html, contains("'flutter-first-frame'"));
  });

  group('phone-width frame', () {
    Future<Size> sizeSeen(WidgetTester tester, Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      late Size seen;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => PhoneWidthFrame(child: child!),
          home: Builder(
            builder: (context) {
              seen = MediaQuery.sizeOf(context);
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      return seen;
    }

    testWidgets('a laptop gets a centered phone-width column', (tester) async {
      final seen = await sizeSeen(tester, const Size(1440, 900));
      expect(seen.width, lessThanOrEqualTo(kFrameWidth));
      expect(tester.getSize(find.byType(Scaffold)).width, seen.width);
      expect(tester.getCenter(find.byType(Scaffold)).dx, 720);
    });

    testWidgets('a phone is left exactly as it is', (tester) async {
      final seen = await sizeSeen(tester, const Size(393, 852));
      expect(seen.width, 393);
    });
  });

  group('start here', () {
    var lesson = 0, life = 0, coach = 0;

    Future<void> show(WidgetTester tester, {List<String> done = const []}) {
      final base = UserStats.defaults('test_user');
      final stats = base.copyWith(
        spendingHabits: {...base.spendingHabits, 'completed_lessons': done},
      );
      return tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>(
          create: (_) =>
              UserStatsController(service: SupabaseService.instance)
                ..seedStatsForTest(stats),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StartHereCard(
                  onLesson: () => lesson++,
                  onLife: () => life++,
                  onCoach: () => coach++,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('a new player sees three steps that go where they say', (
      tester,
    ) async {
      await show(tester);
      await tester.pump();
      expect(find.text('Start here'), findsOneWidget);
      expect(find.text('0 of 3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('start-here-lesson')));
      await tester.tap(find.byKey(const ValueKey('start-here-life')));
      await tester.tap(find.byKey(const ValueKey('start-here-coach')));
      expect((lesson, life, coach), (1, 1, 1));
    });

    testWidgets('steps tick off, and the card leaves when all are done', (
      tester,
    ) async {
      await show(tester, done: const ['lesson_1']);
      await tester.pump();
      expect(find.text('1 of 3'), findsOneWidget);
      await StartHereProgress.instance.mark(StartStep.life);
      await tester.pump();
      expect(find.text('2 of 3'), findsOneWidget);
      await StartHereProgress.instance.mark(StartStep.coach);
      await tester.pump();
      expect(find.text('Start here'), findsNothing);
    });

    testWidgets('Hide puts it away for good', (tester) async {
      await show(tester);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('start-here-hide')));
      await tester.pump();
      expect(find.text('Start here'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('start_here_hidden_v1'), isTrue);
    });
  });
}
