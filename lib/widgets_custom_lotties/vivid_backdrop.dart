import 'package:flutter/material.dart';

/// A background image that actually keeps its colour.
///
/// Most screens in this app used to paint their art and then bury it under
/// a ~0.6-alpha near-black wash, which is the cheapest way to keep text
/// readable and also the fastest way to turn detailed pixel art into one
/// flat block of dark green. This does the readability job the other way
/// round: it **boosts** the art (saturation + a small brightness lift, via
/// a real colour matrix — the same maths an image editor's "vibrance"
/// slider runs), then lays down a much lighter scrim plus a vignette that's
/// strongest at the edges and clears the middle. The result reads as a lit
/// scene rather than a dimmed one, and content still sits on enough
/// contrast to read.
class VividBackdrop extends StatelessWidget {
  const VividBackdrop({
    super.key,
    required this.image,
    this.saturation = 1.45,
    this.brightness = 0.04,
    this.scrimColor = const Color(0xFF0C2418),
    this.scrimOpacity = 0.28,
    this.vignetteOpacity = 0.55,
    this.glowColor,
    this.repeat = ImageRepeat.noRepeat,
    this.fit = BoxFit.cover,
  });

  final String image;

  /// 1.0 leaves colour untouched; above that pushes it. ~1.4-1.6 makes the
  /// pixel art read as vivid without tipping into neon.
  final double saturation;

  /// Flat lift added to every channel (0..1). Small values only — this is
  /// a lift, not an exposure control.
  final double brightness;

  final Color scrimColor;
  final double scrimOpacity;

  /// How dark the corners get. The centre always stays clear so the art
  /// shows through where the eye actually lands.
  final double vignetteOpacity;

  /// Optional accent bloom, so a screen can tint its own light.
  final Color? glowColor;

  final ImageRepeat repeat;
  final BoxFit fit;

  /// Standard luminance-preserving saturation matrix, with [brightness]
  /// folded into the translation column.
  List<double> get _matrix {
    const lumR = 0.213;
    const lumG = 0.715;
    const lumB = 0.072;
    final s = saturation;
    final b = brightness * 255.0;
    final invSatR = (1 - s) * lumR;
    final invSatG = (1 - s) * lumG;
    final invSatB = (1 - s) * lumB;
    return <double>[
      invSatR + s,
      invSatG,
      invSatB,
      0,
      b,
      invSatR,
      invSatG + s,
      invSatB,
      0,
      b,
      invSatR,
      invSatG,
      invSatB + s,
      0,
      b,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.matrix(_matrix),
          child: Image.asset(
            image,
            fit: repeat == ImageRepeat.repeat ? BoxFit.none : fit,
            repeat: repeat,
            // The art is pixel art — smoothing it turns crisp tiles to mush.
            filterQuality: FilterQuality.none,
          ),
        ),
        if (scrimOpacity > 0)
          Positioned.fill(
            child: ColoredBox(
              color: scrimColor.withValues(alpha: scrimOpacity),
            ),
          ),
        if (glowColor != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.55),
                  radius: 1.0,
                  colors: [
                    glowColor!.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        // Edge-weighted vignette: `stops` keeps the first ~55% fully clear
        // so the middle of the screen shows the boosted art at full
        // strength, and only the outer ring darkens for text contrast.
        if (vignetteOpacity > 0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    scrimColor.withValues(alpha: vignetteOpacity * 0.35),
                    scrimColor.withValues(alpha: vignetteOpacity),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
