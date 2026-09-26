import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A controller carrying a chosen age band, without a save round-trip.
UserStatsController _controllerForBand(
  AgeBand band, {
  List<String> completedLessons = const <String>[],
}) {
  final controller = UserStatsController(service: SupabaseService.instance);
  final base = UserStats.defaults('test_user');
  controller.seedStatsForTest(
    base.copyWith(
      spendingHabits: <String, dynamic>{
        ...base.spendingHabits,
        ProfileKeys.ageBand: band.id,
        ProfileKeys.onboardingComplete: true,
        'completed_lessons': completedLessons,
      },
    ),
  );
  return controller;
}

Widget _academyFor(UserStatsController controller) {
  return ChangeNotifierProvider<UserStatsController>.value(
    value: controller,
    child: MaterialApp(
      theme: AppTheme.getLightTheme(),
      home: const LessonScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('a 12-year-old sees an age warning on the adult units', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = _controllerForBand(AgeBand.age9to12);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_academyFor(controller));
    await tester.pump();

    // The unit strip groups by age band, so the older bands are labelled as
    // such even before any unit is opened.
    expect(find.text('Older than you'), findsWidgets);
    expect(find.text('Your age group'), findsOneWidget);
  });

  testWidgets('an adult sees no age warning anywhere', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = _controllerForBand(AgeBand.adult18plus);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_academyFor(controller));
    await tester.pump();

    expect(
      find.text('Older than you'),
      findsNothing,
      reason: 'nothing in the curriculum is written for an older band',
    );
  });

  testWidgets('a player who did not share an age is never warned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = _controllerForBand(AgeBand.undisclosed);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_academyFor(controller));
    await tester.pump();

    expect(find.text('Older than you'), findsNothing);
    expect(find.text('Your age group'), findsNothing);
  });

  testWidgets('skip-ahead warning can be hidden for the current unit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = _controllerForBand(AgeBand.age9to12);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_academyFor(controller));
    await tester.pump();

    final secondLesson = find.text('Things Cost Money');
    await tester.ensureVisible(secondLesson);
    await tester.tap(secondLesson);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Don't show again for this unit"), findsOneWidget);
    await tester.tap(find.text("Don't show again for this unit"));
    await tester.pump();
    await tester.tap(find.text('Continue Anyway!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('skip_ahead_warning_hidden_unit_10'),
      isTrue,
    );

    await tester.pageBack();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
    final lockedQuiz = find.text('Quick Quiz').first;
    await tester.ensureVisible(lockedQuiz);
    await tester.tap(lockedQuiz);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Skipping ahead?'), findsNothing);
  });

  testWidgets('age warning can be hidden for the current unit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final readerStage = AgeBand.age9to12.maxPlausibleStage!;
    final olderUnitIndex = lessonUnits.indexWhere(
      (unit) => unit.ageStage.minAge > readerStage.minAge,
    );
    expect(olderUnitIndex, greaterThan(0));
    final olderUnit = lessonUnits[olderUnitIndex];
    final completedLessons = lessonUnits
        .take(olderUnitIndex)
        .expand((unit) => unit.lessons)
        .map((lesson) => lesson.id)
        .toList();
    final controller = _controllerForBand(
      AgeBand.age9to12,
      completedLessons: completedLessons,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_academyFor(controller));
    await tester.pump();

    final firstLesson = find.text(olderUnit.lessons.first.title).last;
    await tester.ensureVisible(firstLesson);
    await tester.tap(firstLesson);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final warningDialog = find.byType(AlertDialog);
    expect(warningDialog, findsOneWidget);
    expect(
      find.descendant(
        of: warningDialog,
        matching: find.textContaining('Written for '),
      ),
      findsOneWidget,
    );
    expect(find.text("Don't show again for this unit"), findsOneWidget);
    await tester.tap(find.text("Don't show again for this unit"));
    await tester.pump();
    await tester.tap(find.text('Read it anyway'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('above_age_warning_hidden_${olderUnit.id}'),
      isTrue,
    );

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(firstLesson);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
  });

  test('the warning yardstick is the top of the band, not its middle', () {
    // Regression guard: using `recommendedStage` here told a player who chose
    // "18 or older" that the 21+ unit was above their age.
    expect(AgeBand.adult18plus.maxPlausibleStage, AgeStage.adult);
    expect(AgeBand.age9to12.maxPlausibleStage, AgeStage.middleSchool);
    expect(AgeBand.teen16to17.maxPlausibleStage, AgeStage.highSchool);
    expect(AgeBand.undisclosed.maxPlausibleStage, isNull);

    for (final unit in lessonUnits) {
      expect(
        isAboveReaderStage(
          unit.ageStage,
          AgeBand.adult18plus.maxPlausibleStage,
        ),
        isFalse,
        reason: '${unit.id} should never be "above" an open-ended adult band',
      );
    }
  });

  test('the curriculum actually contains units above a 12-year-old', () {
    // Guards the widget tests above: if every unit were middle-school, they
    // would pass by finding nothing rather than by the logic working.
    final reader = AgeBand.age9to12.recommendedStage;
    expect(
      lessonUnits.where((u) => isAboveReaderStage(u.ageStage, reader)).length,
      greaterThan(0),
    );
  });
}
