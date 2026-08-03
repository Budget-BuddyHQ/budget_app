import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/tiled/reader/tiled_asset_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../widgets_custom_lotties/custom_button.dart';

/// Where the exported Tiled map (JSON, not raw .tmx — see the README next to
/// it) is expected to live. `TiledAssetReader` is hardcoded to read from
/// under `assets/images/`, so this can't move without also changing that.
const String kAdventureMapAsset = 'assets/images/maps/adventure_map.json';

/// The RPG overworld — walking the equipped villager skin around a Tiled
/// map. Until a real map is dropped at [kAdventureMapAsset], this shows a
/// plain "waiting for the map" screen instead of trying (and failing) to
/// boot the game canvas.
class AdventureWorldScreen extends StatefulWidget {
  const AdventureWorldScreen({super.key});

  @override
  State<AdventureWorldScreen> createState() => _AdventureWorldScreenState();
}

class _AdventureWorldScreenState extends State<AdventureWorldScreen> {
  // null = still checking, true = map found, false = not there yet.
  bool? _mapReady;

  @override
  void initState() {
    super.initState();
    _checkForMap();
  }

  Future<void> _checkForMap() async {
    var found = true;
    try {
      await rootBundle.load(kAdventureMapAsset);
    } catch (_) {
      found = false;
    }
    if (mounted) {
      setState(() => _mapReady = found);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mapReady == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF071711),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
        ),
      );
    }

    if (_mapReady == false) {
      return const _AdventureMapPendingScreen();
    }

    final stats = context.read<UserStatsController>().stats;
    final equippedSkin = skinFromId(stats.equippedSkin);
    final body = stats.villagerBody;
    // The world only has directional walk art for the villager body — a
    // non-human equipped skin (turtle, critter) falls back to the classic
    // villager here rather than showing a static image trying to "walk".
    final playerSheet = equippedSkin.isHuman
        ? equippedSkin.sheetAsset(body)
        : AppAssets.villagerSheet(null, female: body.isFemale);

    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      body: BonfireWidget(
        map: WorldMapByTiled(TiledAssetReader(asset: kAdventureMapAsset)),
        player: _buildPlayer(playerSheet),
        playerControllers: [Joystick(directional: JoystickDirectional())],
        cameraConfig: CameraConfig(zoom: 1.4),
      ),
    );
  }

  SimplePlayer _buildPlayer(String sheetAsset) {
    // Row layout matches AppAssets' villager sheet convention exactly:
    // 8 columns x 4 rows (south/north/west/east), 104x152 per cell, north
    // has only 7 real frames. See app_assets.dart for the source of truth.
    Future<SpriteAnimation> row(int rowIndex, int frameCount) =>
        _loadRowAnimation(sheetAsset, rowIndex, frameCount);
    Future<SpriteAnimation> frame(int rowIndex) =>
        _loadRowAnimation(sheetAsset, rowIndex, 1, stepTime: 1);

    return SimplePlayer(
      // Placeholder spawn point — once the real map arrives, this should
      // move to wherever its "spawn" object/tile actually is.
      position: Vector2(64, 64),
      size: Vector2.all(32),
      animation: SimpleDirectionAnimation(
        // enabledFlipX defaults true, which would mirror one direction to
        // fake the other — the sheet already has real, distinct west/east
        // art, so that's turned off to avoid double-flipping it.
        enabledFlipX: false,
        idleDown: frame(0),
        runDown: row(0, 8),
        idleUp: frame(1),
        runUp: row(1, 7),
        idleLeft: frame(2),
        runLeft: row(2, 8),
        idleRight: frame(3),
        runRight: row(3, 8),
      ),
    );
  }
}

final _villagerSheetImages = Images(prefix: '');

Future<SpriteAnimation> _loadRowAnimation(
  String sheetAsset,
  int row,
  int frameCount, {
  double stepTime = 0.12,
}) async {
  final image = await _villagerSheetImages.load(sheetAsset);
  final sheet = SpriteSheet(
    image: image,
    srcSize: Vector2(AppAssets.villagerCellWidth, AppAssets.villagerCellHeight),
  );
  return sheet.createAnimation(row: row, stepTime: stepTime, to: frameCount);
}

class _AdventureMapPendingScreen extends StatelessWidget {
  const _AdventureMapPendingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF85EFAC),
                  size: 56,
                ),
                const SizedBox(height: 18),
                Text(
                  'Map on the way',
                  style: GoogleFonts.baloo2(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The adventure world is wired up and ready — it just '
                  'needs its map. Drop the exported Tiled JSON at\n'
                  '$kAdventureMapAsset\n'
                  'and it will load automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Back',
                  width: 160,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
