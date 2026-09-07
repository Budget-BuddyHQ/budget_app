import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/age_scaling_facts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/widgets_custom_lotties/age_scaling_card.dart';

/// Whether the age system is *visible*, which is a separate question from
/// whether it works.
///
/// **The report, twice, in the same words:** *"I'm still not seeing the age
/// separated for the app."* By then the band was deciding six things — which
/// questions are served, whether adult topics are held back, whether the
/// random skin case exists, whether wagers appear, whether the wording is
/// plain, and how fast Leak Patrol runs — and the player was told about it in
/// one sentence at sign-up, which they saw once.
///
/// These tests hold two lines. The **claims must be true**: a card that says
/// an eight-year-old gets fewer questions has to be describing what the
/// routing actually does, or it is worse than saying nothing. And the card
/// must be **reachable**, because a truthful panel nobody can find fixes
/// exactly none of the complaint.
void main() {
  group('the facts describe what the app really does', () {
    test('every band gets a fact for every system it changes', () {
      for (final band in AgeBand.values) {
        final facts = ageScalingFacts(band);
        expect(
          facts.map((f) => f.icon).toSet().length,
          AgeScalingIcon.values.length,
          reason: '${band.label} is missing a fact for one of the systems',
        );
      }
    });

    test('the question count is the real one, not a typed-in number', () {
      // The whole point of quoting a number is that a reader can check it.
      for (final band in AgeBand.values) {
        final reading = ageScalingFacts(
          band,
        ).firstWhere((f) => f.icon == AgeScalingIcon.reading);
        final expected = questionsPerBand[band]!;

        expect(
          reading.detail.startsWith('$expected of ${allQuizQuestions.length}'),
          isTrue,
          reason:
              '${band.label} claims "${reading.detail}" but the bank serves '
              'it $expected of ${allQuizQuestions.length}',
        );
      }
    });

    test('younger bands are told they get fewer questions', () {
      // If this ever inverts, either the routing broke or the card lies.
      final young = questionsPerBand[AgeBand.under9]!;
      final adult = questionsPerBand[AgeBand.adult18plus]!;
      expect(young, lessThan(adult));
    });

    test('the loot box line matches the actual gate', () {
      for (final band in AgeBand.values) {
        final rewards = ageScalingFacts(
          band,
        ).firstWhere((f) => f.icon == AgeScalingIcon.rewards);

        expect(
          rewards.detail.contains('No random case'),
          !band.allowsRandomisedRewards,
          reason:
              '${band.label} is told the wrong thing about the skin case, '
              'which is the one claim here with a store policy behind it',
        );
      }
    });

    test('the wagering line matches the actual gate', () {
      for (final band in AgeBand.values) {
        final wager = ageScalingFacts(
          band,
        ).firstWhere((f) => f.icon == AgeScalingIcon.wager);

        expect(
          wager.detail.contains('never offered a bet'),
          !band.allowsWagering,
          reason: '${band.label} is told the wrong thing about wagers',
        );
      }
    });

    test('a player who declined to say is told how to fix it', () {
      // The one band where the app is guessing. Saying "matched to your age"
      // to somebody who never gave one would be a straight falsehood.
      final reading = ageScalingFacts(
        AgeBand.undisclosed,
      ).firstWhere((f) => f.icon == AgeScalingIcon.reading);

      expect(reading.detail.toLowerCase(), contains('set your age'));
    });

    test('no fact is empty or a placeholder', () {
      for (final band in AgeBand.values) {
        for (final fact in ageScalingFacts(band)) {
          expect(fact.title.trim(), isNotEmpty);
          expect(fact.detail.trim().length, greaterThan(20));
          expect(fact.detail, isNot(contains('TODO')));
        }
      }
    });
  });

  group('the card', () {
    Widget host(AgeBand band, {VoidCallback? onChangeAge}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AgeScalingCard(debugBand: band, onChangeAge: onChangeAge),
        ),
      ),
    );

    testWidgets('collapsed, it says how many things change', (tester) async {
      await tester.pumpWidget(host(AgeBand.age9to12));

      expect(find.text('Matched to your age'), findsOneWidget);
      expect(find.textContaining('9 to 12'), findsOneWidget);
      expect(find.textContaining('6 things change'), findsOneWidget);
    });

    testWidgets('opening it shows every fact', (tester) async {
      await tester.pumpWidget(host(AgeBand.under9));
      await tester.tap(find.text('Matched to your age'));
      await tester.pumpAndSettle();

      for (final fact in ageScalingFacts(AgeBand.under9)) {
        expect(
          find.text(fact.title),
          findsOneWidget,
          reason: '"${fact.title}" is missing from the open card',
        );
      }
    });

    testWidgets('an under-9 is told the case is closed to them', (
      tester,
    ) async {
      await tester.pumpWidget(host(AgeBand.under9));
      await tester.tap(find.text('Matched to your age'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No random case'), findsOneWidget);
    });

    testWidgets('a player with no age set is offered the way to set it', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        host(AgeBand.undisclosed, onChangeAge: () => tapped = true),
      );
      await tester.tap(find.text('Matched to your age'));
      await tester.pumpAndSettle();

      expect(find.text('Set my age'), findsOneWidget);
      await tester.tap(find.text('Set my age'));
      expect(tapped, isTrue);
    });

    testWidgets('it lays out on the narrowest phone', (tester) async {
      // Profile is a long scroll of settings rows and this card is the widest
      // thing on it. A six-line panel that overflows on a small phone would
      // be a worse answer than the note it replaces.
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(host(AgeBand.teen16to17));
      await tester.tap(find.text('Matched to your age'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('it is reachable from the places it describes', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');

    test('Profile carries the panel, beside where the age is set', () {
      final profile = read(
        'lib/screens_minigames_admin_etc/profile/profile_screen.dart',
      );
      expect(profile.contains('AgeScalingCard('), isTrue);
      expect(
        profile.indexOf('AgeScalingCard('),
        lessThan(profile.indexOf("title: 'About You'")),
        reason: 'the explanation should come before the setting it explains',
      );
    });

    test('every screen that filters content says so', () {
      // The surfaces that call an age-filtering function must also carry the
      // note. A screen that quietly serves different content to different
      // children is the exact thing being complained about.
      const surfaces = <String, String>{
        'the Academy quiz':
            'lib/screens_minigames_admin_etc/Gameplay/academy/'
                'lesson_detail_screen.dart',
        'the Brawl checkpoint':
            'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
                'finance_brawl_game.dart',
        'the life sim character sheet':
            'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
                'life_character_sheet.dart',
        'the Market Board':
            'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
                'stock_market_page.dart',
        'the Coach':
            'lib/screens_minigames_admin_etc/coach/coach_report_view.dart',
      };

      for (final entry in surfaces.entries) {
        expect(
          read(entry.value).contains('AgeScaledNote'),
          isTrue,
          reason: '${entry.key} filters by age and does not say so',
        );
      }
    });
  });
}
