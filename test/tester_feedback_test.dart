import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/services_backend_and_other_services/local_web_game_server.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Three things a closed-testing tester hit in their first session.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('the daily budget question finds its files on a phone', () async {
    // "Failed to load the local React challenge bundle: Unable to load
    // asset: AssetManifest.json". Phone builds no longer ship that file.
    final server = LocalWebGameServer();
    final uri = await server.start();
    expect(uri.path, '/index.html');
    await server.stop();
  });

  test('a new player starts at level 1 with nothing made up', () {
    // "A brand new guest starts at LV 7 with 2000 coins, which looks like
    // leftover test data."
    final stats = UserStats.defaults('new_player');
    expect(stats.level, 1);
    expect(stats.gold, kStartingGold);
    expect(stats.holdings, isEmpty);
    expect(stats.portfolioHistory, isEmpty);
    expect(stats.transactions.single.title, 'Welcome gift');

    // And an account with no history is not given an invented one.
    final loaded = UserStats.fromMap(<String, dynamic>{'id': 'x'});
    expect(loaded.transactions, isEmpty);
    expect(loaded.holdings, isEmpty);
  });

  testWidgets('a reading lesson is finished at the bottom, not the top', (
    tester,
  ) async {
    // "Complete Lesson works without scrolling through the lesson."
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final unit = lessonUnits.firstWhere((u) => u.id == 'unit_1');
    await tester.pumpWidget(
      ChangeNotifierProvider<UserStatsController>(
        create: (_) =>
            UserStatsController(service: SupabaseService.instance)
              ..seedStatsForTest(UserStats.defaults('test_user')),
        child: MaterialApp(
          home: LessonDetailScreen(
            lesson: unit.lessons.firstWhere((l) => l.id == 'lesson_1'),
            unit: unit,
            progressionService: ProgressionService(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    FilledButton button() => tester.widget<FilledButton>(
      find.byKey(const ValueKey('lesson-complete')),
    );
    expect(find.text('Scroll to the end to finish'), findsOneWidget);
    expect(button().onPressed, isNull);

    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
    }
    expect(find.text('Complete Lesson'), findsOneWidget);
    expect(button().onPressed, isNotNull);
  });
}
