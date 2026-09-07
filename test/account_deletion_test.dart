import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';

/// The account-deletion path.
///
/// This is the one screen in the app that destroys something permanently, and
/// it is offered to players as young as four. So the guard on it is worth a
/// test in a way that most dialogs are not: the failure mode is not a wrong
/// pixel, it is a child losing forty hours of progress to a mis-tap.
///
/// These tests deliberately stop at the point of confirmation and never reach
/// [SupabaseService.deleteOwnAccount] — there is no signed-in session in a
/// test, so the call would return "You are not signed in" without proving
/// anything. What is worth holding is everything *before* the network: that
/// the entry point exists and is reachable, that it says what it destroys,
/// and that it cannot fire by accident.
void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
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

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(wrap(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    // Profile is a lazily-built `ListView` and this link is the last thing
    // on it, so it does not exist in the tree until it is scrolled to --
    // `find.text` on an unbuilt child finds nothing whether the widget is
    // there or not.
    final entry = find.text('Delete my account');
    await tester.scrollUntilVisible(
      entry,
      280,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    expect(
      entry,
      findsOneWidget,
      reason: 'Play requires an in-app deletion route for any app with '
          'accounts, and it has to be reachable without leaving the app',
    );
    // `scrollUntilVisible` stops as soon as the widget is *built*, which is
    // not the same as being on screen -- it can come to rest just past the
    // bottom edge, and the tap then lands on nothing. Profile grew again (the
    // age-scaling panel), which is what surfaced this.
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  testWidgets('the dialog says what is actually destroyed', (tester) async {
    await openDialog(tester);

    // "Your data will be deleted" does not tell a player that their skins and
    // their past lives go with it. If somebody is about to lose a save they
    // should lose it knowing what was in it.
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.textContaining('skin'), findsOneWidget);
    expect(find.textContaining('ending'), findsOneWidget);
    expect(find.textContaining('friends'), findsOneWidget);
  });

  testWidgets('deleting is disabled until the word is typed', (tester) async {
    await openDialog(tester);

    final button = find.widgetWithText(FilledButton, 'Delete forever');
    expect(button, findsOneWidget);
    expect(
      tester.widget<FilledButton>(button).onPressed,
      isNull,
      reason: 'a single tap must not be able to destroy an account',
    );

    // A near miss stays disabled — this is the mis-tap case, and it is the
    // whole reason the confirmation is typed rather than tapped.
    await tester.enterText(find.byType(TextField), 'delet');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('lowercase counts, because the word is not a puzzle', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextField), '  delete  ');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Delete forever'),
          )
          .onPressed,
      isNotNull,
      reason: 'the word exists so it cannot be typed by accident, and that '
          'survives case perfectly well',
    );
  });

  testWidgets('backing out leaves the account alone', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('Keep my account'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    // Still on Profile, still signed in as far as the screen is concerned.
    expect(find.text('Delete my account'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('the Notifications toggle is gone, not lying', (tester) async {
    await tester.pumpWidget(wrap(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    // It used to promise "Quest reminders and reward alerts" and control
    // nothing at all — no notification package is wired up. In an app whose
    // argument is "check what we tell you", a setting that lies is not a
    // small thing. If it comes back it has to come back working.
    expect(find.text('Notifications'), findsNothing);
    expect(find.textContaining('Quest reminders'), findsNothing);
  });
}
