import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/widgets_custom_lotties/life_money_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widths the panel has to survive, including the narrowest phone the app
/// supports minus the feed's 16px side padding.
const List<double> _widths = <double>[288, 320, 343, 375, 398, 640, 992];

/// A grown-up mid-life, so the budget bar, the runway line and the money
/// tiles are all on screen at once. The age-0 case is already covered by
/// the `Life sim` entry in `responsive_layout_test.dart`, and it takes the
/// *other* branch of this widget (the dependent note), so both are needed.
LifeSimController _adult() => LifeSimController(
  random: Random(11),
  initialAge: 34,
  startMoney: 1840,
  startJob: 'Analyst',
  startSalary: 2400,
);

Widget _wrap(Widget child, double width) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
    ),
  ),
);

Future<List<String>> _renderErrors(
  WidgetTester tester,
  Widget child,
  double width,
) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await tester.pumpWidget(_wrap(child, width));
    await tester.pump(const Duration(milliseconds: 200));
  } finally {
    FlutterError.onError = previous;
  }
  return errors.map((e) => e.exception.toString()).toList(growable: false);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('money panel layout', () {
    for (final width in _widths) {
      testWidgets('lays out at ${width.toInt()}px wide', (tester) async {
        final life = _adult();
        life.setBudget(needs: 55, wants: 25, savings: 20);
        final errors = await _renderErrors(
          tester,
          LifeMoneyPanel(
            life: life,
            onOpenBudget: () {},
            onOpenMoney: () {},
            onOpenConcepts: () {},
          ),
          width,
        );
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }

    testWidgets('survives a budget slice of zero', (tester) async {
      // `Expanded(flex: 0)` asserts, so the bar collapses an empty slice to
      // a hairline instead. Reachable from the budget sheet by dragging any
      // slider to the bottom.
      final life = _adult();
      life.setBudget(needs: 100, wants: 0, savings: 0);
      final errors = await _renderErrors(
        tester,
        LifeMoneyPanel(
          life: life,
          onOpenBudget: () {},
          onOpenMoney: () {},
          onOpenConcepts: () {},
        ),
        343,
      );
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    testWidgets('lays out a six-figure net worth without truncating', (
      tester,
    ) async {
      final life = LifeSimController(
        random: Random(2),
        initialAge: 58,
        startMoney: 942150,
        startJob: 'Partner',
        startSalary: 18000,
      );
      final errors = await _renderErrors(
        tester,
        LifeMoneyPanel(
          life: life,
          onOpenBudget: () {},
          onOpenMoney: () {},
          onOpenConcepts: () {},
        ),
        288,
      );
      expect(errors, isEmpty, reason: errors.join('\n'));
      // Twice: once in the Cash tile, once as net worth — with nothing
      // saved, invested or owed, those are the same figure.
      expect(find.textContaining('942,150'), findsNWidgets(2));
    });
  });

  group('coin formatting', () {
    test('groups thousands', () {
      expect(LifeMoneyPanel.coinsLabel(0), '0');
      expect(LifeMoneyPanel.coinsLabel(999), '999');
      expect(LifeMoneyPanel.coinsLabel(1000), '1,000');
      expect(LifeMoneyPanel.coinsLabel(1234567), '1,234,567');
    });

    test('keeps the sign outside the grouping', () {
      // Net worth goes negative the moment debt outgrows everything else,
      // which is a state the panel is specifically meant to show.
      expect(LifeMoneyPanel.coinsLabel(-1500), '-1,500');
      expect(LifeMoneyPanel.coinsLabel(-42), '-42');
    });
  });

  group('the money-ideas strip', () {
    testWidgets('shows every concept as a slot, met or not', (tester) async {
      // The empty slots are the invitation — hiding unmet ideas would make
      // the collection look complete from the first year.
      final life = _adult();
      await _renderErrors(
        tester,
        LifeMoneyPanel(
          life: life,
          onOpenBudget: () {},
          onOpenMoney: () {},
          onOpenConcepts: () {},
        ),
        375,
      );
      expect(
        find.text('0/${FinanceConcept.values.length}'),
        findsOneWidget,
        reason: 'a fresh life has met nothing yet',
      );
    });

    testWidgets('counts ideas as they are met', (tester) async {
      final life = _adult();
      // setBudget teaches the 50/30/20 rule.
      life.setBudget(needs: 50, wants: 30, savings: 20);
      await _renderErrors(
        tester,
        LifeMoneyPanel(
          life: life,
          onOpenBudget: () {},
          onOpenMoney: () {},
          onOpenConcepts: () {},
        ),
        375,
      );
      expect(find.text('1/${FinanceConcept.values.length}'), findsOneWidget);
    });

    testWidgets('a repeated idea is not double-counted', (tester) async {
      final life = _adult();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.setBudget(needs: 60, wants: 20, savings: 20);
      await _renderErrors(
        tester,
        LifeMoneyPanel(
          life: life,
          onOpenBudget: () {},
          onOpenMoney: () {},
          onOpenConcepts: () {},
        ),
        375,
      );
      expect(find.text('1/${FinanceConcept.values.length}'), findsOneWidget);
    });
  });

  group('concept glyphs', () {
    test('every concept has one', () {
      for (final concept in FinanceConcept.values) {
        expect(concept.emoji, isNotEmpty, reason: '${concept.name} has none');
      }
    });

    test('no two concepts share a glyph', () {
      // Two ideas wearing the same picture makes the strip unreadable as a
      // collection — you cannot tell which slot just filled in.
      final glyphs = FinanceConcept.values.map((c) => c.emoji).toList();
      expect(glyphs.toSet().length, glyphs.length);
    });
  });
}
