import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

enum SkinRarity { common, rare, epic, legendary, mythic }

/// Which villager body a player's avatar uses.
///
/// This is a presentation choice, not a separate unlockable: every villager
/// skin ships both bodies, so choosing one never costs a pull or changes the
/// odds. Doubling the gacha pool instead would have halved everyone's chance
/// of any given skin.
enum VillagerBody {
  masculine('masculine', 'Masculine'),
  feminine('feminine', 'Feminine');

  const VillagerBody(this.id, this.label);

  final String id;
  final String label;

  bool get isFemale => this == VillagerBody.feminine;

  static VillagerBody fromId(Object? raw) {
    final value = raw?.toString().trim();
    return VillagerBody.values.firstWhere(
      (body) => body.id == value,
      orElse: () => VillagerBody.masculine,
    );
  }
}

/// Broad look of an avatar, used to group the customise grid.
enum SkinFamily {
  turtle('Turtles'),
  villager('Villagers'),
  critter('Critters');

  const SkinFamily(this.label);

  final String label;
}

@immutable
class SkinRarityOdds {
  const SkinRarityOdds({
    required this.rarity,
    required this.weight,
    required this.refundGold,
  });

  final SkinRarity rarity;
  final int weight;
  final int refundGold;

  double get percent => weight / skinCaseTotalWeight * 100;

  String get oddsLabel {
    if (rarity == SkinRarity.legendary) {
      return '1 in 1,000';
    }
    if (rarity == SkinRarity.mythic) {
      return '1 in 10,000';
    }
    return '${percent.toStringAsFixed(percent >= 1 ? 1 : 2)}%';
  }
}

const int skinCaseTotalWeight = 10000;

const List<SkinRarityOdds> skinCaseRarityOdds = <SkinRarityOdds>[
  SkinRarityOdds(rarity: SkinRarity.common, weight: 6699, refundGold: 40),
  SkinRarityOdds(rarity: SkinRarity.rare, weight: 2500, refundGold: 70),
  SkinRarityOdds(rarity: SkinRarity.epic, weight: 790, refundGold: 110),
  SkinRarityOdds(rarity: SkinRarity.legendary, weight: 10, refundGold: 180),
  SkinRarityOdds(rarity: SkinRarity.mythic, weight: 1, refundGold: 300),
];

@immutable
class AvatarSkin {
  const AvatarSkin({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.rarity,
    required this.accent,
    this.family = SkinFamily.turtle,
    this.humanVariantId,
    this.isHuman = false,
    this.blurb,
  });

  /// A villager skin built from one of the recoloured human sprite folders.
  /// [variantId] of null means the original blue villager.
  const AvatarSkin.villager({
    required this.id,
    required this.name,
    required String? variantId,
    required this.rarity,
    required this.accent,
    this.blurb,
  }) : humanVariantId = variantId,
       isHuman = true,
       family = SkinFamily.villager,
       assetPath = '';

  final String id;
  final String name;
  final SkinRarity rarity;
  final Color accent;
  final SkinFamily family;

  /// Populated for non-human skins. Villagers derive their art from
  /// [humanVariantId] instead so every walk frame resolves from one prefix.
  final String assetPath;

  final String? humanVariantId;
  final bool isHuman;

  /// One-line flavour text shown in the customise grid.
  final String? blurb;

  /// Still image for non-villager skins. Villagers render from a sprite sheet
  /// and need [sheetAsset] plus a cell index instead — see [VillagerBody].
  String get previewAsset => assetPath;

  /// Sheet holding this villager's frames for the given [body].
  /// Only meaningful when [isHuman].
  String sheetAsset(VillagerBody body) =>
      AppAssets.villagerSheet(humanVariantId, female: body.isFemale);

  /// The one frame a raw `Canvas` should draw for this skin.
  ///
  /// # Why this is not just [previewAsset]
  ///
  /// The widget tree has [AvatarSprite], which hides the fact that villagers
  /// are one cell of a packed 8x4 sheet while turtles and critters are loose
  /// stills. A `Canvas` has no such helper: `drawImageRect` needs to be told
  /// which rectangle of the loaded image is the character, and handing it a
  /// whole villager sheet draws all thirty-two frames squashed into the
  /// destination — which is what the Finance Brawl would have done.
  ///
  /// So the split is answered once, here, and every canvas that wants to draw
  /// a player gets the same answer. [cell] of null means "the whole image".
  ///
  /// The frame is south-facing and first in its row deliberately — the only
  /// pose that reads as a character facing the player rather than one caught
  /// mid-stride.
  ({String asset, Rect? cell}) canvasFrame(VillagerBody body) {
    if (!isHuman) {
      return (asset: previewAsset, cell: null);
    }
    return (
      asset: sheetAsset(body),
      cell: Rect.fromLTWH(
        0,
        AppAssets.villagerRow('south') * AppAssets.villagerCellHeight,
        AppAssets.villagerCellWidth,
        AppAssets.villagerCellHeight,
      ),
    );
  }

  /// Walk-cycle frames for [direction], for skins that still use loose frames.
  /// Villagers return empty — they animate from their sheet instead.
  List<String> walkFrames(String direction) {
    if (id == 'mushroom_goomba') {
      return switch (direction) {
        'north' => AppAssets.goombaWalkNorth,
        _ => AppAssets.goombaWalkSouth,
      };
    }
    return const <String>[];
  }

  String get rarityLabel => switch (rarity) {
    SkinRarity.common => 'Common',
    SkinRarity.rare => 'Rare',
    SkinRarity.epic => 'Epic',
    SkinRarity.legendary => 'Legendary',
    SkinRarity.mythic => 'Mythic',
  };
}

SkinRarityOdds oddsForRarity(SkinRarity rarity) {
  return skinCaseRarityOdds.firstWhere((odds) => odds.rarity == rarity);
}

const List<AvatarSkin> budgetBuddySkins = <AvatarSkin>[
  // --- Turtles -----------------------------------------------------------
  AvatarSkin(
    id: 'classic_turtle',
    name: 'Classic Turtle',
    assetPath: AppAssets.turtleClassic,
    rarity: SkinRarity.common,
    accent: Color(0xFF85EFAC),
    blurb: 'Where every Budget Buddy starts.',
  ),
  AvatarSkin(
    id: 'coin_shell',
    name: 'Coin Shell',
    assetPath: AppAssets.turtleCoinShell,
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
    blurb: 'Carries its savings on its back.',
  ),
  AvatarSkin(
    id: 'explorer_turtle',
    name: 'Explorer',
    assetPath: AppAssets.turtleExplorer,
    rarity: SkinRarity.rare,
    accent: Color(0xFF85EFAC),
    blurb: 'Packed and ready for the meadow.',
  ),
  AvatarSkin(
    id: 'guild_runner',
    name: 'Guild Runner',
    assetPath: AppAssets.turtleGuildRunner,
    rarity: SkinRarity.legendary,
    accent: Color(0xFFFFD45C),
    blurb: 'Fastest shell in the village.',
  ),

  // --- Critters ----------------------------------------------------------
  AvatarSkin(
    id: 'mushroom_goomba',
    name: 'Mushroom Goomba',
    assetPath: AppAssets.goombaWalk,
    rarity: SkinRarity.epic,
    accent: Color(0xFF34D399),
    family: SkinFamily.critter,
    blurb: 'Wandered in from the forest path.',
  ),

  // --- Villagers ---------------------------------------------------------
  AvatarSkin.villager(
    id: 'villager_classic',
    name: 'Villager',
    variantId: null,
    rarity: SkinRarity.common,
    accent: Color(0xFF4A7FBF),
    blurb: 'A familiar face around the square.',
  ),
  AvatarSkin.villager(
    id: 'villager_emerald_scout',
    name: 'Emerald Scout',
    variantId: 'emerald_scout',
    rarity: SkinRarity.rare,
    accent: Color(0xFF2FA36B),
    blurb: 'Maps the meadow, budgets the trip.',
  ),
  AvatarSkin.villager(
    id: 'villager_teal_analyst',
    name: 'Teal Analyst',
    variantId: 'teal_analyst',
    rarity: SkinRarity.rare,
    accent: Color(0xFF2FA3A3),
    blurb: 'Reads the charts before the hype.',
  ),
  AvatarSkin.villager(
    id: 'villager_slate_investor',
    name: 'Slate Investor',
    variantId: 'slate_investor',
    rarity: SkinRarity.rare,
    accent: Color(0xFF5C6B7A),
    blurb: 'Long horizons, steady hands.',
  ),
  AvatarSkin.villager(
    id: 'villager_gold_banker',
    name: 'Gold Banker',
    variantId: 'gold_banker',
    rarity: SkinRarity.epic,
    accent: Color(0xFFE0A93B),
    blurb: 'Keeps the village vault balanced.',
  ),
  AvatarSkin.villager(
    id: 'villager_violet_scholar',
    name: 'Violet Scholar',
    variantId: 'violet_scholar',
    rarity: SkinRarity.epic,
    accent: Color(0xFF8B5CC7),
    blurb: 'Top of the Academy leaderboard.',
  ),
  AvatarSkin.villager(
    id: 'villager_rose_planner',
    name: 'Rose Planner',
    variantId: 'rose_planner',
    rarity: SkinRarity.epic,
    accent: Color(0xFFD9668C),
    blurb: 'Every goal has a date on it.',
  ),
  AvatarSkin.villager(
    id: 'villager_sand_saver',
    name: 'Sand Saver',
    variantId: 'sand_saver',
    rarity: SkinRarity.legendary,
    accent: Color(0xFFD9B98C),
    blurb: 'Turned a sinking fund into a fortune.',
  ),
  AvatarSkin.villager(
    id: 'villager_crimson_trader',
    name: 'Crimson Trader',
    variantId: 'crimson_trader',
    rarity: SkinRarity.legendary,
    accent: Color(0xFFC4483F),
    blurb: 'Rings the bell on the market board.',
  ),
  AvatarSkin.villager(
    id: 'villager_midnight_ledger',
    name: 'Midnight Ledger',
    variantId: 'midnight_ledger',
    rarity: SkinRarity.legendary,
    accent: Color(0xFF2E3F6B),
    blurb: 'Balances the books after dark.',
  ),
  AvatarSkin.villager(
    id: 'villager_aurora_prime',
    name: 'Aurora Prime',
    variantId: 'aurora_prime',
    rarity: SkinRarity.mythic,
    accent: Color(0xFFFFD45C),
    blurb: 'One in ten thousand. Genuinely.',
  ),

  // --- Villagers, second wave --------------------------------------------
  //
  // Eight new pulls, generated by `tool/redraw_villagers.py --new`. The
  // generator needs four colours rather than an artist, so growing the pool
  // costs a palette entry — which is what makes it reasonable to keep adding
  // to it as the app ships.
  //
  // Each is written as a *character* rather than a colourway: the palette,
  // the name and the blurb were chosen together, because "Frost Auditor"
  // being pale blue is the whole reason the pull feels like it meant
  // something.
  AvatarSkin.villager(
    id: 'villager_copper_apprentice',
    name: 'Copper Apprentice',
    variantId: 'copper_apprentice',
    rarity: SkinRarity.common,
    accent: Color(0xFFB86B3A),
    blurb: 'First job, first payslip, first questions.',
  ),
  AvatarSkin.villager(
    id: 'villager_frost_auditor',
    name: 'Frost Auditor',
    variantId: 'frost_auditor',
    rarity: SkinRarity.rare,
    accent: Color(0xFF7AB8D9),
    blurb: 'Reads the fine print twice. Finds the fee.',
  ),
  AvatarSkin.villager(
    id: 'villager_harvest_planner',
    name: 'Harvest Planner',
    variantId: 'harvest_planner',
    rarity: SkinRarity.rare,
    accent: Color(0xFFE88B3A),
    blurb: 'Puts something aside in every good month.',
  ),
  AvatarSkin.villager(
    id: 'villager_neon_daytrader',
    name: 'Neon Daytrader',
    variantId: 'neon_daytrader',
    rarity: SkinRarity.epic,
    accent: Color(0xFF2AE0D0),
    blurb: 'Up all night watching a line move.',
  ),
  AvatarSkin.villager(
    id: 'villager_ember_founder',
    name: 'Ember Founder',
    variantId: 'ember_founder',
    rarity: SkinRarity.epic,
    accent: Color(0xFFD94A2E),
    blurb: 'Started something with a runway of four months.',
  ),
  AvatarSkin.villager(
    id: 'villager_jade_landlord',
    name: 'Jade Landlord',
    variantId: 'jade_landlord',
    rarity: SkinRarity.epic,
    accent: Color(0xFF2EA87A),
    blurb: 'Knows exactly what the roof costs.',
  ),
  AvatarSkin.villager(
    id: 'villager_royal_treasurer',
    name: 'Royal Treasurer',
    variantId: 'royal_treasurer',
    rarity: SkinRarity.legendary,
    accent: Color(0xFF6B3FB8),
    blurb: 'Balances a kingdom before breakfast.',
  ),
  AvatarSkin.villager(
    id: 'villager_solar_index',
    name: 'Solar Index',
    variantId: 'solar_index',
    rarity: SkinRarity.mythic,
    accent: Color(0xFFFFC93C),
    blurb: 'Never picked a stock. Beat almost everyone.',
  ),
];

final Set<String> budgetBuddySkinIds = budgetBuddySkins
    .map((skin) => skin.id)
    .toSet();

bool isRegisteredSkinId(String skinId) => budgetBuddySkinIds.contains(skinId);

AvatarSkin skinFromId(String skinId) {
  return budgetBuddySkins.firstWhere(
    (skin) => skin.id == skinId,
    orElse: () => budgetBuddySkins.first,
  );
}

/// Every rarity the case can roll must have at least one skin behind it,
/// otherwise a lucky roll silently degrades to the fallback skin.
bool get skinCatalogCoversAllRarities => skinCaseRarityOdds.every(
  (odds) => budgetBuddySkins.any((skin) => skin.rarity == odds.rarity),
);

List<AvatarSkin> skinsInFamily(SkinFamily family) => budgetBuddySkins
    .where((skin) => skin.family == family)
    .toList(growable: false);
