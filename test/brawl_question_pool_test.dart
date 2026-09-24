import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_question_pool.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/question_stage.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/reading_grade.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// What Finance Brawl asks a child.
///
/// **Reported as:** a ten-year-old playing the Brawl *"is getting questions that
/// he should not even be facing."* The Brawl's own bank is written for teenagers
/// and adults, and below thirteen it was screened only by reading grade and a
/// short word list. So the tests here read the questions a young player would
/// really get, and fail if any of them is about a later part of life.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// A stand-in for the Brawl's own bank: the kind of question it holds.
  final native = <BrawlItem>[
    for (final q in const [
      'What is a Roth IRA?',
      'What is a bear market?',
      'What does tax-loss harvesting involve?',
      'What is a CD ladder strategy?',
      'What is an Initial Public Offering (IPO)?',
      'What is gross income?',
    ])
      BrawlItem.native(
        question: q,
        options: const ['a', 'b', 'c'],
        correctIndex: 0,
        explanation: 'because',
      ),
  ];

  const kids = [AgeBand.under9, AgeBand.age9to12];

  group('a child is asked child questions', () {
    test('the Brawl\'s own bank is never used for anybody under thirteen', () {
      for (final band in kids) {
        final pool = brawlPool(band: band, native: native);
        expect(
          pool.where((q) => q.id.startsWith('brawl:')),
          isEmpty,
          reason: '$band was handed a question from the adult bank',
        );
      }
    });

    test('and nothing in what they are asked names a later part of life', () {
      for (final band in kids) {
        for (final q in brawlPool(band: band, native: native)) {
          final text = [q.question, ...q.options].join(' ');
          for (final topic in {
            ...kAdultOnlyTopics,
            'roth',
            'bear market',
            'ipo',
            'tax-loss',
          }) {
            expect(
              text.toLowerCase().contains(topic),
              isFalse,
              reason:
                  '"${q.question}" mentions "$topic" and was served to $band',
            );
          }
        }
      }
    });

    test(
      'every question they get belongs to a unit written for ten and under',
      () {
        for (final band in kids) {
          final pool = brawlPool(band: band, native: native);
          final young = pool.where(
            (q) =>
                (kQuestionStage[q.id]?.index ?? 0) <= AgeStage.youngKids.index,
          );
          expect(
            young.length,
            greaterThanOrEqualTo(kBrawlMinimumKidPool),
            reason: 'too few questions for $band to go a whole run',
          );
        }
      },
    );

    test('there are enough to go several checkpoints without a repeat', () {
      for (final band in kids) {
        expect(
          brawlPool(band: band, native: native).length,
          greaterThanOrEqualTo(30),
          reason: '$band would meet the same questions again and again',
        );
      }
    });

    test('and they are short enough to read', () {
      for (final band in kids) {
        for (final q in brawlPool(band: band, native: native)) {
          expect(
            readingGrade(q.question),
            lessThanOrEqualTo(band.maxReadingGrade + 3),
            reason: '"${q.question}" is hard to read for $band',
          );
        }
      }
    });
  });

  group('older players still get more', () {
    test(
      'a thirteen-year-old is not handed retirement accounts or markets',
      () {
        final pool = brawlPool(band: AgeBand.teen13to15, native: native);
        for (final q in pool.where((q) => q.id.startsWith('brawl:'))) {
          expect(q.question.toLowerCase(), isNot(contains('roth')));
          expect(q.question.toLowerCase(), isNot(contains('bear market')));
          expect(q.question.toLowerCase(), isNot(contains('ipo')));
        }
      },
    );

    test('adults get the whole bank as well as the Academy', () {
      final pool = brawlPool(band: AgeBand.adult18plus, native: native);
      expect(
        pool.where((q) => q.id.startsWith('brawl:')).length,
        native.length,
      );
      expect(pool.length, greaterThan(native.length));
    });

    test('every band has something to ask', () {
      for (final band in AgeBand.values) {
        expect(
          brawlPool(band: band, native: native),
          isNotEmpty,
          reason: '$band would meet an empty checkpoint',
        );
      }
    });

    test('the pool grows with the player', () {
      int size(AgeBand b) => brawlPool(band: b, native: native).length;
      expect(
        size(AgeBand.age9to12),
        lessThanOrEqualTo(size(AgeBand.teen13to15)),
      );
      expect(
        size(AgeBand.teen13to15),
        lessThanOrEqualTo(size(AgeBand.adult18plus)),
      );
    });
  });

  group('the real game uses it', () {
    Future<dynamic> pumpGame(WidgetTester tester, AgeBand band) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = UserStatsController(service: SupabaseService.instance);
      final base = UserStats.defaults('test_user');
      controller.seedStatsForTest(
        base.copyWith(
          spendingHabits: <String, dynamic>{
            ...base.spendingHabits,
            ProfileKeys.ageBand: band.id,
          },
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>.value(
          value: controller,
          child: const MaterialApp(home: FinanceBrawlScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      return tester.state(find.byType(FinanceBrawlScreen));
    }

    testWidgets('a ten-year-old\'s checkpoints never ask about later life', (
      tester,
    ) async {
      final game = await pumpGame(tester, AgeBand.age9to12);
      final asked = <String>{};
      for (var i = 0; i < 12; i++) {
        game.runCheckpointForTest(perfect: false);
        await tester.pump();
        asked.addAll((game.checkpointQuestionsForTest as List).cast<String>());
      }
      expect(asked, isNotEmpty);
      for (final question in asked) {
        final lower = question.toLowerCase();
        for (final topic in {
          ...kAdultOnlyTopics,
          'roth',
          'bear market',
          'ipo',
        }) {
          expect(
            lower.contains(topic),
            isFalse,
            reason: 'a ten-year-old was asked: $question',
          );
        }
      }
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a run does not repeat a question until it has to', (
      tester,
    ) async {
      final game = await pumpGame(tester, AgeBand.age9to12);
      final seen = <String>[];
      for (var i = 0; i < 5; i++) {
        game.runCheckpointForTest(perfect: false);
        await tester.pump();
        seen.addAll((game.checkpointQuestionsForTest as List).cast<String>());
      }
      expect(
        seen.toSet().length,
        seen.length,
        reason: 'a repeat inside 15 questions',
      );
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
