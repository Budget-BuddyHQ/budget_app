import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_enemies.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_wave_rules.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Finance Brawl's waves, and the bug that left a player standing on wave ten
/// with nothing to fight and nothing coming.
///
/// **Reported as:** *"the user gets to wave 10 and then nothing spawns and the
/// user is just stuck there."*
///
/// Two separate faults, both about counting:
///
///  * On a boss wave the boss only spawned when the debts cleared were exactly
///    the quota. Subscription Creep spawns five at once and could carry the
///    count past it. Then there was nothing left to kill, the quota was met so
///    nothing more spawned, and the boss waited for a number it could no longer
///    reach.
///  * A perfect checkpoint advanced the wave once when the quiz closed and again
///    when the upgrade was picked, so waves were skipped, and with them the boss
///    on whichever number fell in the gap.
///
/// The first is tested against the pure rules by playing waves out. The second
/// drives the real screen, because the two increments were in two different
/// methods of its state.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the counts add up', () {
    test('a boss wave holds one place back for the boss', () {
      expect(isBossWave(5), isTrue);
      expect(isBossWave(10), isTrue);
      expect(isBossWave(7), isFalse);
      expect(minionQuota(10), debtQuota(10) - 1);
      expect(minionQuota(7), debtQuota(7));
    });

    test('a swarm is trimmed to what the wave has room for', () {
      final quota = minionQuota(4);
      // Two places left and a swarm of five: two, not five.
      expect(
        swarmToSpawn(wave: 4, cleared: quota - 6, aliveMinions: 4, swarm: 5),
        2,
      );
      // Plenty of room: the whole swarm.
      expect(swarmToSpawn(wave: 4, cleared: 0, aliveMinions: 0, swarm: 5), 5);
      // No room at all still spawns one, so the last place is fillable.
      expect(
        swarmToSpawn(wave: 4, cleared: quota, aliveMinions: 0, swarm: 5),
        1,
      );
    });

    test('nothing is spawned once the quota is met', () {
      final quota = minionQuota(3);
      expect(
        nextWaveStep(
          wave: 3,
          cleared: quota,
          aliveMinions: 0,
          bossPresent: false,
        ),
        WaveStep.wait,
      );
    });

    test(
      'the boss comes when the minions are used up, however they got there',
      () {
        // The exact state the bug produced: every minion dead and the count one
        // past the quota, because a swarm carried it over. The old rule waited for
        // `cleared == quota` and so waited forever.
        final quota = minionQuota(10);
        for (final cleared in [quota, quota + 1, quota + 3]) {
          expect(
            nextWaveStep(
              wave: 10,
              cleared: cleared,
              aliveMinions: 0,
              bossPresent: false,
            ),
            WaveStep.spawnBoss,
            reason: 'with $cleared cleared and none alive the boss must come',
          );
        }
      },
    );

    test('the boss does not come while minions are still alive', () {
      expect(
        nextWaveStep(
          wave: 10,
          cleared: minionQuota(10) - 2,
          aliveMinions: 2,
          bossPresent: false,
        ),
        WaveStep.wait,
      );
    });

    test('the boss comes once, not every tick', () {
      expect(
        nextWaveStep(
          wave: 10,
          cleared: minionQuota(10),
          aliveMinions: 0,
          bossPresent: true,
        ),
        WaveStep.wait,
      );
    });
  });

  group('every wave can be finished', () {
    /// Plays a wave out the way the game does: spawn when told to, kill things
    /// at random, and stop when the wave is over. Returns how many ticks it
    /// took, or -1 if it got stuck.
    ///
    /// [alwaysSwarm] forces the archetype that spawns five at once, which is the
    /// worst case for overshoot.
    int playWave(int wave, Random rng, {required bool alwaysSwarm}) {
      var cleared = 0;
      var alive = 0;
      var bossPresent = false;
      var bossesSpawned = 0;
      final quota = debtQuota(wave);
      final swarm = kBrawlEnemies.firstWhere((e) => e.swarmCount > 1);

      for (var tick = 0; tick < 5000; tick++) {
        final step = nextWaveStep(
          wave: wave,
          cleared: cleared,
          aliveMinions: alive,
          bossPresent: bossPresent,
        );
        switch (step) {
          case WaveStep.spawnMinion:
            final archetype = alwaysSwarm
                ? swarm
                : pickEnemy(wave, rng.nextDouble());
            alive += swarmToSpawn(
              wave: wave,
              cleared: cleared,
              aliveMinions: alive,
              swarm: archetype.swarmCount,
            );
          case WaveStep.spawnBoss:
            bossPresent = true;
            bossesSpawned++;
          case WaveStep.wait:
            break;
        }

        // The count on the field plus the count cleared never passes the quota.
        expect(
          cleared + alive,
          lessThanOrEqualTo(minionQuota(wave) + (bossPresent ? 1 : 0)),
          reason: 'wave $wave overshot its quota',
        );

        // Kill something, most ticks. The boss goes last.
        if (alive > 0 && rng.nextInt(3) != 0) {
          alive--;
          if (cleared < quota) cleared++;
        } else if (alive == 0 && bossPresent && rng.nextInt(3) != 0) {
          bossPresent = false;
          if (cleared < quota) cleared++;
          expect(bossesSpawned, 1, reason: 'more than one boss in a wave');
          return tick;
        }

        if (!isBossWave(wave) && cleared >= quota) return tick;
      }
      return -1;
    }

    test('every wave from 1 to 60 ends, even when every spawn is a swarm', () {
      for (var wave = 1; wave <= 60; wave++) {
        for (var seed = 0; seed < 6; seed++) {
          expect(
            playWave(wave, Random(wave * 97 + seed), alwaysSwarm: true),
            isNot(-1),
            reason: 'wave $wave got stuck with nothing to spawn (seed $seed)',
          );
        }
      }
    });

    test('and with the real mix of enemies', () {
      for (var wave = 1; wave <= 60; wave++) {
        for (var seed = 0; seed < 6; seed++) {
          expect(
            playWave(wave, Random(wave * 131 + seed), alwaysSwarm: false),
            isNot(-1),
            reason: 'wave $wave got stuck (seed $seed)',
          );
        }
      }
    });

    test('a boss wave always produces its boss', () {
      for (final wave in [5, 10, 15, 20, 25]) {
        var bossSeen = false;
        var cleared = 0;
        var alive = 0;
        final rng = Random(wave);
        for (var tick = 0; tick < 5000 && !bossSeen; tick++) {
          switch (nextWaveStep(
            wave: wave,
            cleared: cleared,
            aliveMinions: alive,
            bossPresent: false,
          )) {
            case WaveStep.spawnMinion:
              alive += swarmToSpawn(
                wave: wave,
                cleared: cleared,
                aliveMinions: alive,
                swarm: 5,
              );
            case WaveStep.spawnBoss:
              bossSeen = true;
            case WaveStep.wait:
              break;
          }
          if (alive > 0 && rng.nextBool()) {
            alive--;
            cleared++;
          }
        }
        expect(bossSeen, isTrue, reason: 'wave $wave never brought its boss');
      }
    });
  });

  group('waves advance one at a time', () {
    Future<dynamic> pumpGame(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStatsController>(
              create: (_) =>
                  UserStatsController(service: SupabaseService.instance),
            ),
          ],
          child: const MaterialApp(home: FinanceBrawlScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      return tester.state(find.byType(FinanceBrawlScreen));
    }

    testWidgets('a perfect checkpoint moves up by exactly one wave', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      expect(game.waveForTest, 1);
      game.runCheckpointForTest(perfect: true);
      await tester.pump();
      expect(
        game.waveForTest,
        2,
        reason: 'a perfect checkpoint used to count twice and land on wave 3',
      );
      await _letToastsExpire(tester);
    });

    testWidgets('a poor checkpoint moves up by exactly one wave too', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      game.runCheckpointForTest(perfect: false);
      await tester.pump();
      expect(game.waveForTest, 2);
      await _letToastsExpire(tester);
    });

    testWidgets('a run that keeps answering perfectly visits wave ten', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final visited = <int>[game.waveForTest as int];
      for (var i = 0; i < 12; i++) {
        game.runCheckpointForTest(perfect: true);
        await tester.pump();
        visited.add(game.waveForTest as int);
      }
      expect(visited, [
        for (var w = 1; w <= 13; w++) w,
      ], reason: 'no wave, and so no boss, may be skipped');
      await _letToastsExpire(tester);
    });
  });
}

/// The checkpoint shows a toast, and a toast dismisses itself on a timer. A test
/// that ends before it does fails with a pending timer, so run the clock out.
Future<void> _letToastsExpire(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 4));
