import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

enum SkinRarity { common, rare, epic, legendary, mythic }

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
  });

  final String id;
  final String name;
  final String assetPath;
  final SkinRarity rarity;
  final Color accent;

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
  AvatarSkin(
    id: 'classic_turtle',
    name: 'Classic Turtle',
    assetPath: AppAssets.turtleClassic,
    rarity: SkinRarity.common,
    accent: Color(0xFF85EFAC),
  ),
  AvatarSkin(
    id: 'coin_shell',
    name: 'Coin Shell',
    assetPath: AppAssets.turtleCoinShell,
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
  ),
  AvatarSkin(
    id: 'guild_runner',
    name: 'Guild Runner',
    assetPath: AppAssets.turtleGuildRunner,
    rarity: SkinRarity.legendary,
    accent: Color(0xFFFFD45C),
  ),
  AvatarSkin(
    id: 'explorer_turtle',
    name: 'Explorer',
    assetPath: AppAssets.turtleExplorer,
    rarity: SkinRarity.rare,
    accent: Color(0xFF85EFAC),
  ),
  AvatarSkin(
    id: 'mushroom_goomba',
    name: 'Mushroom Goomba',
    assetPath: AppAssets.goombaWalk,
    rarity: SkinRarity.epic,
    accent: Color(0xFF34D399),
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
