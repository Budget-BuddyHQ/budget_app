import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_record.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_snapshot_source.dart';
import 'package:budget_app/screens_minigames_admin_etc/coach/coach_report_view.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// The Coach reads what a life was made of, not only what it was worth.
///
/// **Asked for as:** *"upgrade the coach tab based on the new changes."* The
/// changes are that a life is now school, work, a home and a household, and the
/// Coach's reading of lives was one number: net worth at the end. That cannot say
/// whether a degree paid, or a loan outlasted the thing it bought.
///
/// Held here: each rule fires on the pattern it is named for and stays quiet
/// without it, a life with no recorded detail is never read as one with none,
/// a practice run is left out, and the card on the Coach shows only when there is
/// something true to put on it.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // A snapshot that is not a newcomer's, so the rules run at all.
  MoneySnapshot snap(List<LifeReading> lives) => MoneySnapshot(
    loggedDaysLast14: 6,
    daysSinceLastLog: 1,
    pastLifeNetWorths: [for (final l in lives) l.netWorth],
    lives: lives,
  );

  Set<String> ids(List<LifeReading> lives) => {
    for (final f in analyseMoney(snap(lives)).findings) f.id,
  };

  LifeReading life({
    int netWorth = 2000,
    int happiness = 60,
    int age = 70,
    int degrees = 0,
    int borrowed = 0,
    int promotions = 1,
    int workYears = 30,
    int assets = 4000,
    int owed = 0,
    bool home = false,
  }) => LifeReading(
    age: age,
    netWorth: netWorth,
    happiness: happiness,
    degrees: degrees,
    borrowedForSchool: borrowed,
    promotions: promotions,
    workYears: workYears,
    assetsValue: assets,
    loansOwed: owed,
    ownedHome: home,
  );

  group('school and debt', () {
    test('borrowing for school and still owing, twice, is a pattern', () {
      final found = ids([
        life(degrees: 1, borrowed: 4000, owed: 2500),
        life(degrees: 1, borrowed: 3000, owed: 1200),
        life(),
      ]);
      expect(found, contains('school_debt_pattern'));
    });

    test('once is a story, not a pattern', () {
      final found = ids([
        life(degrees: 1, borrowed: 4000, owed: 2500),
        life(),
        life(),
      ]);
      expect(found, isNot(contains('school_debt_pattern')));
    });

    test('borrowing and paying it all back is not a fault', () {
      final found = ids([
        life(degrees: 1, borrowed: 4000, owed: 0),
        life(degrees: 1, borrowed: 3000, owed: 0),
      ]);
      expect(found, isNot(contains('school_debt_pattern')));
    });

    test('a small loan for a short course does not count', () {
      final found = ids([
        life(borrowed: 300, owed: 100),
        life(borrowed: 400, owed: 200),
      ]);
      expect(found, isNot(contains('school_debt_pattern')));
    });
  });

  group('owing more than owning', () {
    test('twice is a pattern', () {
      expect(
        ids([life(assets: 1000, owed: 6000), life(assets: 500, owed: 4000)]),
        contains('owing_more_than_owning'),
      );
    });

    test('a loan smaller than the thing it bought is not', () {
      expect(
        ids([life(assets: 9000, owed: 4000), life(assets: 9000, owed: 4000)]),
        isNot(contains('owing_more_than_owning')),
      );
    });
  });

  group('careers', () {
    test('long working lives with no promotion are named', () {
      expect(
        ids([
          life(promotions: 0, workYears: 20),
          life(promotions: 0, workYears: 15),
        ]),
        contains('careers_stall'),
      );
    });

    test('a short working life is not a stall', () {
      expect(
        ids([
          life(promotions: 0, workYears: 5),
          life(promotions: 0, workYears: 8),
        ]),
        isNot(contains('careers_stall')),
      );
    });
  });

  group('homes', () {
    test('three full lives with no home are named, gently', () {
      final found = ids([life(), life(), life()]);
      expect(found, contains('never_owned_a_home'));
      final finding = analyseMoney(
        snap([life(), life(), life()]),
      ).findings.firstWhere((f) => f.id == 'never_owned_a_home');
      expect(
        finding.action,
        contains('Renting is a real choice'),
        reason: 'renting is not a mistake and must not be called one',
      );
    });

    test('one home in the run is enough to stop it', () {
      expect(
        ids([life(), life(home: true), life()]),
        isNot(contains('never_owned_a_home')),
      );
    });

    test('lives that ended young are not held to it', () {
      expect(
        ids([life(age: 30), life(age: 25), life(age: 35)]),
        isNot(contains('never_owned_a_home')),
      );
    });
  });

  group('did studying pay', () {
    test('when it did, the Coach says so with both averages', () {
      final report = analyseMoney(
        snap([
          life(degrees: 1, netWorth: 9000),
          life(degrees: 1, netWorth: 8000),
          life(netWorth: 2000),
        ]),
      );
      final finding = report.findings.firstWhere(
        (f) => f.id == 'studying_paid',
      );
      expect(finding.kind, MoneyFindingKind.strength);
      expect(finding.evidence, contains('8500'));
      expect(finding.evidence, contains('2000'));
    });

    test('when it did not, it says that too and does not flatter', () {
      final found = ids([
        life(degrees: 1, netWorth: 1000),
        life(netWorth: 6000),
        life(netWorth: 7000),
      ]);
      expect(found, contains('studying_has_not_paid'));
      expect(found, isNot(contains('studying_paid')));
    });

    test('without both kinds of life there is nothing to compare', () {
      expect(
        ids([life(degrees: 1), life(degrees: 1), life(degrees: 1)]),
        isNot(
          anyOf(contains('studying_paid'), contains('studying_has_not_paid')),
        ),
      );
    });

    test('a small gap is not called a result', () {
      expect(
        ids([
          life(degrees: 1, netWorth: 3000),
          life(netWorth: 2800),
          life(netWorth: 2900),
        ]),
        isNot(
          anyOf(contains('studying_paid'), contains('studying_has_not_paid')),
        ),
      );
    });
  });

  group('money was not the point', () {
    test('rich lives that were not happy ones are named', () {
      expect(
        ids([
          life(netWorth: 9000, happiness: 30),
          life(netWorth: 8000, happiness: 35),
          life(netWorth: 500, happiness: 70),
        ]),
        contains('rich_and_flat'),
      );
    });

    test('a poor unhappy life is not this finding', () {
      expect(
        ids([
          life(netWorth: 100, happiness: 20),
          life(netWorth: 90, happiness: 25),
          life(netWorth: 9000, happiness: 80),
        ]),
        isNot(contains('rich_and_flat')),
      );
    });
  });

  group('quiet on thin data', () {
    test('no lives, none of it', () {
      final found = ids(const <LifeReading>[]);
      for (final id in [
        'school_debt_pattern',
        'owing_more_than_owning',
        'careers_stall',
        'never_owned_a_home',
        'studying_paid',
        'rich_and_flat',
      ]) {
        expect(found, isNot(contains(id)), reason: id);
      }
    });

    test('one life is a story and says nothing about a pattern', () {
      final found = ids([life(degrees: 1, borrowed: 4000, owed: 3000)]);
      expect(found, isNot(contains('school_debt_pattern')));
    });
  });

  group('what the Coach reads out of the saved lives', () {
    LifeRecord record({
      required int day,
      bool graded = true,
      LifeDetail? detail,
      int netWorth = 1000,
    }) => LifeRecord(
      endingId: 'quietLife',
      name: 'Life $day',
      age: 70,
      netWorth: netWorth,
      happiness: 60,
      died: false,
      conceptsMet: 5,
      goldEarned: 0,
      finishedAt: DateTime.utc(2026, 1, day),
      graded: graded,
      detail: detail,
    );

    UserStats statsWith(List<LifeRecord> records) {
      final base = UserStats.defaults('test_user');
      return base.copyWith(
        spendingHabits: <String, dynamic>{
          ...base.spendingHabits,
          'life_records': LifeRecordBook(records).toJson(),
        },
      );
    }

    test('a life with no recorded detail is left out, not read as empty', () {
      final read = buildMoneySnapshot(
        statsWith([
          record(day: 1),
          record(day: 2, detail: const LifeDetail(degrees: 1)),
        ]),
      ).lives;
      expect(read.length, 1, reason: 'the old life has nothing to read');
      expect(read.single.degrees, 1);
    });

    test('a practice run is left out, as it already is for net worth', () {
      final read = buildMoneySnapshot(
        statsWith([
          record(day: 1, graded: false, detail: const LifeDetail(degrees: 2)),
          record(day: 2, detail: const LifeDetail(degrees: 1)),
        ]),
      ).lives;
      expect(read.length, 1);
      expect(read.single.degrees, 1);
    });

    test('newest first', () {
      final read = buildMoneySnapshot(
        statsWith([
          record(day: 1, detail: const LifeDetail(degrees: 1)),
          record(day: 3, detail: const LifeDetail(degrees: 3)),
          record(day: 2, detail: const LifeDetail(degrees: 2)),
        ]),
      ).lives;
      expect([for (final l in read) l.degrees], [3, 2, 1]);
    });

    test('the detail comes through: loans, home, promotions', () {
      final read = buildMoneySnapshot(
        statsWith([
          record(
            day: 1,
            detail: const LifeDetail(
              borrowedForSchool: 4000,
              loansOwed: 1500,
              ownedHome: true,
              promotions: 3,
              workYears: 30,
              assetsValue: 9000,
            ),
          ),
        ]),
      ).lives.single;
      expect(read.schoolDebtLeft, isTrue);
      expect(read.ownedHome, isTrue);
      expect(read.promotions, 3);
      expect(read.underwater, isFalse);
    });
  });

  group('the card on the Coach', () {
    Future<void> pumpCoach(WidgetTester tester, MoneySnapshot snapshot) async {
      tester.view.physicalSize = const Size(393, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = UserStatsController(service: SupabaseService.instance);
      controller.seedStatsForTest(UserStats.defaults('test_user'));
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.getLightTheme(),
            home: Scaffold(body: CoachReportView(snapshot: snapshot)),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows what the lives say once there are some', (tester) async {
      await pumpCoach(
        tester,
        snap([life(degrees: 1, home: true), life(owed: 500), life()]),
      );
      expect(find.byKey(const ValueKey('coach-lives-card')), findsOneWidget);
      expect(find.text('Your lives, read together'), findsOneWidget);
      expect(find.text('1 of 3'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is absent when no life kept its detail', (tester) async {
      await pumpCoach(tester, snap(const <LifeReading>[]));
      expect(find.byKey(const ValueKey('coach-lives-card')), findsNothing);
    });

    testWidgets('says a pattern needs two when there is only one life', (
      tester,
    ) async {
      await pumpCoach(tester, snap([life()]));
      expect(find.textContaining('A pattern needs two'), findsOneWidget);
    });

    testWidgets('lays out on the narrowest phone', (tester) async {
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = UserStatsController(service: SupabaseService.instance);
      controller.seedStatsForTest(UserStats.defaults('test_user'));
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.getLightTheme(),
            home: Scaffold(
              body: CoachReportView(snapshot: snap([life(), life(), life()])),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
