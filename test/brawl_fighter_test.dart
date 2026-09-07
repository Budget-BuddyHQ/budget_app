import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/avatar_skin.dart';

/// The player's fighter in Finance Brawl.
///
/// **What this replaced.** The Brawl already knew which skin was equipped —
/// `equippedSkinId` was threaded all the way into the painter — and used it to
/// draw *the first letter of the id*. Every one of the twenty-four skins a
/// player can win from the case rendered as a capital letter in a green
/// circle: "C" for Classic Turtle, "M" for Mushroom Goomba, and "V" for every
/// single villager, which is most of the roster.
///
/// So the answer to "I want more characters in Finance Brawl" was already
/// bought and paid for. These tests cover the piece that made it drawable:
/// resolving a skin to one frame a `Canvas` can blit, which is not the same
/// question the widget tree answers.
void main() {
  AvatarSkin byId(String id) =>
      budgetBuddySkins.firstWhere((skin) => skin.id == id);

  group('resolving a skin to one canvas frame', () {
    test('a villager resolves to a single cell, not the whole sheet', () {
      // The trap this exists to close. Villager art is a packed 8x4 sheet, so
      // handing the loaded image straight to `drawImageRect` would squeeze all
      // thirty-two frames into the player token.
      final frame = byId('villager_classic').canvasFrame(VillagerBody.masculine);

      expect(frame.cell, isNotNull);
      expect(frame.cell!.width, AppAssets.villagerCellWidth);
      expect(frame.cell!.height, AppAssets.villagerCellHeight);
    });

    test('the cell is the south-facing first frame', () {
      // Facing the player, standing still. Any other row or column is a
      // character caught mid-stride, or one showing you their back.
      final frame = byId('villager_teal_analyst').canvasFrame(
        VillagerBody.feminine,
      );

      expect(frame.cell!.left, 0);
      expect(
        frame.cell!.top,
        AppAssets.villagerRow('south') * AppAssets.villagerCellHeight,
      );
    });

    test('body changes which sheet is loaded', () {
      // A player who switches body must not keep fighting as the old one.
      final skin = byId('villager_classic');

      expect(
        skin.canvasFrame(VillagerBody.masculine).asset,
        isNot(skin.canvasFrame(VillagerBody.feminine).asset),
      );
    });

    test('turtles and critters draw whole, with no cell', () {
      for (final skin in budgetBuddySkins.where((s) => !s.isHuman)) {
        final frame = skin.canvasFrame(VillagerBody.masculine);
        expect(
          frame.cell,
          isNull,
          reason: '${skin.name} is a loose still, not a sheet',
        );
        expect(frame.asset, skin.previewAsset);
      }
    });

    test('every skin resolves to a file that exists', () {
      // The Brawl loads this path at runtime inside the game loop. A skin
      // pointing at nothing would silently drop the player back to the letter
      // the whole change exists to remove.
      for (final skin in budgetBuddySkins) {
        for (final body in VillagerBody.values) {
          final asset = skin.canvasFrame(body).asset;
          expect(
            asset,
            isNotEmpty,
            reason: '${skin.name} resolves to no asset at all',
          );
          expect(
            File(asset).existsSync(),
            isTrue,
            reason: '${skin.name} (${body.label}) points at a missing $asset',
          );
        }
      }
    });

    test('the cell never runs off the end of its sheet', () {
      // Cheap arithmetic guard: if the grid constants are ever edited without
      // repacking the sheets, this catches it before a player sees a sliver of
      // the neighbouring frame stapled to their fighter.
      final frame = byId('villager_classic').canvasFrame(
        VillagerBody.masculine,
      );
      final sheetWidth =
          AppAssets.villagerCellWidth * AppAssets.villagerSheetColumns;
      final sheetHeight =
          AppAssets.villagerCellHeight * AppAssets.villagerSheetRows;

      expect(frame.cell!.right, lessThanOrEqualTo(sheetWidth));
      expect(frame.cell!.bottom, lessThanOrEqualTo(sheetHeight));
    });
  });

  group('the roster this unlocks', () {
    test('there are far more fighters than the Brawl had characters', () {
      // The point of the change: the customise screen becomes a character
      // select. Twenty-four skins is twenty-four fighters, at no art cost.
      expect(budgetBuddySkins.length, greaterThanOrEqualTo(20));
    });

    test('the letter fallback is no longer the only path', () {
      // Source-level, because a CustomPainter's output is not reachable from a
      // unit test. What is checked is that the painter has a sprite branch at
      // all — the regression this guards is somebody deleting the draw and
      // leaving the letter, which would look like nothing changed until you
      // played it.
      final painter = File(
        'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
        'finance_brawl_game.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');

      expect(
        painter.contains('} else if (skinImage != null) {'),
        isTrue,
        reason: 'the equipped skin is no longer drawn as the fighter',
      );
      expect(
        painter.contains('canvas.drawImageRect('),
        isTrue,
        reason:
            'paintImage has no source rectangle — a villager drawn with it '
            'renders the entire sheet inside the player token',
      );
    });
  });
}
