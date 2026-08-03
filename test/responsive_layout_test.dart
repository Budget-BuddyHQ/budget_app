import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/practice_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/feedback_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen sizes the app has to survive.
///
/// The landscape entries are the ones that used to be untested, because the
/// app locked itself to portrait at launch.
const Map<String, Size> _viewports = <String, Size>{
  'small phone portrait': Size(320, 568),
  'phone portrait': Size(375, 812),
  'large phone portrait': Size(430, 932),
  'phone landscape': Size(812, 375),
  'small phone landscape': Size(568, 320),
  'tablet portrait': Size(768, 1024),
  'tablet landscape': Size(1024, 768),
};

/// A handful of fake quotes, including some of the Market Board's
/// logo-carrying symbols, so the ticker tape and trending-now strip
/// actually render during the layout sweep below instead of staying empty
/// (no test environment ever completes a real live-price fetch).
List<LiveQuote> _fakeQuotes() {
  final now = DateTime.now();
  const symbols = <(String, String, double, double)>[
    ('AAPL', 'Apple Inc.', 1900.0, 1.8),
    ('TSLA', 'Tesla, Inc.', 2200.0, -2.4),
    ('MSFT', 'Microsoft Corp.', 3600.0, 0.6),
    ('SBUX', 'Starbucks Corp.', 850.0, -0.3),
  ];
  return [
    for (final (symbol, company, price, pct) in symbols)
      LiveQuote(
        symbol: symbol,
        company: company,
        current: price,
        change: price * pct / 100,
        percentChange: pct,
        high: price * 1.02,
        low: price * 0.98,
        open: price * 0.995,
        previousClose: price / (1 + pct / 100),
        fetchedAt: now,
      ),
  ];
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        // Never initialised: the service reads through a nullable client, so
        // an uninitialised Supabase yields signed-out defaults rather than
        // throwing. That is exactly the state we want to lay out.
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
      ChangeNotifierProvider<MarketDataService>(
        create: (_) => MarketDataService()..seedQuotesForTest(_fakeQuotes()),
      ),
      ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
        create: (context) =>
            DailyPlanController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? DailyPlanController(userStats),
      ),
    ],
    child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
  );
}

void main() {
  setUpAll(() {
    // Stop google_fonts reaching for the network during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final unit = lessonUnits.first;
  final readingLesson = unit.lessons.firstWhere(
    (lesson) => lesson.type == LessonNodeType.lesson,
  );
  final quizNode = unit.lessons.firstWhere(
    (lesson) => lesson.type == LessonNodeType.quiz,
  );
  final testNode = lessonUnits[1].lessons.firstWhere(
    (lesson) => lesson.type == LessonNodeType.unitTest,
  );

  LessonDetailScreen detail(Lesson lesson, LessonUnit inUnit) =>
      LessonDetailScreen(
        lesson: lesson,
        unit: inUnit,
        progressionService: ProgressionService(),
      );

  final screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Adventure': () => const MainGamePage(),
    'Arcade': () => const MinigamesPage(),
    'Customize': () => const CustomizeScreen(),
    'Academy': () => const LessonScreen(),
    'Lesson reading': () => detail(readingLesson, unit),
    'Lesson quiz': () => detail(quizNode, unit),
    'Unit test': () => detail(testNode, lessonUnits[1]),
    'Practice': () => PracticeScreen(unit: unit),
    'Personal details sheet': () => Scaffold(
      body: PersonalDetailsSheet(
        initialAgeBand: AgeBand.teen13to15,
        initialGender: GenderIdentity.undisclosed,
        isFirstRun: true,
      ),
    ),
    'Finance Brawl': () => const FinanceBrawlScreen(),
    'Market Board': () => const StockMarketPage(),
    'Feedback': () => const FeedbackScreen(),
    // No map file exists yet, so this exercises the "waiting for the map"
    // fallback screen, not the Bonfire game canvas itself.
    'Adventure (map pending)': () => const AdventureWorldScreen(),
  };

  for (final screenEntry in screens.entries) {
    group(screenEntry.key, () {
      for (final viewport in _viewports.entries) {
        testWidgets('lays out without overflow on ${viewport.key}', (
          tester,
        ) async {
          final errors = <FlutterErrorDetails>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = errors.add;

          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          try {
            await tester.pumpWidget(_wrap(screenEntry.value()));
            await tester.pump(const Duration(milliseconds: 300));
          } finally {
            FlutterError.onError = previousOnError;
          }

          final overflows = errors
              .map((error) => error.exception.toString())
              .where((message) => message.contains('overflowed by'))
              .toList(growable: false);

          expect(
            overflows,
            isEmpty,
            reason:
                '${screenEntry.key} at ${viewport.key} '
                '(${viewport.value.width.toInt()}x${viewport.value.height.toInt()}):\n'
                '${overflows.join('\n')}',
          );
        });
      }
    });
  }
}
