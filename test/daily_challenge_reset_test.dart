import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_habit_models.dart';

/// The daily challenge is daily.
///
/// **The report:** *"for the daily challenge change it to reset every day"*.
///
/// **What it was.** The completion check accepted an *undated* key next to
/// the dated one:
///
/// ```dart
/// return completed.contains('daily_budget_battle') ||
///     completed.contains('daily_budget_battle_$today');
/// ```
///
/// and the challenge screen wrote both on every win. So the first time
/// anybody finished it, `daily_budget_battle` landed in
/// `completed_challenge_tasks` and stayed there — and the card read
/// *"Challenge cleared. Play again for practice."* every day after, forever.
///
/// The dated key worked perfectly and was never reached, because `||`
/// short-circuited on the legacy one first. Nothing threw, nothing logged,
/// and the feature looked implemented.
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  const controller =
      'lib/controllers_that_updates_stats/user_stats_controller.dart';
  const screen =
      'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
      'react_challenge_screen.dart';

  group('completion is dated', () {
    test('the check never accepts an undated key', () {
      final src = read(controller);
      final start = src.indexOf('bool get isTodayChallengeCompleted');
      expect(start, greaterThan(-1));

      // Only the body. The doc comment above it quotes the old code on
      // purpose, so scanning the whole region would match the very thing
      // being guarded against.
      final body = src.substring(start, src.indexOf('}', start));

      expect(
        body.contains("'daily_budget_battle'"),
        isFalse,
        reason:
            'the undated key is back, and the challenge will never reset '
            'again for anybody who has cleared it once',
      );
      expect(body.contains('HabitDateKeys.todayKey()'), isTrue);
    });

    test('the win never writes an undated key', () {
      final src = read(screen);
      expect(
        src.contains(".add('daily_budget_battle')"),
        isFalse,
        reason: 'writing the undated key pins the card permanently',
      );
      expect(src.contains("'daily_budget_battle_\$today'"), isTrue);
    });

    test('the date format is not hand-rolled a second time', () {
      // It used to build `yyyy-MM-dd` inline while the controller used
      // `HabitDateKeys`. They agreed, which is the dangerous kind of
      // duplication — when a hand-rolled format eventually drifts, the dated
      // key silently stops matching and the challenge is either always done
      // or never done, with no error either way.
      final src = read(screen);
      expect(src.contains('HabitDateKeys.todayKey()'), isTrue);
      expect(
        src.contains("padLeft(2, '0')}-\${now.day"),
        isFalse,
        reason: 'the date format is written out by hand again',
      );
    });

    test('old day keys are pruned', () {
      // This list is stored in `spending_habits` and rewritten on every
      // completion. Unbounded, it grows by one entry a day forever.
      final src = read(screen);
      expect(src.contains('HabitDateKeys.lastDayKeys('), isTrue);
    });
  });

  group('the day key itself', () {
    test('rolls over at midnight and is stable within a day', () {
      final morning = DateTime(2026, 9, 9, 0, 1);
      final night = DateTime(2026, 9, 9, 23, 59);
      final tomorrow = DateTime(2026, 9, 10, 0, 1);

      expect(HabitDateKeys.todayKey(morning), HabitDateKeys.todayKey(night));
      expect(
        HabitDateKeys.todayKey(tomorrow),
        isNot(HabitDateKeys.todayKey(night)),
      );
    });

    test('pads, so keys sort and compare as strings', () {
      expect(HabitDateKeys.todayKey(DateTime(2026, 1, 2)), '2026-01-02');
    });

    test('the last 30 keys are 30 distinct days ending today', () {
      final keys = HabitDateKeys.lastDayKeys(30, now: DateTime(2026, 9, 9));
      expect(keys.length, 30);
      expect(keys.toSet().length, 30);
      expect(keys.last, '2026-09-09');
    });
  });
}
