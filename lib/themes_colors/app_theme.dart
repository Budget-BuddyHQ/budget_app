import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  //
  // **Slate surfaces, a few bold colours with one job each.** The app used to
  // be dark green everywhere: green cards on green pages over green art, with
  // mint and teal accents. Testers called that "looks AI", and the reference
  // the user pointed at — Prodigy, and game apps like Duolingo — does the
  // opposite: neutral slate surfaces with clear outlines, and saturated
  // colours that each mean something (green to act, gold for money, blue for
  // information, red for losses). The backgrounds (reef, village map) stay
  // green; the UI on top of them no longer is.
  //
  // The names are kept so the ~400 call sites did not churn; read
  // `deepForest` as "page" and `panel` as "card".
  static const Color deepForest = Color(0xFF131F24); // page
  static const Color darkForest = Color(0xFF1A2830); // page, raised
  static const Color limeAccent = Color(0xFFB8F28C);
  static const Color greenPrimary = Color(0xFF6CD34A); // act
  static const Color lightGreen = Color(0xFFEFF9E8);
  static const Color teal = Color(0xFF1CB0F6); // information
  static const Color successGreen = Color(0xFF46A302);
  static const Color warningOrange = Color(0xFFFFC800); // money, attention
  static const Color errorRed = Color(0xFFFF6B6B); // loss
  static const Color panel = Color(0xFF202F36); // card
  static const Color panelStrong = Color(0xFF2A3C45); // raised card

  /// The 2px outline game apps put around cards and buttons. A visible edge
  /// is what makes a flat surface read as an object instead of a smudge.
  static const Color outline = Color(0xFF37464F);

  /// Inside a card: a chart well, an inset field.
  static const Color inset = Color(0xFF18252B);

  static const Color textPrimary = Color(0xFFF1F7FB);
  // Every secondary label uses this, on cards up to [panelStrong] and on
  // accent-tinted cards, so it is kept light: 7.6:1 on [panel].
  static const Color textMuted = Color(0xFFB3C4CD);

  // Spacing constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;
  static const double spacingXXLarge = 32.0;

  // border radius. bumped rounder for the puffy / bubbled up look
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;

  /// The typeface for anything containing a **numeral**.
  ///
  /// **Never Pixelify Sans.** Measured with
  /// `tool/check_digit_legibility.py`: at 22px, **18 of the 45 digit pairs in
  /// Pixelify Sans differ in under 18% of their inked pixels**, and 8/9
  /// differ in under 4%. Its 5 and 6 have closed top counters, so rows 3-9 of
  /// those glyphs are pixel-identical to the 8's.
  ///
  /// That is not a matter of taste. A tester was shown *"you get \$1 each
  /// time, after 5 days, how much have you earned?"*, read the 5 as an 8,
  /// looked for \$8, and found options of \$1 / \$3 / \$5 / \$10 — no answer
  /// to the question in front of them. In an app whose entire subject is
  /// arithmetic about money, the font was corrupting the operand.
  ///
  /// Quicksand scores **0 of 45** confusable pairs on the same measurement,
  /// with its worst pair eight times clearer than Pixelify's worst. It is
  /// already bundled and already the body face, so this costs nothing.
  ///
  /// Pixelify stays for wordmarks, titles and labels **without digits** —
  /// it is the app's identity and there is nothing wrong with it there.
  /// `test/digit_legibility_test.dart` holds this line.
  static TextStyle numeric({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.quicksand(
    color: color,
    fontSize: fontSize,
    // Quicksand runs visually lighter than Pixelify at the same weight, so
    // number-carrying text asked for w700 keeps its emphasis rather than
    // quietly receding when it changes face.
    fontWeight: fontWeight ?? FontWeight.w700,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// The typeface for anything set in **ALL CAPS**.
  ///
  /// **Never Pixelify Sans.** Reported as *"that E is pretty hard to read"*,
  /// and the obvious guess — that the pixel face's small lowercase was at
  /// fault — was wrong. Measured with
  /// `tool/check_digit_legibility.py --chars ABC...`:
  ///
  /// | face                  | confusable pairs of 325 |
  /// |-----------------------|-------------------------|
  /// | Pixelify lowercase    | 3                       |
  /// | Pixelify **CAPITALS** | 10–23, at every size    |
  /// | Quicksand lowercase   | 2                       |
  /// | Quicksand **CAPITALS**| 0–1                     |
  ///
  /// Three of Pixelify's confusable capital pairs contain an E — **E/S, B/E
  /// and E/G** — so the reader named the right letter. The first idea was to
  /// set headings in caps to dodge the small lowercase; the measurement says
  /// that would have made it measurably worse.
  ///
  /// It is not a size problem either. The capitals score badly at 12px and at
  /// 30px alike, because they share skeletons rather than lose detail.
  ///
  /// **Pixelify stays for mixed-case titles** — "Play", "Play Life", the
  /// wordmark — which is every place the app is recognized by it, and where
  /// it measures fine. This is only for the shouty labels: badges, section
  /// headers, chips. `test/caps_legibility_test.dart` holds the line.
  ///
  /// The default tracking is deliberate: caps set tight read as a block, and
  /// this face has no pixel-grid rhythm to carry them.
  static TextStyle caps({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.quicksand(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w800,
    height: height,
    letterSpacing: letterSpacing ?? 0.8,
  );
  static const double radiusXLarge = 32.0;

  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 32.0;

  // Shadows
  static final List<BoxShadow> elevationSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> elevationMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> elevationLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// The color a ledge is cut from: [accent] pushed most of the way to the
  /// page's darkest green, so a mint card sits on a dark mint ledge rather
  /// than on grey.
  static Color ledgeColor(Color accent) =>
      Color.lerp(accent, const Color(0xFF0B1418), 0.72)!;

  /// A hard ledge under a card or button: no blur, straight down.
  ///
  /// **Reported as** *"it looks too AI."* This used to be a soft glow in the
  /// card's own color, 28px of blur pulled in under the edges, on almost
  /// every card in the app. A colored halo around every rounded rectangle is
  /// the house style of generated UI, and next to pixel art it reads as two
  /// different apps. A ledge is how the art itself draws depth — the same
  /// dark step under a sign or a crate in the town — so the panels now look
  /// like they belong to the game.
  ///
  /// [restAlpha] still means "how much is this raised", so a hover or a
  /// selected state can ask for more and get a darker ledge. [depth] is in
  /// logical pixels.
  static List<BoxShadow> ledgeShadow(
    Color accent, {
    double restAlpha = 0.22,
    double depth = 4,
  }) {
    return [
      BoxShadow(
        color: ledgeColor(
          accent,
        ).withValues(alpha: (0.6 + restAlpha).clamp(0.0, 1.0)),
        offset: Offset(0, depth),
      ),
    ];
  }

  /// A gradient that steps instead of fading: [colors] are flat bands, and
  /// [edges] (one fewer than [colors], ascending, 0..1) are where one band
  /// stops and the next starts, with nothing blended in between.
  ///
  /// For the places that genuinely need a shade to change across a
  /// surface (water getting deeper, a scrim behind text) without the smooth
  /// fade that a tester called "too AI". Pixel art shades in bands, so this
  /// sits next to it rather than on top of it.
  static LinearGradient steppedGradient({
    required List<Color> colors,
    required List<double> edges,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    assert(edges.length == colors.length - 1);
    final out = <Color>[];
    final stops = <double>[];
    for (var i = 0; i < colors.length; i++) {
      // Each band is the same color at both of its ends, so the shader has
      // nothing to interpolate inside it, and the edge between two bands is
      // two stops at the same position.
      out
        ..add(colors[i])
        ..add(colors[i]);
      stops
        ..add(i == 0 ? 0 : edges[i - 1])
        ..add(i == colors.length - 1 ? 1 : edges[i]);
    }
    return LinearGradient(begin: begin, end: end, colors: out, stops: stops);
  }

  /// [count] flat bands evenly spaced between [from] and [to], for
  /// [steppedGradient].
  static List<Color> bands(Color from, Color to, int count) => [
    for (var i = 0; i < count; i++)
      Color.lerp(from, to, count == 1 ? 0 : i / (count - 1))!,
  ];

  // Material Theme
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: greenPrimary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: deepForest,
      cardColor: panel,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pixelifySans(
          color: textPrimary,
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      textTheme:
          GoogleFonts.pixelifySansTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.pixelifySans(
              color: textPrimary,
              fontSize: fontSizeXXLarge,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            displayMedium: GoogleFonts.pixelifySans(
              color: textPrimary,
              fontSize: fontSizeXLarge,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            headlineSmall: GoogleFonts.pixelifySans(
              color: textPrimary,
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            bodyLarge: GoogleFonts.quicksand(
              color: textPrimary,
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            bodyMedium: GoogleFonts.quicksand(
              color: textMuted,
              fontSize: fontSizeBase,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.2,
            ),
            bodySmall: GoogleFonts.quicksand(
              color: textMuted,
              fontSize: fontSizeSmall,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: greenPrimary,
          foregroundColor: deepForest,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXLarge,
            vertical: spacingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          elevation: 8,
          shadowColor: greenPrimary.withValues(alpha: 0.35),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: limeAccent,
          side: BorderSide(
            color: limeAccent.withValues(alpha: 0.70),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXLarge,
            vertical: spacingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: teal,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelStrong,
        selectedColor: greenPrimary,
        secondarySelectedColor: greenPrimary,
        disabledColor: panel,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: deepForest,
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelStrong,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: greenPrimary.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: greenPrimary.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: fontSizeBase,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: textMuted.withValues(alpha: 0.68),
          fontSize: fontSizeBase,
        ),
        errorStyle: const TextStyle(color: errorRed, fontSize: fontSizeSmall),
      ),
    );
  }

  // glass morphism helper thing
  static BoxDecoration getGlassDecoration({
    Color borderColor = Colors.white,
    double borderWidth = 1,
    double borderOpacity = 0.2,
    double bgOpacity = 0.1,
    double borderRadius = radiusLarge,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: bgOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor.withValues(alpha: borderOpacity),
        width: borderWidth,
      ),
    );
  }

  /// The app's shared card look: a solid fill, a border in the card's accent
  /// and a hard ledge under it (see [ledgeShadow]).
  static BoxDecoration getPuffyDecoration({
    required Color accent,
    Color? fillColor,
    double borderRadius = radiusXLarge,
    double borderOpacity = 0.16,
    double restAlpha = 0.22,
  }) {
    return BoxDecoration(
      color: fillColor ?? panelStrong,
      borderRadius: BorderRadius.circular(borderRadius),
      // A real outline: the slate edge with a little of the card's accent in
      // it, at 2px like the game apps this follows.
      border: Border.all(
        color: Color.lerp(outline, accent, 0.25 + borderOpacity)!,
        width: 2,
      ),
      boxShadow: ledgeShadow(accent, restAlpha: restAlpha),
    );
  }

  // --------------------------------------------------------------------
  // Legibility
  // --------------------------------------------------------------------

  /// Relative luminance, per WCAG 2.1.
  static double luminance(Color c) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  /// The WCAG contrast ratio between two opaque colors, 1.0 to 21.0.
  static double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Flattens [fg] onto an opaque [bg] — what the eye actually receives.
  ///
  /// **Rounded to whole 8-bit channels**, because that is what a screen can
  /// paint. It used to return the exact floating-point blend, and
  /// [legibleOn] would then prove a label against a color no pixel ever
  /// shows. That only matters at the threshold, which is exactly where the
  /// walk stops: the Pink Dream skin's rarity letter cleared its chip at
  /// 4.500:1 against the float fill (63.62, 62.72, 55.54), and measured
  /// 4.478:1 against the fill actually painted, (64, 63, 56) — an AA failure
  /// produced entirely by rounding, in a helper whose job is preventing them.
  static Color flatten(Color fg, Color bg) {
    final a = fg.a;
    if (a >= 1.0) return fg;
    int channel(double f, double b) =>
        ((f * a + b * (1 - a)) * 255).round().clamp(0, 255);
    return Color.fromARGB(
      255,
      channel(fg.r, bg.r),
      channel(fg.g, bg.g),
      channel(fg.b, bg.b),
    );
  }

  /// [tint] shifted just far enough in lightness to be readable on [surface].
  ///
  /// **Why this is a function and not a lookup table.** The app colors
  /// hundreds of small chips by *meaning* — a category's color, a rarity's
  /// color, a stat's color — and then writes the label in that same color
  /// over a translucent wash of it. That reads beautifully when the tint is
  /// bright and becomes unreadable when it is not, and which is which depends
  /// on a color chosen somewhere else entirely. Hardcoding a legible variant
  /// beside every tint means the two drift apart the first time one changes.
  ///
  /// So: keep the hue and saturation, walk the lightness away from the
  /// surface until the contrast target is met, and give up gracefully at the
  /// ends of the ramp rather than looping.
  ///
  /// [target] defaults to WCAG AA for body text. Pass 3.0 for large or bold
  /// text, which is the standard's own allowance.
  static Color legibleOn(Color tint, Color surface, {double target = 4.5}) {
    final flat = flatten(tint, surface);
    if (contrast(flat, surface) >= target) return tint;

    final hsl = HSLColor.fromColor(flat);

    // Walk both ways and take whichever reaches the target with the *smaller*
    // change, so the result stays as close to the designer's color as the
    // target allows.
    //
    // Trying only one direction was the first version's mistake. It picked
    // the direction from the surface's own luminance, which is right for a
    // clearly dark or clearly light ground and wrong for the mid-tones this
    // app is full of — an accent badge is a wash of its own accent, so it
    // lands mid, and a mint icon on it got *darkened* to near-black. That is
    // both ugly and, at 2.75:1, still a failure.
    Color? walk(int direction) {
      for (var step = 1; step <= 25; step++) {
        final l = (hsl.lightness + direction * step * 0.04).clamp(0.0, 1.0);
        final candidate = hsl.withLightness(l).toColor();
        if (contrast(candidate, surface) >= target) return candidate;
        if (l == 0.0 || l == 1.0) return null;
      }
      return null;
    }

    final lighter = walk(1);
    final darker = walk(-1);
    if (lighter != null && darker != null) {
      final upBy = (HSLColor.fromColor(lighter).lightness - hsl.lightness)
          .abs();
      final downBy = (HSLColor.fromColor(darker).lightness - hsl.lightness)
          .abs();
      return upBy <= downBy ? lighter : darker;
    }
    if (lighter != null) return lighter;
    if (darker != null) return darker;

    // Neither ramp reaches the target — this hue cannot make it against this
    // surface. Return the end that gets furthest rather than the original: it
    // is the most legible this color gets, and still recognizably itself.
    final white = hsl.withLightness(1.0).toColor();
    final black = hsl.withLightness(0.0).toColor();
    return contrast(white, surface) >= contrast(black, surface) ? white : black;
  }

  /// A tinted chip: the fill and the label color, together.
  ///
  /// The app's most common small component is a wash of some meaningful
  /// color with the label written in that same color — rarity badges,
  /// difficulty pills, stat meters, category tags. It is also where nearly
  /// every legibility failure came from, for two compounding reasons:
  ///
  /// 1. The wash raises the background *towards* the label, so the darker the
  ///    tint the closer the two get. A deep-blue legendary badge measured
  ///    **1.04:1** — a badge with no letter on it. At the call site both
  ///    colors are the same identifier, so nothing looks wrong.
  /// 2. The wash is translucent, so what the label actually sits on depends
  ///    on whatever is behind the chip — which the call site cannot know and
  ///    which changes when the chip is reused somewhere else.
  ///
  /// Returning both fixes both. The fill comes back **opaque**, pre-blended
  /// over [on], so the chip looks identical on the usual dark surface but no
  /// longer inherits whatever is underneath it; and the ink is measured
  /// against that exact fill. Use them as a pair — taking one and inventing
  /// the other is the bug this exists to prevent.
  ///
  /// ```dart
  /// final chip = AppTheme.tintedChip(rarity.color);
  /// Container(
  ///   decoration: BoxDecoration(color: chip.fill, ...),
  ///   child: Text(label, style: TextStyle(color: chip.ink)),
  /// )
  /// ```
  static ({Color fill, Color ink}) tintedChip(
    Color tint, {
    double alpha = 0.18,
    Color on = deepForest,
    double target = 4.5,
  }) {
    final fill = flatten(tint.withValues(alpha: alpha), on);
    return (fill: fill, ink: legibleOn(tint, fill, target: target));
  }
}
