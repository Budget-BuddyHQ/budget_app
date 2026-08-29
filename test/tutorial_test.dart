import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import 'package:budget_app/navigation_tools_and_animation/main_navigation.dart';
import 'package:budget_app/screens_minigames_admin_etc/onboarding/coach_mark.dart';
import 'package:budget_app/widgets_custom_lotties/pixel_kit.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:budget_app/navigation_tools_and_animation/app_tab_index.dart';
import 'package:budget_app/screens_minigames_admin_etc/onboarding/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// The guided tour is the first thing a new player sees, and it is a pure
/// presentation surface with no backend — which makes it both easy to break
/// silently and easy to cover properly.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('tutorial content', () {
    test('step ids are unique', () {
      // Ids are the stable key for logging/persistence; a duplicate would
      // make two different steps indistinguishable after the fact.
      final ids = kTutorialSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('covers every feature a new player has to find', () {
      // The tour existing is not the same as the tour being complete. These
      // are the surfaces the app actually ships; if one is added and not
      // introduced anywhere, this is the reminder.
      final ids = kTutorialSteps.map((s) => s.id).toSet();
      expect(
        ids,
        containsAll(<String>[
          'home',
          'life',
          'arcade',
          'market_board',
          'learn',
          'daily',
          'style',
          'leaderboard',
          'profile',
        ]),
      );
    });

    test('opens and closes on a mascot greeting', () {
      expect(kTutorialSteps.first.mascot, TutorialMascot.wave);
      expect(kTutorialSteps.last.mascot, TutorialMascot.wave);
    });

    test('every step has usable copy', () {
      for (final step in kTutorialSteps) {
        expect(step.title, isNotEmpty, reason: '${step.id} has no title');
        expect(step.tagline, isNotEmpty, reason: '${step.id} has no tagline');
        expect(step.teaches, isNotEmpty, reason: '${step.id} has no teaches');
        expect(
          step.bullets,
          isNotEmpty,
          reason: '${step.id} has no bullets — a step with nothing to do on '
              'it is a step that should be merged away',
        );
        for (final bullet in step.bullets) {
          expect(bullet, isNotEmpty, reason: '${step.id} has an empty bullet');
        }
      }
    });

    test('jump targets are real tabs', () {
      // An out-of-range index here would land the player on a blank
      // IndexedStack slot rather than the feature they just read about.
      for (final step in kTutorialSteps) {
        final tab = step.jumpTab;
        if (tab == null) continue;
        expect(
          tab,
          allOf(greaterThanOrEqualTo(0), lessThan(AppTabIndex.count)),
          reason: '${step.id} jumps to tab $tab, which does not exist',
        );
      }
    });

    test('every mascot pose resolves to an asset path', () {
      for (final pose in TutorialMascot.values) {
        expect(pose.asset, contains('turtle_mentor'));
      }
    });
  });

  group('TutorialScreen', () {
    /// Wraps a tour in a phone-sized app with animations disabled.
    ///
    /// `disableAnimations` is load-bearing, not tidiness: the mascot rides an
    /// `IdleHoverIcon`, whose idle bob is a `repeat()`ing controller that
    /// never completes, so `pumpAndSettle` times out without it. Setting the
    /// flag both makes the tour testable and exercises the reduce-motion
    /// path the widget already honours.
    Widget tourApp(Widget home) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: home),
    );

    /// Pumps the tour on a phone-sized surface. Deliberately not wrapped in
    /// the app's providers: the screen reads none of them, and proving that
    /// keeps it replayable from anywhere.
    Future<void> pumpTour(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(tourApp(const TutorialScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the first step', (tester) async {
      await pumpTour(tester);
      expect(find.text(kTutorialSteps.first.title), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Continue advances to the next step', (tester) async {
      await pumpTour(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text(kTutorialSteps[1].title), findsOneWidget);
    });

    testWidgets('walks the whole tour and finishes', (tester) async {
      await pumpTour(tester);

      for (var i = 0; i < kTutorialSteps.length - 1; i++) {
        expect(
          find.text(kTutorialSteps[i].title),
          findsOneWidget,
          reason: 'expected to be on step ${kTutorialSteps[i].id}',
        );
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Last step swaps the label rather than adding a second button, so
      // there is never an ambiguous "which one ends it" moment.
      expect(find.text('Start playing'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('every step renders without overflowing a phone', (
      tester,
    ) async {
      // This app has shipped overflow bugs in exactly this shape before
      // (a panel that fit at one width and clipped at another), and the
      // tour has more text per screen than anything else in the app.
      await pumpTour(tester);
      for (var i = 0; i < kTutorialSteps.length; i++) {
        expect(tester.takeException(), isNull, reason: 'overflow on step $i');
        if (i == kTutorialSteps.length - 1) break;
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Back returns to the previous step', (tester) async {
      await pumpTour(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text(kTutorialSteps[1].title), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text(kTutorialSteps.first.title), findsOneWidget);
    });

    testWidgets('Skip pops the tour with no jump target', (tester) async {
      int? result;
      var popped = false;

      await tester.pumpWidget(
        tourApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<int>(
                      MaterialPageRoute(builder: (_) => const TutorialScreen()),
                    );
                    popped = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(result, isNull);
    });

    testWidgets('"Take me there" returns the step\'s tab index', (
      tester,
    ) async {
      int? result;

      await tester.pumpWidget(
        tourApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<int>(
                      MaterialPageRoute(builder: (_) => const TutorialScreen()),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Step 2 is Home, the first step carrying a jump target.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final home = kTutorialSteps.firstWhere((s) => s.id == 'home');
      await tester.tap(find.text('Take me to ${home.title}'));
      await tester.pumpAndSettle();

      expect(result, home.jumpTab);
      expect(result, AppTabIndex.dashboard);
    });
  });

  group('the tour runs over the live app', () {
    // The point of the rewrite: the tour is a layer on top of `MainNavigation`
    // rather than a route pushed over it. A route replaces the app with a
    // description of the app, so a player who read all eleven pages still had
    // to go and find everything afterwards. These check the properties that
    // distinguish the two.

    /// Pumps until the overlay has finished settling on a step.
    ///
    /// [CoachMarkOverlay] deliberately waits ~220ms after a tab switch before
    /// it measures its target — reading geometry in the same frame gets the
    /// *previous* screen's rectangle. Under fake async that wait is a real
    /// pending timer, so a test that stops pumping too early tears the tree
    /// down with a timer outstanding and fails on the invariant rather than
    /// on anything it was checking.
    Future<void> settleTour(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Widget shell() => MediaQuery(
      data: const MediaQueryData(
        disableAnimations: true,
        size: Size(393, 852),
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatsController>(
            create: (_) =>
                UserStatsController(service: SupabaseService.instance),
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
            update: (_, stats, previous) =>
                previous ?? DailyPlanController(stats),
          ),
          ChangeNotifierProxyProvider<
            UserStatsController,
            MoneyHabitController
          >(
            create: (context) =>
                MoneyHabitController(context.read<UserStatsController>()),
            update: (_, stats, previous) =>
                previous ?? MoneyHabitController(stats),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(),
          home: const MainNavigation(),
        ),
      ),
    );

    testWidgets('a replay request opens the coach marks in place', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(shell());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CoachMarkOverlay), findsNothing);

      // Profile cannot start the tour itself — it is a screen *inside* the
      // shell that draws it — so it raises a flag on the settings controller
      // and the shell picks it up. This is that handshake.
      final settings = tester
          .element(find.byType(MainNavigation))
          .read<AppSettingsController>();
      settings.requestTutorialReplay();
      await settleTour(tester);

      expect(find.byType(CoachMarkOverlay), findsOneWidget);

      // The app is still there underneath. That is the difference from the
      // pushed deck, and it is what makes the spotlight mean anything.
      expect(find.byType(IndexedStack), findsWidgets);
    });

    testWidgets('stepping through switches the tab underneath', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(shell());
      await tester.pump(const Duration(milliseconds: 300));

      final element = tester.element(find.byType(MainNavigation));
      element.read<AppSettingsController>().requestTutorialReplay();
      await settleTour(tester);

      int visibleTab() =>
          tester
              .widgetList<IndexedStack>(find.byType(IndexedStack))
              .first
              .index ??
          -1;

      final before = visibleTab();

      // Walk to a step that names a different tab. Advancing settles for
      // 220ms inside the overlay before it measures, so each step needs a
      // pump past that.
      var moved = false;
      for (var i = 0; i < kTutorialSteps.length - 1 && !moved; i++) {
        await tester.tap(find.text('Next'));
        await settleTour(tester);
        moved = visibleTab() != before;
      }

      expect(
        moved,
        isTrue,
        reason:
            'no step in the tour ever changed the visible tab — the tour is '
            'describing screens instead of taking the player to them',
      );
    });

    testWidgets('skipping closes the tour and leaves the app usable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(shell());
      await tester.pump(const Duration(milliseconds: 300));

      final element = tester.element(find.byType(MainNavigation));
      element.read<AppSettingsController>().requestTutorialReplay();
      await settleTour(tester);
      expect(find.byType(CoachMarkOverlay), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await settleTour(tester);

      expect(find.byType(CoachMarkOverlay), findsNothing);
      expect(find.byType(MainNavigation), findsOneWidget);
    });
  });

  group('the coach card is sized for the screen', () {
    // The card is a speech bubble, not a banner. Stretched edge to edge it
    // read as a quarter of a desktop window filled with panel around three
    // words of copy — covering the app it was pointing at.
    Widget card(Size size) => MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(
          body: CoachMarkOverlay(
            steps: kTutorialSteps,
            onFinished: () {},
            onWantTab: (_) async {},
          ),
        ),
      ),
    );

    Future<double> cardWidth(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(card(size));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final width = tester.getSize(find.byType(PixelFrame).first).width;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      return width;
    }

    testWidgets('never spans a wide window', (tester) async {
      // Stated as a *proportion*, not a pixel count. The card's width is
      // derived from the viewport now, so a test pinned to the old 460px cap
      // would fail the next time that fraction is tuned — while saying
      // nothing about the property that matters, which is that a line of copy
      // never gets too long to scan.
      const size = Size(1440, 900);
      final width = await cardWidth(tester, size);
      expect(
        width / size.width,
        lessThan(0.4),
        reason: 'the card takes ${(width / size.width * 100).round()}% of a '
            '1440px window',
      );
      expect(width, lessThanOrEqualTo(540));
    });

    testWidgets('still uses the room a phone has', (tester) async {
      // The other end of the same property: a proportional width must not
      // leave a phone with a thin column. 34% of 375px is 127px, which is
      // why the floor exists.
      const size = Size(375, 812);
      final width = await cardWidth(tester, size);
      expect(
        width / size.width,
        greaterThan(0.7),
        reason: 'the card uses only ${(width / size.width * 100).round()}% of '
            'a 375px phone, wasting the only space there is',
      );
      expect(width, lessThanOrEqualTo(size.width));
    });

    testWidgets('scales between the two rather than jumping', (tester) async {
      // The point of deriving placement from the viewport: a tablet should
      // land between a phone and a desktop, not snap to one of them.
      final phone = await cardWidth(tester, const Size(375, 812));
      final tablet = await cardWidth(tester, const Size(834, 1112));
      final desktop = await cardWidth(tester, const Size(1440, 900));
      expect(phone, lessThan(tablet));
      expect(tablet, lessThanOrEqualTo(desktop));
    });

    testWidgets('shrinks its contents on the smallest phones', (tester) async {
      // Capping the width is not enough on a 320px screen: the mascot and
      // type have to come down too, or the card is still half the viewport.
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(card(const Size(320, 568)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final small = tester.getSize(find.byType(PixelFrame).first).height;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));

      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(card(const Size(768, 1024)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final large = tester.getSize(find.byType(PixelFrame).first).height;

      expect(
        small,
        lessThan(large),
        reason: 'the card is the same height on a 320px phone as on a tablet',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('the card sits next to what it points at', () {
    // The failure this guards: on a desktop window the card was pinned to the
    // top edge while the spotlight was 700px lower down, so the explanation
    // and the thing it explained stopped reading as one instruction.
    testWidgets('the card follows the spotlight down the screen', (
      tester,
    ) async {
      const size = Size(1440, 900);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: size, disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: CoachMarkOverlay(
                steps: kTutorialSteps,
                onFinished: () {},
                // Every step names a tab, so the overlay falls back to the
                // bottom bar's geometry — near the bottom of a 900px window.
                onWantTab: (_) async {},
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      final card = tester.getRect(find.byType(PixelFrame).first);
      expect(
        card.top,
        greaterThan(200),
        reason: 'the card is pinned near the top of a 900px window while the '
            'spotlight is on the bottom bar',
      );
      expect(
        card.bottom,
        lessThanOrEqualTo(size.height),
        reason: 'the card runs off the bottom of the screen',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('the card never covers what it points at', () {
    // The bug this locks down. The card used to be placed by a `Positioned`
    // whose `top` was computed from an *estimate* of the card's height —
    // `190 * scale`, a constant standing in for something that varies with
    // how the copy wraps, whether a Back button is showing, and the reader's
    // text scale. Whenever the real card was taller than the guess, the
    // maths meant to keep it clear of the spotlight put it straight over the
    // spotlight, and the clamp meant to keep it on screen let it hang off the
    // bottom. Both are invisible to a test that only asks "did it render".
    //
    // It is a layout delegate now, which is handed the child's measured size
    // before it has to say where the child goes. These are the two promises
    // that becomes: fully on screen, and never on top of the target.
    const viewports = <String, Size>{
      'small phone': Size(320, 568),
      'phone': Size(375, 812),
      'landscape phone': Size(812, 375),
      'tablet': Size(768, 1024),
      'desktop': Size(1440, 900),
      // Deliberately cramped: at this height the card and the bottom bar are
      // competing for the same room, which is where an estimate goes wrong.
      'short window': Size(900, 420),
    };

    for (final viewport in viewports.entries) {
      testWidgets('on ${viewport.key}', (tester) async {
        tester.view.physicalSize = viewport.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: viewport.value,
              disableAnimations: true,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: CoachMarkOverlay(
                  steps: kTutorialSteps,
                  onFinished: () {},
                  onWantTab: (_) async {},
                ),
              ),
            ),
          ),
        );

        for (var step = 0; step < kTutorialSteps.length; step++) {
          for (var i = 0; i < 3; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }

          final card = tester.getRect(find.byType(PixelFrame).first);
          final where = '${viewport.key}, step $step';

          expect(card.top, greaterThanOrEqualTo(-0.5), reason: 'off the top: $where');
          expect(
            card.bottom,
            lessThanOrEqualTo(viewport.value.height + 0.5),
            reason: 'off the bottom: $where',
          );
          expect(card.left, greaterThanOrEqualTo(-0.5), reason: 'off the left: $where');
          expect(
            card.right,
            lessThanOrEqualTo(viewport.value.width + 0.5),
            reason: 'off the right: $where',
          );

          // Every step in the tour names a tab, so the spotlight falls back
          // to the bottom bar's own geometry — the widest, lowest target the
          // tour ever points at, and the one the card most often collided
          // with.
          final spotlight = TutorialTargets.navTabRect(
            tester.element(find.byType(CoachMarkOverlay)),
            0,
          );
          final band = Rect.fromLTRB(
            0,
            spotlight.top,
            viewport.value.width,
            spotlight.bottom,
          );
          expect(
            card.overlaps(band.deflate(1)),
            isFalse,
            reason: 'the card sits on top of the bottom bar it is '
                'describing: $where',
          );

          if (step < kTutorialSteps.length - 1) {
            await tester.tap(find.text('Next').first, warnIfMissed: false);
          }
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      });
    }
  });

  group('the coach card fits every phone', () {
    // This is where a real "random red error" lived: on a 393px phone, once
    // the Back button appeared, the card's footer overflowed by 39px. It only
    // showed from the second step onward and only on narrower devices, which
    // is exactly the kind of fault that reaches a user as a red flash they
    // cannot screenshot.
    //
    // So this walks the whole tour at every viewport rather than sampling a
    // step: the copy length varies per step, the failure was a sum of widths,
    // and Back only exists from the second step onward.
    const viewports = <String, Size>{
      'small phone': Size(320, 568),
      'phone': Size(375, 812),
      'mid phone': Size(393, 852),
      'large phone': Size(430, 932),
      'phone landscape': Size(812, 375),
      'tablet': Size(768, 1024),
      // The desktop window the tour was first seen misbehaving in: a card
      // pinned 14px from each edge became a 930px banner across the top.
      'desktop window': Size(957, 742),
      'wide desktop': Size(1440, 900),
    };

    for (final viewport in viewports.entries) {
      testWidgets('no overflow on ${viewport.key}', (tester) async {
        tester.view.physicalSize = viewport.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Collect, do not assert, while the handler is overridden. Calling
        // `expect` before restoring `FlutterError.onError` trips an assertion
        // inside the binding itself, and the resulting failure describes the
        // test harness rather than the layout — which is not a useful thing
        // to be told when a card overflows.
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) =>
            errors.add(details.exceptionAsString());

        var finished = false;
        var reached = 0;
        try {
          await tester.pumpWidget(
            MediaQuery(
              // The size has to be stated. Overriding MediaQuery without one
              // hands the overlay `Size.zero`, and it positions its card from
              // `media.size` — so the card lands nowhere and the test fails
              // looking for a button rather than reporting a layout problem.
              data: MediaQueryData(
                size: viewport.value,
                disableAnimations: true,
              ),
              child: MaterialApp(
                home: Scaffold(
                  body: CoachMarkOverlay(
                    steps: kTutorialSteps,
                    onFinished: () => finished = true,
                    onWantTab: (_) async {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          for (var step = 0; step < kTutorialSteps.length; step++) {
            reached = step + 1;
            final last = step == kTutorialSteps.length - 1;
            await tester.tap(find.text(last ? 'Done' : 'Next'));
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pump(const Duration(milliseconds: 300));
          }

          // Drain the settle timer before the tree goes away.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 300));
        } finally {
          FlutterError.onError = previous;
        }

        expect(
          errors,
          isEmpty,
          reason:
              'the coach card broke on ${viewport.key} by step $reached: '
              '${errors.join('; ')}',
        );
        expect(finished, isTrue, reason: 'the tour never reached its end');
      });
    }
  });
}
