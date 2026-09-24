import 'package:flutter/material.dart';

/// The debts you fight in Finance Brawl.
///
/// # Why these are archetypes rather than names
///
/// The game had four "enemies" — Credit Card Debt, Payday Loan, Medical Bill,
/// Auto Loan — with **identical hit points, identical speed, identical
/// colour, identical reward**. They were one enemy with four labels. A second
/// real type unlocked at wave 3, and that was the whole roster.
///
/// So a player fought the same thing for twenty minutes, and the names taught
/// nothing: if a payday loan and an auto loan behave the same way, the game is
/// quietly saying they *are* the same, which is the opposite of true and the
/// opposite of what this app exists to teach.
///
/// # The design rule every entry follows
///
/// **The behaviour is the lesson.** Not a caption, not a tooltip — how the
/// thing moves and what it costs you. A payday loan is small and weak and
/// drains you faster than anything else on screen, because that is what a
/// payday loan is. A student loan has enormous health and barely moves,
/// because it is not an emergency and it is not going away. Subscription
/// creep arrives in swarms of nearly harmless specks that add up to more than
/// any single enemy in the game.
///
/// A player who never reads a word of the Academy still learns which debts
/// are dangerous, because the dangerous ones hurt.
///
/// # Why difficulty is expressed as multipliers
///
/// Every archetype scales off the same wave curve the game already had, so
/// adding one cannot accidentally break the difficulty ramp — it can only be
/// harder or softer *relative* to the baseline that was already tuned.
@immutable
class BrawlEnemy {
  const BrawlEnemy({
    required this.id,
    required this.name,
    required this.color,
    required this.lesson,
    this.hpScale = 1.0,
    this.speedScale = 1.0,
    this.drainScale = 1.0,
    this.radius = 30.0,
    this.goldReward = 5,
    this.minWave = 1,
    this.swarmCount = 1,
    this.isElite = false,
    this.hitScale = 0.8,
  });

  final String id;
  final String name;
  final Color color;

  /// One line, shown on the post-wave card.
  ///
  /// Explains the *behaviour the player just experienced*, which is the only
  /// moment a sentence about debt is going to land — right after a payday
  /// loan has drained half their balance in four seconds.
  final String lesson;

  final double hpScale;
  final double speedScale;
  final double drainScale;
  final double radius;
  final int goldReward;

  /// Wave this first appears. Staggered so the roster reveals itself instead
  /// of arriving all at once, and so the early waves stay teachable.
  final int minWave;

  /// How many spawn together. Above one, the archetype is a swarm.
  final int swarmCount;

  /// Elites are rarer, tougher, and worth more.
  final bool isElite;

  /// How much of the drawn circle actually counts when something touches it, 0
  /// to 1.
  ///
  /// **Why this exists.** Every enemy is drawn in a square as wide as its radius
  /// twice over, and contact used to be tested against the whole radius. But no
  /// sprite fills its square: a subscription speck fills about 59% of it, a
  /// credit card 84% by 59%. Whatever the picture did not cover still hurt, and
  /// shots vanished a few pixels short of the thing they were aimed at. That is
  /// what "the hitboxes are weird" was.
  ///
  /// Each value is the mean of the sprite's opaque width and height as a share of
  /// its frame, measured off the art and trimmed a little so contact is generous
  /// to the player. `brawl_hitbox_test.dart` re-measures the PNGs, so redrawing
  /// a sprite without changing this fails a test instead of feeling wrong again.
  final double hitScale;
}

/// The systemic-risk boss's own, measured the same way from `brawl_boss.png`.
const double kBrawlBossHitScale = 0.8;

/// The roster.
///
/// Ordered by the wave they unlock at, which is also roughly the order a
/// person meets these debts in life.
const List<BrawlEnemy> kBrawlEnemies = <BrawlEnemy>[
  // --- wave 1: the everyday ones ---------------------------------------
  BrawlEnemy(
    id: 'credit_card',
    name: 'Credit Card Debt',
    color: Color(0xFFE25C5C),
    lesson:
        'It is quick and it never stops coming. Credit card debt is the most '
        'expensive ordinary borrowing most people ever do.',
    speedScale: 1.15,
    hpScale: 0.9,
    goldReward: 5,
    hitScale: 0.70,
  ),
  BrawlEnemy(
    id: 'medical_bill',
    name: 'Medical Bill',
    color: Color(0xFFFF8A80),
    lesson:
        'It arrived without warning. That is exactly what an emergency fund '
        'is for — not for emergencies you planned.',
    hpScale: 1.1,
    speedScale: 0.95,
    goldReward: 6,
    hitScale: 0.72,
  ),

  // --- wave 2: the ones that punish inattention -------------------------
  BrawlEnemy(
    id: 'subscription_creep',
    name: 'Subscription Creep',
    color: Color(0xFF7FD4C1),
    lesson:
        'Each one was almost nothing. Together they outweighed every single '
        'enemy on the board — which is how subscriptions actually get you.',
    hpScale: 0.28,
    speedScale: 1.05,
    drainScale: 0.35,
    radius: 17,
    goldReward: 2,
    minWave: 2,
    // The whole point. One is trivial; five is the biggest health pool on
    // screen, and the player has to notice that themselves.
    swarmCount: 5,
    hitScale: 0.58,
  ),
  BrawlEnemy(
    id: 'payday_loan',
    name: 'Payday Loan',
    color: Color(0xFFFFB020),
    lesson:
        'Small, fast, and it drained you faster than anything else out there. '
        'A payday loan is not a small loan — it is the most expensive money '
        'you can borrow.',
    hpScale: 0.55,
    speedScale: 1.55,
    // Four times the drain. The number is the lesson.
    drainScale: 4.0,
    radius: 21,
    goldReward: 9,
    minWave: 2,
    hitScale: 0.72,
  ),

  // --- wave 3: the long ones -------------------------------------------
  BrawlEnemy(
    id: 'auto_loan',
    name: 'Auto Loan',
    color: Color(0xFF8FA8E8),
    lesson:
        'Big, slow, and completely predictable. Secured debt at a fair rate '
        'is the least frightening kind — you can see it coming and plan for '
        'it.',
    hpScale: 1.9,
    speedScale: 0.62,
    drainScale: 0.8,
    radius: 34,
    goldReward: 11,
    minWave: 3,
    hitScale: 0.78,
  ),
  BrawlEnemy(
    id: 'overdraft_fee',
    name: 'Overdraft Fee',
    color: Color(0xFFD98CFF),
    lesson:
        'It turned up when you were already low. Overdraft fees charge you '
        'for not having money, which is when you can least afford them.',
    hpScale: 0.7,
    speedScale: 1.35,
    drainScale: 1.6,
    radius: 22,
    goldReward: 8,
    minWave: 3,
    hitScale: 0.70,
  ),

  // --- wave 5+: the heavy ones -----------------------------------------
  BrawlEnemy(
    id: 'student_loan',
    name: 'Student Loan',
    color: Color(0xFF6FB1FF),
    lesson:
        'Enormous, and it barely moved. A student loan is not an emergency — '
        'it is a long, slow thing you live alongside, and panicking about it '
        'costs more than paying it.',
    hpScale: 3.2,
    speedScale: 0.42,
    drainScale: 0.65,
    radius: 40,
    goldReward: 20,
    minWave: 5,
    isElite: true,
    hitScale: 0.95,
  ),
  BrawlEnemy(
    id: 'subprime_mortgage',
    name: 'Subprime Mortgage',
    color: Color(0xFFA65CE2),
    lesson:
        'A loan sold to someone it did not suit, at a rate that made it '
        'worse. The size was never the problem — the terms were.',
    hpScale: 2.4,
    speedScale: 0.75,
    drainScale: 1.3,
    radius: 36,
    goldReward: 16,
    minWave: 5,
    isElite: true,
    hitScale: 0.95,
  ),

  // --- wave 7+: the ones that are not really debts ----------------------
  BrawlEnemy(
    id: 'inflation',
    name: 'Inflation',
    color: Color(0xFFB8C4A8),
    lesson:
        'You never borrowed it and it took from you anyway. Money left doing '
        'nothing loses value every year — that is why saving is not the same '
        'as investing.',
    hpScale: 1.4,
    speedScale: 0.5,
    drainScale: 0.9,
    radius: 30,
    goldReward: 13,
    minWave: 7,
    hitScale: 0.80,
  ),
  BrawlEnemy(
    id: 'too_good_offer',
    name: '"Guaranteed" Return',
    color: Color(0xFFFFD45C),
    lesson:
        'It looked like the reward and it was the enemy. Anything promising a '
        'guaranteed high return is either lying or is not what it says.',
    hpScale: 1.25,
    speedScale: 1.25,
    drainScale: 2.1,
    radius: 26,
    goldReward: 18,
    minWave: 7,
    isElite: true,
    hitScale: 0.88,
  ),
];

/// Archetypes that can appear on [wave].
List<BrawlEnemy> enemiesForWave(int wave) => [
  for (final e in kBrawlEnemies)
    if (wave >= e.minWave) e,
];

/// Picks the next archetype to spawn.
///
/// [roll] is 0..1, supplied by the caller so the choice stays testable — the
/// game passes its own `Random`, a test passes a fixed value.
///
/// Elites are held to roughly a fifth of spawns. They are the interesting
/// ones and it is tempting to show them often; a board made mostly of elites
/// is just a harder board with the same texture, and the contrast is what
/// makes them read as elite at all.
BrawlEnemy pickEnemy(int wave, double roll) {
  final available = enemiesForWave(wave);
  if (available.isEmpty) return kBrawlEnemies.first;

  final elites = [
    for (final e in available)
      if (e.isElite) e,
  ];
  final regular = [
    for (final e in available)
      if (!e.isElite) e,
  ];

  final wantElite = roll > 0.8 && elites.isNotEmpty;
  final pool = wantElite ? elites : (regular.isEmpty ? available : regular);

  // Reuse the same roll for the index rather than asking for a second one,
  // so one number fully determines the spawn and a test can pin it.
  final index = ((roll * 1000).floor()) % pool.length;
  return pool[index];
}
