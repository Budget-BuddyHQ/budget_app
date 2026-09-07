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
import '../../../widgets_custom_lotties/fitted_label.dart';

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
      _caught = _missed = _wrong = _saved = _lost = 0;
      _holes = List<LeakItem?>.filled(_round.holes, null);
      _resolved.clear();
    });

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish();
    });

    _spawner = Timer.periodic(Duration(milliseconds: _round.popMillis), (_) {
      if (!mounted || !_running) return;
      _popOne();
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
      Duration(milliseconds: _round.visibleMillis),
      () {
        if (!mounted) return;
        // Gone before it was dealt with. A missed *leak* costs nothing
        // directly — the money simply kept leaving — which is why the
        // results card counts misses separately from mistakes.
        final wasLeak = _holes[hole]?.isLeak ?? false;
        setState(() {
          if (!_resolved.contains(hole) && wasLeak) _missed++;
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
        _saved += item.value;
        AppSoundService.play(AppSoundEffect.success);
      } else {
        // The expensive mistake, and the one the game exists to create.
        // Everyone arrives believing vigilance means tapping everything.
        _wrong++;
        _lost += item.value;
        AppSoundService.play(AppSoundEffect.error);
      }
      _holes[hole] = null;
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

    await context.read<UserStatsController>().applyChallengePayload(
      <String, dynamic>{
        'gold_earned': payout,
        'xp_earned': result.caught * 2,
        'literacy_points_earned': result.caught > 0 ? 2 : 0,
        'title': 'Leak Patrol',
        'description':
            'Caught ${result.caught}, cancelled ${result.wronglyTapped} real '
            'charges by mistake.',
      },
    );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _Hud(
                seconds: _secondsLeft,
                caught: _caught,
                wrong: _wrong,
                net: _saved - _lost,
                running: _running,
              ),
              const SizedBox(height: 12),
              if (_lastItem != null && _running)
                _WhyBanner(item: _lastItem!, wasRight: _lastWasRight),
              Expanded(
                child: _running
                    ? _Board(holes: _holes, onTap: _tap)
                    : _finished
                    ? _Results(result: _result!, onAgain: _start)
                    : _Intro(round: _round, onStart: _start),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.round, required this.onStart});

  final LeakRound round;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap the money leaving.\nLeave the money you owe.',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Subscriptions you stopped using, fees, offers that were never '
            'offers — tap those. Rent, food and money moving to savings are '
            'not leaks, and cancelling them costs you more than catching a '
            'leak is worth.',
            style: AppTheme.numeric(
              color: AppTheme.textMuted,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            // Said out loud, because the age scaling is invisible otherwise
            // and a player who has watched somebody older play will notice
            // the difference.
            '${round.seconds} seconds, at a speed set for your age.',
            style: AppTheme.numeric(
              color: AppTheme.greenPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.greenPrimary,
                foregroundColor: const Color(0xFF06251A),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
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

class _Hud extends StatelessWidget {
  const _Hud({
    required this.seconds,
    required this.caught,
    required this.wrong,
    required this.net,
    required this.running,
  });

  final int seconds;
  final int caught;
  final int wrong;
  final int net;
  final bool running;

  @override
  Widget build(BuildContext context) {
    if (!running) return const SizedBox.shrink();
    return Row(
      children: [
        _Stat(label: 'TIME', value: '$seconds', accent: const Color(0xFF58C7FF)),
        const SizedBox(width: 8),
        _Stat(
          label: 'CAUGHT',
          value: '$caught',
          accent: AppTheme.greenPrimary,
        ),
        const SizedBox(width: 8),
        _Stat(
          label: 'WRONG',
          value: '$wrong',
          accent: const Color(0xFFFF8474),
        ),
        const SizedBox(width: 8),
        _Stat(
          label: 'SAVED',
          value: '$net',
          accent: const Color(0xFFFFD45C),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.accent,
  });

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
    final accent = wasRight
        ? AppTheme.greenPrimary
        : const Color(0xFFFF8474);
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

class _Board extends StatelessWidget {
  const _Board({required this.holes, required this.onTap});

  final List<LeakItem?> holes;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across on a phone, four when there is room. Fixed columns
        // rather than a fixed cell size, so the board always fills the space
        // and never scrolls — a hole you have to scroll to is a hole you
        // cannot hit in time.
        final columns = constraints.maxWidth > 520 ? 4 : 3;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: holes.length,
          itemBuilder: (context, index) =>
              _Hole(item: holes[index], onTap: () => onTap(index)),
        );
      },
    );
  }
}

class _Hole extends StatelessWidget {
  const _Hole({required this.item, required this.onTap});

  final LeakItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = item != null;
    return GestureDetector(
      onTap: occupied ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: occupied
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: occupied
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: occupied
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.goombaWalk,
                    height: 42,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.savings_rounded,
                      color: Colors.white70,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Center(
                      child: Text(
                        item!.label,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.numeric(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
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
