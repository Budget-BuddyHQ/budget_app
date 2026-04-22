import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../controllers/adventure_state_controller.dart';
import 'components/camera_lead_target_component.dart';
import 'components/enemy_monster_component.dart';
import 'components/grid_world_component.dart';
import 'components/player_component.dart';

class BudgetBuddyGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, KeyboardEvents {
  BudgetBuddyGame({
    required AdventureStateController adventureState,
  }) : _adventureState = adventureState;

  final AdventureStateController _adventureState;

  static final Vector2 mapSize = Vector2(1600, 1600);

  late final PlayerComponent player;
  late final CameraLeadTargetComponent _cameraTarget;
  late final JoystickComponent joystick;
  TiledComponent? _worldMap;
  Vector2 _mapPixelSize = mapSize.clone();
  final List<EnemyMonsterComponent> _monsters = <EnemyMonsterComponent>[];
  final List<Rect> _collisionRects = <Rect>[];
  EnemyMonsterComponent? _activeEncounter;

  @override
  Color backgroundColor() => const Color(0xFF071711);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final loadedMap = await _loadWorldMapSafely();
    final effectiveMapSize = loadedMap == null
        ? mapSize.clone()
        : Vector2(
            (loadedMap.tileMap.map.width * loadedMap.tileMap.map.tileWidth)
                .toDouble(),
            (loadedMap.tileMap.map.height * loadedMap.tileMap.map.tileHeight)
                .toDouble(),
          );
    _mapPixelSize = effectiveMapSize.clone();

    add(GridWorldComponent(mapSize: effectiveMapSize));
    if (loadedMap != null) {
      _worldMap = loadedMap;
      add(loadedMap);
    }

    _collisionRects
      ..clear()
      ..addAll(_readCollisionRects(loadedMap?.tileMap));
    final spawnPoint = _readSpawnPoint(loadedMap?.tileMap, 'player_spawn') ??
        Vector2(effectiveMapSize.x * 0.4, effectiveMapSize.y * 0.5);
    final enemySpawn = _readSpawnPoint(loadedMap?.tileMap, 'enemy_spawn') ??
        Vector2(effectiveMapSize.x * 0.62, effectiveMapSize.y * 0.52);

    joystick = JoystickComponent(
      margin: const EdgeInsets.only(left: 24, bottom: 24),
      knob: CircleComponent(
        radius: 22,
        paint: Paint()..color = const Color(0xFF85EFAC).withValues(alpha: 0.90),
      ),
      background: CircleComponent(
        radius: 52,
        paint: Paint()..color = const Color(0xFF071711).withValues(alpha: 0.55),
      ),
      priority: 20,
    );
    add(joystick);

    player = PlayerComponent(
      position: spawnPoint,
      joystick: joystick,
      worldBounds: Rect.fromLTWH(0, 0, effectiveMapSize.x, effectiveMapSize.y),
      collisionRects: _collisionRects,
      onEncounter: _beginEncounter,
    );
    add(player);

    _cameraTarget = CameraLeadTargetComponent(
      player: player,
      mapBounds: Rect.fromLTWH(0, 0, effectiveMapSize.x, effectiveMapSize.y),
    );
    add(_cameraTarget);

    _spawnEnemy(enemySpawn, 'Ledger Slime');
    _spawnEnemy(
      Vector2(enemySpawn.x + 180, enemySpawn.y + 180),
      'Invoice Imp',
    );

    camera.viewfinder.zoom = 1.1;
    camera.viewfinder.anchor = const Anchor(0.46, 0.42);
    camera.follow(_cameraTarget);
  }

  Future<TiledComponent?> _loadWorldMapSafely() async {
    try {
      final tiled = await TiledComponent.load(
        'map/world_map.tmx',
        Vector2.all(32),
      );
      if (!_hasRenderableTiles(tiled.tileMap.map)) {
        debugPrint(
          'world_map.tmx loaded but no visible tiles were found. Falling back to solid viewport.',
        );
        return null;
      }
      return tiled;
    } catch (error, stackTrace) {
      debugPrint('Failed to load world_map.tmx: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  bool _hasRenderableTiles(TiledMap map) {
    for (final layer in map.layers) {
      if (layer is TileLayer) {
        final data = layer.data;
        if (data != null && data.any((gid) => gid != 0)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    player.setKeyboardState(keysPressed);
    return KeyEventResult.handled;
  }

  void resolveCombat({required bool victory}) {
    if (_activeEncounter == null) {
      return;
    }

    if (victory) {
      _activeEncounter!.isDefeated = true;
      final defeatedEnemy = _activeEncounter!;
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        final newPosition = _randomRespawnPosition();
        defeatedEnemy.position.setFrom(newPosition);
        defeatedEnemy.isDefeated = false;
      });
    }

    _activeEncounter = null;
    player.movementEnabled = true;
    _adventureState.restoreMovementAfterCombat();
  }

  void _spawnEnemy(Vector2 position, String name) {
    final enemy = EnemyMonsterComponent(
      position: position,
      enemyName: name,
    );
    _monsters.add(enemy);
    add(enemy);
  }

  void _beginEncounter(EnemyMonsterComponent enemy) {
    if (_activeEncounter != null || _adventureState.combatVisible) {
      return;
    }
    _activeEncounter = enemy;
    player.movementEnabled = false;
    _adventureState.beginEncounter(enemy.enemyName);
  }

  Vector2 _randomRespawnPosition() {
    final random = math.Random();

    while (true) {
      final x = 180 + random.nextDouble() * (_mapPixelSize.x - 360);
      final y = 180 + random.nextDouble() * (_mapPixelSize.y - 360);
      final candidate = Rect.fromCenter(
        center: Offset(x, y),
        width: 42,
        height: 42,
      );
      final collides = _collisionRects.any(candidate.overlaps);
      if (!collides) {
        return Vector2(x, y);
      }
    }
  }

  List<Rect> _readCollisionRects(RenderableTiledMap? tiledMap) {
    if (tiledMap == null) {
      return const <Rect>[];
    }
    final collisionLayer = tiledMap.getLayer<ObjectGroup>('Collisions');
    if (collisionLayer == null) {
      return const <Rect>[];
    }
    return collisionLayer.objects
        .map(
          (object) => Rect.fromLTWH(
            object.x,
            object.y,
            object.width,
            object.height,
          ),
        )
        .toList(growable: false);
  }

  Vector2? _readSpawnPoint(RenderableTiledMap? tiledMap, String objectName) {
    if (tiledMap == null) {
      return null;
    }
    final spawnLayer = tiledMap.getLayer<ObjectGroup>('SpawnPoints');
    if (spawnLayer == null) {
      return null;
    }
    for (final object in spawnLayer.objects) {
      if (object.name == objectName) {
        return Vector2(object.x + (object.width / 2), object.y + (object.height / 2));
      }
    }
    return null;
  }
}
