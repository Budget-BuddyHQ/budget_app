import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  // Bumped lighter/warmer than the original near-black values (twice now,
  // per direct feedback the first pass still read too dark) so the app
  // reads as a lit night scene rather than a cave — still a dark forest
  // theme, not a light-mode swap.
  static const Color deepForest = Color(0xFF0F2E20);
  static const Color darkForest = Color(0xFF1B4633);
  static const Color limeAccent = Color(0xFFB7F7D7);
  static const Color greenPrimary = Color(0xFF4BD2A3);
  static const Color lightGreen = Color(0xFFEAFBF4);
  static const Color teal = Color(0xFF69C6FF);
  static const Color successGreen = Color(0xFF2C9C73);
  static const Color warningOrange = Color(0xFFF2C66D);
  static const Color errorRed = Color(0xFFFF8474);
  static const Color panel = Color(0xFF264F3D);
  static const Color panelStrong = Color(0xFF335D48);
  static const Color textPrimary = Color(0xFFF7FFFB);
  static const Color textMuted = Color(0xFFB9D1C6);

  // Spacing constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;
  static const double spacingXXLarge = 32.0;

  // Border radius — bumped rounder for the "puffy"/bubbled-up look.
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;
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

  /// A soft, colour-tinted "puffy" glow — used instead of flat black shadows
  /// to make cards/buttons read as raised and bubbled-up rather than flat.
  /// Always visible at [restAlpha] (so touch devices, which never hover,
  /// still see it) and can be intensified for a hover/press state.
  static List<BoxShadow> puffyShadow(
    Color accent, {
    double restAlpha = 0.22,
    double blurRadius = 28,
    double spreadRadius = -6,
    Offset offset = const Offset(0, 12),
  }) {
    return [
      BoxShadow(
        color: accent.withValues(alpha: restAlpha),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  // Gradients
  static const LinearGradient gradientForest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepForest, Color(0xFF0C211A), Color(0xFF16392D)],
  );

  static const LinearGradient gradientGreen = LinearGradient(
    colors: [Color(0xFF7BE1BB), greenPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientTeal = LinearGradient(
    colors: [teal, Color(0xFF7BE1BB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

  // Helper for glass morphism effect
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

  /// The app's shared "puffy" card look: a rounded fill with a soft
  /// colour-tinted glow and a faint highlight border, instead of a flat
  /// panel with a hard black shadow.
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
      border: Border.all(
        color: accent.withValues(alpha: borderOpacity),
        width: 1.5,
      ),
      boxShadow: puffyShadow(accent, restAlpha: restAlpha),
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

  /// The WCAG contrast ratio between two opaque colours, 1.0 to 21.0.
  static double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Flattens [fg] onto an opaque [bg] — what the eye actually receives.
  static Color flatten(Color fg, Color bg) {
    final a = fg.a;
    if (a >= 1.0) return fg;
    return Color.from(
      alpha: 1.0,
      red: fg.r * a + bg.r * (1 - a),
      green: fg.g * a + bg.g * (1 - a),
      blue: fg.b * a + bg.b * (1 - a),
    );
  }

  /// [tint] shifted just far enough in lightness to be readable on [surface].
  ///
  /// **Why this is a function and not a lookup table.** The app colours
  /// hundreds of small chips by *meaning* — a category's colour, a rarity's
  /// colour, a stat's colour — and then writes the label in that same colour
  /// over a translucent wash of it. That reads beautifully when the tint is
  /// bright and becomes unreadable when it is not, and which is which depends
  /// on a colour chosen somewhere else entirely. Hardcoding a legible variant
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
    // Move away from the surface: lighten a tint on a dark ground, darken one
    // on a light ground. Going the other way would reach the target too, but
    // by inverting the design's light/dark intent.
    final lighten = luminance(surface) < 0.18;

    var best = flat;
    for (var step = 1; step <= 24; step++) {
      final l = lighten
          ? (hsl.lightness + step * 0.04).clamp(0.0, 1.0)
          : (hsl.lightness - step * 0.04).clamp(0.0, 1.0);
      final candidate = hsl.withLightness(l).toColor();
      best = candidate;
      if (contrast(candidate, surface) >= target) return candidate;
      if (l == 0.0 || l == 1.0) break;
    }
    // The ramp ran out — this hue cannot make the target against this
    // surface. Return the far end rather than the original: it is the most
    // legible this colour gets, and it is still recognisably itself.
    return best;
  }

  /// A tinted chip: the fill and the label colour, together.
  ///
  /// The app's most common small component is a wash of some meaningful
  /// colour with the label written in that same colour — rarity badges,
  /// difficulty pills, stat meters, category tags. It is also where nearly
  /// every legibility failure came from, for two compounding reasons:
  ///
  /// 1. The wash raises the background *towards* the label, so the darker the
  ///    tint the closer the two get. A deep-blue legendary badge measured
  ///    **1.04:1** — a badge with no letter on it. At the call site both
  ///    colours are the same identifier, so nothing looks wrong.
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
