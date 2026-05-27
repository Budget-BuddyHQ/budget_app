import 'package:flutter/material.dart';

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
    assetPath: 'assets/images/turtles/Wface_no_bg_l7nvmfum.png',
    rarity: SkinRarity.common,
    accent: Color(0xFF85EFAC),
  ),
  AvatarSkin(
    id: 'coin_shell',
    name: 'Coin Shell',
    assetPath: 'assets/images/turtles/cuteBigHead_no_bg_3xfq2ne3.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
  ),
  AvatarSkin(
    id: 'emerald_strider',
    name: 'Emerald Strider',
    assetPath: 'assets/images/turtles/purplewithChestBack_no_bg_8cqt48zg.png',
    rarity: SkinRarity.rare,
    accent: Color(0xFF7CF3C7),
  ),
  AvatarSkin(
    id: 'guild_runner',
    name: 'Guild Runner',
    assetPath: 'assets/images/turtles/walkingredshell_no_bg_63pfbf03.png',
    rarity: SkinRarity.legendary,
    accent: Color(0xFFFFD45C),
  ),
  AvatarSkin(
    id: 'cyber_turtle',
    name: 'Cyber Turtle',
    assetPath: 'assets/images/turtles/BlueDiamond_no_bg_3napzapt.png',
    rarity: SkinRarity.epic,
    accent: Color(0xFFB9A5FF),
  ),
  AvatarSkin(
    id: 'piggy_bank_turtle',
    name: 'Piggy Bank',
    assetPath: 'assets/images/turtles/sodapopVibe_no_bg_w331x5ng.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
  ),
  AvatarSkin(
    id: 'explorer_turtle',
    name: 'Explorer',
    assetPath: 'assets/images/turtles/cuteTropicalhandDrawn_no_bg_i3ipxxln.png',
    rarity: SkinRarity.rare,
    accent: Color(0xFF85EFAC),
  ),
  AvatarSkin(
    id: 'starlight_turtle',
    name: 'Starlight',
    assetPath:
        'assets/images/turtles/catearsBlueWithDiamond_no_bg_vyk193le.png',
    rarity: SkinRarity.mythic,
    accent: Color(0xFFFF6B9D),
  ),
  AvatarSkin(
    id: 'trailblazer',
    name: 'Trailblazer',
    assetPath: 'assets/images/turtles/player_topview.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFC96B),
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
