import 'dart:io';

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

  group('a guest has never signed in, so the bottom of Profile is different', () {
    // A guest has no `auth.users` row and no session -- offering "Log Out"
    // would either do nothing or, worse, look like it is doing something.
    // And "Delete my account" implies there is a server-side account to
    // delete, which for a guest there is not. Both have to be replaced, not
    // just hidden.
    setUp(() async {
      await SupabaseService.instance.setLocalGuestMode(true);
    });

    tearDown(() async {
      // `SupabaseService.instance` outlives this test group.
      await SupabaseService.instance.setLocalGuestMode(false);
    });

    testWidgets(
      'offers creating an account and erasing local data instead',
      (tester) async {
        await tester.pumpWidget(wrap(const ProfileScreen()));
        await tester.pump(const Duration(milliseconds: 400));

        // Scroll to the lower of the two guest-only entries -- scrolling
        // just far enough for the upper one can leave this one sitting past
        // the bottom edge, unbuilt, the same trap `openDialog` above already
        // has to work around.
        final eraseEntry = find.text('Erase local data and start over');
        await tester.scrollUntilVisible(
          eraseEntry,
          280,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 60,
        );
        await tester.ensureVisible(eraseEntry);
        await tester.pumpAndSettle();

        expect(find.text('Create an Account'), findsOneWidget);
        expect(eraseEntry, findsOneWidget);
        expect(
          find.text('Log Out'),
          findsNothing,
          reason: 'a guest has no session to sign out of',
        );
        expect(
          find.text('Delete my account'),
          findsNothing,
          reason: 'a guest has no server-side account to delete',
        );
      },
    );

    testWidgets('erasing is disabled until the word is typed', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ProfileScreen()));
      await tester.pump(const Duration(milliseconds: 400));

      final entry = find.text('Erase local data and start over');
      await tester.scrollUntilVisible(
        entry,
        280,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, 'Erase and start over');
      expect(button, findsOneWidget);
      expect(
        tester.widget<FilledButton>(button).onPressed,
        isNull,
        reason: 'a single tap must not be able to wipe local progress',
      );

      await tester.enterText(find.byType(TextField), 'RESET');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });
  });

  group('the delete_own_account() SQL function', () {
    // **The bugs this exists to prevent, both of which had already
    // happened, back to back.**
    //
    // Bug 1: `user_stats`'s only identity column is `id` -- it has never
    // had a `user_id` column. The function's cleanup line read `where
    // user_id = uid`, which Postgres rejects with `42703 undefined_column`
    // the moment the function runs, so every deletion attempt failed.
    //
    // Bug 2, found only after fixing bug 1: `user_stats.id` and
    // `app_feedback.user_id` are both `text` (the app stores non-uuid ids
    // like the local guest placeholder `'user_123'` there too), while `uid`
    // is declared `uuid`. Postgres has no `text = uuid` operator, so `where
    // id = uid` still throws -- `42883 operator does not exist` instead of
    // `42703` -- and the account is still not deleted.
    //
    // Both times, the client-side error handling made the real cause harder
    // to see: it pattern-matched the raw error text for
    // `'delete_own_account'`, which appears in the CONTEXT line of *any*
    // error thrown inside this function, so a completely different failure
    // kept getting reported as "account deletion is not set up on the
    // server".
    //
    // This is a source check, not a database test, because the migration is
    // run by hand in the Supabase SQL editor and a wrong column name or type
    // mismatch is silent until a real user taps delete.
    final sql = File(
      'supabase/migrations/0003_account_deletion.sql',
    ).readAsStringSync();

    test('deletes user_stats and app_feedback by their real, text-typed ids', () {
      expect(
        sql.contains('delete from public.user_stats where id = uid::text'),
        isTrue,
        reason: 'user_stats.id is text, not uuid -- comparing it to uid '
            'without a cast throws 42883 operator does not exist',
      );
      expect(
        sql.contains('delete from public.app_feedback where user_id = uid::text'),
        isTrue,
        reason: 'app_feedback.user_id is text too, and has the same '
            'text = uuid mismatch if left uncast',
      );
      expect(
        sql.contains('user_stats where user_id'),
        isFalse,
        reason: 'this is the first bug that shipped: deleting by a column '
            'user_stats does not have',
      );
    });
  });
}
