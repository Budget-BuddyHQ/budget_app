import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';

/// The four action menus, opened and photographed at two very different ages.
///
/// **Why these get their own shots.** The Activities menu at age five was
/// reported as a wall of grey — eight rows, seven of them locked, with the one
/// thing a five-year-old can actually do sitting fourth in the list. That is
/// not something a layout test can catch, because nothing overflows and
/// nothing clips; the screen is technically correct and practically useless.
/// It has to be looked at.
///
/// The assertions here are deliberately thin — they hold the property the
/// redesign is *for* (the things you can do come before the things you
/// cannot) and leave everything else to the eye.
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

  /// A run parked at [age] with money in hand, so the only thing that can
  /// grey a row out is the age gate itself.
  LifeSimController at(int age) =>
      LifeSimController(random: Random(11), initialAge: age, startMoney: 400);

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

  /// What the bottom bar calls each menu, which is not what the sheet calls
  /// it: the Activities sheet is headed "Activities" and reached by a button
  /// marked "Do", and Career reads "School" until you are eighteen.
  String barLabel(String menu, int age) => switch (menu) {
    'Activities' => 'Do',
    'Career' => age < 18 ? 'School' : 'Career',
    _ => menu,
  };

  /// Opens one of the four menus by tapping its button in the game's own
  /// bottom bar, so this exercises the real route rather than constructing
  /// the sheet directly.
  Future<void> openMenu(WidgetTester tester, int age, String menu) async {
    tester.view.physicalSize = const Size(560, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: wrap(LifeSimPage(debugInitialLife: at(age))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(barLabel(menu, age)).last);
    await tester.pumpAndSettle();

    // The sheet is headed with the menu's own name, so this doubles as a
    // check that the button opened the sheet it claims to.
    expect(find.text(menu), findsWidgets);
  }

  /// The vertical position of a row's label inside the open sheet.
  double topOf(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label).last).dy;

  for (final age in const <int>[5, 30]) {
    for (final menu in const <String>['Activities', 'Money', 'Career']) {
      testWidgets('$menu at $age', (tester) async {
        await openMenu(tester, age, menu);
        await shoot(tester, 'menu_${menu.toLowerCase()}_$age');
      });
    }
  }

  testWidgets('a five-year-old is not offered investing', (tester) async {
    // The reported bug, held at the level it was reported: the row was
    // enabled, and pressing it did nothing at all because `invest` checks
    // the gate itself and returns silently.
    await openMenu(tester, 5, 'Money');
    expect(find.text('Invest 100 coins'), findsOneWidget);
    expect(
      find.text('You need to be 16 to open an account'),
      findsOneWidget,
      reason: 'the row must say why rather than looking pressable',
    );
  });

  testWidgets('what you can do comes before what you cannot', (tester) async {
    await openMenu(tester, 5, 'Activities');

    // At five: the clinic is open (a parent takes you), the gym and the
    // library and every job are not.
    final doctor = topOf(tester, 'See a doctor');
    final heading = topOf(tester, 'When you are older');
    final gym = topOf(tester, 'Go to the gym');

    expect(
      doctor,
      lessThan(heading),
      reason: 'the one thing a five-year-old can do should be above the fold',
    );
    expect(
      gym,
      greaterThan(heading),
      reason: 'locked rows belong under the heading, not interleaved',
    );
  });

  testWidgets('an adult sees no locked section at all', (tester) async {
    await openMenu(tester, 30, 'Activities');
    expect(find.text('When you are older'), findsNothing);
    expect(find.text('Not yet'), findsNothing);
  });

  testWidgets('the locked heading only promises what age can fix', (
    tester,
  ) async {
    // Activities at five is locked purely by age, so growing up really is
    // the answer there.
    await openMenu(tester, 5, 'Activities');
    expect(find.text('When you are older'), findsOneWidget);
  });

  testWidgets('a mixed lock does not blame age for all of it', (tester) async {
    // Money at five locks investing on age but budgeting on not having a job,
    // and no amount of birthdays fixes the second one.
    await openMenu(tester, 5, 'Money');
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('When you are older'), findsNothing);
  });

  testWidgets('a row does not promise a number the action will not pay', (
    tester,
  ) async {
    // Both of these labels were wrong for a long time. When the menu versions
    // of the library and the park were reduced -- so that walking to the real
    // one in town was worth doing -- the controller changed and the labels
    // did not, so the menu advertised +4 Smarts for something that pays +2
    // and +10 Happiness for something that pays +6.
    //
    // A game about money that quotes the wrong price is a specific kind of
    // bad, so the two numbers are pinned against the controller here rather
    // than trusted to stay in step.
    final life = at(30);

    final smartsBefore = life.smarts;
    life.visitLibrary();
    expect(life.smarts - smartsBefore, 2);

    final happyBefore = life.happiness;
    life.haveFun();
    expect(life.happiness - happyBefore, 6);

    await openMenu(tester, 30, 'Activities');
    // Matched against the whole row rather than the bare number: Volunteer
    // also says "+2 Smarts", and a finder that cannot tell those two apart
    // would pass with the library row still wrong.
    expect(find.textContaining('Read at home. +2 Smarts'), findsOneWidget);
    expect(
      find.textContaining('An afternoon out. +6 Happiness'),
      findsOneWidget,
    );
    expect(
      find.textContaining('+4 Smarts'),
      findsNothing,
      reason: 'the old, wrong number is back',
    );
    expect(find.textContaining('+10 Happiness'), findsNothing);
  });

  testWidgets('the town doors are marked as such', (tester) async {
    // Two routes to one outcome is fine — the map is not always open to you.
    // Two routes with nothing saying they meet is what read as duplication.
    await openMenu(tester, 30, 'Activities');
    expect(find.text('in town'), findsWidgets);

    for (final action in LifeAction.values) {
      final marked = LifeSimController.hasTownEquivalent(action);
      if (!marked) continue;
      expect(
        const <LifeAction>{
          LifeAction.library,
          LifeAction.goOut,
          LifeAction.doctor,
          LifeAction.findJob,
        }.contains(action),
        isTrue,
        reason: '$action is marked "in town" but has no building there',
      );
    }
  });
}
