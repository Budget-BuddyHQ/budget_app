import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// How repetitive a played-out life *reads*.
///
/// **Why this is measured rather than eyeballed.** Reported as the main game
/// feeling repeated — and the events were not the problem. Across sixty runs,
/// any two lives share only 2-12% of their events. What repeated was the
/// prose around them:
///
/// * `'Turned $age.'` printed on every year that drew an event, about three
///   quarters of them, directly under a feed header that already said
///   "Age 12". The single most common line in the log was a restatement of
///   the line above it.
/// * The paycheck line was one fixed sentence on every earning year — 15% of
///   every line in the feed, word for word.
/// * "A tight year. You made it work." was another 6%.
///
/// A player scrolling back through a life saw the same handful of sentences
/// over and over and correctly concluded the game was repeating itself, even
/// though the decisions were not. The feed is where every lesson in this app
/// lives, so a feed people stop reading is not a cosmetic problem.
///
/// These thresholds are deliberately loose. The point is to catch a *new*
/// line becoming wallpaper, not to freeze the current wording.
void main() {
  /// Plays [runs] lives to their end and returns every log line produced.
  List<String> playedLines({int runs = 40}) {
    final lines = <String>[];
    for (var seed = 0; seed < runs; seed++) {
      final life = LifeSimController(random: Random(seed), initialAge: 0);
      while (!life.finished && life.age < 90) {
        final event = life.currentEvent;
        if (event != null) {
          life.chooseOption(
            Random(seed * 7 + life.age).nextInt(event.choices.length),
          );
        }
        life.ageUp();
      }
      lines.addAll(life.history.map((entry) => entry.text));
    }
    return lines;
  }

  test('no single line dominates the feed', () {
    final lines = playedLines();
    final counts = <String, int>{};
    for (final line in lines) {
      counts[line] = (counts[line] ?? 0) + 1;
    }
    final worst = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final share = worst.value / lines.length;
    expect(
      share,
      lessThan(0.05),
      reason:
          '"${worst.key}" is ${(share * 100).toStringAsFixed(1)}% of every '
          'line a player reads',
    );
  });

  test('the age header is not restated as a log line', () {
    // The exact line that was removed. The feed already prints "Age 12" above
    // the year; printing "Turned 12." inside it says nothing twice.
    final lines = playedLines(runs: 20);
    final restatements = lines.where(
      (line) => RegExp(r'^Turned \d+\.$').hasMatch(line),
    );
    expect(
      restatements,
      isEmpty,
      reason: '${restatements.length} lines just repeat the age header',
    );
  });

  test('a life produces mostly distinct lines', () {
    final lines = playedLines();
    final distinct = lines.toSet().length;
    expect(
      distinct / lines.length,
      greaterThan(0.18),
      reason:
          'only ${(distinct / lines.length * 100).round()}% of the lines in a '
          'life are distinct',
    );
  });

  test('the routine lines vary without hiding the numbers', () {
    // The budget line has to fire every earning year — that is what makes it
    // a routine, and the routine is the lesson. What it must not do is fire
    // in identical words, so there are several openers and all of them carry
    // the figure.
    final lines = playedLines(runs: 25);
    final pay = lines.where((l) => l.contains('50/30/20')).toList();
    expect(pay, isNotEmpty, reason: 'the budget line stopped firing at all');

    final openers = pay
        .map((l) => l.split(RegExp(r'[.,]')).first)
        .toSet();
    expect(
      openers.length,
      greaterThan(2),
      reason: 'the paycheck line has only ${openers.length} phrasing(s)',
    );
    for (final line in pay) {
      expect(
        RegExp(r'\d').hasMatch(line),
        isTrue,
        reason: 'a paycheck line with no figure in it: "$line"',
      );
    }
  });

  test('quiet years still say something age-appropriate', () {
    // About a quarter of years draw no event on purpose, so events feel like
    // events. Those are the years with nothing else to print, and they are
    // the ones that most need not to be identical.
    final life = LifeSimController(random: Random(3), initialAge: 0);
    final quiet = <String>{};
    while (!life.finished && life.age < 90) {
      final before = life.history.length;
      final event = life.currentEvent;
      if (event != null) life.chooseOption(0);
      life.ageUp();
      if (life.history.length > before && life.currentEvent == null) {
        quiet.add(life.history.last.text);
      }
    }
    expect(
      quiet.length,
      greaterThan(4),
      reason: 'a whole life produced only ${quiet.length} quiet-year lines',
    );
  });
}
