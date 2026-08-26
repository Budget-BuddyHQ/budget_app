/// Widgets that draw the app's pixel UI kit.
///
/// **Why these exist.** The app kept being described as having no UI, and the
/// cause was structural rather than a matter of taste: there was nothing to
/// build a game interface *out of*. Every panel was a `BoxDecoration` rounded
/// rect, every button a `FilledButton`, every icon a Material glyph — so the
/// product read as Material with a pixel font on top.
///
/// The art itself was already in the repo and referenced by nothing (see
/// `tool/build_ui_pack.py`). Assets on disk do not fix anything on their own —
/// the previous kit sat unused in `assets/images/ui/` for exactly that reason.
/// These widgets are the bridge: they make the art the *easy* choice at a call
/// site, so new UI reaches for it by default instead of for a `Container`.
///
/// Everything here paints with [FilterQuality.none] and a `centerSlice`. Both
/// are load-bearing. Without `none`, the default smoothing turns pixel art to
/// mush at these scale factors; without the slice, a 192px source stretched to
/// a 340px panel smears its bevel into a gradient and reads as a scaling bug.
library;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Which surface art a [PixelFrame] wears.
enum PixelFrameStyle {
  /// Cream parchment. The default reading surface — highest contrast for
  /// body text, so it is what long copy sits on.
  paper(
    AppAssets.kitPanelPaper,
    AppAssets.kitSlicePanelPaper,
    AppAssets.kitSizePanelPaper,
  ),

  /// Dark slate with gold filigree corners. For panels on top of bright art,
  /// and for anything that should feel premium (rewards, summaries).
  slate(
    AppAssets.kitPanelSlate,
    AppAssets.kitSlicePanelSlate,
    AppAssets.kitSizePanelSlate,
  ),

  /// A hanging scroll with a rolled bottom edge. Deliberately *not*
  /// interchangeable with [paper]: the rolled edge is drawn into the bottom
  /// slice, so it only looks right when it is the last thing in a column.
  banner(
    AppAssets.kitPanelBanner,
    AppAssets.kitSlicePanelBanner,
    AppAssets.kitSizePanelBanner,
  ),

  /// Wooden boards with green corner brackets. Shops, inventory, the town.
  wood(
    AppAssets.kitPanelWood,
    AppAssets.kitSlicePanelWood,
    AppAssets.kitSizePanelWood,
  );

  const PixelFrameStyle(this.asset, this.slice, this.source);

  final String asset;
  final Rect slice;

  /// The art's own pixel size, needed to work out the end caps — see
  /// [AppAssets.kitSizePanelPaper].
  final Size source;
}

/// Draws a nine-slice, falling back when the box is smaller than its caps.
///
/// **This guard is not defensive padding, it is required.** Flutter subtracts
/// the two end caps from the destination before fitting a `centerSlice`, and a
/// negative remainder trips an assertion rather than clipping — so a panel
/// asked to render narrower than its own corners *crashes the frame*. That is
/// a live hazard here because these are shared widgets: any caller with a
/// tight `Expanded` can hit it, and it was hit for real by the Finance Brawl
/// HUD, whose panels get ~119px on a phone.
///
/// Below the limit it draws a plain rounded rect in the same family instead,
/// which at that size is indistinguishable from the art anyway.
class _NineSlice extends StatelessWidget {
  const _NineSlice({
    required this.asset,
    required this.slice,
    required this.source,
    required this.fallbackColor,
    this.fallbackRadius = 8,
    this.fallbackBorder,
  });

  final String asset;
  final Rect slice;

  /// The art's own size. Passed in rather than derived from the slice: the
  /// generator trims transparent padding, so the caps are no longer
  /// symmetric and `slice.left + slice.left` is simply wrong.
  final Size source;
  final Color fallbackColor;
  final double fallbackRadius;
  final Color? fallbackBorder;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => DecoratedBox(
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: BorderRadius.circular(fallbackRadius),
        border: fallbackBorder == null
            ? null
            : Border.all(color: fallbackBorder!, width: 1.5),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The caps are everything outside the slice, in source pixels.
        final capsWide = slice.left + (source.width - slice.right);
        final capsTall = slice.top + (source.height - slice.bottom);
        // `<=`, not `<`. A destination exactly equal to the caps leaves a
        // stretchable middle of zero, and the fit maths fails on that just
        // as it does on a negative one — which is how a 52px-tall button
        // drawn from art with 52px of vertical caps still asserted after the
        // first version of this guard.
        final tooNarrow =
            constraints.maxWidth.isFinite && constraints.maxWidth <= capsWide;
        final tooShort =
            constraints.maxHeight.isFinite && constraints.maxHeight <= capsTall;
        if (tooNarrow || tooShort) return fallback();

        return Image.asset(
          asset,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
          centerSlice: slice,
          // A missing asset must degrade to something styled rather than to a
          // broken-image glyph sitting inside the layout.
          errorBuilder: (_, _, _) => fallback(),
        );
      },
    );
  }

}

/// A nine-sliced pixel panel that stretches to any size without smearing.
class PixelFrame extends StatelessWidget {
  const PixelFrame({
    super.key,
    required this.child,
    this.style = PixelFrameStyle.slate,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final Widget child;
  final PixelFrameStyle style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _NineSlice(
            asset: style.asset,
            slice: style.slice,
            source: style.source,
            fallbackColor: const Color(0xFF264F3D),
            fallbackBorder: const Color(0xFF0A1A12),
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    );
  }
}

/// A section heading drawn on a ribbon.
///
/// Cheapest big win in the kit. The same words in bold text read as a
/// settings screen; on a ribbon they read as a game. Only works stretched —
/// the caps stay fixed while the middle grows to fit the words, which is what
/// [AppAssets.kitSliceRibbon] pins.
class PixelRibbon extends StatelessWidget {
  const PixelRibbon({
    super.key,
    required this.label,
    this.asset = AppAssets.kitRibbonGreen,
    this.slice = AppAssets.kitSliceRibbonGreen,
    this.source = AppAssets.kitSizeRibbon,
    this.height = 46,
    this.textColor = const Color(0xFF10281F),
  });

  final String label;
  final String asset;

  /// Slice and source travel with the asset: the three big ribbons share a
  /// geometry, but the small ones do not, so a caller swapping the art has
  /// to swap these too.
  final Rect slice;
  final Size source;
  final double height;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: _NineSlice(
              asset: asset,
              slice: slice,
              source: source,
              fallbackColor: const Color(0xFF2C9C73),
              fallbackRadius: 999,
            ),
          ),
          Center(
            child: Padding(
              // The ribbon's swallow-tail ends are art, not padding — text
              // has to clear them or it sits on the notch.
              padding: EdgeInsets.symmetric(horizontal: height * 0.7),
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: height * 0.34,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colour of a [PixelButton].
enum PixelButtonTone {
  primary(
    AppAssets.kitBtnPrimary,
    AppAssets.kitSliceBtnPrimary,
    AppAssets.kitSizeBtnPrimary,
    AppAssets.kitBtnPrimaryPressed,
    AppAssets.kitSliceBtnPrimaryPressed,
    AppAssets.kitSizeBtnPrimaryPressed,
  ),
  danger(
    AppAssets.kitBtnDanger,
    AppAssets.kitSliceBtnDanger,
    AppAssets.kitSizeBtnDanger,
    AppAssets.kitBtnDangerPressed,
    AppAssets.kitSliceBtnDangerPressed,
    AppAssets.kitSizeBtnDangerPressed,
  );

  const PixelButtonTone(
    this.asset,
    this.slice,
    this.source,
    this.pressedAsset,
    this.pressedSlice,
    this.pressedSource,
  );

  final String asset;
  final Rect slice;
  final Size source;

  /// The pressed art is a *different size* from the resting art — the pack
  /// draws it lower in its cell — so it carries its own slice and extent
  /// rather than reusing the resting one.
  final String pressedAsset;
  final Rect pressedSlice;
  final Size pressedSource;
}

/// A chunky pixel button that actually depresses when you hold it.
///
/// The pressed state is a separate piece of art with its bevel inverted, not
/// a tint or an opacity change. That distinction matters: a colour shift says
/// "this changed", but only moving the light says "this went down".
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = PixelButtonTone.primary,
    this.icon,
    this.height = 52,
  });

  final String label;

  /// Null disables the button, which desaturates it rather than swapping art
  /// — the pack has no disabled face, and a greyed tint over the real bevel
  /// keeps the shape readable.
  final VoidCallback? onPressed;
  final PixelButtonTone tone;

  /// Optional kit icon path, drawn before the label.
  final String? icon;
  final double height;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = _down && enabled;
    final asset = pressed ? widget.tone.pressedAsset : widget.tone.asset;

    Widget face = _NineSlice(
      asset: asset,
      slice: pressed ? widget.tone.pressedSlice : widget.tone.slice,
      source: pressed ? widget.tone.pressedSource : widget.tone.source,
      fallbackColor: widget.tone == PixelButtonTone.danger
          ? const Color(0xFFFF8474)
          : const Color(0xFF4BD2A3),
      fallbackRadius: 10,
    );
    if (!enabled) {
      face = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0, 0, 0, 0.6, 0,
        ]),
        child: face,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(child: face),
              Padding(
                // Asymmetric: the art's bottom edge is a shadow, so a
                // geometrically centred label sits visibly low on the face.
                padding: EdgeInsets.fromLTRB(
                  widget.height * 0.3,
                  0,
                  widget.height * 0.3,
                  widget.height * 0.1,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        PixelKitIcon(widget.icon!, size: widget.height * 0.36),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            // Ink rather than white: these faces are bright,
                            // and white on bright green is the least readable
                            // pairing in the palette.
                            color: enabled
                                ? const Color(0xFF10281F)
                                : Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w900,
                            fontSize: widget.height * 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pixel progress bar: framed track, stretched fill, optional caption.
///
/// Built because Finance Brawl was *dropping* its "Debts Paid 3/12" line
/// whenever the panel got narrow, which is exactly the number telling the
/// player how far they are from the next upgrade. A bar is legible at any
/// width, so nothing has to be dropped to make room — and it answers "how
/// much further" at a glance, which the sentence never did.
class PixelProgressBar extends StatelessWidget {
  const PixelProgressBar({
    super.key,
    required this.value,
    this.height = 18,
    this.fillAsset = AppAssets.kitBarFillGreen,
    this.baseAsset = AppAssets.kitBarBase,
  });

  /// 0..1. Clamped, so a caller that divides by a zero total still renders.
  final double value;
  final double height;
  final String fillAsset;
  final String baseAsset;

  @override
  Widget build(BuildContext context) {
    final fraction = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The track art has an end cap at each side; the fill is inset so
          // it sits inside the frame instead of painting over the rim.
          final inset = height * 0.28;
          final trackWidth = (constraints.maxWidth - inset * 2).clamp(
            0.0,
            constraints.maxWidth,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: _NineSlice(
                  asset: baseAsset,
                  slice: AppAssets.kitSliceBarBase,
                  source: AppAssets.kitSizeBarBase,
                  fallbackColor: Colors.black.withValues(alpha: 0.35),
                  fallbackRadius: 999,
                ),
              ),
              Positioned(
                left: inset,
                top: height * 0.28,
                bottom: height * 0.28,
                child: SizedBox(
                  width: trackWidth * fraction,
                  child: ClipRect(
                    child: Image.asset(
                      fillAsset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4BD2A3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One kit icon, nearest-neighbour scaled.
///
/// Never tinted. The colour is painted into the art, so a coin is gold
/// everywhere it appears rather than taking whatever accent its host widget
/// happened to have — which is what made the old Material-glyph treatment
/// read as decoration instead of as a thing.
class PixelKitIcon extends StatelessWidget {
  const PixelKitIcon(this.asset, {super.key, this.size = 16});

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
