import 'package:flutter/material.dart';

/// The sky behind a scene, chosen from the device clock.
///
/// **Why bother.** `assets/map_assets_coins/day-night-cycle/` has held
/// fourteen 1280x720 sky gradients — dawn through midnight — that nothing
/// referenced, while the app painted the same flat dark green at every hour.
/// Opening a game at eight in the morning and at eleven at night and seeing
/// an identical screen is a small thing that adds up: it is the difference
/// between a place and a menu.
///
/// It is also the cheapest personalisation there is. No account, no setting,
/// no data collected — the clock is already on the device, and a player who
/// only ever plays after dinner gets a dusk-coloured app without ever being
/// asked a question.
///
/// The art is used as a **backdrop, never as content**: it sits behind
/// everything at reduced opacity with a dark scrim over it, so the text on
/// top keeps the contrast the audit checks for regardless of which sky is
/// showing. A bright noon gradient at full strength would take a screenful of
/// carefully measured labels down with it.
class DayNightSky extends StatelessWidget {
  const DayNightSky({
    super.key,
    required this.child,
    this.now,
    this.opacity = 0.5,
    this.scrim = 0.55,
  });

  final Widget child;

  /// Injectable so tests can pin an hour instead of depending on when the
  /// suite happens to run.
  final DateTime? now;

  /// How strongly the sky reads. Deliberately below 1: see the class note.
  final double opacity;

  /// A dark wash over the sky, so foreground text keeps its contrast at
  /// noon as well as at midnight.
  final double scrim;

  static const int frameCount = 14;

  /// Which of the fourteen frames belongs to [hour].
  ///
  /// The sheet runs dawn → day → dusk → night → dawn, so the mapping is a
  /// simple proportional wrap: hour 0 lands mid-night, hour 12 lands mid-day.
  /// Offsetting by six is what puts noon at the *brightest* frame rather than
  /// at the start of the sequence.
  static int frameForHour(int hour) {
    final normalized = hour % 24;
    return ((normalized / 24 * frameCount).floor() + frameCount ~/ 2) %
        frameCount;
  }

  /// The asset path for [hour]. Frames are numbered from 1.
  static String assetForHour(int hour) =>
      'assets/map_assets_coins/day-night-cycle/'
      'Day_Night_cycle-${frameForHour(hour) + 1}.png';

  /// A word for the current sky, for a caption or a semantics label.
  static String labelForHour(int hour) {
    final h = hour % 24;
    if (h < 5) return 'Late night';
    if (h < 8) return 'Sunrise';
    if (h < 11) return 'Morning';
    if (h < 15) return 'Midday';
    if (h < 18) return 'Afternoon';
    if (h < 21) return 'Sunset';
    return 'Night';
  }

  @override
  Widget build(BuildContext context) {
    final hour = (now ?? DateTime.now()).hour;

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: opacity,
          child: Image.asset(
            assetForHour(hour),
            fit: BoxFit.cover,
            // A missing frame must degrade to the plain background rather
            // than to a broken-image glyph behind the whole screen.
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        // The scrim is not decoration — it is what keeps every measured text
        // colour on this screen valid no matter which sky is behind it.
        ColoredBox(color: Colors.black.withValues(alpha: scrim)),
        child,
      ],
    );
  }
}
