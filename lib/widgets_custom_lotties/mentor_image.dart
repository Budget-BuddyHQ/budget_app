import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_assets.dart';
import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/tutorial_steps.dart';

/// The guide turtle, wearing whatever the player has equipped.
///
/// # Why this widget exists
///
/// Asked for directly: *"make the turtle skins change it for the guides and
/// tutorials"*. The guide — the turtle who runs the tour, the coach marks and
/// the daily tip — was four hardcoded PNGs of the **classic** turtle. So a
/// player who had pulled Guild Runner, a 1-in-1,000 legendary, walked the
/// whole app as an orange turtle and was then taught by a green one. The skin
/// was visible everywhere except on the character who talks to you, which is
/// the one place a costume is actually looked at.
///
/// # Why a widget rather than a helper function
///
/// Four call sites, and two of them (the tour and the coach marks) can be
/// built before any account is in scope. Reading the controller in each of
/// them would be four chances to forget the fallback and crash the onboarding
/// flow — which is the worst screen in the app to crash, because it is the
/// first one.
class MentorImage extends StatelessWidget {
  const MentorImage({
    super.key,
    required this.pose,
    required this.size,
    this.errorBuilder,
    this.debugSkinId,
  });

  final TutorialMascot pose;
  final double size;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Bypasses the signed-in account. Tests only.
  final String? debugSkinId;

  /// The equipped skin, or the classic turtle when nothing is in scope.
  ///
  /// The tour can run before sign-in completes and the coach marks are
  /// inserted as overlays whose ancestry is not guaranteed to include the
  /// providers, so this must never be the thing that throws.
  static String equippedSkinOf(BuildContext context) {
    try {
      return context.watch<UserStatsController>().stats.equippedSkin;
    } on ProviderNotFoundException {
      return 'classic_turtle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final skinId = debugSkinId ?? equippedSkinOf(context);

    return Image.asset(
      pose.assetFor(skinId),
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      // A skin whose art is missing falls back to the classic pose rather
      // than to a broken-image icon: the generated sets are derived files,
      // and a build that skipped `tool/make_mentor_skins.py` should lose the
      // costume, not the guide.
      errorBuilder:
          errorBuilder ??
          (context, error, stack) => Image.asset(
            pose.asset,
            width: size,
            height: size,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
          ),
    );
  }
}

/// The same fallback rule for the places that need a path, not a widget.
String mentorAssetFor(BuildContext context, String pose) =>
    AppAssets.turtleMentorPose(pose, MentorImage.equippedSkinOf(context));
