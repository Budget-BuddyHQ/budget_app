import 'package:flutter/material.dart';

import 'pixel_kit.dart';

/// A pixel panel. Now a thin alias for [PixelFrame].
///
/// **Kept only so existing call sites keep compiling.** This used to draw
/// `assets/images/ui/panel_dialog.png` — a flat green rectangle with a gold
/// stripe, which was the whole reason the app read as Material with a pixel
/// font on top. That art and its folder are gone; the real surfaces come from
/// the sliced, recolored pack (`tool/build_ui_pack.py`) that [PixelFrame]
/// draws.
///
/// Prefer [PixelFrame] directly in new code: it exposes the four surface
/// styles, and this wrapper can only express two of them.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 16, 14, 14),
    this.plain = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Was "the borderless square panel". Now selects the parchment surface
  /// instead of the slate one, which is the nearest equivalent distinction.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    return PixelFrame(
      style: plain ? PixelFrameStyle.paper : PixelFrameStyle.slate,
      padding: padding,
      child: child,
    );
  }
}

/// One kit icon at a usable size. Alias for [PixelKitIcon].
///
/// The old 8x8 glyphs it used to draw are gone with the rest of that kit;
/// the replacements are 16x16 with real interior detail.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.asset, {super.key, this.size = 16});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => PixelKitIcon(asset, size: size);
}
