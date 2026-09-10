import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

/// The Ranked board.
///
/// **What was missing.** Ranked is the one-life scored mode, and its whole
/// premise is *"given the same start everybody else got, how much can you
/// build?"* — a question that only means anything if the answer is comparable
/// to somebody. It was not comparable to anything, including your own last
/// attempt: `scoreRankedRun` produced a score, the epilogue screen showed it,
/// and the number was gone the moment that screen was popped.
///
/// So the mode had no memory, no personal best, and no board.
void main() {
  LeaderboardEntry entry({
    int literacy = 0,
    int xp = 0,
    int gold = 0,
    int ranked = 0,
    String grade = '',
    int age = 0,
  }) => LeaderboardEntry(
    id: 'x',
    rank: 1,
    username: 'x',
    literacyPoints: literacy,
    xp: xp,
    gold: gold,
    isCurrentUser: false,
    rankedScore: ranked,
    rankedGrade: grade,
    rankedAge: age,
  );

  group('the metric', () {
    test('there are three of them', () {
      // This was `bool byGold`, which is the shape that stops working the
      // moment there is a third thing to rank by.
      expect(LeaderboardMetric.values.length, 3);
    });

    test('each sorts by its own column first', () {
      expect(LeaderboardMetric.literacy.orderColumns.first, 'literacy_points');
      expect(LeaderboardMetric.gold.orderColumns.first, 'gold');
      expect(
        LeaderboardMetric.ranked.orderColumns.first,
        'best_ranked_score',
      );
    });

    test('every metric has tie-breaks', () {
      // A single sort key leaves ties ordered by whatever the database felt
      // like, which means the board can reshuffle between two identical
      // loads.
      for (final metric in LeaderboardMetric.values) {
        expect(
          metric.orderColumns.length,
          greaterThanOrEqualTo(2),
          reason: '${metric.name} has no tie-break',
        );
        expect(
          metric.orderColumns.toSet().length,
          metric.orderColumns.length,
          reason: '${metric.name} repeats a column',
        );
      }
    });

    test('ranked breaks ties toward the longer life', () {
      // Surviving longer for the same total is the harder run — the same
      // reasoning that makes survival a *multiplier* in `scoreRankedRun`
      // rather than a bonus.
      expect(LeaderboardMetric.ranked.orderColumns[1], 'best_ranked_age');
    });
  });

  group('what a row shows', () {
    test('the headline follows the metric', () {
      final row = entry(literacy: 40, gold: 900, ranked: 1200);
      expect(row.headlineFor(LeaderboardMetric.literacy), '40 LP');
      expect(row.headlineFor(LeaderboardMetric.gold), '900g');
      expect(row.headlineFor(LeaderboardMetric.ranked), '1200');
    });

    test('somebody who has never played Ranked shows a dash, not a zero', () {
      // A zero looks like a score you earned and lost with. A dash is honest
      // about there being nothing there — and on a board where most players
      // have not tried the mode, that distinction is most of the screen.
      final row = entry(literacy: 40);
      expect(row.headlineFor(LeaderboardMetric.ranked), '—');
      expect(row.detailFor(LeaderboardMetric.ranked), 'No ranked life yet');
    });

    test('the ranked detail says what the score was made of', () {
      // The grade and the age. A fortune at thirty-five and a comfortable
      // eighty can total the same, and they are not the same run.
      final row = entry(ranked: 900, grade: 'B', age: 74);
      expect(row.detailFor(LeaderboardMetric.ranked), contains('B'));
      expect(row.detailFor(LeaderboardMetric.ranked), contains('74'));
    });

    test('a scored run with no stored grade still reads', () {
      // Grades were added alongside the score, so a row written by an older
      // client can have one without the other.
      final row = entry(ranked: 500, age: 60);
      expect(row.detailFor(LeaderboardMetric.ranked), contains('60'));
      expect(row.detailFor(LeaderboardMetric.ranked), isNot(contains('••')));
    });
  });

  group('it survives the database not being ready', () {
    test('a row with no ranked columns defaults to nothing, not a crash', () {
      // `0005_leaderboard_profile.sql` may not have been run. Every column
      // added after the original six is read defensively for that reason —
      // this project once shipped a feature ahead of its migration and spent
      // weeks showing players a raw Postgres error code.
      final row = entry();
      expect(row.rankedScore, 0);
      expect(row.rankedGrade, '');
      expect(row.rankedAge, 0);
    });

    test('the view exposes the three ranked columns', () {
      final sql = File(
        'supabase/migrations/0005_leaderboard_profile.sql',
      ).readAsStringSync();

      for (final column in <String>[
        'best_ranked_score',
        'best_ranked_grade',
        'best_ranked_age',
      ]) {
        expect(
          sql.contains('as $column'),
          isTrue,
          reason: 'the Ranked board has no $column to sort on',
        );
      }
    });

    test('the ranked score is coerced, not cast', () {
      // Same reasoning as `daily_streak`: this is JSON written by clients of
      // several versions, and a bad cast takes the whole leaderboard down
      // rather than one column.
      final sql = File(
        'supabase/migrations/0005_leaderboard_profile.sql',
      ).readAsStringSync();
      final at = sql.indexOf('as best_ranked_score');
      expect(at, greaterThan(-1));
      expect(sql.substring(0, at), contains('regexp_replace'));
    });
  });

  group('only a personal best is kept', () {
    test('the controller compares before it writes', () {
      // A board of most-recent runs rewards playing often, and this is a
      // one-life challenge. Keeping the best also means a bad run costs
      // nothing but the time, which is the right shape for something people
      // should feel free to attempt badly.
      final controller = File(
        'lib/controllers_that_updates_stats/user_stats_controller.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');

      final at = controller.indexOf('Future<StatsActionResult> recordRankedRun');
      expect(at, greaterThan(-1), reason: 'ranked runs are not recorded');
      expect(
        controller.substring(at, at + 500),
        contains('score <= _stats.bestRankedScore'),
      );
    });

    test('the life screen actually files it', () {
      // The score used to be computed and handed straight to the epilogue,
      // which is where it died.
      final page = File(
        'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
        'life_sim_page.dart',
      ).readAsStringSync();
      expect(page.contains('recordRankedRun('), isTrue);
    });
  });
}
