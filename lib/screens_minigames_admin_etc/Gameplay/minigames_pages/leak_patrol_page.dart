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

  /// The last thing resolved, so the board can say why without a modal.
  LeakItem? _lastItem;
  bool _lastWasRight = false;

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
      _lastItem = null;
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
  /// one speed from the first second to the last — the final twenty seconds
  /// of a fifty-second round were indistinguishable from the first twenty. A
  /// game with no shape is a drill.
  ///
  /// Rescheduling each time lets the gap come from [LeakPacing], which reads
  /// the round's own progress. The ramp is deliberately gentle and bounded:
  /// the skill here is *reading before acting*, and a speed that eventually
  /// outruns reading would train the opposite.
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
        final wasLeak = _holes[hole]?.isLeak ?? false;
        final unresolved = !_resolved.contains(hole);
        setState(() {
          if (unresolved && wasLeak) {
            _missed++;
            // A leak that got away breaks the run. Letting a *real charge*
            // retreat does not — leaving it alone was the correct decision
            // and it is the decision the game is teaching, so it advances
            // the streak instead.
            _streak = _streak.broken();
          } else if (unresolved && !wasLeak) {
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
      _lastItem = item;
      _lastWasRight = item.isLeak;
      if (item.isLeak) {
        _caught++;
        // The streak multiplies what a catch is worth, which is why it is
        // advanced *before* the coins are counted.
        _streak = _streak.advanced();
        final gained = item.value * _streak.multiplier;
        _saved += gained;
        _hits[hole] = _Hit(item: item, right: true, delta: gained);
        AppSoundService.play(AppSoundEffect.success);
      } else {
        // The expensive mistake, and the one the game exists to create.
        // Everyone arrives believing vigilance means tapping everything.
        _wrong++;
        _lost += item.value;
        _streak = _streak.broken();
        _hits[hole] = _Hit(item: item, right: false, delta: -item.value);
        AppSoundService.play(AppSoundEffect.error);
      }
    });

    // The hole stays occupied for the length of the squash frame, then
    // clears. Clearing it immediately is what made a tap feel like nothing
    // happening: the sprite vanished on the same frame as the tap, so there
    // was no moment for the hit to be seen.
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
      // The town map behind the game, like every other screen in the app.
      // This was a flat `deepForest` fill — reported as wanting *"the maps
      // that we have"* — and a solid colour is what made the screen read as
      // a settings page with a grid on it.
      body: Stack(
        children: [
          const MapBackdrop(style: MapBackdropStyle.decorative),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _Hud(
                    seconds: _secondsLeft,
                    caught: _caught,
                    wrong: _wrong,
                    net: _saved - _lost,
                    streak: _streak,
                    running: _running,
                  ),
                  if (_running) _StreakBar(streak: _streak),
                  const SizedBox(height: 12),
                  if (_lastItem != null && _running)
                    _WhyBanner(item: _lastItem!, wasRight: _lastWasRight),
                  Expanded(
                    child: _running
                        ? _Board(holes: _holes, hits: _hits, onTap: _tap)
                        : _finished
                        ? _Results(result: _result!, onAgain: _start)
                        : _Intro(
                            round: _round,
                            pool: _pool,
                            best: _streak.best,
                            onStart: _start,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The current run of correct decisions.
///
/// # Why it is a bar and not a number in the HUD
///
/// The streak is the only thing on this screen that rewards *not* acting, so
/// it has to be visible at the moment somebody is deciding whether to tap. A
/// fifth stat tile beside TIME and CAUGHT would be read once at the start of
/// the round and never again.
///
/// It appears only once there is a streak worth having. A permanent "streak:
/// 0" is a scoreboard for failure.
class _StreakBar extends StatelessWidget {
  const _StreakBar({required this.streak});

  final LeakStreak streak;

  @override
  Widget build(BuildContext context) {
    if (streak.current < 2) return const SizedBox(height: 8);

    final accent = streak.multiplier >= LeakStreak.maxMultiplier
        ? const Color(0xFFFFD45C)
        : const Color(0xFF85EFAC);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, size: 16, color: accent),
            const SizedBox(width: 7),
            Text(
              '${streak.current} right in a row',
              style: AppTheme.numeric(
                color: accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (streak.multiplier > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${streak.multiplier}x',
                  style: AppTheme.numeric(
                    color: const Color(0xFF06251A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The start screen.
///
/// # What this replaced
///
/// A heading, a paragraph, a line of grey text and a green button — reported
/// as *"the starting screen for this minigame is pretty bad"*, which it was.
/// It described the game in prose to a player who had not seen it, on a
/// screen with nothing on it, and then asked them to commit sixty seconds.
///
/// # Why it shows the two cases instead of explaining them
///
/// The single thing a new player has to understand is that **some of these
/// you tap and some of these you must not**, and that is a distinction you
/// learn by seeing two examples side by side, not by reading a sentence
/// containing the words "subscriptions", "fees" and "offers that were never
/// offers".
///
/// So the screen shows one real leak and one real charge, drawn with the same
/// creatures and the same cards the game uses, one marked tap and one marked
/// leave. It is the rules, rendered in the game's own materials.
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

  /// Best streak so far, or zero. Shown only once there is one — an empty
  /// personal best on a first run is a reminder that you have never played.
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap the money leaving.',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Leave the money you owe.',
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFFD98CFF),
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          // The rules, in the game's own materials.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Example(item: leak, tap: true)),
              const SizedBox(width: 12),
              Expanded(child: _Example(item: real, tap: false)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Cancelling a real charge costs you more than catching a leak is '
            'worth. Reading beats tapping.',
            style: AppTheme.numeric(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.timer_rounded,
                label: '${round.seconds}s',
                accent: const Color(0xFF6CB6DA),
              ),
              _Chip(
                icon: Icons.grid_view_rounded,
                label: '${round.holes} holes',
                accent: const Color(0xFF85EFAC),
              ),
              _Chip(
                icon: Icons.speed_rounded,
                label: 'Speeds up',
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
          // The age scaling, said out loud. It is invisible otherwise, and a
          // player who has watched somebody older play will notice the
          // difference and have no way to account for it.
          const AgeScaledNote(what: 'The speed'),
          const SizedBox(height: 20),
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
      ),
    );
  }
}

/// One worked example on the start screen: a real item, drawn as it will
/// appear, labelled with what to do about it.
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
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 2),
      ),
      child: Column(
        children: [
          Image.asset(
            creatureFor(item.id).frame('idle'),
            height: 54,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Icon(Icons.savings_rounded, color: accent, size: 40),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tap ? 'TAP IT' : 'LEAVE IT',
              style: AppTheme.caps(
                color: const Color(0xFF06251A),
                fontSize: 11,
              ),
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

class _Hud extends StatelessWidget {
  const _Hud({
    required this.seconds,
    required this.caught,
    required this.wrong,
    required this.net,
    required this.streak,
    required this.running,
  });

  final int seconds;
  final int caught;
  final int wrong;
  final int net;

  /// The run of correct decisions, and what it is currently multiplying by.
  final LeakStreak streak;

  final bool running;

  @override
  Widget build(BuildContext context) {
    if (!running) return const SizedBox.shrink();
    return Row(
      children: [
        _Stat(
          label: 'TIME',
          value: '$seconds',
          // Red for the last ten seconds. A timer that looks the same at 50
          // and at 3 is a timer nobody looks at.
          accent: seconds <= 10
              ? const Color(0xFFFF8474)
              : const Color(0xFF58C7FF),
        ),
        const SizedBox(width: 8),
        _Stat(label: 'CAUGHT', value: '$caught', accent: AppTheme.greenPrimary),
        const SizedBox(width: 8),
        _Stat(label: 'WRONG', value: '$wrong', accent: const Color(0xFFFF8474)),
        const SizedBox(width: 8),
        _Stat(label: 'SAVED', value: '$net', accent: const Color(0xFFFFD45C)),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: Column(
          children: [
            FittedLabel(
              label,
              style: GoogleFonts.pixelifySans(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            FittedLabel(
              value,
              style: AppTheme.numeric(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why the last tap was right or wrong, without stopping play.
///
/// A modal here would pause the clock and turn a reflex game into a slideshow.
/// A banner that changes as you go teaches during the round instead of after
/// it, which is when the player can still use it.
class _WhyBanner extends StatelessWidget {
  const _WhyBanner({required this.item, required this.wasRight});

  final LeakItem item;
  final bool wasRight;

  @override
  Widget build(BuildContext context) {
    final accent = wasRight ? AppTheme.greenPrimary : const Color(0xFFFF8474);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        item.why,
        style: AppTheme.numeric(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One resolved tap, held just long enough to be seen.
///
/// The squash frame, the coloured burst and the floating number are the same
/// event, so they read from one record. Kept as a type rather than three
/// parallel maps because three maps is three chances for the burst to be
/// green while the number is negative.
@immutable
class _Hit {
  const _Hit({required this.item, required this.right, required this.delta});

  final LeakItem item;

  /// Whether the player was correct. Green burst, or red.
  final bool right;

  /// Coins gained or lost, already multiplied by the streak.
  final int delta;
}

/// The nine holes, on ground rather than on a flat panel.
///
/// The board used to be dark rounded rectangles on the page background —
/// nine grey slabs, which is what made a whack-a-mole read as a list of
/// buttons. It is now the app's own meadow tile, so the holes are holes *in*
/// something.
class _Board extends StatelessWidget {
  const _Board({required this.holes, required this.hits, required this.onTap});

  final List<LeakItem?> holes;
  final Map<int, _Hit> hits;
  final void Function(int hole) onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tiled rather than stretched: it is a 384x192 tile and scaling it
          // to fill a phone would make every blade of grass four pixels wide.
          Image.asset(
            AppAssets.meadowTileBackground,
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFF13301F)),
          ),
          // The board sits above bright grass and the labels are white, so
          // the ground is darkened under them. Without this the game is
          // unreadable in exactly the moment it has to be read.
          Container(color: const Color(0xFF0A1F14).withValues(alpha: 0.55)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = holes.length <= 6 ? 2 : 3;
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: holes.length,
                  itemBuilder: (context, index) => _Hole(
                    item: holes[index],
                    hit: hits[index],
                    onTap: () => onTap(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One hole, and whatever is coming out of it.
///
/// # What this replaced
///
/// A rounded rectangle containing **one static frame of the Goomba** and a
/// label. It did not move when a thing appeared, did not move when a thing
/// left, and did not react to being tapped. Nine holes held nine identical
/// pictures.
///
/// # The three states
///
///  * **empty** — a dark oval in the ground. A hole has to look like
///    somewhere a thing could come from, or the board reads as a grid of
///    cards.
///  * **up** — the sprite slides up from behind the rim over 180ms, using the
///    stretched `rise` frame for the first beat and settling on `idle`.
///    Clipped to the tile, so it genuinely emerges rather than fading in.
///  * **hit** — the squashed `hit` frame, a burst in green or red, and the
///    coins floating away.
///
/// # Why the sprite is chosen by hash
///
/// Four creatures, picked by `creatureFor(item.id)` — stable per item and
/// carrying no information about whether it is a leak. Making leaks look
/// different from real charges would be the obvious move and would delete
/// the entire lesson: the game would be winnable without reading a word.
class _Hole extends StatelessWidget {
  const _Hole({required this.item, required this.hit, required this.onTap});

  final LeakItem? item;
  final _Hit? hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = item != null;
    final resolved = hit;

    return GestureDetector(
      onTap: occupied && resolved == null ? onTap : null,
      // Opaque, so a tap anywhere in the cell counts. Hitting a 40px sprite
      // is a test of aim, and aim is not what this game is about.
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // The hole itself.
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 0.82,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF061A10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          if (occupied)
            Positioned.fill(
              bottom: 6,
              child: _Riser(item: item!, hit: resolved),
            ),
          if (resolved != null)
            Positioned(
              top: 0,
              child: _FloatingDelta(
                delta: resolved.delta,
                right: resolved.right,
              ),
            ),
        ],
      ),
    );
  }
}

/// The sprite coming up out of the hole, and its label.
class _Riser extends StatefulWidget {
  const _Riser({required this.item, required this.hit});

  final LeakItem item;
  final _Hit? hit;

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
    final creature = creatureFor(widget.item.id);
    final hit = widget.hit;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutBack
            .transform(_controller.value)
            .clamp(0.0, 1.2);
        // The stretched frame only for the first beat of the rise. Held any
        // longer it stops reading as motion and starts reading as a
        // differently-shaped creature.
        final pose = hit != null
            ? 'hit'
            : (_controller.value < 0.45 ? 'rise' : 'idle');

        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: Transform.translate(
              // Slides up from below the rim.
              offset: Offset(0, (1 - t) * 46),
              // **Label above, creature below.** The first build had these
              // the other way round, and rendering a mock of the board made
              // the fault obvious: the label chip sat *between* the sprite
              // and the hole, so nothing appeared to come out of anything.
              // The creature floated above a caption above a hole.
              //
              // The creature's feet have to meet the rim or this is not a
              // whack-a-mole, it is a grid of cards with pictures on them —
              // which is what it was.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The label is the game. This is the part that has to be
                  // legible in the second it is up.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06251A).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.item.label,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.numeric(
                        color: Colors.white,
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (hit != null) _Burst(right: hit.right),
                        Image.asset(
                          creature.frame(pose),
                          height: 46,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.savings_rounded,
                            color: Colors.white70,
                            size: 36,
                          ),
                        ),
                      ],
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

/// The impact burst. Green for a leak caught, red for a charge cancelled by
/// mistake.
///
/// Drawn here rather than baked into the sprite sheet, which is where it
/// started. A baked burst can only be one colour, and the frame a player
/// looks at hardest is the one right after they tap — which makes it the
/// best place in the game to say whether they were right.
class _Burst extends StatelessWidget {
  const _Burst({required this.right});

  final bool right;

  @override
  Widget build(BuildContext context) {
    // Wider than the sprite it sits behind. The hit frame is squashed
    // *outwards*, so a burst sized to the idle pose disappears underneath it
    // — which is what the first render showed: eight spikes, all hidden.
    return SizedBox(
      width: 84,
      height: 84,
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
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Eight spikes, alternating length. Even spikes read as a gear; uneven
    // ones read as an impact.
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final inner = i.isEven ? 24.0 : 20.0;
      final outer = i.isEven ? 39.0 : 30.0;
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

/// The coins, floating up and fading.
///
/// A number that appears where the thing was is the only feedback that
/// answers "how much did that cost me" at the moment it is being asked. The
/// HUD total answers it too, several seconds later, by which time the player
/// has stopped connecting the two.
class _FloatingDelta extends StatefulWidget {
  const _FloatingDelta({required this.delta, required this.right});

  final int delta;
  final bool right;

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
            style: AppTheme.numeric(
              color: colour,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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
    return SingleChildScrollView(
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
          _Line('Real charges you cancelled', '${result.wronglyTapped}'),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.numeric(
                color: AppTheme.textMuted,
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
