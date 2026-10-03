import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_activities.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_activities_sheet.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:budget_app/widgets_custom_lotties/how_to_budget.dart';
import 'package:budget_app/widgets_custom_lotties/payday_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fixed_random.dart';

/// Four things a younger tester could not work out, reported together:
///
/// > *"he couldn't find where the doctor was on the menu, ... he wasn't
/// > understanding why he wasn't getting any money from his job, he didn't
/// > know when he missed work, he didn't know how to set a budget after
/// > reading the coach's feedback."*
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  LifeSimController worker({int health = 80, int happiness = 70}) {
    final life = LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Sam',
      initialAge: 25,
      startMoney: 500,
      startJob: 'Baker',
      startSalary: 1000,
    );
    life.debugSetStats(health: health, happiness: happiness);
    return life;
  }

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: SingleChildScrollView(child: child),
    ),
  );

  group('the doctor', () {
    testWidgets('is on the menu for somebody well enough to go out', (
      tester,
    ) async {
      final life = worker();
      expect(life.outingPermission.allowed, isTrue);
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityListSheet(
              life: life,
              category: ActivityCategory.mindBody,
              onVolunteer: () {},
              onSkills: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('See the doctor'), findsOneWidget);

      final before = life.health;
      await tester.tap(find.text('See the doctor'));
      await tester.pump();
      expect(life.health, greaterThan(before));
    });
  });

  group('payday', () {
    test('every coin of the pay is accounted for', () {
      final life = worker();
      life.ageUp();
      final slip = life.lastPaySlip!;
      expect(slip.pay, 1000);
      expect(slip.weeksMissed, 0);
      final named = slip.loans + slip.bills + slip.wants + slip.saved;
      // Whatever is not named is debt interest and the like, never negative.
      expect(slip.pay - named - slip.toCash, greaterThanOrEqualTo(0));
      expect(slip.saved, greaterThan(0));
    });

    test('missed work says how much and why', () {
      final life = worker(health: 20);
      life.ageUp();
      final slip = life.lastPaySlip!;
      expect(slip.weeksMissed, greaterThan(0));
      expect(slip.missedPay, greaterThan(0));
      expect(slip.missedBecause, contains('unwell'));
    });

    test('no paycheck, no slip', () {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Sam',
        initialAge: 25,
        startMoney: 500,
      );
      life.ageUp();
      expect(life.lastPaySlip, isNull);
    });

    testWidgets('the card shows the split and the button to change it', (
      tester,
    ) async {
      final life = worker()..ageUp();
      await tester.pumpWidget(
        host(
          PaydayCard(
            life: life,
            onOpenBudget: () {},
            onFindJob: () {},
            onSeeDoctor: () {},
          ),
        ),
      );
      expect(find.text('Payday'), findsOneWidget);
      expect(find.textContaining('Fun money'), findsOneWidget);
      expect(find.textContaining('Saved'), findsOneWidget);
      expect(find.text('Set my budget'), findsOneWidget);
      expect(find.textContaining('You missed'), findsNothing);
    });

    testWidgets('missed work is in red, with a way to fix it', (tester) async {
      final life = worker(health: 20)..ageUp();
      var doctor = 0;
      await tester.pumpWidget(
        host(
          PaydayCard(
            life: life,
            onOpenBudget: () {},
            onFindJob: () {},
            onSeeDoctor: () => doctor++,
          ),
        ),
      );
      expect(find.textContaining('You missed'), findsOneWidget);
      await tester.tap(find.text('See the doctor'));
      expect(doctor, 1);
    });

    testWidgets('an adult with no job is told why there is no pay', (
      tester,
    ) async {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Sam',
        initialAge: 25,
        startMoney: 500,
      );
      var found = 0;
      await tester.pumpWidget(
        host(
          PaydayCard(
            life: life,
            onOpenBudget: () {},
            onFindJob: () => found++,
            onSeeDoctor: () {},
          ),
        ),
      );
      expect(find.text('No job, no payday'), findsOneWidget);
      await tester.tap(find.text('Find a job'));
      expect(found, 1);
    });
  });

  group('setting a budget', () {
    test('advice that says "set your budget" offers the how-to', () {
      // Without the flag the card has nowhere to send the player.
      const ids = {'lives_flat', 'lives_exploring'};
      final flagged = <String>{};
      // Newest first, and not improving: one flat run of lives, one run
      // spread across several endings.
      for (final (worths, endings) in const [
        ([100, 100, 100], 1),
        ([50, 9000, 4000], 3),
      ]) {
        final report = analyzeMoney(
          MoneySnapshot(pastLifeNetWorths: worths, distinctEndings: endings),
        );
        for (final f in report.findings) {
          if (ids.contains(f.id)) {
            expect(f.showsBudgetHowTo, isTrue, reason: f.id);
            expect(f.action, isNot(contains('Assets tab')), reason: f.id);
            flagged.add(f.id);
          }
        }
      }
      expect(flagged, isNotEmpty);
    });

    testWidgets('the how-to names what is on screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (_) => const HowToBudgetButton()),
          ),
        ),
      );
      await tester.tap(find.text('How do I set a budget?'));
      await tester.pumpAndSettle();
      // The words on the real controls, so the player recognises them.
      expect(find.textContaining('Pick a budget'), findsWidgets);
      expect(find.textContaining('Save budget'), findsOneWidget);
      expect(find.textContaining('Use 50/30/20'), findsOneWidget);
      expect(find.text('Play Life'), findsOneWidget);
    });
  });
}
