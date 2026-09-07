import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_conditions.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/pixel_frame_animation.dart';
import '../../../widgets_custom_lotties/pixel_panel.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_challenges.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/pixel_kit.dart';
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
  const TownInteriorScreen({
    super.key,
    required this.spot,
    this.lifeAge,
    this.today,
    this.settled = false,
  });

  final TownSpot spot;

  /// Whether this exact encounter has already paid out.
  ///
  /// The decision is still offered — reading it and choosing *is* the lesson,
  /// and a locked door teaches nothing. What is withheld is the money, and
  /// this is what lets the screen say so **before** the choice rather than
  /// after it. Being quietly paid nothing is how a game loses trust; being
  /// told "you already settled this, come back tomorrow" is a rule.
  ///
  /// Computed by the caller, which owns the saved ledger. It has to be
  /// derived from the same `townEncounterFor(spot, lifeAge:, conditionId:)`
  /// this screen calls below, or the two will disagree about which
  /// conversation is on.
  final bool settled;

  /// The character's age, when this was entered from a run.
  ///
  /// Null when the town is being wandered on its own, in which case the
  /// building rotates on the calendar day alone. See [townEncounterFor].
  final int? lifeAge;

  /// What the town is like today, or null when nothing is passing one in
  /// (the interior is also reachable from tests and from the map-pending
  /// screen). Only used to print a line — the *prices* are applied by the
  /// caller, which is the only place that knows the player's balance.
  final TownCondition? today;

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
      // floor colour sampled straight out of the room art's bottom strip so
      // the area under the backdrop reads as more floor and not as the app
      // background leaking through
      backgroundColor: const Color(0xFF593F21),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _RoomBackdrop(spot: spot),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // the Adventure map locks landscape and this screen gets
                // pushed on top of it, so landscape is the *normal* case
                // here, not the edge case. side by side keeps the room
                // visible next to the decision instead of squashing them
                // both into one short column
                final wide =
                    constraints.maxWidth > constraints.maxHeight * 1.15;
                final stage = _InteriorStage(
                  spot: spot,
                  confirming: _confirming != null,
                  onSellFinished: _sellFinished,
                );
                // A puzzle where there is one, the conversation otherwise.
                //
                // **Why the challenge replaces the dialogue rather than
                // sitting beside it.** Reported as: the library offers "book
                // the room / go to the cafe / work at home", and the Life
                // menu already has a "Visit the library" row doing the same
                // job — so the map was a second menu with a longer walk. Two
                // panels would have made that worse, not better. The
                // buildings that can pose a real question now pose one, and
                // the menu keeps the plain version.
                //
                // The park and your own house keep the conversation on
                // purpose: they are places to *be*, and arithmetic in them
                // would turn the whole town into a worksheet.
                // Seeded from the day's condition rather than a date.
                //
                // `today` is a `TownCondition` — the weather-and-economy
                // state, which already rotates once per in-game day. Using it
                // means the puzzle changes exactly when everything else about
                // the town changes, so one walk through the town is one
                // consistent day rather than a set of independently shuffling
                // parts.
                final challenge = townChallengeFor(
                  spot.kind,
                  age: widget.lifeAge ?? 12,
                  daySeed: stableChallengeHash(widget.today?.id ?? 'clear'),
                );

                final panel = challenge == null
                    ? _DecisionPanel(
                        spot: spot,
                        lifeAge: widget.lifeAge,
                        today: widget.today,
                        settled: widget.settled,
                        busy: _confirming != null,
                        onChoose: _choose,
                        onLeave: () => Navigator.of(context).pop(),
                      )
                    : _ChallengePanel(
                        challenge: challenge,
                        settled: widget.settled,
                        onFinish: (choice) =>
                            Navigator.of(context).pop(choice),
                        onLeave: () => Navigator.of(context).pop(),
                      );

                if (wide) {
                  // Both columns centred, and the panel capped.
                  //
                  // Stretched, this read as a broken screen: the panel hugged
                  // the top-right corner, the stall sat in the bottom-left,
                  // and the middle of a 965px window was a field of empty
                  // floor between them. A room with a person in it and a
                  // conversation about it should look like one scene, which
                  // means both halves sit on the same eye line.
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: Center(child: stage)),
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(4, 12, 14, 14),
                              child: panel,
                            ),
                          ),
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
                child: _LeaveButton(onTap: () => Navigator.of(context).pop()),
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
        //
        // The plain gradient alone read as *empty*, not as floor — on a wide
        // window it is the biggest single area on screen and it had nothing
        // in it. A skirting line where the wall meets the floor and a few
        // faint board seams cost nothing and turn a void into a room.
        Expanded(
          child: CustomPaint(
            painter: const _FloorPainter(),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

/// Floorboards, receding.
///
/// Deliberately faint. This sits behind a decision panel that the contrast
/// audit measures text against, so it has to add *shape* without adding
/// contrast — the seams are two percent white and the boards get closer
/// together toward the horizon, which is enough for the eye to read depth and
/// far too little to interfere with anything on top of it.
class _FloorPainter extends CustomPainter {
  const _FloorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4B28), Color(0xFF2A1E12)],
        ).createShader(rect),
    );

    // The skirting: the line where wall meets floor. One dark band and one
    // light one, because a single line reads as a crack rather than an edge.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 3),
      Paint()..color = const Color(0xFF3A2915),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 3, size.width, 1),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    final seam = Paint()..color = Colors.white.withValues(alpha: 0.02);
    // Boards bunching toward the top, which is where the horizon is.
    var y = size.height;
    var gap = size.height * 0.16;
    while (y > 6 && gap > 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), seam);
      y -= gap;
      gap *= 0.78;
    }
  }

  @override
  bool shouldRepaint(_FloorPainter oldDelegate) => false;
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

/// A playable money puzzle inside a building.
///
/// **What makes this a minigame rather than a shop dialogue.** There is a
/// right answer, you find out immediately whether you had it, and the
/// arithmetic that decided it is shown either way. A dialogue asks what you
/// would like; this asks whether you can work it out — and only the second
/// one can be got wrong, which is the only reason to walk here rather than
/// tap the menu.
///
/// **Payout goes through `TownChoice`** rather than a new reward path. That
/// is not laziness: the caller already owns the ledger, already knows whether
/// this encounter has been settled today, and already applies anti-farming.
/// A second payout route would be a second place for the farming bug to come
/// back — and it has come back once already, through the coins.
class _ChallengePanel extends StatefulWidget {
  const _ChallengePanel({
    required this.challenge,
    required this.settled,
    required this.onFinish,
    required this.onLeave,
  });

  final TownChallenge challenge;
  final bool settled;
  final ValueChanged<TownChoice> onFinish;
  final VoidCallback onLeave;

  @override
  State<_ChallengePanel> createState() => _ChallengePanelState();
}

class _ChallengePanelState extends State<_ChallengePanel> {
  int? _picked;

  bool get _answered => _picked != null;
  bool get _correct => _picked == widget.challenge.correctIndex;

  void _pick(int index) {
    if (_answered) return;
    setState(() => _picked = index);
    AppSoundService.play(
      index == widget.challenge.correctIndex
          ? AppSoundEffect.success
          : AppSoundEffect.error,
    );
  }

  /// Turns the result into the shape the caller already knows how to pay.
  ///
  /// A wrong answer still pays a little. The alternative — nothing at all —
  /// teaches a nine-year-old that the safe move is to stop opening buildings,
  /// which is the opposite of what a town full of practice is for. Getting it
  /// right is worth roughly three times as much, so the incentive is intact
  /// without the punishment.
  TownChoice _asChoice() {
    final c = widget.challenge;
    final right = _correct;
    return TownChoice(
      label: c.title,
      outcome: right ? 'You worked it out.' : c.explanation,
      gold: right ? c.reward * 3 : 1,
      xp: right ? c.reward * 2 : 1,
      literacy: right ? c.reward : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final accent = _answered
        ? (_correct ? AppTheme.greenPrimary : const Color(0xFFFFB084))
        : AppTheme.greenPrimary;

    return PixelFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.title,
            style: GoogleFonts.pixelifySans(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.prompt,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.settled) ...[
            const SizedBox(height: 8),
            Text(
              'You already settled here today — this one is for the practice.',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < c.options.length; i++) ...[
            _ChallengeOptionTile(
              option: c.options[i],
              // The working stays hidden until an answer is in. Showing the
              // per-unit price up front turns the puzzle into a reading
              // exercise, which is the mistake most teaching apps make.
              revealed: _answered,
              isCorrect: i == c.correctIndex,
              isPicked: i == _picked,
              onTap: _answered ? null : () => _pick(i),
            ),
            const SizedBox(height: 8),
          ],
          if (_answered) ...[
            const SizedBox(height: 2),
            Text(
              c.explanation,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PixelButton(
                label: _correct ? 'Take the reward' : 'Got it',
                onPressed: () => widget.onFinish(_asChoice()),
              ),
            ),
          ] else
            Center(
              child: TextButton(
                onPressed: widget.onLeave,
                child: Text(
                  'Leave',
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChallengeOptionTile extends StatelessWidget {
  const _ChallengeOptionTile({
    required this.option,
    required this.revealed,
    required this.isCorrect,
    required this.isPicked,
    required this.onTap,
  });

  final ChallengeOption option;
  final bool revealed;
  final bool isCorrect;
  final bool isPicked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // After answering, the correct row is marked whether or not it was the
    // one picked. Being shown only that you were wrong, without being shown
    // what was right, is the least useful possible feedback.
    final accent = !revealed
        ? Colors.white.withValues(alpha: 0.18)
        : isCorrect
        ? AppTheme.greenPrimary
        : isPicked
        ? const Color(0xFFFF8A80)
        : Colors.white.withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: revealed ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent, width: revealed ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (revealed) ...[
                      const SizedBox(height: 3),
                      Text(
                        option.detail,
                        style: GoogleFonts.quicksand(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (revealed && isCorrect)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.greenPrimary,
                  size: 20,
                )
              else if (revealed && isPicked)
                const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFFF8A80),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prompt and the choices — the part that was already right.
class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({
    required this.spot,
    required this.lifeAge,
    required this.today,
    required this.settled,
    required this.busy,
    required this.onChoose,
    required this.onLeave,
  });

  final TownSpot spot;
  final int? lifeAge;

  /// See [TownInteriorScreen.settled].
  final bool settled;

  /// Today's conditions, for the price line. Null when nothing passed one.
  final TownCondition? today;

  final bool busy;
  final ValueChanged<TownChoice> onChoose;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    // Today's encounter, not the spot's built-in one. Each building has
    // several scenes and rotates them by day *and* by the character's age —
    // see [townEncounterFor] for why the choice is fixed within a day rather
    // than rerolled on every visit, and why a life's years move it too.
    final encounter = townEncounterFor(
      spot,
      lifeAge: lifeAge,
      conditionId: today?.id,
    );
    final todayHint = today?.hintFor(spot.kind);

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
          // What today does to the prices here, at the point somebody is
          // about to spend.
          //
          // The map banner already says it, and the map banner is the wrong
          // place for it to matter: by the time a player is choosing whether
          // to buy lunch they are two screens away from the line telling them
          // lunch is cheap today. This is the same fact where the decision
          // actually happens.
          if (todayHint != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: spot.kind.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(today!.icon, color: spot.kind.accent, size: 14),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      todayHint,
                      style: GoogleFonts.quicksand(
                        color: spot.kind.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Said before the choice, not after it.
          //
          // The alternative — let somebody pick, then hand them nothing — is
          // the shape of a bug even when it is the intended rule, and it is
          // the version a player would reasonably describe as the game having
          // stopped paying out. A stated rule is a rule; a silent one is a
          // fault.
          if (settled) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white70,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'You already settled this one. Nothing to earn or '
                      'spend here — come back when something has changed.',
                      style: GoogleFonts.quicksand(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (final choice in encounter.choices) ...[
            _ChoiceRow(
              choice: choice,
              // Nothing is charged or paid on a settled encounter, so the
              // price pill would be quoting a number that will not happen.
              shownGold: settled
                  ? 0
                  : today?.priceFor(choice.gold, spot.kind) ?? choice.gold,
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
    required this.shownGold,
    required this.choice,
    required this.accent,
    required this.onTap,
  });

  final TownChoice choice;

  /// The price after today's conditions — what will actually be charged.
  ///
  /// **Not `choice.gold`.** The row used to print the list price while the
  /// map charged the adjusted one, so on a sale day the sign said "cheaper
  /// than usual" and the button underneath it still said -8. A discount you
  /// only find out about by watching your balance afterwards is not a lesson
  /// about sales, it is a game that cannot be trusted to quote a price.
  final int shownGold;

  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final costs = shownGold < 0;
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
                if (shownGold != 0) ...[
                  const SizedBox(width: 10),
                  // The price is on the label anyway in most of these
                  // prompts ("Buy the $4 bag"), so showing it here is a
                  // reminder rather than a spoiler — and it makes the
                  // *comparison* between options a glance instead of a
                  // read, which is the whole unit-price lesson.
                  Text(
                    '${costs ? '' : '+'}$shownGold',
                    style: AppTheme.numeric(
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
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
