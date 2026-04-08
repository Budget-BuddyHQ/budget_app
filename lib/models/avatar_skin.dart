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
    assetPath: 'assets/images/Screenshot_2026-03-28_222840-removebg-preview.png',
    rarity: SkinRarity.common,
    accent: Color(0xFF85EFAC),
    weight: 58,
  ),
  AvatarSkin(
    id: 'coin_shell',
    name: 'Coin Shell',
    assetPath: 'assets/images/logo.png',
    rarity: SkinRarity.common,
    accent: Color(0xFFFFD45C),
    weight: 30,
  ),
  AvatarSkin(
    id: 'emerald_strider',
    name: 'Emerald Strider',
    assetPath: 'assets/images/Screenshot_2026-03-28_222539-removebg-preview.png',
    rarity: SkinRarity.rare,
    accent: Color(0xFF7CF3C7),
    weight: 10,
  ),
  AvatarSkin(
    id: 'guild_runner',
    name: 'Guild Runner',
    assetPath: 'assets/images/Screenshot_2026-03-28_222821-removebg-preview.png',
    rarity: SkinRarity.epic,
    accent: Color(0xFF58C7FF),
    weight: 2,
  ),
];

AvatarSkin skinFromId(String skinId) {
  return budgetBuddySkins.firstWhere(
    (skin) => skin.id == skinId,
    orElse: () => budgetBuddySkins.first,
  );
}
