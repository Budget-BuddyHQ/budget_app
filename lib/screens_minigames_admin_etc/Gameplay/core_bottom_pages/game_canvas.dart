import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';

/// The adventure world, running on Bonfire: a tile world generated from the
/// terrain matrix below, a joystick, collectible coins that pay out real
/// gold, and the player's equipped turtle skin as the hero.
class GameCanvas extends StatefulWidget {
  const GameCanvas({
    super.key,
    this.mapId,
    this.initialPosition,
    this.skinAssetPath,
  });

  final String? mapId;
  final Offset? initialPosition;
  final String? skinAssetPath;

  static const double tileSize = 48;

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas> {
  int _coinsCollected = 0;
  bool _rewardClaimed = false;

  // 0 = grass, 1 = water (blocked), 2 = dirt path.
  // A village loop on the west side, a lake in the middle, a beach trail
  // east, and a southern road connecting them — mirrors the adventure map.
  static const List<List<double>> _terrain = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 2, 2, 0, 0],
    [0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 2, 2, 2, 0, 0],
    [0, 2, 0, 0, 0, 0, 2, 2, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 0, 2, 0, 0],
    [0, 2, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 1, 1, 1, 0, 0, 2, 2, 0, 0, 2, 0, 0],
    [0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 1, 1, 0, 0, 2, 2, 0, 0, 0, 2, 0, 0],
    [0, 0, 2, 2, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 0, 0],
    [0, 0, 0, 2, 2, 0, 1, 1, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 2, 0, 0],
    [0, 0, 0, 0, 2, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 2, 0, 0],
    [0, 0, 0, 0, 2, 2, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 0, 0],
    [0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0],
    [0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];

  // Tile coordinates for collectible coins, spread across the zones.
  static const List<Offset> _coinTiles = [
    Offset(3, 3),
    Offset(6, 5),
    Offset(9, 2),
    Offset(16, 3),
    Offset(20, 5),
    Offset(10, 9),
    Offset(15, 10),
    Offset(20, 8),
  ];

  void _onCoin() {
    setState(() => _coinsCollected++);
    HapticFeedback.lightImpact();
  }

  Future<void> _leaveWorld() async {
    if (_coinsCollected > 0 && !_rewardClaimed) {
      _rewardClaimed = true;
      final controller = context.read<UserStatsController>();
      final result = await controller.applyChallengePayload(<String, dynamic>{
        'status': 'completed',
        'gold_earned': _coinsCollected * 5,
        'xp_earned': _coinsCollected * 2,
        'literacy_points_earned': 0,
        'title': 'Adventure Coins',
        'description': 'Collected $_coinsCollected coins exploring the world.',
      });
      if (mounted) {
        GameToast.show(
          context,
          title: 'Coins banked',
          message:
              '+${_coinsCollected * 5} gold from $_coinsCollected coins. ${result.message}',
          icon: Icons.paid_rounded,
          accent: const Color(0xFFFFD45C),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStats = context.read<UserStatsController>().stats;
    final equippedSkin = skinFromId(userStats.equippedSkin);
    final skinPath = (widget.skinAssetPath ?? equippedSkin.assetPath)
        .replaceFirst('assets/images/', '');

    // Saved adventure positions from the old placeholder are in pixels;
    // convert anything outside the tile grid, then clamp inside the walls.
    var start = widget.initialPosition ?? const Offset(4, 5);
    if (start.dx > 23 || start.dy > 13) {
      start = Offset(
        start.dx / GameCanvas.tileSize,
        start.dy / GameCanvas.tileSize,
      );
    }
    start = Offset(
      start.dx.clamp(1.0, 22.0).toDouble(),
      start.dy.clamp(1.0, 12.0).toDouble(),
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
              components: [
                for (final tile in _coinTiles)
                  _Coin(
                    position: Vector2(
                      tile.dx * GameCanvas.tileSize + 10,
                      tile.dy * GameCanvas.tileSize + 10,
                    ),
                    onCollected: _onCoin,
                  ),
              ],
              player: _TurtlePlayer(
                position: Vector2(
                  start.dx * GameCanvas.tileSize,
                  start.dy * GameCanvas.tileSize,
                ),
                spritePath: skinPath,
              ),
              cameraConfig: CameraConfig(zoom: 1.4, moveOnlyMapArea: true),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF071711).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: _leaveWorld,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071711).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD45C).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.paid_rounded,
                            color: Color(0xFFFFD45C),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_coinsCollected / ${_coinTiles.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      width: GameCanvas.tileSize,
      height: GameCanvas.tileSize,
      sprite: TileSprite(path: path),
      collisions: blocked
          ? [RectangleHitbox(size: Vector2.all(GameCanvas.tileSize))]
          : null,
    );
  }
}

class _TurtlePlayer extends SimplePlayer {
  _TurtlePlayer({required super.position, required String spritePath})
    : super(
        size: Vector2.all(GameCanvas.tileSize * 0.9),
        speed: 130,
        animation: _animationFor(spritePath),
      );

  /// Skins that ship as a multi-frame walk cycle animate directionally; every
  /// other skin is a single static sprite reused for idle and run.
  static SimpleDirectionAnimation _animationFor(String path) {
    if (path.contains('goomba/')) {
      const south = <String>[
        'goomba/south1.png',
        'goomba/south2.png',
        'goomba/south3.png',
        'goomba/south4.png',
      ];
      const north = <String>[
        'goomba/north1.png',
        'goomba/north2.png',
        'goomba/north3.png',
        'goomba/north4.png',
      ];
      // Left/right reuse the front (south) frames; SimpleDirectionAnimation
      // flips horizontally on its own, so the goomba always faces the camera
      // sideways and turns away only when walking up.
      return SimpleDirectionAnimation(
        idleRight: _walk(<String>[south.first]),
        runRight: _walk(south),
        idleDown: _walk(<String>[south.first]),
        runDown: _walk(south),
        idleUp: _walk(<String>[north.first]),
        runUp: _walk(north),
      );
    }
    return SimpleDirectionAnimation(
      idleRight: _frame(path),
      runRight: _frame(path),
    );
  }

  static Future<SpriteAnimation> _walk(List<String> paths) async {
    final sprites = <Sprite>[];
    for (final path in paths) {
      sprites.add(await Sprite.load(path));
    }
    return SpriteAnimation.spriteList(
      sprites,
      stepTime: sprites.length > 1 ? 0.16 : 0.4,
    );
  }

  static Future<SpriteAnimation> _frame(String path) async {
    final sprite = await Sprite.load(path);
    return SpriteAnimation.spriteList([sprite], stepTime: 0.4);
  }
}

class _Coin extends GameDecoration with Sensor {
  _Coin({required super.position, required this.onCollected})
    : super.withSprite(
        sprite: Sprite.load('tiles/coin.png'),
        size: Vector2.all(26),
      );

  final VoidCallback onCollected;
  bool _taken = false;

  @override
  Future<void> onLoad() {
    add(RectangleHitbox(size: size));
    return super.onLoad();
  }

  @override
  void onContact(GameComponent component) {
    if (_taken || component is! Player) {
      return;
    }
    _taken = true;
    onCollected();
    removeFromParent();
  }
}
