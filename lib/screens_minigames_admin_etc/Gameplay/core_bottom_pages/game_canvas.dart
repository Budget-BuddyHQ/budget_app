import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';

/// The adventure world, running on Bonfire: a tile map generated from the
/// village terrain matrix below, a joystick, and the player's equipped
/// turtle skin walking around it.
class GameCanvas extends StatelessWidget {
  const GameCanvas({
    super.key,
    this.mapId,
    this.initialPosition,
    this.skinAssetPath,
  });

  final String? mapId;
  final Offset? initialPosition;
  final String? skinAssetPath;

  static const double _tileSize = 48;

  // 0 = grass, 1 = water (blocked), 2 = dirt path.
  static const List<List<double>> _terrain = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 2, 2, 0, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 2, 0, 0, 0, 2, 2, 2, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 2, 0, 0, 0, 0, 0, 2, 2, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 2, 2, 0, 0, 0, 0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 0, 0],
    [0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0],
    [0, 0, 0, 2, 2, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0],
    [0, 0, 0, 0, 2, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0],
    [0, 0, 0, 0, 2, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0],
    [0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];

  @override
  Widget build(BuildContext context) {
    final userStats = context.read<UserStatsController>().stats;
    final equippedSkin = skinFromId(userStats.equippedSkin);
    final skinPath = (skinAssetPath ?? equippedSkin.assetPath).replaceFirst(
      'assets/images/',
      '',
    );

    // Saved adventure positions from the old placeholder are in pixels;
    // convert anything outside the tile grid, then clamp inside the walls.
    var start = initialPosition ?? const Offset(4, 5);
    if (start.dx > 17 || start.dy > 11) {
      start = Offset(start.dx / _tileSize, start.dy / _tileSize);
    }
    start = Offset(
      start.dx.clamp(1.0, 16.0).toDouble(),
      start.dy.clamp(1.0, 10.0).toDouble(),
    );

    return OrientationScope(
      orientations: const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF071711),
        body: Stack(
          children: [
            BonfireWidget(
              backgroundColor: const Color(0xFF0A1D17),
              playerControllers: [Joystick(directional: JoystickDirectional())],
              map: MatrixMapGenerator.generate(
                layers: [MatrixLayer(matrix: _terrain, axisInverted: true)],
                builder: _buildTile,
              ),
              player: _TurtlePlayer(
                position: Vector2(start.dx * _tileSize, start.dy * _tileSize),
                spritePath: skinPath,
              ),
              cameraConfig: CameraConfig(zoom: 1.4, moveOnlyMapArea: true),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF071711).withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Tile _buildTile(ItemMatrixProperties properties) {
    final String path;
    final bool blocked;
    switch (properties.value.toInt()) {
      case 1:
        path = 'tiles/tile_water.png';
        blocked = true;
      case 2:
        path = 'tiles/tile_dirt.png';
        blocked = false;
      default:
        path = 'tiles/tile_grass.png';
        blocked = false;
    }

    return Tile(
      x: properties.position.x,
      y: properties.position.y,
      width: _tileSize,
      height: _tileSize,
      sprite: TileSprite(path: path),
      collisions: blocked
          ? [RectangleHitbox(size: Vector2.all(_tileSize))]
          : null,
    );
  }
}

class _TurtlePlayer extends SimplePlayer {
  _TurtlePlayer({required super.position, required String spritePath})
    : super(
        size: Vector2.all(GameCanvas._tileSize * 0.9),
        speed: 130,
        animation: SimpleDirectionAnimation(
          idleRight: _frame(spritePath),
          runRight: _frame(spritePath),
        ),
      );

  static Future<SpriteAnimation> _frame(String path) async {
    final sprite = await Sprite.load(path);
    return SpriteAnimation.spriteList([sprite], stepTime: 0.4);
  }
}
