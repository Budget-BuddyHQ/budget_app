import 'dart:io';
import 'dart:ui' as ui;

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/outing_rules.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';
import 'support/fixed_random.dart';
import 'support/life_fixtures.dart';

/// The Life page as a player meets it: five tabs, four stat bars, a header with
/// net worth, and a pop-up when a decision comes.
///
/// **Asked for as:** the BitLife layout, *"Occupation, Assets, Relationships,
/// Activities and a big Age button; four stat bars; and pop-up decision cards
/// with a Surprise Me button."* Each tab is opened by tapping its label in the
/// real bottom bar, so this exercises the real route and not a sheet built by
/// hand.
void main() {
  const outDir = 'build/screens';

  setUpAll(() async {
    await loadAppFonts();
    Directory(outDir).createSync(recursive: true);
  });

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      home: child,
    ),
  );

  final shotKey = GlobalKey();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final layer =
          shotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await layer.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> show(
    WidgetTester tester,
    LifeSimController life, {
    Size size = const Size(393, 852),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: wrap(LifeSimPage(debugInitialLife: life)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  LifeSimController adult({int money = 400}) => LifeSimController(
    random: FixedRandom.unlucky(),
    name: 'Alex Morgan',
    initialAge: 30,
    startMoney: money,
    startJob: 'Barista',
    startSalary: 400,
  );

  group('the page', () {
    testWidgets('has the five tabs, and the Age button in the middle', (
      tester,
    ) async {
      await show(tester, adult());
      for (final label in const [
        'Occupation',
        'Assets',
        'People',
        'Activities',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await shoot(tester, 'life_page');
    });

    testWidgets('always shows the four stat bars', (tester) async {
      await show(tester, adult());
      for (final label in const ['Happiness', 'Health', 'Smarts', 'Looks']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('a student\'s first tab says School', (tester) async {
      final kid = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 8,
      );
      await show(tester, kid);
      expect(find.text('School'), findsWidgets);
      expect(find.text('Occupation'), findsNothing);
    });

    testWidgets('the header shows net worth and not just cash', (tester) async {
      final life = adult(money: 100)..depositSavings(60);
      await show(tester, life);
      expect(find.text('net worth'), findsOneWidget);
      expect(find.text('coins'), findsNothing);
    });

    testWidgets('holds at 320 wide', (tester) async {
      await show(tester, adult(), size: const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    // Asked for as: the Life menu is "hard to navigate... unlike Finance
    // Brawl." The "This year" card was a full panel — weather, family, and
    // a consequence box — shown at full size on every single year, whether
    // or not any of it was worth a second look. Most years nothing is.
    testWidgets(
      'the "this year" card is one line when nothing stops you going out',
      (tester) async {
        final life = adult();
        expect(life.outingPermission.allowed, isTrue);
        await show(tester, life);
        // The full card's own heading and boxed explanation are gone...
        expect(find.text('This year'), findsNothing);
        expect(
          find.text('You can head into town whenever you like.'),
          findsNothing,
        );
        // ...and the facts it held are still on screen, just compact.
        expect(find.text(life.weather.label), findsOneWidget);
        expect(find.text(life.strictness.label), findsOneWidget);
      },
    );

    testWidgets(
      'and is the full card, with why, when you actually cannot go out',
      (tester) async {
        final child = LifeSimController(
          random: FixedRandom.unlucky(),
          initialAge: 6,
        );
        expect(child.outingPermission.allowed, isFalse);
        await show(tester, child);
        expect(find.text('This year'), findsOneWidget);
        expect(find.text(child.outingPermission.message), findsOneWidget);
      },
    );
  });

  group('the tabs open real screens', () {
    testWidgets('Occupation shows the job and what to do about it', (
      tester,
    ) async {
      await show(tester, adult());
      await tab(tester, 'Occupation');
      expect(find.text('Barista'), findsWidgets);
      expect(find.text('Work harder'), findsOneWidget);
      expect(find.text('Ask for a raise'), findsOneWidget);
      expect(find.text('Look for a better job'), findsOneWidget);
      // Below the fold, so it has to be scrolled to.
      await tester.scrollUntilVisible(
        find.text('Resign'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Resign'), findsOneWidget);
    });

    testWidgets('Occupation for a child is about school', (tester) async {
      final kid = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 8,
      );
      await show(tester, kid);
      await tab(tester, 'School');
      expect(find.text('Grades'), findsOneWidget);
      expect(find.textContaining('too young for work'), findsNothing);
    });

    testWidgets('Assets shows net worth, where you live and the shop', (
      tester,
    ) async {
      await show(tester, adult());
      await tab(tester, 'Assets');
      expect(find.text('Net worth'), findsWidgets);
      expect(find.text('Where you live'), findsOneWidget);
      expect(find.text('Browse and buy'), findsOneWidget);
      expect(find.text('Move money'), findsOneWidget);
    });

    testWidgets('People has a bar for each person', (tester) async {
      final life = adult()
        ..debugAddPerson('Sam Reyes', closeness: 60)
        ..debugAddPerson('Kim Park', closeness: 30);
      await show(tester, life);
      await tab(tester, 'People');
      // Also drawn as chips in the feed behind the sheet, so more than one.
      expect(find.text('Sam Reyes'), findsWidgets);
      expect(find.text('Kim Park'), findsWidgets);
      // Two friends, and a bar under each.
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.text('Good'), findsWidgets);
    });

    testWidgets('Activities is a grid of categories', (tester) async {
      await show(tester, adult());
      await tab(tester, 'Activities');
      for (final label in const [
        'Mind and body',
        'Friends and community',
        'Love and dating',
        'Travel and fun',
        'Learning',
        'Sport',
        'Special careers',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });
  });

  group('doing things', () {
    testWidgets('an activity can be done from its category', (tester) async {
      final life = adult();
      await show(tester, life);
      await tab(tester, 'Activities');
      await tester.tap(find.text('Mind and body'));
      await tester.pumpAndSettle();
      final before = life.health;
      await tester.tap(find.text('Eat well for a while'));
      await tester.pumpAndSettle();
      expect(life.health, before + 5);
    });

    // Asked for as: *"remove things that can be done in the open world from the
    // menu, like hiking, meditation and going outside."* The catalogue still
    // holds them, at a place; the menu lists what has none.
    testWidgets('what belongs to the town is not in the menu, and it says so', (
      tester,
    ) async {
      await show(tester, adult());
      await tab(tester, 'Activities');
      await tester.tap(find.text('Mind and body'));
      await tester.pumpAndSettle();
      for (final gone in const [
        'Go for a run',
        'Go for a hike',
        'Meditate',
        'Stretch and breathe',
        'Read a good book',
        'Go to the gym',
      ]) {
        expect(find.text(gone), findsNothing, reason: '$gone is still listed');
      }
      // Somebody who goes looking is told where it went, not left with a gap.
      expect(
        find.byKey(const ValueKey('activities-town-note')),
        findsOneWidget,
      );
      expect(find.textContaining('done in town'), findsOneWidget);
    });

    // A player at 15 health is "too unwell to leave the house", which is the
    // moment a doctor is needed. A clinic they may not walk to would be a trap.
    testWidgets('somebody too unwell to go out can still see a doctor', (
      tester,
    ) async {
      final life = adult()..debugSetStats(health: 10);
      expect(life.outingPermission.allowed, isFalse);
      await show(tester, life);
      await tab(tester, 'Activities');
      await tester.tap(find.text('Mind and body'));
      await tester.pumpAndSettle();
      expect(find.text('See the doctor'), findsOneWidget);
      final before = life.health;
      await tester.tap(find.text('See the doctor'));
      await tester.pumpAndSettle();
      expect(life.health, greaterThan(before));
    });

    // It used to send somebody well enough to go out to the clinic on the map,
    // and only the map. Reported as a younger tester "couldn't find where the
    // doctor was on the menu": a sick player looks for a doctor in the menu.
    // The clinic in town still does a check-up too.
    testWidgets('and somebody well enough to go out finds one in the menu', (
      tester,
    ) async {
      final life = adult();
      expect(life.outingPermission.allowed, isTrue);
      await show(tester, life);
      await tab(tester, 'Activities');
      await tester.tap(find.text('Mind and body'));
      await tester.pumpAndSettle();
      expect(find.text('See the doctor'), findsOneWidget);
    });

    testWidgets('a person can be talked to, and the bar moves', (tester) async {
      final life = adult()..debugAddPerson('Sam Reyes', closeness: 40);
      await show(tester, life);
      await tab(tester, 'People');
      await tester.tap(find.text('Sam Reyes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Have a conversation'));
      await tester.pumpAndSettle();
      expect(life.personByName('Sam Reyes')!.closeness, 46);
    });

    testWidgets('the job board shows what each job needs', (tester) async {
      await show(tester, adult());
      await tab(tester, 'Occupation');
      await tester.tap(find.text('Look for a better job'));
      await tester.pumpAndSettle();
      expect(find.text('Job board'), findsOneWidget);
      expect(find.text('Line of work'), findsOneWidget);
      expect(find.textContaining('Odds:'), findsWidgets);
    });

    testWidgets('a locked job says what is in the way', (tester) async {
      await show(tester, adult());
      await tab(tester, 'Occupation');
      await tester.tap(find.text('Look for a better job'));
      await tester.pumpAndSettle();
      // Not `scrollUntilVisible`: it requires its finder to resolve to a
      // single element at every step along the way, and a growing job
      // catalogue means more than one row can say "bachelor's degree" at
      // once by the time scrolling gets there.
      final jobList = find.byType(Scrollable).last;
      for (var i = 0; i < 20; i++) {
        if (find.textContaining("bachelor's degree").evaluate().isNotEmpty) {
          break;
        }
        await tester.drag(jobList, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining("bachelor's degree"), findsWidgets);
    });
  });

  group('the debt row', () {
    LifeSimController owing({required int cash}) {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 30,
        startMoney: 400,
        startJob: 'Barista',
        startSalary: 1000,
      );
      life.applyShock(600, 'Boiler');
      life.debugSetStats(money: cash);
      return life;
    }

    testWidgets('is not there when nothing is owed', (tester) async {
      await show(tester, adult());
      await tab(tester, 'Assets');
      expect(find.text('Pay back what you owe'), findsNothing);
    });

    testWidgets('appears with the debt and what it costs', (tester) async {
      final life = owing(cash: 300);
      expect(life.debt, 200);
      await show(tester, life);
      await tab(tester, 'Assets');
      expect(find.text('Pay back what you owe'), findsOneWidget);
      expect(find.textContaining('You owe 200'), findsOneWidget);
      expect(find.textContaining('about 36 a year'), findsOneWidget);
    });

    testWidgets('pays the debt when pressed', (tester) async {
      final life = owing(cash: 300);
      await show(tester, life);
      await tab(tester, 'Assets');
      await tester.tap(find.text('Pay back what you owe'));
      await tester.pumpAndSettle();
      expect(life.debt, 0);
      expect(life.money, 100);
    });

    testWidgets('says why when there is nothing to pay it with', (
      tester,
    ) async {
      final life = owing(cash: 0);
      await show(tester, life);
      await tab(tester, 'Assets');
      expect(find.text('Cash and savings are both empty'), findsOneWidget);
      await tester.tap(find.text('Pay back what you owe'));
      await tester.pumpAndSettle();
      expect(life.debt, 200, reason: 'a greyed row must do nothing');
    });

    for (final size in const <Size>[Size(320, 568), Size(360, 640)]) {
      testWidgets('fits on a ${size.width.toInt()}-wide phone', (tester) async {
        await show(tester, owing(cash: 300), size: size);
        await tab(tester, 'Assets');
        expect(tester.takeException(), isNull);
        expect(find.text('Pay back what you owe'), findsOneWidget);
      });
    }
  });

  group('the decision pop-up', () {
    const card = LifeEvent(
      id: 'test_card',
      prompt: 'A friend asks you to lend them some money.',
      icon: Icons.handshake_rounded,
      choices: [
        LifeChoice(label: 'Lend it', outcome: 'You lent it.', money: -100),
        LifeChoice(label: 'Say no', outcome: 'You said no.', happiness: -2),
        LifeChoice(label: 'Give less', outcome: 'You gave less.', money: -30),
      ],
    );

    LifeSimController withCard() {
      final life = adult(money: 500);
      life.debugSetEvent(card);
      return life;
    }

    testWidgets('appears by itself, with the choices and a Surprise me', (
      tester,
    ) async {
      await show(tester, withCard());
      expect(
        find.text('A friend asks you to lend them some money.'),
        findsOneWidget,
      );
      expect(find.text('Lend it'), findsOneWidget);
      expect(find.text('Say no'), findsOneWidget);
      expect(find.text('Give less'), findsOneWidget);
      expect(find.text('Surprise me!'), findsOneWidget);
      // Let the pop-up finish appearing before it is photographed.
      await tester.pump(const Duration(milliseconds: 600));
      await shoot(tester, 'life_event_dialog');
    });

    testWidgets('picking an option applies it and closes the card', (
      tester,
    ) async {
      final life = withCard();
      await show(tester, life);
      await tester.tap(find.text('Lend it'));
      await tester.pumpAndSettle();
      expect(life.money, 400);
      expect(life.currentEvent, isNull);
      expect(find.text('Surprise me!'), findsNothing);
    });

    testWidgets('Surprise me picks for you', (tester) async {
      final life = withCard();
      await show(tester, life);
      await tester.tap(find.text('Surprise me!'));
      await tester.pumpAndSettle();
      expect(life.currentEvent, isNull, reason: 'one of the three was taken');
    });

    testWidgets('the card cannot be swiped away without choosing', (
      tester,
    ) async {
      final life = withCard();
      await show(tester, life);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(life.currentEvent, isNotNull);
      expect(find.text('Lend it'), findsOneWidget);
    });

    testWidgets('fits on a small phone', (tester) async {
      await show(tester, withCard(), size: const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a decision can open the form it asked about', (tester) async {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Alex Morgan',
        initialAge: 17,
        startMoney: 500,
      );
      life.ageUp(); // graduates, and the "what next" card is queued
      await show(tester, life);
      expect(find.text('Apply to college'), findsOneWidget);
      await tester.tap(find.text('Apply to college'));
      await tester.pumpAndSettle();
      // A lesson may land first. Dismiss it if it did.
      if (find.text('Got it').evaluate().isNotEmpty) {
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Apply to study'), findsOneWidget);
    });
  });

  group('the busy life', () {
    testWidgets('lays out with everything in it', (tester) async {
      await show(tester, busyAdult());
      expect(tester.takeException(), isNull);
      await shoot(tester, 'life_page_busy');
    });
  });
}
