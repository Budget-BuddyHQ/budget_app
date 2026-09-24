import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';
import 'support/fixed_random.dart';

/// "Where does my money go?"
///
/// **Reported as:** ten-year-olds playing said *"they don't know what is taking
/// money from them."* The year charged rent, food, loan payments, interest and
/// the budget split, and named each one once in a feed that scrolls away. These
/// hold the itemised year to what the year really does, because a list that says
/// one thing while the game does another would be worse than no list.
void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  LifeSimController adult({int salary = 1200, int age = 30}) =>
      LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Alex Morgan',
        initialAge: age,
        startMoney: 800,
        startJob: 'Barista',
        startSalary: salary,
      );

  group('the itemised year', () {
    test('has the pay, the bills, fun money and savings', () {
      final flow = adult().moneyFlow;
      final labels = [for (final l in flow.lines) l.label];
      expect(labels, containsAll(['Your pay', 'Food and bills', 'Fun money']));
      expect(labels, contains('Put into savings'));
    });

    test('and every row says in a sentence what it is', () {
      for (final l in adult().moneyFlow.lines) {
        expect(l.why.trim().length, greaterThan(15), reason: l.label);
      }
    });

    test('pay is what the job pays', () {
      final flow = adult(salary: 1500).moneyFlow;
      expect(flow.lines.firstWhere((l) => l.isIncome).amount, 1500);
    });

    test('the split is the budget the player chose', () {
      final life = adult();
      life.setBudget(needs: 40, wants: 40, savings: 20);
      final flow = life.moneyFlow;
      final fun = flow.lines.firstWhere((l) => l.label == 'Fun money').amount;
      final saved = flow.lines
          .firstWhere((l) => l.label == 'Put into savings')
          .amount;
      expect(fun, (1200 * 40 / 100).round());
      expect(saved, (1200 * 20 / 100).round());
    });

    test('and what it says is left is what a real year leaves', () {
      // The one that matters: a preview that disagrees with the year is worse
      // than none. Cash and savings together, because the savings slice leaves
      // the pocket and lands in the fund.
      final life = adult();
      final flow = life.moneyFlow;
      final saved = flow.lines
          .firstWhere((l) => l.label == 'Put into savings')
          .amount;
      final before = life.money + life.emergencyFund;
      life.ageUp();
      final after = life.money + life.emergencyFund;
      expect(after - before, flow.leftOver + saved);
    });

    test('a loan is shown, and comes out of the pay first', () {
      final life = adult(salary: 3000);
      life.debugAddLoanForTest(balance: 900);
      final flow = life.moneyFlow;
      final loans = flow.lines.where((l) => l.kind == MoneyFlowKind.loan);
      expect(loans, isNotEmpty, reason: 'a loan is not in the list');
      final split = flow.lines.firstWhere((l) => l.label == 'Fun money').amount;
      final pay = flow.lines.firstWhere((l) => l.isIncome).amount;
      final paidOut = loans.fold<int>(0, (sum, l) => sum + l.amount);
      expect(
        split,
        ((pay - paidOut) * life.wantsPct / 100).round(),
        reason: 'the split is of what is left after the loan',
      );
    });

    test('rent is a line only for somebody who rents', () {
      final life = adult();
      final hasRent = life.moneyFlow.lines.any((l) => l.label == 'Rent');
      expect(hasRent, life.housingCost > 0);
    });

    test('somebody with no job has bills and nothing coming in', () {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Alex Morgan',
        initialAge: 30,
        startMoney: 800,
      );
      final flow = life.moneyFlow;
      expect(flow.lines.any((l) => l.isIncome), isFalse);
      expect(flow.leftOver, lessThan(0));
      expect(flow.note, contains('no job'));
    });

    test('a child is told somebody else pays', () {
      final kid = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Sam',
        initialAge: 10,
      );
      final flow = kid.moneyFlow;
      expect(flow.lines.single.kind, MoneyFlowKind.family);
      expect(flow.lines.single.label, contains('food'));
      expect(flow.leftOver, 0);
    });
  });

  group('on the Life page', () {
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

    Future<void> show(WidgetTester tester, LifeSimController life) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(LifeSimPage(debugInitialLife: life)));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('the question is asked in the money panel, in those words', (
      tester,
    ) async {
      await show(tester, adult());
      expect(find.text('Where does my money go?'), findsOneWidget);
    });

    testWidgets('and opens the year with a sentence on each row', (
      tester,
    ) async {
      await show(tester, adult());
      await tester.ensureVisible(find.byKey(const ValueKey('where-it-goes')));
      await tester.tap(find.byKey(const ValueKey('where-it-goes')));
      await tester.pumpAndSettle();
      for (final title in const [
        'Your pay',
        'Food and bills',
        'Fun money',
        'Put into savings',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.byKey(const ValueKey('flow-left')), findsOneWidget);
      expect(find.byKey(const ValueKey('flow-surprises')), findsOneWidget);
    });

    testWidgets('and a child sees who pays', (tester) async {
      await show(
        tester,
        LifeSimController(
          random: FixedRandom.unlucky(),
          name: 'Sam',
          initialAge: 10,
        ),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('where-it-goes')));
      await tester.tap(find.byKey(const ValueKey('where-it-goes')));
      await tester.pumpAndSettle();
      expect(find.text('Home, food and school'), findsOneWidget);
      expect(find.text('Paid for you'), findsOneWidget);
    });
  });
}
