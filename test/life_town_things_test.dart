import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_town_things.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_activities.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_interior_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';
import 'support/fixed_random.dart';

/// Hiking, running, meditating, the gym, the doctor and the library, done in the
/// town and not from a menu.
///
/// **Asked for as:** *"you're still able to do hiking in the menu, where I want
/// the user to do it in the open world and other things in the other world, so
/// remove things that can be done in the open world from the menu, like hiking,
/// meditation and going outside."* The Activities menu no longer lists them.
/// Each building lists what can be done in it, with the same effects, the same
/// prices and the same yearly limits, so this is a move and not a rebalance.
void main() {
  setUpAll(loadAppFonts);

  LifeSimController person({int age = 30, int money = 900}) =>
      LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Alex Morgan',
        initialAge: age,
        startMoney: money,
      );

  List<String> idsAt(LifeSimController life, TownSpotKind kind) => [
    for (final t in life.thingsToDoAt(kind)) t.id,
  ];

  TownThing thing(LifeSimController life, TownSpotKind kind, String id) =>
      life.thingsToDoAt(kind).firstWhere((t) => t.id == id);

  group('what the catalogue says belongs to a building', () {
    test('nothing that has a place is listed in the menu', () {
      for (final category in ActivityCategory.values) {
        for (final a in activitiesIn(category)) {
          expect(a.place, isNull, reason: '${a.id} is in the menu and in town');
        }
      }
    });

    test('and the ones the request named are all at a place', () {
      for (final id in const [
        'run',
        'hike',
        'meditate',
        'stretch',
        'hang_out',
        'amusement',
        'day_trip',
      ]) {
        expect(
          activityById(id)!.place,
          TownSpotKind.park,
          reason: '$id is an outdoor thing and belongs in the park',
        );
      }
    });

    test('every place an activity names is a building on the map', () {
      for (final a in kActivities.where((a) => a.place != null)) {
        expect(
          kTownSpots.any((s) => s.kind == a.place),
          isTrue,
          reason: '${a.id} is done at ${a.place}, which the town does not have',
        );
      }
    });

    test('and each is offered at the place it names', () {
      final life = person(age: 40, money: 5000);
      for (final a in kActivities.where((a) => a.place != null)) {
        expect(
          idsAt(life, a.place!),
          contains(a.id),
          reason: '${a.id} was taken out of the menu and put nowhere',
        );
      }
    });
  });

  group('what can be done where', () {
    test('the park', () {
      expect(
        idsAt(person(), TownSpotKind.park),
        containsAll(<String>[
          'run',
          'hike',
          'meditate',
          'stretch',
          'hang_out',
          'amusement',
          'day_trip',
          'town_go_out',
        ]),
      );
    });

    test('the gym, the clinic, the library, the cafe and the market', () {
      final life = person();
      expect(idsAt(life, TownSpotKind.gym), ['town_gym']);
      expect(idsAt(life, TownSpotKind.clinic), ['town_doctor']);
      expect(
        idsAt(life, TownSpotKind.library),
        containsAll(<String>['read_book', 'museum', 'town_library']),
      );
      expect(idsAt(life, TownSpotKind.cafe), ['dinner_out']);
      expect(idsAt(life, TownSpotKind.market), ['fair']);
    });

    test('a shop and a bank have nothing to do but their own business', () {
      final life = person();
      expect(idsAt(life, TownSpotKind.store), isEmpty);
      expect(idsAt(life, TownSpotKind.bank), isEmpty);
      expect(idsAt(life, TownSpotKind.job), isEmpty);
    });

    test('a small child is offered only what they are old enough for', () {
      final kid = person(age: 7, money: 0);
      final ids = idsAt(kid, TownSpotKind.park);
      expect(ids, contains('hike'));
      expect(ids, isNot(contains('run')), reason: 'running starts at 8');
      expect(ids, isNot(contains('meditate')), reason: 'meditating is 12+');
      expect(ids, isNot(contains('day_trip')), reason: 'a day trip is 10+');
    });

    test('a child is not shown a price, and an adult is', () {
      final kid = person(age: 10, money: 0);
      expect(thing(kid, TownSpotKind.park, 'amusement').cost, 0);
      final adult = person();
      expect(thing(adult, TownSpotKind.park, 'amusement').cost, 30);
      expect(thing(adult, TownSpotKind.clinic, 'town_doctor').cost, 60);
    });
  });

  group('doing them is what the menu always did', () {
    test('a run gives what it always gave', () {
      final life = person();
      final well = life.health;
      final cash = life.money;
      final run = thing(life, TownSpotKind.park, 'run');
      expect(run.gate(), isNull);
      run.perform();
      expect(life.health, well + 5);
      expect(life.money, cash);
      expect(life.log, isNotEmpty);
    });

    test('the yearly limit is the same, and says so', () {
      final life = person();
      for (var i = 0; i < 4; i++) {
        thing(life, TownSpotKind.park, 'run').perform();
      }
      expect(
        thing(life, TownSpotKind.park, 'run').gate(),
        'Done for this year',
      );
    });

    test('the gym is free and the doctor is not', () {
      final life = person();
      final cash = life.money;
      thing(life, TownSpotKind.gym, 'town_gym').perform();
      expect(life.money, cash);
      thing(life, TownSpotKind.clinic, 'town_doctor').perform();
      expect(life.money, cash - 60);
    });

    test('and it cannot be done without the money', () {
      final life = person(money: 10);
      final doctor = thing(life, TownSpotKind.clinic, 'town_doctor');
      expect(doctor.gate(), contains('60'));
    });
  });

  group('in the building itself', () {
    Future<void> enter(
      WidgetTester tester,
      TownSpotKind kind,
      LifeSimController? life, {
      Size size = const Size(430, 1600),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStatsController>(
              create: (_) =>
                  UserStatsController(service: SupabaseService.instance),
            ),
            ChangeNotifierProvider<AppSettingsController>(
              create: (_) => AppSettingsController(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.getLightTheme(),
            home: TownInteriorScreen(
              spot: kTownSpots.firstWhere((s) => s.kind == kind),
              life: life,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('the park lists what can be done and doing it changes them', (
      tester,
    ) async {
      final life = person();
      await enter(tester, TownSpotKind.park, life);
      expect(find.text('Things to do here'), findsOneWidget);

      final before = life.health;
      await tester.tap(find.byKey(const ValueKey('thing-run')));
      await tester.pump();
      expect(life.health, before + 5);
      // What happened is said, under the list, where the player is looking.
      expect(find.byKey(const ValueKey('things-result')), findsOneWidget);
    });

    testWidgets('the gym and the clinic each list their own', (tester) async {
      final life = person();
      await enter(tester, TownSpotKind.gym, life);
      expect(find.byKey(const ValueKey('thing-town_gym')), findsOneWidget);
      expect(find.byKey(const ValueKey('thing-town_doctor')), findsNothing);

      await enter(tester, TownSpotKind.clinic, life);
      expect(find.byKey(const ValueKey('thing-town_doctor')), findsOneWidget);
      expect(find.byKey(const ValueKey('thing-town_gym')), findsNothing);
    });

    testWidgets('a limit reached is shown as a reason, and cannot be tapped', (
      tester,
    ) async {
      final life = person();
      for (var i = 0; i < 4; i++) {
        life.doActivity('run');
      }
      await enter(tester, TownSpotKind.park, life);
      expect(find.text('Done for this year'), findsWidgets);
      final before = life.health;
      await tester.tap(find.byKey(const ValueKey('thing-run')));
      await tester.pump();
      expect(life.health, before);
    });

    testWidgets('with no life to act for, the building is only its scene', (
      tester,
    ) async {
      await enter(tester, TownSpotKind.park, null);
      expect(find.text('Things to do here'), findsNothing);
    });

    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(393, 852),
      Size(800, 360),
    ]) {
      testWidgets(
        'nothing overflows at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          for (final kind in const [
            TownSpotKind.park,
            TownSpotKind.gym,
            TownSpotKind.clinic,
            TownSpotKind.library,
            TownSpotKind.cafe,
          ]) {
            await enter(tester, kind, person(), size: size);
            expect(
              tester.takeException(),
              isNull,
              reason: '$kind at ${size.width}x${size.height}',
            );
          }
        },
      );
    }
  });
}
