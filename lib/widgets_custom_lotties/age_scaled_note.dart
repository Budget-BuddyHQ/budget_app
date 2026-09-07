import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../themes_colors/app_theme.dart';

/// One line saying that what is on screen is matched to the player's age.
///
/// # Why this widget exists
///
/// Reported as *"I'm still not seeing the age separated for the app"*, which
/// was fair. The age system had grown to cover a great deal — quiz reading
/// levels, the Finance Brawl question bank, life-sim vocabulary, wagering,
/// randomised rewards, Leak Patrol's speed — and it was **stated to the
/// player in five places**, four of which were inside the Academy. The one
/// clear sentence lived on the sign-up screen and was never repeated.
///
/// So the app was doing a large amount of work that nobody could see. Age
/// scaling that is invisible is indistinguishable from age scaling that does
/// not exist, and it is one of the strongest things about this app.
///
/// # Why one widget rather than a line per screen
///
/// Copy written five separate times drifts five separate ways, and this
/// sentence has to stay true as the gating grows. One widget, one string per
/// band, and every surface that filters content shows the same thing.
///
/// # Why it is quiet
///
/// It is a note, not a banner. A player who has read it once should be able
/// to stop seeing it, which small muted text achieves without any dismissal
/// logic to remember or get wrong.
class AgeScaledNote extends StatelessWidget {
  const AgeScaledNote({
    super.key,
    required this.what,
    this.margin = EdgeInsets.zero,
    this.debugBand,
  });

  /// What is being scaled, in the player's words — "questions", "prices",
  /// "the speed". Reads as "Questions matched to your age."
  final String what;

  final EdgeInsets margin;

  /// Bypasses the signed-in account. Tests only.
  final AgeBand? debugBand;

  @override
  Widget build(BuildContext context) {
    final band =
        debugBand ?? context.watch<UserStatsController>().stats.ageBand;

    return Padding(
      padding: margin,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tune_rounded,
            size: 13,
            color: AppTheme.textMuted.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              band == AgeBand.undisclosed
                  // Says what to do about it, since this is the one band
                  // where the app is guessing rather than knowing.
                  ? '$what set to a general mix — set your age in Profile to '
                        'sharpen it.'
                  : '$what matched to your age (${band.label}).',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
