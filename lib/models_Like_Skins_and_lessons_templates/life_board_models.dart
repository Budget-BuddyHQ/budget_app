import 'package:flutter/material.dart';

/// Data model for the Life Board — the main game's framework: a looping board
/// you move around by dice (the "life" board-game spine), earning and spending
/// a self-contained cash balance, levelling three RPG-style stats, and buying
/// tycoon assets that pay passive income each lap.
///
/// This file is pure data. All the rules live in `LifeBoardController`, and the
/// screen only renders what the controller exposes — so the game can grow
/// (more tiles, events, assets, a real map) without touching the UI wiring.

/// What happens when a token lands on a tile.
enum LifeTileType {
  /// Lap marker. Passing it collects salary + every asset's income.
  start,

  /// Earn cash, boosted by your knowledge and reputation.
  payday,

  /// Pay a bill — cash out.
  expense,

  /// Trade energy for knowledge.
  study,

  /// Recover energy.
  rest,

  /// Spend a little cash to gain reputation.
  social,

  /// A chance to buy a tycoon asset.
  opportunity,

  /// A random event — could help or hurt.
  chance,
}

@immutable
class LifeTile {
  const LifeTile({
    required this.type,
    required this.label,
    required this.amount,
  });

  final LifeTileType type;
  final String label;

  /// Coins for money tiles; stat points for study/rest/social. Ignored by
  /// [LifeTileType.start], [LifeTileType.opportunity], and
  /// [LifeTileType.chance], which compute their own effect.
  final int amount;

  IconData get icon => switch (type) {
    LifeTileType.start => Icons.flag_rounded,
    LifeTileType.payday => Icons.payments_rounded,
    LifeTileType.expense => Icons.receipt_long_rounded,
    LifeTileType.study => Icons.menu_book_rounded,
    LifeTileType.rest => Icons.bedtime_rounded,
    LifeTileType.social => Icons.groups_rounded,
    LifeTileType.opportunity => Icons.storefront_rounded,
    LifeTileType.chance => Icons.casino_rounded,
  };

  Color get color => switch (type) {
    LifeTileType.start => const Color(0xFFE1BB72),
    LifeTileType.payday => const Color(0xFF85EFAC),
    LifeTileType.expense => const Color(0xFFFF8A80),
    LifeTileType.study => const Color(0xFF58C7FF),
    LifeTileType.rest => const Color(0xFFB388FF),
    LifeTileType.social => const Color(0xFFFF8FB1),
    LifeTileType.opportunity => const Color(0xFFFFD45C),
    LifeTileType.chance => const Color(0xFF7CE07C),
  };
}

/// A property or business the player can own. Each pays [incomePerLap] coins
/// every time the token passes Start — the tycoon layer.
@immutable
class TycoonAsset {
  const TycoonAsset({
    required this.id,
    required this.name,
    required this.cost,
    required this.incomePerLap,
    required this.icon,
  });

  final String id;
  final String name;
  final int cost;
  final int incomePerLap;
  final IconData icon;
}

/// The starting board. A single loop; keep Start at index 0 so lap detection
/// stays simple.
const List<LifeTile> kLifeBoard = <LifeTile>[
  LifeTile(type: LifeTileType.start, label: 'Start', amount: 0),
  LifeTile(type: LifeTileType.payday, label: 'Payday', amount: 120),
  LifeTile(type: LifeTileType.study, label: 'Study', amount: 12),
  LifeTile(type: LifeTileType.expense, label: 'Rent', amount: 90),
  LifeTile(type: LifeTileType.opportunity, label: 'Market Stall', amount: 0),
  LifeTile(type: LifeTileType.social, label: 'Meetup', amount: 10),
  LifeTile(type: LifeTileType.chance, label: 'Chance', amount: 0),
  LifeTile(type: LifeTileType.rest, label: 'Rest', amount: 20),
  LifeTile(type: LifeTileType.payday, label: 'Payday', amount: 140),
  LifeTile(type: LifeTileType.expense, label: 'Bills', amount: 70),
  LifeTile(type: LifeTileType.opportunity, label: 'Workshop', amount: 0),
  LifeTile(type: LifeTileType.study, label: 'Course', amount: 16),
  LifeTile(type: LifeTileType.chance, label: 'Chance', amount: 0),
  LifeTile(type: LifeTileType.social, label: 'Festival', amount: 14),
  LifeTile(type: LifeTileType.expense, label: 'Repairs', amount: 110),
  LifeTile(type: LifeTileType.rest, label: 'Holiday', amount: 26),
];

/// Assets an [LifeTileType.opportunity] tile can offer, cheapest first.
const List<TycoonAsset> kTycoonAssets = <TycoonAsset>[
  TycoonAsset(
    id: 'lemonade',
    name: 'Lemonade Stand',
    cost: 250,
    incomePerLap: 40,
    icon: Icons.local_drink_rounded,
  ),
  TycoonAsset(
    id: 'foodcart',
    name: 'Food Cart',
    cost: 480,
    incomePerLap: 85,
    icon: Icons.lunch_dining_rounded,
  ),
  TycoonAsset(
    id: 'cottage',
    name: 'Rental Cottage',
    cost: 900,
    incomePerLap: 150,
    icon: Icons.cottage_rounded,
  ),
  TycoonAsset(
    id: 'arcade',
    name: 'Arcade',
    cost: 1500,
    incomePerLap: 260,
    icon: Icons.videogame_asset_rounded,
  ),
  TycoonAsset(
    id: 'startup',
    name: 'Tech Startup',
    cost: 2600,
    incomePerLap: 470,
    icon: Icons.rocket_launch_rounded,
  ),
];
