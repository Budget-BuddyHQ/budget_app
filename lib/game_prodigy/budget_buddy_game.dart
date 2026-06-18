import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../controllers_that_updates_stats/adventure_state_controller.dart';
import 'components/camera_lead_target_component.dart';
import 'components/enemy_monster_component.dart';
import 'components/grid_world_component.dart';
import 'components/player_component.dart';
import 'adventure_world.dart';

typedef AdventureProgressChanged =
    void Function(String mapId, Vector2 position);

class BudgetBuddyGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, KeyboardEvents {
  BudgetBuddyGame({
    required AdventureStateController adventureState,
    String? mapId,
    Vector2? initialPosition,
    required String skinAssetPath,
    AdventureProgressChanged? onProgressChanged,
  }) : _adventureState = adventureState,
       _world = adventureWorldForId(mapId),
       _initialPosition = initialPosition,
       _skinAssetPath = skinAssetPath,
       _onProgressChanged = onProgressChanged;

  final AdventureStateController _adventureState;
  final AdventureWorld _world;
  final Vector2? _initialPosition;
  final String _skinAssetPath;
  final AdventureProgressChanged? _onProgressChanged;

  static final Vector2 mapSize = Vector2(1600, 1600);

  PlayerComponent? _player;
  late final CameraLeadTargetComponent _cameraTarget;
  late final JoystickComponent joystick;
  Vector2 _mapPixelSize = mapSize.clone();
  final List<EnemyMonsterComponent> _monsters = <EnemyMonsterComponent>[];
  final List<Rect> _collisionRects = <Rect>[];
  EnemyMonsterComponent? _activeEncounter;
  static final Vector2 _cameraAnchorRatio = Vector2(0.46, 0.42);
  double _progressEmitClock = 0;
  Vector2? _lastEmittedProgressPosition;

  String get mapId => _world.id;

  Vector2? get playerWorldPosition => _player?.position.clone();

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
      add(loadedMap);
    }

    _collisionRects
      ..clear()
      ..addAll(_readCollisionRects(loadedMap?.tileMap));
    final spawnPoint = _resolveSpawnPoint(loadedMap?.tileMap, effectiveMapSize);
    final enemySpawn =
        _readSpawnPoint(loadedMap?.tileMap, 'enemy_spawn') ??
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

    _player = PlayerComponent(
      position: spawnPoint,
      joystick: joystick,
      worldBounds: Rect.fromLTWH(0, 0, effectiveMapSize.x, effectiveMapSize.y),
      collisionRects: _collisionRects,
      skinAssetPath: _skinAssetPath,
      onEncounter: _beginEncounter,
    );
    add(_player!);

    _cameraTarget = CameraLeadTargetComponent(
      player: _player!,
      mapBounds: Rect.fromLTWH(0, 0, effectiveMapSize.x, effectiveMapSize.y),
    );
    add(_cameraTarget);

    _spawnEnemy(enemySpawn, 'Ledger Slime');
    _spawnEnemy(Vector2(enemySpawn.x + 180, enemySpawn.y + 180), 'Invoice Imp');
    _spawnEnemy(
      Vector2(enemySpawn.x - 220, enemySpawn.y + 260),
      'Impulse Goblin',
    );
    _spawnEnemy(Vector2(enemySpawn.x + 260, enemySpawn.y - 180), 'Fee Phantom');

    camera.viewfinder.zoom = 1.1;
    camera.viewfinder.anchor = Anchor(
      _cameraAnchorRatio.x,
      _cameraAnchorRatio.y,
    );
    camera.follow(_cameraTarget);
    _emitProgressIfMoved(force: true);
  }

  Future<TiledComponent?> _loadWorldMapSafely() async {
    try {
      final tiled = await TiledComponent.load(_world.tmxPath, Vector2.all(32));
      if (!_hasRenderableTiles(tiled.tileMap.map)) {
        debugPrint(
          '${_world.tmxPath} loaded but no visible tiles were found. Falling back to solid viewport.',
        );
        return null;
      }
      return tiled;
    } catch (error, stackTrace) {
      debugPrint('Failed to load ${_world.tmxPath}: $error');
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
  void update(double dt) {
    super.update(dt);
    _progressEmitClock += dt;
    if (_progressEmitClock >= 1.5) {
      _progressEmitClock = 0;
      _emitProgressIfMoved();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _player?.setKeyboardState(keysPressed);
    super.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  void movePlayerTowardCanvasPosition(Vector2 canvasPosition) {
    if (_activeEncounter != null || _adventureState.combatVisible) {
      clearPointerMovement();
      return;
    }

    _player?.setPointerTarget(_canvasToWorldPosition(canvasPosition));
  }

  void steerPlayerWithCanvasDirection(Vector2 canvasDirection) {
    if (_activeEncounter != null || _adventureState.combatVisible) {
      clearPointerMovement();
      return;
    }

    _player?.setPointerDirection(canvasDirection);
  }

  void clearPointerMovement() {
    _player?.clearPointerTarget();
    _player?.clearPointerDirection();
  }

  Vector2 _canvasToWorldPosition(Vector2 canvasPosition) {
    final anchorPoint = Vector2(
      size.x * _cameraAnchorRatio.x,
      size.y * _cameraAnchorRatio.y,
    );
    final worldPosition =
        camera.viewfinder.position +
        ((canvasPosition - anchorPoint) / camera.viewfinder.zoom);

    worldPosition.x = worldPosition.x.clamp(0, _mapPixelSize.x).toDouble();
    worldPosition.y = worldPosition.y.clamp(0, _mapPixelSize.y).toDouble();
    return worldPosition;
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
        defeatedEnemy.scheduleRespawn(
          newPosition,
          delay: const Duration(milliseconds: 1100),
        );
      });
    }

    _activeEncounter = null;
    _player?.movementEnabled = true;
    _adventureState.restoreMovementAfterCombat();
    _emitProgressIfMoved(force: true);
  }

  void _spawnEnemy(Vector2 position, String name) {
    final enemy = EnemyMonsterComponent(
      position: position,
      enemyName: name,
      movementBounds: Rect.fromLTWH(0, 0, _mapPixelSize.x, _mapPixelSize.y),
    );
    _monsters.add(enemy);
    add(enemy);
  }

  void _beginEncounter(EnemyMonsterComponent enemy) {
    if (_activeEncounter != null || _adventureState.combatVisible) {
      return;
    }
    _activeEncounter = enemy;
    _player?.movementEnabled = false;
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

  Vector2 _resolveSpawnPoint(RenderableTiledMap? tiledMap, Vector2 mapSize) {
    final savedPosition = _initialPosition;
    if (savedPosition != null && _isValidSpawn(savedPosition, mapSize)) {
      return savedPosition.clone();
    }

    final tiledSpawn = _readSpawnPoint(tiledMap, 'player_spawn');
    if (tiledSpawn != null && _isValidSpawn(tiledSpawn, mapSize)) {
      return tiledSpawn;
    }

    final worldSpawn = _world.fallbackSpawn;
    if (_isValidSpawn(worldSpawn, mapSize)) {
      return worldSpawn.clone();
    }

    return Vector2(mapSize.x * 0.4, mapSize.y * 0.5);
  }

  bool _isValidSpawn(Vector2 position, Vector2 mapSize) {
    if (!position.x.isFinite || !position.y.isFinite) {
      return false;
    }
    return position.x >= 0 &&
        position.y >= 0 &&
        position.x <= mapSize.x &&
        position.y <= mapSize.y;
  }

  void _emitProgressIfMoved({bool force = false}) {
    final position = _player?.position;
    if (position == null) {
      return;
    }

    final lastPosition = _lastEmittedProgressPosition;
    if (!force &&
        lastPosition != null &&
        (position - lastPosition).length2 < 24 * 24) {
      return;
    }

    _lastEmittedProgressPosition = position.clone();
    _onProgressChanged?.call(_world.id, position.clone());
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
          (object) =>
              Rect.fromLTWH(object.x, object.y, object.width, object.height),
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
        return Vector2(
          object.x + (object.width / 2),
          object.y + (object.height / 2),
        );
      }
    }
    return null;
  }
}
