import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../themes_colors/app_theme.dart';

/// The village map behind a screen, at a strength matched to what sits on it.
///
/// **Why one widget instead of four `Positioned.fill`s.** Seven screens
/// paint this map behind their stuff, each with its own scrim, and the alphas
/// had drifted to 0.55, 0.74, 0.78 and 0.82 with nothing anywhere saying why.
/// two of those screens put body text straight on top of the result.
///
/// **What was actually wrong with the reading screens.** Measured against the
/// real asset, the 0.74 scrim was fine on paper: white text over the
/// *brightest* pixel in the map came out at 4.53:1, clearing WCAG AA. It still
/// read badly, and the numbers say why — under that scrim the backdrop ranged
/// from 4.53:1 to 12.4:1 depending on which tile a letter happened to land on,
/// and the map's detail sits at about the scale of a letterform. A contrast
/// ratio describes one pixel against one background. It cannot describe a
/// background that changes underneath a word.
///
/// So [MapBackdropStyle.reading] uses a pre-blurred copy of the same map
/// (`tool/make_reading_backdrop.py`) instead of just a darker scrim. blur
/// squashes that 7.9 point spread down to 2.2 with a floor of 6.5:1. doing it
/// at build time instead of `ImageFiltered` = free at runtime, its a static
/// image sat behind a scrolling list, no reason to refilter it 60x a second
/// Which of the two town maps is behind the screen.
///
/// The app had one backdrop on every surface, on every launch, forever, and
/// a background you have seen four hundred times stops being scenery and
/// starts being wallpaper. There is a second town map in the repo that was
/// drawn to be *played* and could not be — its collision data was never in
/// the PNG, and three separate heuristics all read the main promenade as
/// solid, which cuts the town in half. A backdrop needs no colliders.
enum MapVariant {
  village(AppAssets.villageMapBackground, AppAssets.villageMapBackgroundSoft),
  market(
    AppAssets.villageMapTwoBackground,
    AppAssets.villageMapTwoBackgroundSoft,
  );

  const MapVariant(this.sharp, this.soft);

  final String sharp;
  final String soft;

  /// The variant for this launch.
  ///
  /// **Rolled once per app run, not per build.** A `Random()` call inside
  /// `build` would re-roll on every rebuild — every setState, every tab
  /// switch, every scroll that crosses a repaint boundary — and the backdrop
  /// would flicker between two towns. Holding it for the session also means
  /// the whole app agrees with itself: you do not walk from a Learn screen in
  /// one town into a Play screen in another.
  static final MapVariant session =
      MapVariant.values[Random().nextInt(MapVariant.values.length)];

  /// Overrides the session roll. Tests and screenshots need a backdrop they
  /// can predict; without this, a golden that renders the map is a coin flip.
  @visibleForTesting
  static MapVariant? debugOverride;

  static MapVariant get current => debugOverride ?? session;
}

enum MapBackdropStyle {
  /// For screens whose content sits in its own opaque cards: the map is
  /// decoration and can be seen properly.
  decorative(0.62),

  /// For screens with body text laid directly on the backdrop — the lesson,
  /// the quiz, the practice run.
  reading(0.84),

  /// For the welcome screen, where the map is the first thing anybody sees
  /// and blurring it away would be throwing out the app's whole first
  /// impression.
  ///
  /// So the art stays sharp and bright at the top, and a gradient deepens
  /// toward the bottom third, where the wordmark and the two buttons live.
  /// Before this, "Welcome Back" sat on pale water tiles at the exact point
  /// the screen's own radial glow was *lightening* the background — the one
  /// label on the launch screen that a returning player has to find.
  hero(0.42);

  const MapBackdropStyle(this.scrim);

  final double scrim;

  /// Reading wants the pre-blurred copy; the other two want the art sharp.
  String assetFor(MapVariant variant) =>
      this == MapBackdropStyle.reading ? variant.soft : variant.sharp;
}

class MapBackdrop extends StatelessWidget {
  const MapBackdrop({
    super.key,
    this.style = MapBackdropStyle.decorative,
    this.variant,
  });

  final MapBackdropStyle style;

  /// Which town. Defaults to the one rolled for this launch.
  final MapVariant? variant;

  @override
  Widget build(BuildContext context) {
    final town = variant ?? MapVariant.current;
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            style.assetFor(town),
            fit: BoxFit.cover,
            // `none` on the sharp copy so the pixel art stays pixel art. The
            // soft copy is already blurred, so its filtering is moot.
            filterQuality: FilterQuality.none,
          ),
          ColoredBox(color: AppTheme.panel.withValues(alpha: style.scrim)),
          if (style == MapBackdropStyle.hero)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Full strength by the halfway mark and held from there,
                  // rather than peaking at the very edge. The wordmark sits at
                  // about 50% of the height and the first button at 61%, and
                  // the busiest part of the map — a block of pale water tiles
                  // — is directly behind both. The top fifth stays untouched,
                  // which is the part that is actually doing the work of
                  // saying "this is a game".
                  stops: <double>[0.0, 0.18, 0.46, 1.0],
                  colors: <Color>[
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xD9102A1E),
                    Color(0xD9102A1E),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
