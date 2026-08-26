import 'package:budget_app/models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import 'package:budget_app/navigation_tools_and_animation/app_tab_index.dart';
import 'package:budget_app/screens_minigames_admin_etc/onboarding/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guided tour is the first thing a new player sees, and it is a pure
/// presentation surface with no backend — which makes it both easy to break
/// silently and easy to cover properly.
void main() {
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
}
