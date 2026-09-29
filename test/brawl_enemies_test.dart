import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_enemies.dart';

/// The Finance Brawl roster.
///
/// **What this replaced.** Four "enemies" — Credit Card Debt, Payday Loan,
/// Medical Bill, Auto Loan — with identical hit points, speed, color and
/// reward. One enemy with four labels, plus a single real variant at wave 3.
/// Naming a payday loan and an auto loan differently while making them behave
/// identically quietly teaches that they *are* the same, which is false and is
/// the opposite of what this app is for.
///
/// The design rule every archetype follows is that **the behavior is the
/// lesson**, so these tests check the behavior rather than the copy. A
/// payday loan that stops draining faster than everything else has lost the
/// only thing it was teaching, and no test of its description would notice.
void main() {
  BrawlEnemy byId(String id) => kBrawlEnemies.firstWhere((e) => e.id == id);

  group('the roster is actually varied', () {
    test('there are meaningfully more than the old four', () {
      expect(kBrawlEnemies.length, greaterThanOrEqualTo(10));
    });

    test('ids are unique', () {
      final ids = kBrawlEnemies.map((e) => e.id).toSet();
      expect(ids.length, kBrawlEnemies.length);
    });

    test('no two archetypes share a stat block', () {
      // The exact bug being fixed: four names, one set of numbers.
      final blocks = kBrawlEnemies
          .map((e) => '${e.hpScale}/${e.speedScale}/${e.drainScale}/'
              '${e.radius}/${e.swarmCount}')
          .toSet();
      expect(
        blocks.length,
        kBrawlEnemies.length,
        reason: 'two enemies are mechanically identical and differ only by '
            'name, which is what the old roster did',
      );
    });

    test('every archetype explains itself', () {
      for (final e in kBrawlEnemies) {
        expect(e.name.trim(), isNotEmpty);
        expect(
          e.lesson.trim().length,
          greaterThan(40),
          reason: '${e.id} has no real lesson attached',
        );
        expect(e.goldReward, greaterThan(0));
        expect(e.hpScale, greaterThan(0));
        expect(e.speedScale, greaterThan(0));
      }
    });
  });

  group('the behavior matches what the debt actually does', () {
    test('a payday loan drains faster than anything else', () {
      final payday = byId('payday_loan');
      for (final other in kBrawlEnemies) {
        if (other.id == 'payday_loan') continue;
        expect(
          payday.drainScale,
          greaterThan(other.drainScale),
          reason: 'the payday loan is meant to be the most expensive thing '
              'on the board — that is the entire lesson',
        );
      }
      // Small and quick, so the damage is clearly not about size.
      expect(payday.radius, lessThan(byId('auto_loan').radius));
      expect(payday.speedScale, greaterThan(1.0));
    });

    test('a student loan is huge and slow, not an emergency', () {
      final student = byId('student_loan');
      expect(student.hpScale, greaterThan(2.5));
      expect(student.speedScale, lessThan(0.6));
      // And it should not be the thing draining you fastest — panicking about
      // it is the mistake, so it must not behave like a crisis.
      expect(student.drainScale, lessThan(byId('payday_loan').drainScale));
    });

    test('subscription creep is trivial alone and heavy together', () {
      final subs = byId('subscription_creep');
      expect(subs.swarmCount, greaterThan(1));
      expect(subs.hpScale, lessThan(0.4));

      // The point: five of them outweigh a single ordinary enemy.
      final creditCard = byId('credit_card');
      expect(
        subs.hpScale * subs.swarmCount,
        greaterThan(creditCard.hpScale),
        reason: 'a swarm of subscriptions has to add up to more than one '
            'normal enemy or the lesson does not happen',
      );
    });

    test('an auto loan is big, slow and predictable', () {
      final auto = byId('auto_loan');
      expect(auto.hpScale, greaterThan(1.5));
      expect(auto.speedScale, lessThan(0.8));
      expect(auto.drainScale, lessThanOrEqualTo(1.0));
    });
  });

  group('the roster reveals itself over time', () {
    test('wave 1 is a teachable handful, not everything at once', () {
      final first = enemiesForWave(1);
      expect(first, isNotEmpty);
      expect(
        first.length,
        lessThan(kBrawlEnemies.length),
        reason: 'every enemy in the game arrives in wave 1',
      );
    });

    test('later waves strictly add to earlier ones', () {
      for (var wave = 1; wave < 12; wave++) {
        final now = enemiesForWave(wave).map((e) => e.id).toSet();
        final next = enemiesForWave(wave + 1).map((e) => e.id).toSet();
        expect(
          now.difference(next),
          isEmpty,
          reason: 'an enemy available at wave $wave disappears at ${wave + 1}',
        );
      }
    });

    test('the whole roster is reachable', () {
      final late = enemiesForWave(20).map((e) => e.id).toSet();
      expect(late.length, kBrawlEnemies.length);
    });
  });

  group('picking a spawn', () {
    test('it never returns an enemy the wave has not unlocked', () {
      for (var wave = 1; wave <= 12; wave++) {
        for (var i = 0; i <= 100; i++) {
          final picked = pickEnemy(wave, i / 100);
          expect(
            picked.minWave,
            lessThanOrEqualTo(wave),
            reason: '${picked.id} (wave ${picked.minWave}) spawned on $wave',
          );
        }
      }
    });

    test('elites stay rare enough to feel like elites', () {
      var elites = 0;
      const rolls = 200;
      for (var i = 0; i < rolls; i++) {
        if (pickEnemy(10, i / rolls).isElite) elites++;
      }
      // A board made mostly of elites is just a harder board with the same
      // texture — the contrast is what makes them read as special.
      expect(elites / rolls, lessThan(0.35));
      expect(elites, greaterThan(0));
    });

    test('one roll fully determines the spawn', () {
      // The caller supplies the randomness so this stays testable, and the
      // same number has to give the same enemy or nothing can be pinned.
      for (var i = 0; i <= 20; i++) {
        final roll = i / 20;
        expect(pickEnemy(8, roll).id, pickEnemy(8, roll).id);
      }
    });

    test('early waves still produce variety', () {
      final seen = <String>{};
      for (var i = 0; i <= 100; i++) {
        seen.add(pickEnemy(3, i / 100).id);
      }
      expect(
        seen.length,
        greaterThan(2),
        reason: 'wave 3 keeps spawning the same one or two enemies',
      );
    });
  });

  group('every archetype has its own face', () {
    // Ten archetypes rendered from three images, chosen by `isBoss` /
    // `isEnemyTwo`. Two bits cannot tell ten things apart, so a student loan
    // and an overdraft fee were the same object on screen — which undoes the
    // rule the whole roster is built on, because a player cannot learn "that
    // one is dangerous" from something they cannot pick out.
    //
    // Drawn by `tool/make_brawl_enemies.py`. Re-run it after adding an
    // archetype.
    File spriteFor(BrawlEnemy enemy) =>
        File(AppAssets.brawlEnemySprite(enemy.id));

    test('a sprite exists for every archetype', () {
      for (final enemy in kBrawlEnemies) {
        final file = spriteFor(enemy);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              '${enemy.name} has no sprite at ${file.path}. '
              'Run: python tool/make_brawl_enemies.py',
        );
      }
    });

    test('no two archetypes share artwork', () {
      // The generator builds each sprite from its archetype's own color, so
      // a duplicate here means a builder was copied and not edited — which
      // would put the roster straight back where it started.
      final byDigest = <String, String>{};
      for (final enemy in kBrawlEnemies) {
        final file = spriteFor(enemy);
        if (!file.existsSync()) continue;
        final digest = base64Encode(file.readAsBytesSync());
        expect(
          byDigest.containsKey(digest),
          isFalse,
          reason:
              '${enemy.name} is pixel-identical to ${byDigest[digest]}',
        );
        byDigest[digest] = enemy.name;
      }
    });

    test('the sprite folder is declared in pubspec', () {
      // Flutter asset directories are not recursive: `assets/images/` does
      // not carry `assets/images/finance_brawl_ui/enemies/` with it, and a
      // missing line here fails only at runtime, in release, as ten enemies
      // silently reverting to the old shared art.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        pubspec.contains('assets/images/finance_brawl_ui/enemies/'),
        isTrue,
        reason: 'the per-archetype sprites will not ship',
      );
    });
  });
}
