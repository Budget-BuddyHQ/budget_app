import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_assets.dart';
import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'sprite_sheet_image.dart';

/// Draws any [AvatarSkin] at a given size.
///
/// Villagers come from a packed sprite sheet and need a cell lookup; turtles
/// and critters are still single images. This hides that split so call sites
/// can just say "draw this skin".
class AvatarSprite extends StatelessWidget {
  const AvatarSprite({
    super.key,
    required this.skin,
    this.body,
    this.size,
    this.direction = 'south',
    this.frame = 0,
    this.fit = BoxFit.contain,
  });

  final AvatarSkin skin;

  /// Only affects villager skins; ignored by turtles and critters. Defaults to
  /// the signed-in player's saved body so call sites do not have to thread it
  /// through every widget layer.
  final VillagerBody? body;

  final double? size;
  final String direction;
  final int frame;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!skin.isHuman) {
      return Image.asset(
        skin.previewAsset,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stack) => _MissingArt(size: size),
      );
    }

    final effectiveBody =
        body ??
        context.select<UserStatsController, VillagerBody>(
          (controller) => controller.stats.villagerBody,
        );

    final cellW = AppAssets.villagerCellWidth;
    final cellH = AppAssets.villagerCellHeight;
    // Fit the cell's aspect ratio inside the requested square.
    final targetW = size == null ? cellW : size! * (cellW / cellH);

    return SpriteSheetImage(
      sheetAsset: skin.sheetAsset(effectiveBody),
      columns: AppAssets.villagerSheetColumns,
      rows: AppAssets.villagerSheetRows,
      column: frame.clamp(0, AppAssets.villagerFrameCount(direction) - 1),
      row: AppAssets.villagerRow(direction),
      cellWidth: cellW,
      cellHeight: cellH,
      width: targetW,
      height: size ?? cellH,
      errorBuilder: (context, error, stack) => _MissingArt(size: size),
    );
  }
}

class _MissingArt extends StatelessWidget {
  const _MissingArt({this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      size: (size ?? 48) * 0.6,
      color: Colors.white.withValues(alpha: 0.4),
    );
  }
}
