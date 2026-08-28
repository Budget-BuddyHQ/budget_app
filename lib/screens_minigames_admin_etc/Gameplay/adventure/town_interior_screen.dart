import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/pixel_frame_animation.dart';
import '../../../widgets_custom_lotties/pixel_panel.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_scenarios.dart';

/// Inside a town building — a whole screen, with the room art as the room.
///
/// **What this replaces.** Walking into a shop used to open a modal bottom
/// sheet with a 96px-tall strip of interior art pasted across the top and
/// the decision underneath. It read as a menu with a picture on it. The
/// building was never a *place*; it was a dialog that happened to be
/// decorated.
///
/// So: a pushed route, the room art as the actual backdrop, and a
/// shopkeeper who is animated and reacts when you buy something. The
/// decision itself is unchanged — same prompt, same [TownChoice] list, same
/// return value — because the decision was never the problem.
///
/// Pops with the chosen [TownChoice], or with null if the player leaves.
class TownInteriorScreen extends StatefulWidget {
  const TownInteriorScreen({super.key, required this.spot});

  final TownSpot spot;

  @override
  State<TownInteriorScreen> createState() => _TownInteriorScreenState();
}

class _TownInteriorScreenState extends State<TownInteriorScreen> {
  /// Set while the shopkeeper plays the one-shot sale animation, so the
  /// purchase visibly *happens* before the screen closes. Without the beat,
  /// tapping a choice pops instantly and the animation is never seen.
  TownChoice? _confirming;

  bool get _hasCounter => widget.spot.kind == TownSpotKind.store;

  void _choose(TownChoice choice) {
    if (_confirming != null) return;
    if (!_hasCounter) {
      Navigator.of(context).pop(choice);
      return;
    }
    setState(() => _confirming = choice);
  }

  void _sellFinished() {
    final choice = _confirming;
    if (choice == null || !mounted) return;
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    return Scaffold(
      // The floor colour sampled out of the room art's bottom strip, so the
      // area below the backdrop reads as more floor rather than as the app
      // background showing through.
      backgroundColor: const Color(0xFF593F21),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _RoomBackdrop(spot: spot),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The Adventure map locks landscape, and this screen is
                // pushed on top of it, so landscape is the *common* case
                // here rather than the edge case. Side by side keeps the
                // room visible next to the decision instead of squashing
                // both into a short column.
                final wide =
                    constraints.maxWidth > constraints.maxHeight * 1.15;
                final stage = _InteriorStage(
                  spot: spot,
                  confirming: _confirming != null,
                  onSellFinished: _sellFinished,
                );
                final panel = _DecisionPanel(
                  spot: spot,
                  busy: _confirming != null,
                  onChoose: _choose,
                  onLeave: () => Navigator.of(context).pop(),
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: stage),
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(4, 12, 14, 14),
                          child: panel,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    // A third of the height for the room, never less than
                    // 150px — below that the stall is unreadable and the
                    // art is doing nothing for its space.
                    SizedBox(
                      height: (constraints.maxHeight * 0.34).clamp(
                        150.0,
                        260.0,
                      ),
                      child: stage,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                        child: panel,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _LeaveButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The room art, full bleed.
///
/// `fitWidth` + top alignment rather than `cover`: the source is 500x175, a
/// very wide, very short strip, and `cover` on a tall phone crops away
/// either the whole wall or the whole floor. Aligning it to the top and
/// letting the scaffold's floor colour continue underneath keeps all of it.
class _RoomBackdrop extends StatelessWidget {
  const _RoomBackdrop({required this.spot});

  final TownSpot spot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          spot.kind == TownSpotKind.home
              ? AppAssets.plainRoomBackground
              : AppAssets.shopRoomBackground,
          fit: BoxFit.fitWidth,
          width: double.infinity,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        // The floor runs to the bottom of the screen under a scrim, so the
        // decision panel sits on something dark enough to read against.
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF593F21),
                  AppTheme.deepForest.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The stall (or the building's character) standing in the room.
class _InteriorStage extends StatelessWidget {
  const _InteriorStage({
    required this.spot,
    required this.confirming,
    required this.onSellFinished,
  });

  final TownSpot spot;
  final bool confirming;
  final VoidCallback onSellFinished;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: spot.kind == TownSpotKind.store
                ? _ShopStall(
                    selling: confirming,
                    onSellFinished: onSellFinished,
                  )
                : _InteriorNpc(kind: spot.kind),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spot.kind.icon, color: spot.kind.accent, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: FittedLabel(
                  spot.title,
                  alignment: Alignment.center,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopStall extends StatelessWidget {
  const _ShopStall({required this.selling, required this.onSellFinished});

  final bool selling;
  final VoidCallback onSellFinished;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave room for the title strip along the bottom.
        final height = (constraints.maxHeight - 30).clamp(90.0, 220.0);
        final width =
            height *
            (AppAssets.shopStallWidth * AppAssets.shopStallCropFactor) /
            AppAssets.shopStallHeight;
        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: SizedBox(
            width: width,
            height: height,
            // Trims the sprite's leftover purple wall panel — see
            // [AppAssets.shopStallCropLeft]. Aligning right and shrinking
            // the width factor drops pixels off the *left* edge, which is
            // where the panel is.
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: AppAssets.shopStallCropFactor,
                child: PixelFrameAnimation(
                  key: ValueKey<bool>(selling),
                  frames: selling
                      ? AppAssets.shopSellFrames
                      : AppAssets.shopIdleFrames,
                  loop: !selling,
                  frameDuration: Duration(milliseconds: selling ? 70 : 200),
                  onComplete: selling ? onSellFinished : null,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Every other building gets the character who works there, idling.
class _InteriorNpc extends StatelessWidget {
  const _InteriorNpc({required this.kind});

  final TownSpotKind kind;

  static List<String> _framesFor(TownSpotKind kind) => switch (kind) {
    // The bank teller and the tax office share the one suited character —
    // he is the only "person behind a desk" sprite in the set.
    TownSpotKind.bank => AppAssets.taxerIdleFrames,
    TownSpotKind.job => AppAssets.workerIdleFrames,
    TownSpotKind.school => AppAssets.fancyIdleFrames,
    _ => AppAssets.customerIdleFrames,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxHeight - 40).clamp(70.0, 170.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: PixelFrameAnimation(
            frames: _framesFor(kind),
            frameDuration: const Duration(milliseconds: 240),
            height: height,
            width: height * AppAssets.npcAspectRatio,
            fit: BoxFit.fitHeight,
          ),
        );
      },
    );
  }
}

/// The prompt and the choices — the part that was already right.
class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({
    required this.spot,
    required this.busy,
    required this.onChoose,
    required this.onLeave,
  });

  final TownSpot spot;
  final bool busy;
  final ValueChanged<TownChoice> onChoose;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    // Today's encounter, not the spot's built-in one. Each building has
    // several scenes and rotates them daily — see [townEncounterFor] for why
    // the choice is fixed within a day rather than rerolled on every visit.
    final encounter = townEncounterFor(spot);

    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            encounter.prompt,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              height: 1.45,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (final choice in encounter.choices) ...[
            _ChoiceRow(
              choice: choice,
              accent: spot.kind.accent,
              // Disabled while the sale animation plays, so a second tap
              // cannot queue a second purchase behind the first.
              onTap: busy ? null : () => onChoose(choice),
            ),
            const SizedBox(height: 9),
          ],
          Center(
            child: TextButton(
              onPressed: busy ? null : onLeave,
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
              child: Text(
                'Leave',
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.choice,
    required this.accent,
    required this.onTap,
  });

  final TownChoice choice;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final costs = choice.gold < 0;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    choice.label,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (choice.gold != 0) ...[
                  const SizedBox(width: 10),
                  // The price is on the label anyway in most of these
                  // prompts ("Buy the $4 bag"), so showing it here is a
                  // reminder rather than a spoiler — and it makes the
                  // *comparison* between options a glance instead of a
                  // read, which is the whole unit-price lesson.
                  Text(
                    '${costs ? '' : '+'}${choice.gold}',
                    style: GoogleFonts.pixelifySans(
                      color: costs ? const Color(0xFFFF8FB1) : accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveButton extends StatelessWidget {
  const _LeaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
