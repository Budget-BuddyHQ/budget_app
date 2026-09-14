import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/leak_patrol_models.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/confetti_burst.dart';
import '../../../widgets_custom_lotties/age_scaled_note.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/map_backdrop.dart';

/// Leak Patrol — tap the money leaving, leave the money you owe.
///
/// The arcade's third mechanic. Coin Cascade is allocation, Finance Brawl is
/// recall under pressure, and this is **noticing** — the skill behind the way
/// most people actually lose money, which is small charges nobody looked at.
///
/// It is also the Mushroom Goomba's job. That skin was in the catalogue,
/// buyable and equippable, and its 8-frame walk cycle was reached only by
/// `AvatarSkin.walkFrames`, a method with no callers at all. The sprite
/// existed and never animated once.
class LeakPatrolPage extends StatefulWidget {
  const LeakPatrolPage({super.key});

  @override
  State<LeakPatrolPage> createState() => _LeakPatrolPageState();
}

/// The dark panel every block of text on this screen sits on.
///
/// The town map behind the game is busy and bright, and white text laid
/// straight over it was the main reason the screen read as confusing: the
/// eye could not tell what was UI and what was scenery.
const Color _panel = Color(0xE60A1F14);

class _LeakPatrolPageState extends State<LeakPatrolPage> {
  final Random _random = Random();

  late LeakRound _round;
  late List<LeakItem> _pool;

  /// What is currently up in each hole, or null for empty.
  late List<LeakItem?> _holes;

  /// Holes the player has already resolved this pop, so one thing cannot be
  /// tapped twice — a double tap during the pop-down animation would
  /// otherwise pay twice.
  final Set<int> _resolved = <int>{};

  Timer? _clock;
  Timer? _spawner;
  final Map<int, Timer> _retreats = <int, Timer>{};

  int _secondsLeft = 0;
  int _caught = 0;
  int _missed = 0;
  int _wrong = 0;
  int _saved = 0;
  int _lost = 0;

  bool _running = false;
  bool _finished = false;
  LeakResult? _result;

  /// Correct decisions in a row. Leaving a real charge alone counts, because
  /// that is a decision and it is the one this game is trying to teach.
  /// See [LeakStreak] for why a streak rather than a flat multiplier.
  LeakStreak _streak = const LeakStreak.empty();

  /// Holes mid-hit, and what the hit was worth. Drives the squash frame, the
  /// coloured burst and the floating number — all of which are the same
  /// event, so they share one piece of state and cannot disagree.
  final Map<int, _Hit> _hits = <int, _Hit>{};

  /// Seconds into the round, for [LeakPacing]. Counted up rather than derived
  /// from `_secondsLeft` so a paused or resumed clock cannot make the pacing
  /// jump backwards.
  int _elapsed = 0;

  /// The last thing that happened, and what it meant.
  ///
  /// This used to show only the item's explanation — *"A charge for not
  /// having money, applied when you have least of it"* — with no word of
  /// which item it was, whether the tap was right, or what it cost. It read
  /// as a random sentence appearing over the board.
  _Feedback? _feedback;

  @override
  void initState() {
    super.initState();
    final band = context.read<UserStatsController>().stats.ageBand;
    _round = LeakRound.forBand(band);
    _pool = leakItemsFor(band);
    _holes = List<LeakItem?>.filled(_round.holes, null);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _spawner?.cancel();
    for (final timer in _retreats.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _finished = false;
      _result = null;
      _feedback = null;
      _secondsLeft = _round.seconds;
      _elapsed = 0;
      _caught = _missed = _wrong = _saved = _lost = 0;
      _holes = List<LeakItem?>.filled(_round.holes, null);
      _resolved.clear();
      _hits.clear();
      // Best survives a replay; current does not.
      _streak = LeakStreak(0, _streak.best);
    });

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        _elapsed++;
      });
      if (_secondsLeft <= 0) _finish();
    });

    _scheduleNextPop();
  }

  /// Schedules one pop, then reschedules itself.
  ///
  /// **Not `Timer.periodic`**, which is what this was. A periodic timer is
  /// fixed at the interval it was created with, so the round ran at exactly
  /// one speed from the first second to the last. Rescheduling each time lets
  /// the gap come from [LeakPacing], which reads the round's own progress.
  void _scheduleNextPop() {
    _spawner?.cancel();
    final gap = LeakPacing.popMillisAt(_round, _elapsed, _round.seconds);
    _spawner = Timer(Duration(milliseconds: gap), () {
      if (!mounted || !_running) return;
      _popOne();
      _scheduleNextPop();
    });
  }

  void _popOne() {
    final empty = <int>[
      for (var i = 0; i < _holes.length; i++)
        if (_holes[i] == null) i,
    ];
    if (empty.isEmpty) return;

    final hole = empty[_random.nextInt(empty.length)];
    final item = _pool[_random.nextInt(_pool.length)];

    setState(() {
      _holes[hole] = item;
      _resolved.remove(hole);
    });

    _retreats[hole]?.cancel();
    _retreats[hole] = Timer(
      Duration(
        milliseconds: LeakPacing.visibleMillisAt(
          _round,
          _elapsed,
          _round.seconds,
        ),
      ),
      () {
        if (!mounted) return;
        // Gone before it was dealt with. A missed *leak* costs nothing
        // directly — the money simply kept leaving — which is why the
        // results card counts misses separately from mistakes.
        final gone = _holes[hole];
        final unresolved = !_resolved.contains(hole);
        setState(() {
          if (unresolved && gone != null && gone.isLeak) {
            _missed++;
            // A leak that got away breaks the run. Letting a *real charge*
            // retreat does not — leaving it alone was the correct decision
            // and it is the decision the game is teaching, so it advances
            // the streak instead.
            _streak = _streak.broken();
            _feedback = _Feedback(gone, _Outcome.missedLeak, 0);
          } else if (unresolved && gone != null) {
            _streak = _streak.advanced();
          }
          _holes[hole] = null;
        });
      },
    );
  }

  void _tap(int hole) {
    final item = _holes[hole];
    if (item == null || _resolved.contains(hole) || !_running) return;

    _resolved.add(hole);
    HapticFeedback.selectionClick();

    setState(() {
      if (item.isLeak) {
        _caught++;
        // The streak multiplies what a catch is worth, which is why it is
        // advanced *before* the coins are counted.
        _streak = _streak.advanced();
        final gained = item.value * _streak.multiplier;
        _saved += gained;
        _hits[hole] = _Hit(item: item, right: true, delta: gained);
        _feedback = _Feedback(item, _Outcome.caught, gained);
        AppSoundService.play(AppSoundEffect.success);
      } else {
        // The expensive mistake, and the one the game exists to create.
        // Everyone arrives believing vigilance means tapping everything.
        _wrong++;
        _lost += item.value;
        _streak = _streak.broken();
        _hits[hole] = _Hit(item: item, right: false, delta: -item.value);
        _feedback = _Feedback(item, _Outcome.cancelledBill, -item.value);
        AppSoundService.play(AppSoundEffect.error);
      }
    });

    // The hole stays occupied for the length of the squash frame, then
    // clears. Clearing it immediately is what made a tap feel like nothing
    // happening: the sprite vanished on the same frame as the tap.
    _retreats[hole]?.cancel();
    Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() {
        _hits.remove(hole);
        _holes[hole] = null;
      });
    });
  }

  Future<void> _finish() async {
    _clock?.cancel();
    _spawner?.cancel();
    for (final timer in _retreats.values) {
      timer.cancel();
    }
    _retreats.clear();

    final result = LeakResult(
      caught: _caught,
      missed: _missed,
      wronglyTapped: _wrong,
      coinsSaved: _saved,
      coinsLost: _lost,
    );

    setState(() {
      _running = false;
      _finished = true;
      _result = result;
      _holes = List<LeakItem?>.filled(_round.holes, null);
    });

    final payout = leakPayout(result);
    if (!mounted) return;

    if (result.accuracy >= 0.9 && result.caught >= 3) {
      ConfettiBurst.show(context);
    }

    await context
        .read<UserStatsController>()
        .applyChallengePayload(<String, dynamic>{
          'gold_earned': payout,
          'xp_earned': result.caught * 2,
          'literacy_points_earned': result.caught > 0 ? 2 : 0,
          'title': 'Leak Patrol',
          'description':
              'Caught ${result.caught}, cancelled ${result.wronglyTapped} real '
              'charges by mistake.',
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Leak Patrol',
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          // The town map behind the game, like every other screen in the app.
          const MapBackdrop(style: MapBackdropStyle.decorative),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _running
                  ? _PlayView(
                      seconds: _secondsLeft,
                      caught: _caught,
                      wrong: _wrong,
                      net: _saved - _lost,
                      streak: _streak,
                      feedback: _feedback,
                      holes: _holes,
                      hits: _hits,
                      onTap: _tap,
                    )
                  : _Centred(
                      scrolls: _finished,
                      child: _finished
                          ? _Results(result: _result!, onAgain: _start)
                          : _Intro(
                              round: _round,
                              pool: _pool,
                              best: _streak.best,
                              onStart: _start,
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A readable column on any window.
///
/// On a desktop-sized window the intro stretched its two example cards to
/// half the screen each, with the explanation as one very long line under
/// them. Text has a comfortable measure; past it, it stops being read.
class _Centred extends StatelessWidget {
  const _Centred({required this.child, this.scrolls = true});

  final Widget child;

  /// The intro scrolls its own panel and keeps Start pinned below it.
  final bool scrolls;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: scrolls ? SingleChildScrollView(child: child) : child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Playing
// ---------------------------------------------------------------------------

/// The round in progress: score, what just happened, and the board.
///
/// # Why nothing above the board changes height
///
/// The streak bar and the explanation banner used to appear and disappear
/// above the board, and every time they did the board shrank or grew. On a
/// game where the player is aiming a tap, a board that moves between looking
/// and tapping is a board that makes them hit the wrong hole. Both now live
/// in one panel with a fixed height.
class _PlayView extends StatelessWidget {
  const _PlayView({
    required this.seconds,
    required this.caught,
    required this.wrong,
    required this.net,
    required this.streak,
    required this.feedback,
    required this.holes,
    required this.hits,
    required this.onTap,
  });

  final int seconds;
  final int caught;
  final int wrong;
  final int net;
  final LeakStreak streak;
  final _Feedback? feedback;
  final List<LeakItem?> holes;
  final Map<int, _Hit> hits;
  final void Function(int hole) onTap;

  /// Below this, a board stacked under the score and the tip panel is too
  /// short to play: on a phone held sideways the holes came out 16px tall.
  static const double _minStackedBoard = 240;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackedBoard =
            constraints.maxHeight -
            _Hud.rowHeight -
            8 -
            _FeedbackPanel.stackedHeight -
            10;
        final sideways =
            constraints.maxWidth > constraints.maxHeight &&
            stackedBoard < _minStackedBoard;

        final hud = _Hud(
          seconds: seconds,
          caught: caught,
          wrong: wrong,
          net: net,
          twoByTwo: sideways,
        );
        final board = _Board(
          holes: holes,
          hits: hits,
          onTap: onTap,
          alignment: sideways ? Alignment.center : Alignment.topCenter,
        );

        if (sideways) {
          // Short and wide: the reading goes on the left, the board gets the
          // full height on the right.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: min(300.0, constraints.maxWidth * 0.42),
                child: Column(
                  children: [
                    hud,
                    const SizedBox(height: 8),
                    Expanded(
                      child: _FeedbackPanel(
                        feedback: feedback,
                        streak: streak,
                        fixedHeight: null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: board),
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                hud,
                const SizedBox(height: 8),
                _FeedbackPanel(feedback: feedback, streak: streak),
                const SizedBox(height: 10),
                Expanded(child: board),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.seconds,
    required this.caught,
    required this.wrong,
    required this.net,
    this.twoByTwo = false,
  });

  final int seconds;
  final int caught;
  final int wrong;
  final int net;

  /// Two rows of two, for the narrow side column on a sideways phone.
  final bool twoByTwo;

  /// Roughly one row of stat tiles, for deciding the layout before building.
  static const double rowHeight = 58;

  @override
  Widget build(BuildContext context) {
    final time = _Stat(
      label: 'TIME',
      value: '${seconds}s',
      // Red for the last ten seconds. A timer that looks the same at 50
      // and at 3 is a timer nobody looks at.
      accent: seconds <= 10 ? const Color(0xFFFF8474) : const Color(0xFF7FD3FF),
    );
    final caughtStat = _Stat(
      label: 'CAUGHT',
      value: '$caught',
      accent: AppTheme.greenPrimary,
    );
    final mistakes = _Stat(
      label: 'MISTAKES',
      value: '$wrong',
      accent: const Color(0xFFFF8474),
    );
    // It was labelled SAVED and showed saved-minus-lost, so a player who had
    // saved 20 and lost 24 was told they had "saved -4".
    final coins = _Stat(
      label: 'COINS',
      value: '$net',
      accent: const Color(0xFFFFD45C),
    );

    if (twoByTwo) {
      return Column(
        children: [
          Row(children: [time, const SizedBox(width: 8), caughtStat]),
          const SizedBox(height: 8),
          Row(children: [mistakes, const SizedBox(width: 8), coins]),
        ],
      );
    }
    return Row(
      children: [
        time,
        const SizedBox(width: 8),
        caughtStat,
        const SizedBox(width: 8),
        mistakes,
        const SizedBox(width: 8),
        coins,
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
        ),
        child: Column(
          children: [
            FittedLabel(
              label,
              style: AppTheme.caps(color: accent, fontSize: 10.5),
            ),
            const SizedBox(height: 2),
            FittedLabel(
              value,
              style: AppTheme.numeric(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Outcome { caught, cancelledBill, missedLeak }

@immutable
class _Feedback {
  const _Feedback(this.item, this.outcome, this.delta);

  final LeakItem item;
  final _Outcome outcome;
  final int delta;
}

/// The rule, until something happens; then what happened and why.
///
/// Before the first tap it states the rule, because the intro is gone by
/// then and a player who skimmed it has nothing else on screen to go by.
/// After that it names the item, says whether the call was right, shows the
/// coins, and gives the reason — in that order, because that is the order a
/// player asks the questions in.
class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.feedback,
    required this.streak,
    this.fixedHeight = stackedHeight,
  });

  final _Feedback? feedback;
  final LeakStreak streak;

  /// Fixed when stacked above the board, so the board never moves. See
  /// [_PlayView].
  static const double stackedHeight = 74;

  /// Null fills the space given, in the sideways layout.
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final fb = feedback;
    final (
      Color accent,
      IconData icon,
      String title,
      String body,
    ) = switch (fb?.outcome) {
      null => (
        const Color(0xFF7FD3FF),
        Icons.lightbulb_rounded,
        'Tap the leaks. Let real bills go by.',
        'Leaks are money wasted. Tapping a real bill, like rent or food, '
            'costs you coins.',
      ),
      _Outcome.caught => (
        AppTheme.greenPrimary,
        Icons.check_circle_rounded,
        'Leak caught: ${fb!.item.label}',
        fb.item.why,
      ),
      _Outcome.cancelledBill => (
        const Color(0xFFFF8474),
        Icons.cancel_rounded,
        'That was a real bill: ${fb!.item.label}',
        fb.item.why,
      ),
      _Outcome.missedLeak => (
        const Color(0xFFFFD45C),
        Icons.error_rounded,
        'A leak got away: ${fb!.item.label}',
        fb.item.why,
      ),
    };

    return Container(
      height: fixedHeight,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: fixedHeight == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.numeric(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (fb != null && fb.delta != 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${fb.delta > 0 ? '+' : '−'}${fb.delta.abs()}',
                        style: AppTheme.numeric(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (streak.current >= 2) ...[
                      const SizedBox(width: 8),
                      _StreakPill(streak: streak),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                    body,
                    maxLines: fixedHeight == null ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.numeric(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The current run of correct decisions.
///
/// It appears only once there is a streak worth having. A permanent "streak:
/// 0" is a scoreboard for failure.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final LeakStreak streak;

  @override
  Widget build(BuildContext context) {
    final accent = streak.multiplier >= LeakStreak.maxMultiplier
        ? const Color(0xFFFFD45C)
        : const Color(0xFF85EFAC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 12,
            color: Color(0xFF06251A),
          ),
          const SizedBox(width: 3),
          Text(
            streak.multiplier > 1
                ? '${streak.current} · ${streak.multiplier}x'
                : '${streak.current}',
            style: AppTheme.numeric(
              color: const Color(0xFF06251A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// How the holes are arranged to fit the space they are given.
///
/// # The bug this fixes
///
/// The grid was a fixed three columns of near-square cells, sized from the
/// board's **width** alone. On a phone in portrait that happens to fit. On a
/// laptop window each cell came out about 310px tall, three rows needed
/// ~980px, the board had ~550px, and the grid could not scroll — so **six of
/// the nine holes were below the bottom of the screen**, still spawning
/// leaks nobody could see or tap. What was left was one row of holes in the
/// middle of an empty field.
///
/// The cell size is now the largest square that fits *both* dimensions, and
/// the board is only as big as its holes, centred in the space.
@immutable
class LeakBoardLayout {
  const LeakBoardLayout(this.columns, this.rows, this.cell);

  final int columns;
  final int rows;

  /// Side of one square cell, in logical pixels.
  final double cell;

  static const double gap = 10;

  double get width => columns * cell + (columns - 1) * gap;
  double get height => rows * cell + (rows - 1) * gap;

  /// Tries every grid of at most 3x3 that holds [holes] exactly, and keeps
  /// the one with the biggest cells. A six-hole round goes 3x2 on a wide
  /// window and 2x3 on a tall one; nine holes are always 3x3.
  static LeakBoardLayout fit(int holes, double width, double height) {
    LeakBoardLayout? best;
    for (var columns = 1; columns <= holes; columns++) {
      if (holes % columns != 0) continue;
      final rows = holes ~/ columns;
      if (columns > 3 || rows > 3) continue;
      final byWidth = (width - (columns - 1) * gap) / columns;
      final byHeight = (height - (rows - 1) * gap) / rows;
      final cell = max(0.0, min(byWidth, byHeight));
      if (best == null || cell > best.cell) {
        best = LeakBoardLayout(columns, rows, cell);
      }
    }
    // A hole count with no grid of at most 3x3 (none today) falls back to a
    // single scrolling-free row rather than throwing.
    return best ?? LeakBoardLayout(holes, 1, max(0.0, width / holes));
  }
}

/// The holes, on ground rather than on a flat panel.
class _Board extends StatelessWidget {
  const _Board({
    required this.holes,
    required this.hits,
    required this.onTap,
    required this.alignment,
  });

  final List<LeakItem?> holes;
  final Map<int, _Hit> hits;
  final void Function(int hole) onTap;

  /// Top in portrait, so the board sits under the tip panel instead of
  /// floating mid-screen with a gap above it.
  final Alignment alignment;

  static const double _inset = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = LeakBoardLayout.fit(
          holes.length,
          constraints.maxWidth - _inset * 2,
          constraints.maxHeight - _inset * 2,
        );

        return Align(
          alignment: alignment,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: layout.width + _inset * 2,
              height: layout.height + _inset * 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Tiled rather than stretched: it is a 384x192 tile and
                  // scaling it would make every blade of grass huge.
                  Image.asset(
                    AppAssets.meadowTileBackground,
                    repeat: ImageRepeat.repeat,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, _, _) =>
                        Container(color: const Color(0xFF13301F)),
                  ),
                  // Darkened so the white labels read against bright grass.
                  Container(
                    color: const Color(0xFF0A1F14).withValues(alpha: 0.5),
                  ),
                  for (var index = 0; index < holes.length; index++)
                    Positioned(
                      left:
                          _inset +
                          (index % layout.columns) *
                              (layout.cell + LeakBoardLayout.gap),
                      top:
                          _inset +
                          (index ~/ layout.columns) *
                              (layout.cell + LeakBoardLayout.gap),
                      width: layout.cell,
                      height: layout.cell,
                      child: _Hole(
                        key: ValueKey<String>('leak-hole-$index'),
                        item: holes[index],
                        hit: hits[index],
                        onTap: () => onTap(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One hole, and whatever is coming out of it.
///
/// Everything inside is sized from the cell, not in fixed pixels. The sprite
/// was a fixed 46px and the label a fixed 10.5pt, so on a big window a
/// thumbnail sat in a huge empty cell, and on a small phone in landscape the
/// label and sprite together were taller than the cell and the sprite was
/// clipped away entirely — leaving a caption on a hole with nothing in it.
///
/// # Why the sprite carries no information
///
/// Four creatures, picked by `creatureFor(item.id)` — stable per item and
/// carrying no information about whether it is a leak. Making leaks look
/// different would make the game winnable without reading a word.
class _Hole extends StatelessWidget {
  const _Hole({
    super.key,
    required this.item,
    required this.hit,
    required this.onTap,
  });

  final LeakItem? item;
  final _Hit? hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = item != null;
    final resolved = hit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final rimHeight = (side * 0.13).clamp(10.0, 26.0);
        final rimBottom = side * 0.07;
        final spriteSize = (side * 0.48).clamp(24.0, 128.0);
        final labelSize = (side * 0.075).clamp(9.5, 15.0);

        return GestureDetector(
          onTap: occupied && resolved == null ? onTap : null,
          // Opaque, so a tap anywhere in the cell counts. Aim is not what
          // this game is about.
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The hole itself: a dark opening with a lighter lip, so an
              // empty hole still reads as somewhere a thing could come from.
              Positioned(
                left: constraints.maxWidth * 0.12,
                right: constraints.maxWidth * 0.12,
                bottom: rimBottom,
                height: rimHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF051109),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF6B5A3A),
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (occupied)
                // Clipped at the middle of the rim, so the creature really
                // comes up out of the hole instead of fading in over it.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: rimBottom + rimHeight / 2,
                  child: ClipRect(
                    child: _Riser(
                      item: item!,
                      hit: resolved,
                      spriteSize: spriteSize,
                      labelSize: labelSize,
                      maxLabelWidth: constraints.maxWidth * 0.94,
                    ),
                  ),
                ),
              if (resolved != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _FloatingDelta(
                      delta: resolved.delta,
                      right: resolved.right,
                      fontSize: (side * 0.1).clamp(14.0, 24.0),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The sprite coming up out of the hole, and its label.
class _Riser extends StatefulWidget {
  const _Riser({
    required this.item,
    required this.hit,
    required this.spriteSize,
    required this.labelSize,
    required this.maxLabelWidth,
  });

  final LeakItem item;
  final _Hit? hit;
  final double spriteSize;
  final double labelSize;
  final double maxLabelWidth;

  @override
  State<_Riser> createState() => _RiserState();
}

class _RiserState extends State<_Riser> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutBack
            .transform(_controller.value)
            .clamp(0.0, 1.2);
        final hit = widget.hit;
        // The stretched frame only for the first beat of the rise; held
        // longer it reads as a different creature.
        final pose = hit != null
            ? 'hit'
            : (_controller.value < 0.45 ? 'rise' : 'idle');
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            // Slides up from below the rim.
            offset: Offset(0, (1 - t) * widget.spriteSize),
            child: _figure(pose, hit),
          ),
        );
      },
    );
  }

  /// Label and creature, as one unit, scaled down together if a very short
  /// cell cannot hold both at full size. Scaling beats clipping: a smaller
  /// label can still be read, a clipped one cannot.
  Widget _figure(String pose, _Hit? hit) {
    final sprite = widget.spriteSize;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // **Label above, creature below**, so the creature's feet meet the
          // rim. The label is the game: it has to be legible in the second
          // the thing is up.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxLabelWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xF206251A),
                borderRadius: BorderRadius.circular(8),
                border: hit == null
                    ? null
                    : Border.all(
                        color: hit.right
                            ? const Color(0xFF85EFAC)
                            : const Color(0xFFFF8474),
                        width: 1.5,
                      ),
              ),
              child: Text(
                widget.item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.numeric(
                  color: Colors.white,
                  fontSize: widget.labelSize,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: sprite * 0.04),
          SizedBox(
            width: sprite,
            height: sprite,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (hit != null)
                  OverflowBox(
                    maxWidth: sprite * 1.8,
                    maxHeight: sprite * 1.8,
                    child: _Burst(right: hit.right, size: sprite * 1.8),
                  ),
                Image.asset(
                  creatureFor(widget.item.id).frame(pose),
                  width: sprite,
                  height: sprite,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.savings_rounded,
                    color: Colors.white70,
                    size: sprite * 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The impact burst. Green for a leak caught, red for a charge cancelled by
/// mistake.
class _Burst extends StatelessWidget {
  const _Burst({required this.right, required this.size});

  final bool right;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BurstPainter(
          colour: right ? const Color(0xFF85EFAC) : const Color(0xFFFF8474),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.colour});

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    // Drawn for an 84px box originally; everything scales from that.
    final k = size.shortestSide / 84;
    final paint = Paint()
      ..color = colour
      ..strokeWidth = max(2.0, 3 * k)
      ..strokeCap = StrokeCap.round;

    // Eight spikes, alternating length. Even spikes read as a gear; uneven
    // ones read as an impact.
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final inner = (i.isEven ? 24.0 : 20.0) * k;
      final outer = (i.isEven ? 39.0 : 30.0) * k;
      canvas.drawLine(
        centre + Offset(cos(angle) * inner, sin(angle) * inner),
        centre + Offset(cos(angle) * outer, sin(angle) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.colour != colour;
}

/// One resolved tap, held just long enough to be seen.
@immutable
class _Hit {
  const _Hit({required this.item, required this.right, required this.delta});

  final LeakItem item;

  /// Whether the player was correct. Green burst, or red.
  final bool right;

  /// Coins gained or lost, already multiplied by the streak.
  final int delta;
}

/// The coins, floating up and fading.
class _FloatingDelta extends StatefulWidget {
  const _FloatingDelta({
    required this.delta,
    required this.right,
    required this.fontSize,
  });

  final int delta;
  final bool right;
  final double fontSize;

  @override
  State<_FloatingDelta> createState() => _FloatingDeltaState();
}

class _FloatingDeltaState extends State<_FloatingDelta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colour = widget.right
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8474);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: (1 - _controller.value).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -18 * _controller.value),
          child: Text(
            '${widget.delta > 0 ? '+' : ''}${widget.delta}',
            style:
                AppTheme.numeric(
                  color: colour,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                ).copyWith(
                  shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Before and after
// ---------------------------------------------------------------------------

/// The start screen.
///
/// # What was confusing
///
/// It opened on two lines of pixel text — "Tap the money leaving. Leave the
/// money you owe." — which are a riddle to somebody who has not played, then
/// two example cards with no word of what happens if you get them wrong,
/// then the sentence that actually explains the game in small grey text,
/// then "9 holes" and "Speeds up" chips, all laid straight over the town map.
///
/// # What it does now
///
/// Says what a leak is in plain words, then three numbered steps in the
/// order they happen in a round, each with its consequence. The two example
/// cards follow, labelled with what the tap is worth, so the rule and the
/// cost are learned together. Everything sits on a dark panel.
///
/// The examples are pulled from the live item list rather than written here,
/// so the tutorial cannot describe a game that no longer exists.
class _Intro extends StatelessWidget {
  const _Intro({
    required this.round,
    required this.pool,
    required this.best,
    required this.onStart,
  });

  final LeakRound round;
  final List<LeakItem> pool;

  /// Best streak so far, or zero. Shown only once there is one.
  final int best;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final leak = pool.firstWhere(
      (item) => item.isLeak,
      orElse: () => pool.first,
    );
    final real = pool.firstWhere(
      (item) => !item.isLeak,
      orElse: () => pool.last,
    );

    final panel = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catch the leaks',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A leak is money quietly wasted — a subscription you forgot, a '
            'sneaky fee, a scam. Real bills are money you actually owe.',
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _Step(
            number: 1,
            accent: Color(0xFF7FD3FF),
            title: 'Read the label',
            body: 'Charges pop out of the holes. Each one says what it is.',
          ),
          const _Step(
            number: 2,
            accent: Color(0xFF85EFAC),
            title: 'Leak? Tap it.',
            body: 'You save its coins. Right answers in a row multiply them.',
          ),
          const _Step(
            number: 3,
            accent: Color(0xFFFF8474),
            title: 'Real bill? Leave it alone.',
            body: 'Let it drop back down. Tapping a real bill costs you coins.',
          ),
          const SizedBox(height: 6),
          Text(
            'FOR EXAMPLE',
            style: AppTheme.caps(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Example(item: leak, tap: true)),
                const SizedBox(width: 10),
                Expanded(child: _Example(item: real, tap: false)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.timer_rounded,
                label: '${round.seconds} seconds',
                accent: const Color(0xFF7FD3FF),
              ),
              _Chip(
                icon: Icons.speed_rounded,
                label: 'Gets faster',
                accent: const Color(0xFFFFD45C),
              ),
              if (best > 0)
                _Chip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Best streak $best',
                  accent: const Color(0xFFFF8474),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // The age scaling, said out loud. It is invisible otherwise.
          const AgeScaledNote(what: 'The speed'),
        ],
      ),
    );

    // The button sits under the panel, outside the scroll. With the
    // steps and examples added, the intro is taller than a small phone,
    // and a Start button you have to scroll to find is one a new player
    // does not find.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: SingleChildScrollView(child: panel)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.greenPrimary,
              foregroundColor: const Color(0xFF06251A),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              'Start',
              style: GoogleFonts.pixelifySans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.accent,
    required this.title,
    required this.body,
  });

  final int number;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: AppTheme.numeric(
                color: const Color(0xFF06251A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.numeric(
                    color: accent,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  body,
                  style: AppTheme.numeric(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One worked example on the start screen: a real item, drawn as it will
/// appear, labelled with what to do about it and what that is worth.
class _Example extends StatelessWidget {
  const _Example({required this.item, required this.tap});

  final LeakItem item;
  final bool tap;

  @override
  Widget build(BuildContext context) {
    final accent = tap ? const Color(0xFF85EFAC) : const Color(0xFFFF8474);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
      ),
      child: Column(
        children: [
          Text(
            tap ? 'LEAK' : 'REAL BILL',
            style: AppTheme.caps(color: accent, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Image.asset(
            creatureFor(item.id).frame('idle'),
            height: 56,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Icon(Icons.savings_rounded, color: accent, size: 40),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tap ? 'TAP IT' : 'LEAVE IT',
              style: AppTheme.caps(
                color: const Color(0xFF06251A),
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tap ? '+${item.value} coins' : 'Tapping it: −${item.value} coins',
            textAlign: TextAlign.center,
            style: AppTheme.numeric(
              color: accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.numeric(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.onAgain});

  final LeakResult result;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.headline,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _Line('Leaks caught', '${result.caught}'),
          _Line('Leaks that got past you', '${result.missed}'),
          _Line('Real bills you tapped by mistake', '${result.wronglyTapped}'),
          _Line('Coins saved', '${result.coinsSaved}'),
          _Line('Coins lost', '${result.coinsLost}'),
          const SizedBox(height: 14),
          Text(
            '+${leakPayout(result)} gold',
            style: AppTheme.numeric(
              color: const Color(0xFFFFD45C),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAgain,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.greenPrimary,
                foregroundColor: const Color(0xFF06251A),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'Go again',
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.numeric(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
