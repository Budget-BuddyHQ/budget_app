import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/widgets_custom_lotties/sprite_sheet_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SpriteSheetImage keeps its aspect-correct size inside a mismatched '
    'square ancestor',
    (tester) async {
      // Regression for the bleed/clip bug: a villager cell is 104x152 (taller
      // than wide). Callers commonly wrap it in a SQUARE SizedBox (a circular
      // avatar frame, a grid tile). Before the Center() fix, that square
      // ancestor's tight constraints forced the inner cell to stretch to the
      // square, widening the visible clip window past one cell and bleeding
      // in neighboring frames.
      const requestedSize = 160.0;
      const cellW = AppAssets.villagerCellWidth;
      const cellH = AppAssets.villagerCellHeight;
      final expectedWidth = requestedSize * (cellW / cellH);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: requestedSize,
                height: requestedSize,
                // Mirrors AvatarSprite's fix: Center loosens the square
                // ancestor's tight constraint before it reaches the sheet.
                child: Center(
                  child: SpriteSheetImage(
                    sheetAsset: AppAssets.villagerSheet(
                      'emerald_scout',
                      female: false,
                    ),
                    columns: AppAssets.villagerSheetColumns,
                    rows: AppAssets.villagerSheetRows,
                    column: 0,
                    row: 0,
                    cellWidth: cellW,
                    cellHeight: cellH,
                    width: expectedWidth,
                    height: requestedSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // The rendered SizedBox inside SpriteSheetImage must keep its narrow
      // aspect-correct width, NOT be stretched to the square ancestor's width.
      final renderedSize = tester.getSize(find.byType(SpriteSheetImage));
      expect(renderedSize.height, closeTo(requestedSize, 0.5));
      expect(
        renderedSize.width,
        closeTo(expectedWidth, 0.5),
        reason:
            'SpriteSheetImage stretched to ${renderedSize.width}, expected '
            '~$expectedWidth. A wider box than one cell means the OverflowBox '
            'clip window is wider than a single cell and neighboring frames '
            'will bleed into view.',
      );
      expect(renderedSize.width, lessThan(requestedSize));
    },
  );
}
