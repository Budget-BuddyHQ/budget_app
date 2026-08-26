import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_record.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

LifeRecord rec({
  String ending = 'quietLife',
  String name = 'Ada',
  int age = 70,
  int netWorth = 1000,
  int happiness = 50,
  bool died = false,
  int concepts = 5,
  int gold = 10,
  DateTime? at,
}) {
  return LifeRecord(
    endingId: ending,
    name: name,
    age: age,
    netWorth: netWorth,
    happiness: happiness,
    died: died,
    conceptsMet: concepts,
    goldEarned: gold,
    finishedAt: at ?? DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('LifeRecord serialization', () {
    test('round-trips through JSON', () {
      final original = rec(
        ending: 'legacyBuilder',
        name: 'Grace',
        age: 88,
        netWorth: 12345,
        happiness: 77,
        died: true,
        concepts: 12,
        gold: 240,
        at: DateTime.utc(2026, 3, 4, 5, 6, 7),
      );

      final restored = LifeRecord.fromJson(original.toJson());

      expect(restored.endingId, original.endingId);
      expect(restored.name, original.name);
      expect(restored.age, original.age);
      expect(restored.netWorth, original.netWorth);
      expect(restored.happiness, original.happiness);
      expect(restored.died, original.died);
      expect(restored.conceptsMet, original.conceptsMet);
      expect(restored.goldEarned, original.goldEarned);
      expect(restored.finishedAt, original.finishedAt);
    });

    test('coerces numbers that came back as strings or doubles', () {
      // This blob round-trips through a remote JSON column; what goes in as
      // an int does not reliably come back as one.
      final restored = LifeRecord.fromJson(<String, dynamic>{
        'ending': 'quietLife',
        'name': 'Ada',
        'age': '70',
        'net_worth': 1000.0,
        'happiness': '50',
        'died': false,
        'concepts': 5.0,
        'gold': '10',
        'at': '2026-01-01T00:00:00.000Z',
      });

      expect(restored.age, 70);
      expect(restored.netWorth, 1000);
      expect(restored.happiness, 50);
      expect(restored.conceptsMet, 5);
      expect(restored.goldEarned, 10);
    });

    test('survives missing and junk fields', () {
      final restored = LifeRecord.fromJson(<String, dynamic>{'name': 'X'});
      expect(restored.name, 'X');
      expect(restored.age, 0);
      expect(restored.netWorth, 0);
      expect(restored.died, isFalse);
      expect(restored.archetype, isNull);
    });

    test('archetype resolves, and is null for an unknown id', () {
      expect(rec(ending: 'legacyBuilder').archetype,
          LifeEndingArchetype.legacyBuilder);
      expect(rec(ending: 'ending_from_a_future_build').archetype, isNull);
    });
  });

  group('LifeRecordBook', () {
    test('is empty by default and from junk input', () {
      expect(const LifeRecordBook(<LifeRecord>[]).isEmpty, isTrue);
      expect(LifeRecordBook.fromJson(null).isEmpty, isTrue);
      expect(LifeRecordBook.fromJson('not a list').isEmpty, isTrue);
      expect(LifeRecordBook.fromJson(<Object>[1, 'two']).isEmpty, isTrue);
    });

    test('skips unreadable rows instead of losing the whole history', () {
      final book = LifeRecordBook.fromJson(<Object?>[
        rec(name: 'Good').toJson(),
        'garbage',
        42,
        rec(name: 'AlsoGood').toJson(),
      ]);
      expect(book.totalLives, 2);
      expect(book.records.map((r) => r.name), containsAll(['Good', 'AlsoGood']));
    });

    test('computes the three bests', () {
      final book = LifeRecordBook(<LifeRecord>[
        rec(name: 'Rich', netWorth: 9000, age: 40, concepts: 2),
        rec(name: 'Old', netWorth: 100, age: 95, concepts: 3),
        rec(name: 'Wise', netWorth: 500, age: 60, concepts: 14),
      ]);

      expect(book.richest?.name, 'Rich');
      expect(book.longest?.name, 'Old');
      expect(book.wisest?.name, 'Wise');
    });

    test('bests are null on an empty book', () {
      const book = LifeRecordBook(<LifeRecord>[]);
      expect(book.richest, isNull);
      expect(book.longest, isNull);
      expect(book.wisest, isNull);
    });

    test('newestFirst sorts by finish time', () {
      final book = LifeRecordBook(<LifeRecord>[
        rec(name: 'middle', at: DateTime.utc(2026, 2)),
        rec(name: 'oldest', at: DateTime.utc(2026, 1)),
        rec(name: 'newest', at: DateTime.utc(2026, 3)),
      ]);
      expect(
        book.newestFirst.map((r) => r.name),
        ['newest', 'middle', 'oldest'],
      );
    });

    test('add caps the history and drops the oldest', () {
      var book = const LifeRecordBook(<LifeRecord>[]);
      for (var i = 0; i < LifeRecordBook.maxRecords + 5; i++) {
        book = book.add(
          rec(name: 'life$i', at: DateTime.utc(2026, 1, 1).add(Duration(days: i))),
        );
      }

      expect(book.totalLives, LifeRecordBook.maxRecords);
      // The five oldest are gone; the newest is still at the front.
      expect(book.newestFirst.first.name,
          'life${LifeRecordBook.maxRecords + 4}');
      expect(book.records.any((r) => r.name == 'life0'), isFalse);
    });

    group('bestsBeaten', () {
      test('a first life beats nothing', () {
        // It technically tops every category, but calling a debut three
        // personal bests would make the label meaningless.
        const book = LifeRecordBook(<LifeRecord>[]);
        expect(book.bestsBeaten(rec(netWorth: 9999)), isEmpty);
      });

      test('reports only the categories actually beaten', () {
        final book = LifeRecordBook(<LifeRecord>[
          rec(netWorth: 1000, age: 70, concepts: 5),
        ]);

        expect(
          book.bestsBeaten(rec(netWorth: 2000, age: 60, concepts: 4)),
          {LifeBest.netWorth},
        );
        expect(
          book.bestsBeaten(rec(netWorth: 500, age: 80, concepts: 9)),
          {LifeBest.age, LifeBest.concepts},
        );
        expect(
          book.bestsBeaten(rec(netWorth: 3000, age: 90, concepts: 20)),
          {LifeBest.netWorth, LifeBest.age, LifeBest.concepts},
        );
      });

      test('matching a record does not count as beating it', () {
        final book = LifeRecordBook(<LifeRecord>[
          rec(netWorth: 1000, age: 70, concepts: 5),
        ]);
        expect(
          book.bestsBeaten(rec(netWorth: 1000, age: 70, concepts: 5)),
          isEmpty,
        );
      });
    });

    test('endingsSeen collects distinct non-empty ids', () {
      final book = LifeRecordBook(<LifeRecord>[
        rec(ending: 'quietLife'),
        rec(ending: 'quietLife'),
        rec(ending: 'legacyBuilder'),
        rec(ending: ''),
      ]);
      expect(book.endingsSeen, {'quietLife', 'legacyBuilder'});
    });

    test('a book survives a full JSON round-trip', () {
      final book = LifeRecordBook(<LifeRecord>[
        rec(name: 'A', at: DateTime.utc(2026, 1)),
        rec(name: 'B', at: DateTime.utc(2026, 2)),
      ]);
      final restored = LifeRecordBook.fromJson(book.toJson());
      expect(restored.totalLives, 2);
      expect(restored.newestFirst.first.name, 'B');
    });
  });

  group('LifeSummary carries conceptsMet', () {
    test('defaults to zero so old call sites keep compiling', () {
      const summary = LifeSummary(
        name: 'Ada',
        gender: Gender.female,
        origin: LifeOrigin.comfortable,
        job: 'Student',
        age: 30,
        yearsLived: 30,
        died: false,
        netWorth: 100,
        happiness: 50,
        health: 50,
        smarts: 50,
        looks: 50,
        relationships: <String>[],
        goldReward: 0,
        archetype: LifeEndingArchetype.quietLife,
      );
      expect(summary.conceptsMet, 0);
      expect(LifeRecord.fromSummary(summary).conceptsMet, 0);
    });

    test('fromSummary copies the run onto the record', () {
      const summary = LifeSummary(
        name: 'Grace',
        gender: Gender.female,
        origin: LifeOrigin.wealthy,
        job: 'Engineer',
        age: 82,
        yearsLived: 82,
        died: true,
        netWorth: 5400,
        happiness: 71,
        health: 20,
        smarts: 80,
        looks: 60,
        relationships: <String>['Sam'],
        goldReward: 190,
        archetype: LifeEndingArchetype.legacyBuilder,
        conceptsMet: 9,
      );

      final record = LifeRecord.fromSummary(summary);
      expect(record.endingId, 'legacyBuilder');
      expect(record.name, 'Grace');
      expect(record.age, 82);
      expect(record.netWorth, 5400);
      expect(record.died, isTrue);
      expect(record.conceptsMet, 9);
      expect(record.goldEarned, 190);
    });
  });
}
