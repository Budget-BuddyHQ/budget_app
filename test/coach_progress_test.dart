import 'dart:convert';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/coach_memory.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/coach_rewards.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/screens_minigames_admin_etc/coach/coach_report_view.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Coach sends you to the lesson that fixes something, and says so when
/// you have fixed it.
///
/// **Asked for as:** *"for the coach I want it to send back to the lesson
/// where the users can improve ... make sure that the things that improved
/// and finished disappear and congratulate them for doing so."*
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  MoneyFinding finding(
    String id, {
    MoneyFindingKind kind = MoneyFindingKind.fix,
  }) => MoneyFinding(
    id: id,
    kind: kind,
    dimension: MoneyDimension.saving,
    title: 'Title of $id',
    evidence: '',
    action: '',
  );

  group('CoachMemory', () {
    test('a finding that stops being flagged is fixed', () {
      final m = CoachMemory();
      expect(m.update([finding('a')]), isTrue);
      expect(m.fixedFindings, isEmpty, reason: 'first sighting is not a fix');
      m.update(const []);
      expect(m.fixedFindings.single.id, 'a');
    });

    test('flagged again means it is not fixed any more', () {
      final m = CoachMemory()..update([finding('a')]);
      m.update(const []);
      m.update([finding('a')]);
      expect(m.fixedFindings, isEmpty);
    });

    test('strengths and the newcomer card are never "fixed"', () {
      final m = CoachMemory()
        ..update([
          finding('good', kind: MoneyFindingKind.strength),
          finding('start_here'),
        ]);
      m.update(const []);
      expect(m.fixedFindings, isEmpty);
    });

    test('a weak topic answered right is celebrated too', () {
      final m = CoachMemory()
        ..update(const [], extra: const {'skill:income': 'Income'});
      m.update(const []);
      expect(m.fixedFindings.single.title, 'Income');
    });

    test('dismissing clears the congratulations and nothing else', () {
      final m = CoachMemory()..update([finding('a'), finding('b')]);
      m.update([finding('b')]);
      m.dismissFixed();
      expect(m.fixedFindings, isEmpty);
      expect(m.open.keys, ['b']);
    });

    test('survives a restart', () async {
      final m = CoachMemory()..update([finding('a')]);
      m.update(const []);
      await m.save();
      final back = await CoachMemory.load();
      expect(back.fixedFindings.single.id, 'a');
    });
  });

  group('the Coach screen', () {
    late UserStatsController controller;

    Future<void> show(
      WidgetTester tester, {
      List<String> weak = const [],
    }) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final base = UserStats.defaults('test_user');
      final stats = base.copyWith(
        spendingHabits: {...base.spendingHabits, 'weak_skills': weak},
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>(
          create: (_) => controller = UserStatsController(
            service: SupabaseService.instance,
          )..seedStatsForTest(stats),
          child: const MaterialApp(home: Scaffold(body: CoachReportView())),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('names the lesson for each weak topic', (tester) async {
      await show(tester, weak: const ['income']);
      expect(find.text('Where to improve'), findsOneWidget);
      expect(find.text('Lesson: Understanding Income'), findsOneWidget);
      expect(find.text('Go to lesson'), findsOneWidget);
    });

    testWidgets('a topic put right leaves the list and is congratulated', (
      tester,
    ) async {
      // Last visit flagged "income"; it is no longer weak.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'coach_open_findings_v1': jsonEncode({'skill:income': 'Income'}),
      });
      await show(tester);
      expect(find.text('Where to improve'), findsNothing);
      expect(find.text('You fixed it!'), findsOneWidget);
      expect(find.text('Income: no longer a weak spot'), findsOneWidget);

      // And it pays: a weak topic is worth the smaller reward.
      final gold = controller.stats.gold;
      expect(
        find.text(
          'Claim +${CoachRewards.skillGold} gold · +${CoachRewards.skillXp} XP',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('coach-claim')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(controller.stats.gold, gold + CoachRewards.skillGold);
      expect(controller.stats.coachFixesTotal, 1);
      expect(find.text('You fixed it!'), findsNothing);
    });

    testWidgets('each weak topic says what fixing it is worth', (tester) async {
      await show(tester, weak: const ['income']);
      expect(
        find.textContaining('Fix it: +${CoachRewards.skillGold}'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('coach-fix-progress')), findsOneWidget);
    });
  });

  group('Coach rewards', () {
    UserStatsController fresh() =>
        UserStatsController(service: SupabaseService.instance);

    test('a fix pays once, then not again for 30 days', () async {
      final c = fresh();
      final gold = c.stats.gold;
      final first = await c.claimCoachRewards(['lives_flat']);
      expect(first.gold, CoachRewards.findingGold);
      expect(c.stats.gold, gold + CoachRewards.findingGold);

      // Flag it again, fix it again: the same id inside the cooldown.
      final again = await c.claimCoachRewards(['lives_flat']);
      expect(again.paidAnything, isFalse);
      expect(c.stats.gold, gold + CoachRewards.findingGold);
    });

    test('the tenth fix unlocks the Golden skin', () async {
      final c = fresh();
      await c.claimCoachRewards([for (var i = 0; i < 9; i++) 'skill:s$i']);
      expect(c.stats.unlockedSkins, isNot(contains(CoachRewards.skinId)));
      final tenth = await c.claimCoachRewards(['finding_x']);
      expect(tenth.unlockedSkinId, CoachRewards.skinId);
      expect(c.stats.unlockedSkins, contains(CoachRewards.skinId));
      expect(c.stats.coachFixesTotal, 10);
    });
  });
}
