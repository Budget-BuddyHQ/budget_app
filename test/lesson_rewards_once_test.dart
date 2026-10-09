import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/quiz_widgets.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lesson pays once.
///
/// **Reported as:** players *"can just keep pressing the lessons to get more
/// and infinite coins."* The normal lesson reward was already one-time, but
/// the Unit 6 payouts (`kLessonPayouts`: 400–800 gold and free shares) were
/// granted through a path that never asked whether the lesson was done before,
/// so replaying a reading lesson paid out every time.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  UserStatsController fresh() =>
      UserStatsController(service: SupabaseService.instance);

  Future<void> finish(UserStatsController c, String id) {
    final payout = kLessonPayouts[id];
    return c.completeLessonProgress(
      lessonId: id,
      lessonTitle: id,
      xpEarned: 12,
      goldEarned: 50,
      bonusGold: payout?.gold ?? 0,
      bonusShares: payout?.shares ?? const <String, double>{},
    );
  }

  test('a Unit 6 payout is paid the first time only', () async {
    final c = fresh();
    final startGold = c.stats.gold;
    final payout = kLessonPayouts['lesson_26']!;

    await finish(c, 'lesson_26');
    final afterFirst = c.stats.gold;
    final spy = c.stats.holdings['stock_SPY'] ?? 0;
    expect(afterFirst, startGold + 50 + payout.gold);
    expect(spy, payout.shares['SPY']);

    for (var i = 0; i < 5; i++) {
      await finish(c, 'lesson_26');
    }
    expect(c.stats.gold, afterFirst, reason: 'replays paid out again');
    expect(c.stats.holdings['stock_SPY'], spy, reason: 'shares granted again');
  });

  test('a retaken quiz pays nothing and says nothing about gold', () async {
    final c = fresh();
    await c.completeLessonProgress(
      lessonId: 'quiz_1',
      lessonTitle: 'Quiz',
      goldEarned: 70,
      quizCorrect: 4,
      quizTotal: 4,
    );
    final gold = c.stats.gold;
    final ledger = c.stats.transactions.length;

    await c.completeLessonProgress(
      lessonId: 'quiz_1',
      lessonTitle: 'Quiz',
      goldEarned: 70,
      quizCorrect: 4,
      quizTotal: 4,
    );
    expect(c.stats.gold, gold);
    // No "+70" line in the money history for gold that never arrived.
    expect(c.stats.transactions.length, ledger);
    // The score itself is still recorded.
    expect((c.stats.quizScores['quiz_1'] as Map)['attempts'], 2);
  });

  test('a topic answered right in a quiz stops being weak', () async {
    // Practice runs cleared recovered topics; quizzes and tests never did,
    // so the Coach kept listing something the player had since fixed.
    final c = fresh();
    await c.completeLessonProgress(
      lessonId: 'quiz_1',
      lessonTitle: 'Quiz',
      quizCorrect: 0,
      quizTotal: 1,
      missedSkills: const ['income'],
    );
    expect(c.stats.weakSkills, contains('income'));
    await c.completeLessonProgress(
      lessonId: 'quiz_1',
      lessonTitle: 'Quiz',
      quizCorrect: 1,
      quizTotal: 1,
      correctSkills: const ['income'],
    );
    expect(c.stats.weakSkills, isNot(contains('income')));
  });

  group('the results screen', () {
    Future<void> show(WidgetTester tester, QuizResultsCard card) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: card)),
        ),
      );
    }

    testWidgets('a perfect score is not a blank page', (tester) async {
      final questions = quizFor('test_1').take(7).toList();
      await show(
        tester,
        QuizResultsCard(
          correct: questions.length,
          total: questions.length,
          missed: const [],
          answers: [for (final _ in questions) true],
          questions: questions,
          reward: (gold: 85, xp: 26, firstTime: true),
        ),
      );
      expect(find.text('Perfect score!'), findsOneWidget);
      expect(find.text('YOU SHOWED YOU KNOW'), findsOneWidget);
      expect(find.text('+85'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(questions.length));
    });

    testWidgets('a replay says the rewards were already earned', (
      tester,
    ) async {
      await show(
        tester,
        const QuizResultsCard(
          correct: 7,
          total: 7,
          missed: [],
          reward: (gold: 85, xp: 26, firstTime: false),
        ),
      );
      expect(find.textContaining('Practice run'), findsOneWidget);
      expect(find.text('+85'), findsNothing);
    });
  });
}
