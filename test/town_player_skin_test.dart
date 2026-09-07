import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/avatar_skin.dart';

/// Who the player is when they walk into town.
///
/// **The bug.** `adventure_world_screen.dart` picked the sprite with
/// `equippedSkin.isHuman ? equippedSkin.sheetAsset(body) :
/// AppAssets.villagerSheet(null, ...)`. Read the second branch: **every
/// non-villager skin walked the town as the default blue villager.** All four
/// turtles and the Mushroom Goomba.
///
/// It never threw and never logged, because the fallback is a real sheet that
/// loads perfectly — it is simply somebody else. That is the shape of every
/// bug in this area: the art system works, and points at the wrong art.
///
/// Sheets are built by `tool/make_town_sheets.py`, which packs the stills into
/// the villager grid so the town's loaders, cell size and aspect ratio all
/// keep working untouched.
void main() {
  group('every skin has a body in town', () {
    test('no skin falls back to the blue villager', () {
      // The regression, stated once: a skin that resolves to neither its own
      // villager sheet nor a town sheet is a player wearing somebody else.
      for (final skin in budgetBuddySkins) {
        if (skin.isHuman) continue;
        expect(
          AppAssets.townSheet(skin.id),
          isNotNull,
          reason:
              '${skin.name} would walk the town as the default villager. '
              'Add it to tool/make_town_sheets.py and re-run.',
        );
      }
    });

    test('the sheets exist on disk', () {
      for (final skinId in AppAssets.townSheetSkinIds) {
        final path = AppAssets.townSheet(skinId)!;
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path is missing. Run: python tool/make_town_sheets.py',
        );
      }
    });

    test('a villager gets null, not a town sheet', () {
      // Villagers already have real sheets with real side views. Routing them
      // through the generated ones would be a downgrade.
      expect(AppAssets.townSheet('villager_classic'), isNull);
    });
  });

  group('the sheets fit the grid the town assumes', () {
    test('every sheet is exactly the villager grid', () async {
      // Bonfire slices these by cell size and column index. A sheet even a
      // few pixels off would show slivers of the neighbouring frame in every
      // step of the walk cycle — the same fault `avatar_sprite.dart` documents
      // for the customise grid.
      final expectedW =
          (AppAssets.villagerCellWidth * AppAssets.villagerSheetColumns)
              .round();
      final expectedH =
          (AppAssets.villagerCellHeight * AppAssets.villagerSheetRows).round();

      for (final skinId in AppAssets.townSheetSkinIds) {
        final bytes = await File(AppAssets.townSheet(skinId)!).readAsBytes();
        final codec = await instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;

        expect(
          [image.width, image.height],
          [expectedW, expectedH],
          reason:
              '$skinId is ${image.width}x${image.height}, expected '
              '${expectedW}x$expectedH',
        );
      }
    });

    test('no sprite spills out of its own cell', () async {
      // A frame that overflows its cell bleeds into the neighbour, which the
      // town would render as a second turtle hanging off the first.
      final cellW = AppAssets.villagerCellWidth.round();
      final cellH = AppAssets.villagerCellHeight.round();

      for (final skinId in AppAssets.townSheetSkinIds) {
        final bytes = await File(AppAssets.townSheet(skinId)!).readAsBytes();
        final codec = await instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        final data = (await image.toByteData())!;

        for (var row = 0; row < AppAssets.villagerSheetRows; row++) {
          for (var col = 0; col < AppAssets.villagerSheetColumns; col++) {
            // Walk the cell's border; any opaque pixel on it means the art is
            // touching, and probably crossing, the seam.
            var onEdge = 0;
            for (var x = 0; x < cellW; x++) {
              for (final y in <int>[0, cellH - 1]) {
                final px = col * cellW + x;
                final py = row * cellH + y;
                final alpha = data.getUint8((py * image.width + px) * 4 + 3);
                if (alpha != 0) onEdge++;
              }
            }
            expect(
              onEdge,
              0,
              reason:
                  '$skinId row $row column $col touches its cell edge '
                  '($onEdge pixels)',
            );
          }
        }
      }
    });

    test('the walk row is not eight copies of one frame', () async {
      // The bob is what makes a still read as a walk. If the generator ever
      // stops applying it, every column becomes identical and the character
      // slides around the map like furniture.
      final cellW = AppAssets.villagerCellWidth.round();
      final cellH = AppAssets.villagerCellHeight.round();

      final bytes = await File(
        AppAssets.townSheet('classic_turtle')!,
      ).readAsBytes();
      final codec = await instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      final data = (await image.toByteData())!;

      int topOfArt(int col) {
        for (var y = 0; y < cellH; y++) {
          for (var x = 0; x < cellW; x++) {
            final px = col * cellW + x;
            if (data.getUint8((y * image.width + px) * 4 + 3) != 0) return y;
          }
        }
        return cellH;
      }

      final tops = <int>{for (var c = 0; c < 8; c++) topOfArt(c)};
      expect(
        tops.length,
        greaterThan(1),
        reason: 'the south walk row has no bob — every frame is identical',
      );
    });
  });
}
