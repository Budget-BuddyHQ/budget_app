import 'package:flame/components.dart';

const String defaultAdventureWorldId = 'starter_village';

class AdventureWorld {
  const AdventureWorld({
    required this.id,
    required this.title,
    required this.district,
    required this.tmxPath,
    required this.fallbackSpawn,
  });

  final String id;
  final String title;
  final String district;
  final String tmxPath;
  final Vector2 fallbackSpawn;
}

final List<AdventureWorld> adventureWorlds = <AdventureWorld>[
  AdventureWorld(
    id: defaultAdventureWorldId,
    title: 'Starter Village',
    district: 'Starter Village',
    tmxPath: 'map/world_map.tmx',
    fallbackSpawn: Vector2(640, 800),
  ),
  AdventureWorld(
    id: 'market_square',
    title: 'Market Square',
    district: 'Market Square',
    tmxPath: 'map/world_map.tmx',
    fallbackSpawn: Vector2(760, 520),
  ),
  AdventureWorld(
    id: 'savings_grove',
    title: 'Savings Grove',
    district: 'Savings Grove',
    tmxPath: 'map/world_map.tmx',
    fallbackSpawn: Vector2(1120, 1080),
  ),
  AdventureWorld(
    id: 'credit_cliffs',
    title: 'Credit Cliffs',
    district: 'Credit Cliffs',
    tmxPath: 'map/world_map.tmx',
    fallbackSpawn: Vector2(620, 1180),
  ),
  AdventureWorld(
    id: 'investor_ridge',
    title: 'Investor Ridge',
    district: 'Investor Ridge',
    tmxPath: 'map/world_map.tmx',
    fallbackSpawn: Vector2(1260, 1260),
  ),
];

AdventureWorld adventureWorldForId(String? id) {
  final normalized = normalizeAdventureWorldId(id);
  return adventureWorlds.firstWhere((world) => world.id == normalized);
}

String normalizeAdventureWorldId(String? id) {
  final normalized = id?.trim();
  if (normalized == null || normalized.isEmpty) {
    return defaultAdventureWorldId;
  }
  return adventureWorlds.any((world) => world.id == normalized)
      ? normalized
      : defaultAdventureWorldId;
}
