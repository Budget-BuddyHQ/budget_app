import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/park_activity_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/park_activity_panel.dart';

/// The park has something to do in it.
///
/// It used to be three sentences and three buttons, in the one place on the
/// map somebody walks to for fun. These hold the two things that make the
/// games worth having: the rules are honest, and the panel they play inside
/// fits on a phone in landscape, which is the orientation the town locks.
void main() {
  group('Price Dash asks a fair question', () {
    test('the bigger pack usually wins, and sometimes does not', () {
      final bigWins = kPricePairs.where((p) => p.bigIsCheaper).length;
      // If the big pack always won, the game would teach "buy the big one"
      // instead of "check". If it usually lost, it would be lying about how
      // a supermarket shelf works.
      expect(bigWins, 7);
      expect(kPricePairs.length - bigWins, 3);
    });

    test('the exceptions are the packs with marketing on the front', () {
      final traps = kPricePairs.where((p) => !p.bigIsCheaper);
      for (final pair in traps) {
        final label = pair.bigLabel.toLowerCase();
        expect(
          label.contains('value') ||
              label.contains('bonus') ||
              label.contains('party'),
          isTrue,
          reason: '${pair.item} is a trap with no tell on the label',
        );
      }
    });

    test('every pair is a real comparison, not a rounding artefact', () {
      for (final pair in kPricePairs) {
        expect(pair.smallUnits, greaterThan(0));
        expect(pair.bigUnits, greaterThan(pair.smallUnits));
        expect(pair.bigPrice, greaterThan(pair.smallPrice));
        final gap =
            (pair.bigPerUnit - pair.smallPerUnit).abs() / pair.smallPerUnit;
        expect(
          gap,
          greaterThan(0.04),
          reason:
              '${pair.item} is within 4% either way, which is a coin flip '
              'dressed as a question',
        );
      }
    });
  });

  group('Coin Rush rules', () {
    test('tapping everything is not a strategy', () {
      // A third of what falls is a fee, and a fee is worth less than a coin
      // is worth gaining, so reflex-tapping loses to looking.
      final random = Random(7);
      var fees = 0;
      const draws = 3000;
      for (var i = 0; i < draws; i++) {
        if (rollFalling(random) == FallingKind.fee) fees++;
      }
      expect(fees / draws, closeTo(0.34, 0.03));
      expect(valueOf(FallingKind.fee), lessThan(0));
      expect(valueOf(FallingKind.gem), greaterThan(valueOf(FallingKind.coin)));
    });

    test('a clean run is worth more literacy than a messy one', () {
      final clean = scoreCoinRush(collected: 20, feesTapped: 0, coinsMissed: 3);
      final messy = scoreCoinRush(collected: 20, feesTapped: 4, coinsMissed: 3);
      expect(clean.literacy, greaterThan(messy.literacy));
      expect(clean.gold, messy.gold);
      expect(clean.outcome, isNot(messy.outcome));
    });

    test('a bad round never costs the player gold', () {
      final wiped = scoreCoinRush(collected: 0, feesTapped: 9, coinsMissed: 12);
      expect(wiped.gold, 0, reason: 'a park game must not take gold away');
    });
  });

  group('age scaling', () {
    test('younger players get longer to look', () {
      final young = ParkPacing.forBand(AgeBand.under9);
      final adult = ParkPacing.forBand(AgeBand.adult18plus);
      expect(young.fallSeconds, greaterThan(adult.fallSeconds));
      expect(young.spawnMillis, greaterThan(adult.spawnMillis));
      expect(young.questionSeconds, greaterThan(adult.questionSeconds));
      expect(young.rounds, lessThanOrEqualTo(adult.rounds));
    });

    test('every band has pacing', () {
      for (final band in AgeBand.values) {
        final pacing = ParkPacing.forBand(band);
        expect(pacing.seconds, greaterThan(0));
        expect(pacing.rounds, greaterThan(0));
      }
    });
  });

  group('the panel', () {
    final park = kTownSpots.firstWhere((s) => s.kind == TownSpotKind.park);

    Widget host({
      void Function(TownChoice)? onFinish,
      VoidCallback? onTalk,
      Size size = const Size(1024, 461),
    }) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ParkActivityPanel(
            spot: park,
            band: AgeBand.age9to12,
            random: Random(3),
            onTalk: onTalk ?? () {},
            onFinish: onFinish ?? (_) {},
          ),
        ),
      ),
    );

    for (final size in const <String, Size>{
      'phone landscape': Size(1024, 461),
      'small phone landscape': Size(568, 320),
      'phone portrait': Size(390, 844),
      'small phone portrait': Size(320, 568),
    }.entries) {
      testWidgets('offers both games at ${size.key}', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;

        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host());
        await tester.pump();
        FlutterError.onError = previous;

        expect(find.text('Coin Rush'), findsOneWidget);
        expect(find.text('Price Dash'), findsOneWidget);
        expect(find.text('Sit and talk instead'), findsOneWidget);
        expect(
          errors.map((e) => e.exceptionAsString()).toList(),
          isEmpty,
          reason: 'the park panel overflows at ${size.key}',
        );
      });
    }

    testWidgets('the conversation is still one tap away', (tester) async {
      var talked = false;
      await tester.pumpWidget(host(onTalk: () => talked = true));
      await tester.tap(find.text('Sit and talk instead'));
      await tester.pump();
      expect(talked, isTrue);
    });

    testWidgets('Coin Rush plays and pays', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TownChoice? paid;
      await tester.pumpWidget(host(onFinish: (choice) => paid = choice));
      await tester.tap(find.text('Coin Rush'));
      await tester.pump();

      expect(find.text('TIME'), findsOneWidget);
      expect(find.text('FEES'), findsOneWidget);

      // Let the round run out.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Head back out'),
        findsOneWidget,
        reason: 'the round never ended',
      );
      await tester.tap(find.text('Head back out'));
      await tester.pump();

      expect(paid, isNotNull);
      expect(paid!.gold, greaterThanOrEqualTo(0));
      expect(paid!.literacy, greaterThan(0));
      expect(paid!.outcome, isNotEmpty);
    });

    testWidgets('Price Dash runs its questions and pays', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TownChoice? paid;
      await tester.pumpWidget(host(onFinish: (choice) => paid = choice));
      await tester.tap(find.text('Price Dash'));
      await tester.pump();

      expect(find.text('QUESTION'), findsOneWidget);

      // Answer every question by taking the first option, whatever it is.
      for (var i = 0; i < ParkPacing.forBand(AgeBand.age9to12).rounds; i++) {
        final options = find.byType(InkWell);
        expect(options, findsWidgets);
        await tester.tap(options.first);
        await tester.pump();
      }

      expect(find.text('Head back out'), findsOneWidget);
      await tester.tap(find.text('Head back out'));
      await tester.pump();
      expect(paid, isNotNull);
      expect(paid!.xp, greaterThan(0));
    });
  });
}
