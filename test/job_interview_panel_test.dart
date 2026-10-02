import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/job_interview_panel.dart';

import 'support/fixed_random.dart';

/// The Job Board's in-person interview.
///
/// The arithmetic behind `interviewScore` is proven in `life_careers_test`;
/// this is the panel wiring — picking a real listing, running the questions,
/// and that a finished interview really does call through to
/// [LifeSimController.applyForJob] rather than just animating a result.
void main() {
  LifeSimController adult({bool lucky = true}) {
    final life = LifeSimController(
      random: lucky ? FixedRandom.lucky() : FixedRandom.unlucky(),
      name: 'Tester',
      initialAge: 20,
      startMoney: 200,
    );
    life.debugSetStats(smarts: 60, health: 85, happiness: 65);
    return life;
  }

  Widget host(
    LifeSimController life, {
    VoidCallback? onTalk,
    VoidCallback? onLeave,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: JobInterviewPanel(
          life: life,
          random: Random(3),
          onTalk: onTalk ?? () {},
          onLeave: onLeave ?? () {},
        ),
      ),
    ),
  );

  testWidgets('offers real listings, not a random roll', (tester) async {
    final life = adult();
    await tester.pumpWidget(host(life));
    await tester.pump();

    // Every qualified listing shows the same odds the Occupation tab would,
    // which is the thing this screen has to beat, not hide.
    expect(find.textContaining('Online odds:'), findsWidgets);
  });

  testWidgets('picking a listing starts the interview', (tester) async {
    final life = adult();
    await tester.pumpWidget(host(life));
    await tester.pump();

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    expect(find.text('QUESTION'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
  });

  testWidgets(
    'answering every question reaches a result and actually hires',
    (tester) async {
      final life = adult();
      expect(life.hasJob, isFalse);

      await tester.pumpWidget(host(life));
      await tester.pump();
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      for (var i = 0; i < 4; i++) {
        final options = find.byType(InkWell);
        expect(options, findsWidgets, reason: 'question ${i + 1} has no answers');
        await tester.tap(options.first);
        await tester.pump();
      }

      expect(find.text('You got it'), findsOneWidget);
      expect(
        life.hasJob,
        isTrue,
        reason: 'the result screen is cosmetic unless it really called '
            'applyForJob',
      );
      expect(find.textContaining('Odds online:'), findsOneWidget);
    },
  );

  testWidgets('a rejection is shown honestly, not hidden', (tester) async {
    final life = adult(lucky: false);
    await tester.pumpWidget(host(life));
    await tester.pump();
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    for (var i = 0; i < 4; i++) {
      final options = find.byType(InkWell);
      await tester.tap(options.first);
      await tester.pump();
    }

    expect(find.text('Not this time'), findsOneWidget);
    expect(life.hasJob, isFalse);
  });

  testWidgets('done leaves the building', (tester) async {
    final life = adult();
    var left = false;
    await tester.pumpWidget(host(life, onLeave: () => left = true));
    await tester.pump();
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
    }

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(left, isTrue);
  });

  testWidgets('chatting instead skips the interview entirely', (
    tester,
  ) async {
    final life = adult();
    var talked = false;
    await tester.pumpWidget(host(life, onTalk: () => talked = true));
    await tester.pump();

    await tester.tap(find.text('Just chat instead'));
    await tester.pump();

    expect(talked, isTrue);
    expect(life.hasJob, isFalse);
  });
}
