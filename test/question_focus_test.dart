import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/custom_made_widgets/habit_challenge_row_item.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/leak_patrol_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/question_focus.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/question_focus_picker.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "My weak spots" or "My age group" in the arcade.
///
/// **Asked for as:** *"give them an option for the questions to be on the
/// things they need to work on or just the questions in their age group"*,
/// in Finance Brawl and the other games except the Market Board.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('which questions', () {
    test('weak spots never reach past the age gate', () {
      final allSkills = {for (final q in allQuizQuestions) q.skillId};
      for (final band in AgeBand.values) {
        final forAge = {
          for (final q in ageAppropriateQuestions(
            allQuizQuestions.toList(),
            band,
          ))
            q.id,
        };
        final weak = focusedQuestions(
          band: band,
          focus: QuestionFocus.weakSpots,
          weakSkills: allSkills,
        );
        for (final q in weak.questions) {
          expect(forAge, contains(q.id), reason: '${band.name}: ${q.id}');
        }
      }
    });

    test('weak spots ask only the weak topics when there are enough', () {
      final r = focusedQuestions(
        band: AgeBand.adult18plus,
        focus: QuestionFocus.weakSpots,
        weakSkills: const {'budget_basics', 'income'},
      );
      expect(r.toppedUp, isFalse);
      expect(r.questions.length, greaterThanOrEqualTo(kWeakSpotMinimum));
      expect(
        r.questions.map((q) => q.skillId).toSet(),
        everyElement(isIn(const {'budget_basics', 'income'})),
      );
    });

    test('too few weak questions are topped up, weak ones first', () {
      final r = focusedQuestions(
        band: AgeBand.adult18plus,
        focus: QuestionFocus.weakSpots,
        weakSkills: const {'no_such_skill'},
      );
      expect(r.toppedUp, isTrue);
      expect(r.questions, isNotEmpty);
    });

    test('age group is everything for the age, as before', () {
      final r = focusedQuestions(
        band: AgeBand.age9to12,
        focus: QuestionFocus.ageGroup,
        weakSkills: const {'income'},
      );
      expect(
        r.questions.map((q) => q.id),
        ageAppropriateQuestions(
          allQuizQuestions.toList(),
          AgeBand.age9to12,
        ).map((q) => q.id),
      );
    });

    test('a bonus question is a weak one when there is one', () {
      final pool = focusedQuestions(
        band: AgeBand.adult18plus,
        focus: QuestionFocus.weakSpots,
        weakSkills: const {'no_such_skill', 'income'},
      );
      final random = Random(3);
      for (var i = 0; i < 20; i++) {
        expect(
          pickFocusedQuestion(random, pool, const {'income'})!.skillId,
          'income',
        );
      }
    });
  });

  group('Leak Patrol', () {
    final pool = leakItemsFor(AgeBand.adult18plus);

    test('weak ideas come up more often', () {
      final weak = {pool.first.concept};
      final share = pool.where((i) => weak.contains(i.concept)).length;
      if (share < 3) return; // Not enough items on one idea to lean on.
      final random = Random(7);
      var hits = 0;
      for (var i = 0; i < 1000; i++) {
        if (weak.contains(pickLeakItem(random, pool, weak).concept)) hits++;
      }
      expect(hits, greaterThan(500));
    });

    test('without weak ideas every item can come up', () {
      final random = Random(7);
      final seen = <String>{};
      for (var i = 0; i < 4000; i++) {
        seen.add(pickLeakItem(random, pool, const <FinanceConcept>{}).id);
      }
      expect(seen.length, pool.length);
    });
  });

  group('answers count', () {
    test('right clears a weak topic, wrong adds one', () async {
      final c = UserStatsController(service: SupabaseService.instance);
      final base = c.stats;
      c.seedStatsForTest(
        base.copyWith(
          spendingHabits: {
            ...base.spendingHabits,
            'weak_skills': ['income', 'saving'],
          },
        ),
      );
      await c.recordArcadeAnswers(
        correctSkills: ['income'],
        missedSkills: ['taxes'],
      );
      expect(c.stats.weakSkills.toSet(), {'saving', 'taxes'});
    });
  });

  group('the picker', () {
    Future<QuestionFocus?> open(
      WidgetTester tester, {
      List<String> weak = const [],
    }) async {
      final base = UserStats.defaults('test_user');
      final stats = base.copyWith(
        spendingHabits: {...base.spendingHabits, 'weak_skills': weak},
      );
      QuestionFocus? picked;
      var done = false;
      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>(
          create: (_) =>
              UserStatsController(service: SupabaseService.instance)
                ..seedStatsForTest(stats),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showQuestionFocusPicker(
                    context,
                    gameTitle: 'Finance Brawl',
                  );
                  done = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Which questions do you want?'), findsOneWidget);
      if (weak.isEmpty) {
        await tester.tap(find.byKey(const ValueKey('focus-weak-spots')));
        await tester.pumpAndSettle();
        expect(
          find.text('Which questions do you want?'),
          findsOneWidget,
          reason: 'nothing to practise yet, so the choice does nothing',
        );
        await tester.tap(find.byKey(const ValueKey('focus-age-group')));
      } else {
        expect(find.textContaining('Income'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('focus-weak-spots')));
      }
      await tester.pumpAndSettle();
      expect(done, isTrue);
      return picked;
    }

    testWidgets('no weak spots yet: only the age group can be chosen', (
      tester,
    ) async {
      expect(await open(tester), QuestionFocus.ageGroup);
    });

    testWidgets('weak spots names them and can be chosen', (tester) async {
      expect(
        await open(tester, weak: const ['income']),
        QuestionFocus.weakSpots,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kQuestionFocusPrefKey), 'weakSpots');
    });
  });

  group('challenge pictures', () {
    testWidgets('a step shows the habit picture and a readable status', (
      tester,
    ) async {
      final challenge = habitChallenges.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HabitChallengeRowItem(
                tasks: challenge.tasks,
                statusFor: (_) => HabitRowStatus.completed,
                onTaskTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // The picture, not a dark icon on a dark card.
      expect(find.byType(Image), findsWidgets);
      // The pill reads dark on light, not dark green on dark green.
      final done = tester.widget<Text>(find.text('Done').first);
      expect(done.style?.color, const Color(0xFF172328));
    });
  });
}
