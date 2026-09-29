import 'package:flutter/material.dart';

/// Renders a single cell from a sprite sheet.
///
/// Pure widgets, no async image decoding: the sheet is drawn at full size
/// inside an [OverflowBox] and clipped down to one cell, with [Alignment]
/// selecting which cell lands in the window. That keeps it usable anywhere a
/// plain `Image.asset` was, including inside const-heavy build methods.
class SpriteSheetImage extends StatelessWidget {
  const SpriteSheetImage({
    super.key,
    required this.sheetAsset,
    required this.columns,
    required this.rows,
    required this.column,
    required this.row,
    required this.cellWidth,
    required this.cellHeight,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String sheetAsset;
  final int columns;
  final int rows;
  final int column;
  final int row;
  final double cellWidth;
  final double cellHeight;

  /// Display size. Defaults to the natural cell size.
  final double? width;
  final double? height;

  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final displayW = width ?? cellWidth;
    final displayH = height ?? cellHeight;

    // Scale the whole sheet by the same factor the cell is being scaled by,
    // so the clipped window shows exactly one cell at the requested size.
    final scale = displayW / cellWidth;
    final sheetW = cellWidth * columns * scale;
    final sheetH = cellHeight * rows * scale;

    // Alignment maps -1..1 across the available travel. With a single row or
    // column there is no travel, so clamp to center to avoid dividing by zero.
    final alignX = columns > 1 ? (column / (columns - 1)) * 2 - 1 : 0.0;
    final alignY = rows > 1 ? (row / (rows - 1)) * 2 - 1 : 0.0;

    return SizedBox(
      width: displayW,
      height: displayH,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: sheetW,
          maxHeight: sheetH,
          minWidth: sheetW,
          minHeight: sheetH,
          alignment: Alignment(alignX, alignY),
          child: Image.asset(
            sheetAsset,
            width: sheetW,
            height: sheetH,
            filterQuality: FilterQuality.none,
            fit: BoxFit.fill,
            errorBuilder: errorBuilder,
          ),
        ),
      ),
    );
  }
}
