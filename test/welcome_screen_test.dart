import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart';
import 'package:budget_app/screens_minigames_admin_etc/onboarding/welcome_screen.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The guest entry point on the very first screen the app shows.
///
/// This is the one path in the whole guest-mode feature where getting it
/// wrong is invisible until a real player hits it: a broken navigation here
/// means the "Just Looking?" button looks fine, does nothing (or crashes),
/// and there is no error toast to point at -- the player is just stuck on
/// Welcome.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    // `SupabaseService.instance` outlives any one test.
    await SupabaseService.instance.setLocalGuestMode(false);
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
      ChangeNotifierProvider<MarketDataService>(
        create: (_) => MarketDataService(),
      ),
      ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
        create: (context) =>
            DailyPlanController(context.read<UserStatsController>()),
        update: (_, stats, previous) => previous ?? DailyPlanController(stats),
      ),
      ChangeNotifierProxyProvider<UserStatsController, MoneyHabitController>(
        create: (context) =>
            MoneyHabitController(context.read<UserStatsController>()),
        update: (_, stats, previous) => previous ?? MoneyHabitController(stats),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      home: child,
    ),
  );

  testWidgets('the guest control is present alongside sign-up and login', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Join the Squad'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Just Looking? Play as a Guest'), findsOneWidget);
  });

  testWidgets(
    'tapping guest, then Continue on the terms sheet, reaches the dashboard',
    (tester) async {
      // `WelcomeScreen`'s background float animation repeats forever, so
      // `pumpAndSettle` would never return -- every wait here is a bounded
      // `pump` instead, sized to the modal sheet's and `FadePageRoute`'s own
      // (non-repeating) transitions.
      await tester.pumpWidget(wrap(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Just Looking? Play as a Guest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // The one-time acknowledgment sheet, not a full sign-up form.
      expect(find.text('Playing as a guest'), findsOneWidget);
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byType(DashboardShell),
        findsOneWidget,
        reason: 'accepting the guest terms has to actually land in the app, '
            'not leave the player stuck on a closed sheet',
      );
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(
        SupabaseService.instance.isLocalGuest,
        isTrue,
        reason: 'the whole point of the button is to set this flag',
      );
    },
  );

  testWidgets('backing out of the terms sheet leaves Welcome untouched', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Just Looking? Play as a Guest'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Dismiss the sheet without tapping Continue, by tapping the modal
    // barrier above it rather than the sheet's own content.
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(DashboardShell), findsNothing);
    expect(SupabaseService.instance.isLocalGuest, isFalse);
  });
}
