import 'dart:math';

/// How many enemies a Finance Brawl wave asks for, and what to spawn next.
///
/// **Why this is a file of its own.** These rules lived inline in the game's
/// tick, next to the drawing code, where the only way to test them was to play
/// the game to wave ten. That is how a bug got to a player: on a boss wave the
/// boss only appeared when the number of debts cleared was *exactly* the quota,
/// and a swarm (Subscription Creep arrives five at a time) could carry the count
/// past the quota in one spawn. Nothing was left to kill, the quota was already
/// met so nothing more spawned, and the boss never came. The player stood in an
/// empty field on wave ten with no way forward.
///
/// Two rules close that, and both are here so a test can hold them:
///
///  * a swarm is **trimmed to what the wave still has room for**, so the count
///    can never overshoot, and
///  * the boss comes when the minions are **used up**, not when a counter
///    happens to equal a number, so a wave can never wait for a value that is
///    no longer reachable.

/// Every fifth wave is a market crisis with a boss at the end of it.
bool isBossWave(int wave) => wave % 5 == 0;

/// How many debts a wave counts. The bar on screen fills to this.
int debtQuota(int wave) => 6 + (wave * 3);

/// How many ordinary enemies a wave spawns. A boss wave saves one place in its
/// quota for the boss.
int minionQuota(int wave) {
  final quota = debtQuota(wave);
  return isBossWave(wave) ? max(0, quota - 1) : quota;
}

/// What the spawner should do on this tick.
enum WaveStep {
  /// Add an ordinary enemy (or a swarm of them).
  spawnMinion,

  /// Every minion has been spawned and killed: bring in the boss.
  spawnBoss,

  /// Nothing to add. Either enemies are still alive to be cleared, or the boss
  /// is out, or the wave is complete.
  wait,
}

/// Decides the next spawn.
///
/// [cleared] is debts cleared so far this wave, [aliveMinions] the ordinary
/// enemies currently on the field, and [bossPresent] whether the boss is out.
WaveStep nextWaveStep({
  required int wave,
  required int cleared,
  required int aliveMinions,
  required bool bossPresent,
}) {
  final quota = minionQuota(wave);
  if (cleared + aliveMinions < quota) return WaveStep.spawnMinion;
  if (isBossWave(wave) && !bossPresent && aliveMinions == 0) {
    return WaveStep.spawnBoss;
  }
  return WaveStep.wait;
}

/// How many of a [swarm] to actually spawn.
///
/// Never more than the wave has room for, and never fewer than one: a swarm that
/// would not fit still spawns a single enemy, so the last place in a quota is
/// always fillable.
int swarmToSpawn({
  required int wave,
  required int cleared,
  required int aliveMinions,
  required int swarm,
}) {
  final room = minionQuota(wave) - (cleared + aliveMinions);
  return min(max(1, swarm), max(1, room));
}
