import 'dart:convert';
import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_debrief.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_record.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_run_record.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_life_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'support/debrief_fixture.dart';

/// A finished life keeps its story, so Past Lives can open it.
///
/// **Asked for as:** *"when they click on one of these past runs it pulls their
/// diagnostic."* The debrief was shown once, on the ending screen, and then gone.
/// For it to come back a record has to keep what it was graded on, and that data
/// travels through a JSON column that comes back with numbers as whatever type
/// the last thing to touch it made them, which is where a save like this breaks.
///
/// Four things are held: the story survives a real encode and decode, an old
/// record still opens, the store stays small by keeping the story for the newest
/// few only, and tapping a life on the screen shows its diagnostic.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Through the same door a saved life goes: to JSON text and back.
  T roundTrip<T>(
    T Function(Map<dynamic, dynamic>) read,
    Map<String, dynamic> j,
  ) => read(jsonDecode(jsonEncode(j)) as Map<dynamic, dynamic>);

  group('the story survives being saved', () {
    test('the curve, the moments and the totals come back', () {
      final original = richRunRecord();
      final back = LifeRunRecord.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(back.curve.length, original.curve.length);
      expect(back.curve.first.age, original.curve.first.age);
      expect(back.curve.last.netWorth, original.curve.last.netWorth);
      expect(back.moments.length, original.moments.length);
      expect(back.moments.first.title, original.moments.first.title);
      expect(back.moments.first.concept, original.moments.first.concept);
      expect(
        back.moments.first.betterOption,
        original.moments.first.betterOption,
      );
      expect(back.tally.incomeTotal, original.tally.incomeTotal);
      expect(back.tally.peakAge, original.tally.peakAge);
      expect(back.tally.firstJobAge, original.tally.firstJobAge);
    });

    test('a shock that was not covered stays not covered', () {
      final back = LifeRunRecord.fromJson(
        jsonDecode(jsonEncode(richRunRecord().toJson())),
      );
      expect(back.moments.where((m) => !m.covered), isNotEmpty);
    });

    test('a number that comes back as a double or a string is still read', () {
      // A remote JSON column can hand any of these back.
      final back = LifeRunTally.fromJson(<String, dynamic>{
        'ay': 40.0,
        'wy': '32',
        'it': 12000.4,
      });
      expect(back.adultYears, 40);
      expect(back.workYears, 32);
      expect(back.incomeTotal, 12000);
    });

    test('grading the saved story gives the same diagnostic', () {
      final facts = richRunFacts();
      final back = roundTrip(LifeRunFacts.fromJson, facts.toJson());

      final was = debriefLife(facts);
      final now = debriefLife(back);
      expect(now.headline, was.headline);
      expect(
        [for (final f in now.findings) f.id],
        [for (final f in was.findings) f.id],
      );
      expect(now.scores, was.scores);
    });

    test('a story is small enough to keep', () {
      // It sits in a blob that is rewritten on nearly every action. Five of
      // these must stay far under what a person would call heavy.
      final bytes = utf8.encode(jsonEncode(richRunFacts().toJson())).length;
      expect(
        bytes,
        lessThan(9000),
        reason: 'a stored life is $bytes bytes; five are kept',
      );
    });

    test('a very long life keeps only its heaviest moments', () {
      final many = LifeRunRecord(
        moments: [
          for (var i = 0; i < 100; i++)
            LifeMoment(
              age: 20 + i % 60,
              kind: LifeMomentKind.shock,
              title: 'Bill $i',
              chose: 'Paid',
              moneyDelta: -(i + 1),
            ),
        ],
      );
      final back = LifeRunRecord.fromJson(
        jsonDecode(jsonEncode(many.toJson())),
      );
      expect(back.moments.length, LifeRunRecord.maxStoredMoments);
      // The biggest bills are the ones that stay.
      expect(back.moments.any((m) => m.title == 'Bill 99'), isTrue);
      expect(back.moments.any((m) => m.title == 'Bill 0'), isFalse);
    });
  });

  group('a real life is filed with its story', () {
    LifeSimController live(int seed) {
      final life = LifeSimController(
        random: Random(seed),
        startMoney: 800,
        withFamily: true,
      );
      for (var i = 0; i < 70 && !life.finished; i++) {
        life.ageUp();
        if (life.currentEvent != null) life.chooseOption(0);
        life.takeFollowUp();
      }
      return life;
    }

    test('the summary carries the facts it was graded on', () {
      final summary = LifeSummary.fromController(live(3));
      expect(summary.facts, isNotNull);
      expect(summary.facts!.age, summary.age);
      expect(summary.facts!.netWorth, summary.netWorth);
    });

    test('and the record keeps both the story and the small detail', () {
      final record = LifeRecord.fromSummary(
        LifeSummary.fromController(live(4)),
      );
      expect(record.facts, isNotNull);
      expect(record.detail, isNotNull);

      final back = roundTrip(LifeRecord.fromJson, record.toJson());
      expect(back.facts, isNotNull);
      expect(back.detail, isNotNull);
      expect(
        back.facts!.record.curve.length,
        record.facts!.record.curve.length,
      );
      expect(back.detail!.workYears, record.detail!.workYears);
    });

    test('the same life graded before and after saving reads the same', () {
      final summary = LifeSummary.fromController(live(5));
      final record = LifeRecord.fromSummary(summary);
      final back = roundTrip(LifeRecord.fromJson, record.toJson());

      final now = debriefLife(back.facts!);
      expect(now.headline, summary.debrief!.headline);
      expect(
        [for (final f in now.findings) f.id],
        [for (final f in summary.debrief!.findings) f.id],
      );
    });
  });

  group('an old record still opens', () {
    test(
      'one saved before any of this existed has neither story nor detail',
      () {
        final back = LifeRecord.fromJson(<String, dynamic>{
          'ending': 'quietLife',
          'name': 'Ada',
          'age': 70,
          'net_worth': 1000,
          'happiness': 50,
          'died': false,
          'concepts': 5,
          'gold': 10,
          'at': '2026-01-01T00:00:00.000Z',
        });
        expect(back.facts, isNull);
        expect(back.detail, isNull);
        expect(back.graded, isTrue);
      },
    );
  });

  group('only the newest few keep the story', () {
    LifeRecord withStory(int n) => LifeRecord(
      endingId: 'quietLife',
      name: 'Life $n',
      age: 60 + n,
      netWorth: 100 * n,
      happiness: 50,
      died: false,
      conceptsMet: n,
      goldEarned: 0,
      finishedAt: DateTime.utc(2026, 1, 1).add(Duration(days: n)),
      detail: LifeDetail(degrees: n % 2, workYears: 20),
      facts: richRunFacts(),
    );

    test('the newest keep it and the older ones keep only the detail', () {
      var book = const LifeRecordBook(<LifeRecord>[]);
      for (var n = 1; n <= 8; n++) {
        book = book.add(withStory(n));
      }
      final newest = book.newestFirst;
      for (var i = 0; i < LifeRecordBook.keepFactsFor; i++) {
        expect(newest[i].facts, isNotNull, reason: 'life ${newest[i].name}');
      }
      for (var i = LifeRecordBook.keepFactsFor; i < newest.length; i++) {
        expect(newest[i].facts, isNull, reason: 'life ${newest[i].name}');
        expect(newest[i].detail, isNotNull, reason: 'the detail is kept');
      }
    });

    test('and that is what is written down', () {
      var book = const LifeRecordBook(<LifeRecord>[]);
      for (var n = 1; n <= 8; n++) {
        book = book.add(withStory(n));
      }
      final written = book.toJson();
      final withFacts = written.where((r) => r.containsKey('facts')).length;
      expect(withFacts, LifeRecordBook.keepFactsFor);
      expect(written.every((r) => r.containsKey('detail')), isTrue);
    });
  });

  group('the new things a life is graded on', () {
    LifeRunFacts facts({
      LifeRunTally tally = const LifeRunTally(adultYears: 30, workYears: 25),
      int age = 50,
      int assetsValue = 0,
      int loanBalance = 0,
      bool ownsHome = false,
      bool hasPartner = false,
      int children = 0,
      int? connection,
    }) => LifeRunFacts(
      age: age,
      netWorth: 1000,
      cash: 500,
      investments: 0,
      emergencyFund: 500,
      debt: 0,
      health: 70,
      happiness: 60,
      conceptsMet: 6,
      died: false,
      everStarved: false,
      budgetSet: true,
      assetsValue: assetsValue,
      loanBalance: loanBalance,
      ownsHome: ownsHome,
      hasPartner: hasPartner,
      children: children,
      connection: connection,
      record: LifeRunRecord(tally: tally),
    );

    Set<String> ids(LifeRunFacts f) => {
      for (final finding in debriefLife(f).findings) finding.id,
    };

    test('school borrowed for and never cleared is a fault', () {
      final found = ids(
        facts(
          tally: const LifeRunTally(adultYears: 30, studentBorrowed: 4000),
          loanBalance: 2500,
          assetsValue: 9000,
        ),
      );
      expect(found, contains('school_debt_carried'));
      expect(found, isNot(contains('school_debt_cleared')));
    });

    test('school borrowed for and paid off is a strength, not silence', () {
      final found = ids(
        facts(
          tally: const LifeRunTally(adultYears: 30, studentBorrowed: 4000),
          loanBalance: 0,
        ),
      );
      expect(found, contains('school_debt_cleared'));
      expect(found, isNot(contains('school_debt_carried')));
    });

    test('a small loan for a short course is not called a problem', () {
      final found = ids(
        facts(
          tally: const LifeRunTally(adultYears: 30, studentBorrowed: 300),
          loanBalance: 100,
          assetsValue: 5000,
        ),
      );
      expect(found, isNot(contains('school_debt_carried')));
    });

    test('a qualification that led up a ladder is named', () {
      final found = ids(
        facts(
          tally: const LifeRunTally(
            adultYears: 30,
            workYears: 25,
            degreesEarned: 1,
            promotions: 2,
          ),
        ),
      );
      expect(found, contains('qualification_paid'));
    });

    test(
      'twelve years on one rung is named, and a layoff is not blamed on it',
      () {
        expect(
          ids(facts(tally: const LifeRunTally(adultYears: 30, workYears: 14))),
          contains('stuck_on_a_rung'),
        );
        expect(
          ids(
            facts(
              tally: const LifeRunTally(
                adultYears: 30,
                workYears: 14,
                timesLaidOff: 1,
              ),
            ),
          ),
          isNot(contains('stuck_on_a_rung')),
          reason: 'losing a job explains no promotion better than a stall does',
        );
      },
    );

    test('owing more than you own is a fault, at any age past thirty', () {
      expect(
        ids(facts(age: 45, loanBalance: 8000, assetsValue: 3000)),
        contains('owed_more_than_owned'),
      );
      expect(
        ids(facts(age: 22, loanBalance: 8000, assetsValue: 3000)),
        isNot(contains('owed_more_than_owned')),
        reason: 'a young adult mid-loan is not yet in trouble',
      );
    });

    test('owning a home with more value than loan is a strength', () {
      expect(
        ids(facts(ownsHome: true, assetsValue: 9000, loanBalance: 2000)),
        contains('owned_something'),
      );
    });

    test('people who held together, with a family, are named', () {
      expect(
        ids(facts(connection: 80, hasPartner: true, children: 2)),
        contains('held_together'),
      );
      expect(
        ids(facts(connection: 80)),
        isNot(contains('held_together')),
        reason: 'no partner and no children is not this finding',
      );
    });

    test('a life with none of it says none of it', () {
      final found = ids(facts());
      for (final id in [
        'school_debt_carried',
        'school_debt_cleared',
        'qualification_paid',
        'owed_more_than_owned',
        'owned_something',
        'held_together',
      ]) {
        expect(found, isNot(contains(id)), reason: id);
      }
    });
  });

  group('tapping a life on Past Lives', () {
    UserStatsController controllerWith(List<LifeRecord> records) {
      final controller = UserStatsController(service: SupabaseService.instance);
      final base = UserStats.defaults('test_user');
      controller.seedStatsForTest(
        base.copyWith(
          spendingHabits: <String, dynamic>{
            ...base.spendingHabits,
            'life_records': LifeRecordBook(records).toJson(),
          },
        ),
      );
      return controller;
    }

    Future<void> pumpList(WidgetTester tester, List<LifeRecord> records) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final controller = controllerWith(records);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.getLightTheme(),
            home: const PastLivesScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    LifeRecord record({
      required String name,
      LifeRunFacts? facts,
      int day = 1,
    }) => LifeRecord(
      endingId: 'quietLife',
      name: name,
      age: 68,
      netWorth: 8400,
      happiness: 70,
      died: false,
      conceptsMet: 9,
      goldEarned: 20,
      finishedAt: DateTime.utc(2026, 1, day),
      facts: facts,
    );

    /// The row for the life filed on [day]. By key rather than by name, because
    /// a life's name also appears on the "best" tile it earned.
    Finder openLife(int day) => find.byKey(
      ValueKey('open-life-${DateTime.utc(2026, 1, day).toIso8601String()}'),
    );

    testWidgets('a life with its story opens the diagnostic', (tester) async {
      await pumpList(tester, [record(name: 'Ada', facts: richRunFacts())]);

      await tester.tap(openLife(1));
      await tester.pumpAndSettle();

      expect(find.byType(PastLifeScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('past-life-debrief')), findsOneWidget);
      expect(find.byKey(const ValueKey('past-life-no-story')), findsNothing);
    });

    testWidgets('an older life says plainly that its story was not kept', (
      tester,
    ) async {
      await pumpList(tester, [record(name: 'Bea')]);

      await tester.tap(openLife(1));
      await tester.pumpAndSettle();

      expect(find.byType(PastLifeScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('past-life-no-story')), findsOneWidget);
      expect(find.byKey(const ValueKey('past-life-debrief')), findsNothing);
    });

    testWidgets('each row tells you it can be opened', (tester) async {
      await pumpList(tester, [
        record(name: 'Ada', facts: richRunFacts(), day: 3),
        record(name: 'Bea', day: 2),
      ]);
      expect(find.text('Tap to see how this life went'), findsOneWidget);
      expect(find.text('Tap for the summary'), findsOneWidget);
    });

    testWidgets('you can come back to the list', (tester) async {
      await pumpList(tester, [record(name: 'Ada', facts: richRunFacts())]);
      await tester.tap(openLife(1));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PastLifeScreen), findsNothing);
      expect(find.text('History'), findsOneWidget);
    });
  });
}
