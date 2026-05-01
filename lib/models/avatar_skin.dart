import 'package:flutter/material.dart';

enum SkinRarity {
  common,
  rare,
  epic,
}

@immutable
class AvatarSkin {
  const AvatarSkin({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.rarity,
    required this.accent,
    required this.weight,
  });

  final String id;
  final String name;
  final String assetPath;
  final SkinRarity rarity;
  final Color accent;
  final int weight;

  String get rarityLabel => switch (rarity) {
        SkinRarity.common => 'Common',
        SkinRarity.rare => 'Rare',
        SkinRarity.epic => 'Epic',
      };
}

const List<AvatarSkin> budgetBuddySkins = <AvatarSkin>[
  AvatarSkin(
    id: 'classic_turtle',
    name: 'Classic Turtle',
    assetPath: 'assets/images/turtles/Wface_no_bg_l7nvmfum.png',
    rarity: SkinRarity.common,
    accent: Color(0xFF85EFAC),
    weight: 58,
  ),
  AvatarSkin(
    id: 'coin_shell',
    name: 'Coin Shell',
    assetPath: 'assets/images/turtles/cuteBigHead_no_bg_3xfq2ne3.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
    weight: 30,
  ),
  AvatarSkin(
    id: 'emerald_strider',
    name: 'Emerald Strider',
    assetPath: 'assets/images/turtles/purplewithChestBack_no_bg_8cqt48zg.png',
    rarity: SkinRarity.rare,
    accent: Color(0xFF7CF3C7),
    weight: 10,
  ),
  AvatarSkin(
    id: 'guild_runner',
    name: 'Guild Runner',
    assetPath: 'assets/images/turtles/walkingredshell_no_bg_63pfbf03.png',
    rarity: SkinRarity.epic,
    accent: Color(0xFF58C7FF),
    weight: 2,
  ),
  AvatarSkin(
    id: 'cyber_turtle',
    name: 'Cyber Turtle',
    assetPath: 'assets/images/turtles/BlueDiamond_no_bg_3napzapt.png',
    rarity: SkinRarity.rare,
    accent: Color(0xFF58C7FF),
    weight: 9,
  ),
  AvatarSkin(
    id: 'piggy_bank_turtle',
    name: 'Piggy Bank',
    assetPath: 'assets/images/turtles/sodapopVibe_no_bg_w331x5ng.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
    weight: 20,
  ),
  AvatarSkin(
    id: 'explorer_turtle',
    name: 'Explorer',
    assetPath: 'assets/images/turtles/cuteTropicalhandDrawn_no_bg_i3ipxxln.png',
    rarity: SkinRarity.rare,
    accent: Color(0xFF85EFAC),
    weight: 12,
  ),
  AvatarSkin(
    id: 'starlight_turtle',
    name: 'Starlight',
    assetPath: 'assets/images/turtles/catearsBlueWithDiamond_no_bg_vyk193le.png',
    rarity: SkinRarity.epic,
    accent: Color(0xFFB9A5FF),
    weight: 4,
  ),
  AvatarSkin(
    id: 'trailblazer',
    name: 'Trailblazer',
    assetPath: 'assets/images/turtles/player_topview.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFC96B),
    weight: 20,
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
