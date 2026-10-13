import 'dart:io';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/skill_lessons.dart';
import 'package:budget_app/screens_minigames_admin_etc/coach/coach_report_view.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every card worth fixing says how it clears, and names the lessons that
/// close the gap.
///
/// **Asked for as:** *"how do I get rid of them"*, about "Your lives are not
/// getting richer" and "None of these lives owned a home", and *"guide them to
/// lessons that help them bridge that gap."*
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final source = File(
    'lib/models_Like_Skins_and_lessons_templates/money_analyzer.dart',
  ).readAsStringSync();

  // Each MoneyFinding(...) in the analyzer, as source.
  List<String> findingBlocks() {
    final blocks = <String>[];
    var i = 0;
    while (true) {
      final start = source.indexOf('MoneyFinding(\n', i);
      if (start < 0) return blocks;
      var depth = 0;
      var k = start + 'MoneyFinding'.length;
      for (; k < source.length; k++) {
        if (source[k] == '(') depth++;
        if (source[k] == ')' && --depth == 0) break;
      }
      blocks.add(source.substring(start, k + 1));
      i = k;
    }
  }

  test('every card worth fixing says what clears it', () {
    final missing = [
      for (final b in findingBlocks())
        if (!b.contains('MoneyFindingKind.strength') &&
            !b.contains('clearsWhen:'))
          RegExp(r"id: '([^']+)'").firstMatch(b)?.group(1) ?? b,
    ];
    expect(missing, isEmpty, reason: missing.join(', '));
  });

  test('every lesson a card names is a real lesson', () {
    final ids = RegExp(
      r"'(lesson_\d+)'",
    ).allMatches(source).map((m) => m.group(1)!).toSet();
    expect(ids, isNotEmpty);
    final unknown = [
      for (final id in ids)
        if (lessonById(id) == null) id,
    ];
    expect(unknown, isEmpty, reason: unknown.join(', '));
  });

  test('advice names the tabs by what they are called now', () {
    for (final stale in [
      'Assets tab',
      'Occupation tab',
      'Relationships and Activities',
    ]) {
      expect(source, isNot(contains(stale)), reason: stale);
    }
  });

  testWidgets('a card shows how to clear it and opens its lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    LifeReading life(int worth) => LifeReading(
      age: 70,
      netWorth: worth,
      happiness: 60,
      degrees: 0,
      borrowedForSchool: 0,
      promotions: 1,
      workYears: 30,
      assetsValue: 4000,
      loansOwed: 0,
      ownedHome: false,
    );
    final lives = [life(1000), life(2000), life(3000)];
    final snapshot = MoneySnapshot(
      loggedDaysLast14: 6,
      daysSinceLastLog: 1,
      pastLifeNetWorths: [for (final l in lives) l.netWorth],
      lives: lives,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
        child: MaterialApp(
          home: Scaffold(body: CoachReportView(snapshot: snapshot)),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The single most useful thing is first, with one button to its lesson.
    // Reported as the page being "kinda hard to follow".
    expect(find.byKey(const ValueKey('coach-next-step')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('coach-next-step-lesson')),
      findsOneWidget,
    );
    expect(find.text('None of these lives owned a home'), findsOneWidget);
    expect(
      find.textContaining(
        'Clears when one of your next lives owns a home',
        findRichText: true,
      ),
      findsOneWidget,
    );
    final lesson = find.byKey(const ValueKey('coach-lesson-lesson_55'));
    expect(lesson, findsOneWidget);
    expect(find.text('Renting Your First Place'), findsWidgets);

    await tester.ensureVisible(lesson);
    await tester.tap(lesson);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LessonScreen), findsOneWidget);
  });
}
