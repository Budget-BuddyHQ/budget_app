import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// A panel drawn from the hand-made pixel UI kit in `assets/images/ui/`,
/// stretched with a nine-slice so it keeps its 1px border and gold header
/// bar crisp at any size.
///
/// **Why this exists.** The kit (`panel_dialog.png`, `panel_square.png`,
/// the 8x8 coin/heart/star/bag icons, the little bars) was drawn for this
/// app and then never used — every panel in the app was a `BoxDecoration`
/// with a rounded rect and a tint, which is why the UI read as generic
/// Material with a pixel font on top rather than as a pixel game. This is
/// the bridge: real art, arbitrary size.
///
/// `centerSlice` is what makes it work. The source is 48x32, so without a
/// nine-slice it would either tile visibly or smear the border into a
/// gradient; slicing pins the corners and edges and stretches only the
/// flat middle.
///
/// `filterQuality: none` is not optional here — the default smooths pixel
/// art into mush at these scale factors.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 16, 14, 14),
    this.plain = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Use the borderless square panel instead of the one with the gold
  /// header bar — for nested or secondary surfaces, where a second header
  /// stripe would read as a second section.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            plain ? AppAssets.uiPanelSquare : AppAssets.uiPanelDialog,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            // Corners and edges stay 1:1; only the flat interior stretches.
            // The top band is left outside the slice so the gold header bar
            // survives instead of being scaled away.
            centerSlice: plain
                ? const Rect.fromLTRB(6, 6, 26, 26)
                : const Rect.fromLTRB(6, 10, 42, 26),
            errorBuilder: (_, _, _) => DecoratedBox(
              // The panels are declared in pubspec.yaml, but a missing
              // asset should degrade to something styled rather than to a
              // broken-image glyph in the middle of the UI.
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFE9C46A).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    );
  }
}

/// One of the kit's 8x8 icons at a usable size, nearest-neighbour scaled.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.asset, {super.key, this.size = 16});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
    );
  }
}
