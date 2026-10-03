import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// A test whose questions were all held back for the player's age.
///
/// **Reported as:** *"the unit test doesn't show anything for some reason?"*
/// Unit 9's test was a placeholder sentence and a "Complete Lesson" button:
/// its four questions are all about loans, cars and rent, and for a player
/// who chose "Rather not say" the age filter removed every one. That was 14
/// of the 26 quizzes and tests for that band.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> open(WidgetTester tester, String lessonId) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final unit = lessonUnits.firstWhere(
      (u) => u.lessons.any((l) => l.id == lessonId),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<UserStatsController>(
        create: (_) =>
            UserStatsController(service: SupabaseService.instance)
              ..seedStatsForTest(UserStats.defaults('test_user')),
        child: MaterialApp(
          home: LessonDetailScreen(
            lesson: unit.lessons.firstWhere((l) => l.id == lessonId),
            unit: unit,
            progressionService: ProgressionService(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  test('the case this covers really happens', () {
    // If this ever stops being true the screen below is untested, not fixed.
    expect(quizFor('test_12'), isNotEmpty);
    expect(
      ageAppropriateQuestions(quizFor('test_12'), AgeBand.undisclosed),
      isEmpty,
    );
  });

  testWidgets('says why, instead of an empty test to "complete"', (
    tester,
  ) async {
    await open(tester, 'test_12');
    expect(find.text('Take the full test'), findsOneWidget);
    expect(find.text('Complete Lesson'), findsNothing);
    expect(find.textContaining('written for older players'), findsOneWidget);
  });

  testWidgets('and the full test is there when asked for', (tester) async {
    await open(tester, 'test_12');
    await tester.tap(find.text('Take the full test'));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.text(quizFor('test_12').first.prompt), findsOneWidget);
  });

  test('every quiz and test has something for an older player', () {
    for (final unit in lessonUnits) {
      for (final lesson in unit.lessons) {
        if (lesson.type == LessonNodeType.lesson) continue;
        expect(quizFor(lesson.id), isNotEmpty, reason: lesson.id);
      }
    }
  });
}
