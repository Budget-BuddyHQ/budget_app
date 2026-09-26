import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors `_flatCandles`' pairing rule so it can be tested without reaching
/// into a private helper on a 3,500-line screen.
///
/// The rule is the whole point: stamps pair from the **end**. A save that
/// predates timestamps has values with no times, and the newest points are
/// the ones that have them — aligning from the front would put yesterday's
/// clock on today's balance.
List<DateTime?> pairFromEnd(int valueCount, List<DateTime> stamps) {
  final offset = valueCount - stamps.length;
  return [
    for (var i = 0; i < valueCount; i++)
      (i - offset) >= 0 && (i - offset) < stamps.length
          ? stamps[i - offset]
          : null,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('net-worth history pairs values with times', () {
    final t0 = DateTime.utc(2026, 8, 20, 9);

    test('a fully stamped series pairs one to one', () {
      final stamps = [
        for (var i = 0; i < 5; i++) t0.add(Duration(hours: i)),
      ];
      final paired = pairFromEnd(5, stamps);
      expect(paired.whereType<DateTime>().length, 5);
      expect(paired.first, t0);
      expect(paired.last, t0.add(const Duration(hours: 4)));
    });

    test('a legacy series with no stamps pairs nothing, and does not throw', () {
      final paired = pairFromEnd(5, const <DateTime>[]);
      expect(paired.every((t) => t == null), isTrue);
    });

    test('a partly stamped series stamps the newest points', () {
      // Two of five values have times: they belong to the two most recent
      // snapshots, because timestamps started being recorded partway through.
      final stamps = [t0, t0.add(const Duration(hours: 1))];
      final paired = pairFromEnd(5, stamps);
      expect(paired[0], isNull);
      expect(paired[1], isNull);
      expect(paired[2], isNull);
      expect(paired[3], t0);
      expect(paired[4], t0.add(const Duration(hours: 1)));
    });

    test('more stamps than values never indexes out of range', () {
      // Defensive: the two lists are trimmed together, but a corrupted save
      // should degrade rather than crash the P&L tab.
      final stamps = [
        for (var i = 0; i < 8; i++) t0.add(Duration(hours: i)),
      ];
      expect(() => pairFromEnd(3, stamps), returnsNormally);
      final paired = pairFromEnd(3, stamps);
      expect(paired.length, 3);
    });

    test('an empty series pairs to an empty list', () {
      expect(pairFromEnd(0, const <DateTime>[]), isEmpty);
    });

    test('a forced snapshot preserves a trade at unchanged net worth', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = UserStatsController(service: SupabaseService.instance);

      await controller.recordNetWorth(2000);
      await controller.recordNetWorth(2000, force: true);

      expect(controller.realPortfolioHistory, hasLength(2));
      expect(controller.portfolioHistoryTimes, hasLength(2));
    });
  });

  group('endings still resolve', () {
    // Cheap guard that the archetype table did not lose an entry while the
    // portraits were being wired in.
    test('every archetype has a label and a portrait', () {
      for (final a in LifeEndingArchetype.values) {
        expect(a.label, isNotEmpty);
        expect(a.portrait, contains('ending_faces'));
      }
    });
  });
}
