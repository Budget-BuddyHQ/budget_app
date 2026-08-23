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
        titleTextStyle: GoogleFonts.baloo2(
          color: textPrimary,
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      textTheme:
          GoogleFonts.baloo2TextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.baloo2(
              color: textPrimary,
              fontSize: fontSizeXXLarge,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            displayMedium: GoogleFonts.baloo2(
              color: textPrimary,
              fontSize: fontSizeXLarge,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            headlineSmall: GoogleFonts.baloo2(
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
}
