import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models_Like_Skins_and_lessons_templates/park_activity_models.dart';
import '../../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import '../../../navigation_tools_and_animation/pauses_in_background.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../themes_colors/app_theme.dart';

/// The park, with something to actually do in it.
///
/// **What this replaced.** Three sentences and three buttons, in the one
/// place on the map a player goes to for fun. The buildings around it all
/// pose a real question now, and the park was still a menu.
///
/// It keeps the conversation — "sit and talk" is a first-class option and
/// pays what it always did — and adds two games that run inside the dialogue
/// panel rather than on a screen of their own. Staying in the panel matters:
/// the player walked here, and being thrown into a full-screen game would
/// lose the town around them.
class ParkActivityPanel extends StatefulWidget {
  const ParkActivityPanel({
    super.key,
    required this.spot,
    required this.band,
    required this.onTalk,
    required this.onFinish,
    this.random,
  });

  final TownSpot spot;

  /// Drives the speed. See [ParkPacing].
  final AgeBand band;

  /// Switches to the ordinary conversation for this spot.
  final VoidCallback onTalk;

  /// Hands the reward back through the town's normal payout path.
  final void Function(TownChoice choice) onFinish;

  /// Seeded in tests so a round is repeatable.
  final Random? random;

  @override
  State<ParkActivityPanel> createState() => _ParkActivityPanelState();
}

class _ParkActivityPanelState extends State<ParkActivityPanel> {
  ParkActivity? _playing;
  ParkReward? _done;

  void _finished(ParkReward reward) {
    setState(() {
      _playing = null;
      _done = reward;
    });
  }

  void _take() {
    final reward = _done!;
    widget.onFinish(
      TownChoice(
        label: 'Played in the park',
        outcome: reward.outcome,
        gold: reward.gold,
        xp: reward.xp,
        literacy: reward.literacy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pacing = ParkPacing.forBand(widget.band);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.park_rounded, color: Color(0xFF9BE870)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.spot.title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_done != null)
            _RewardCard(reward: _done!, onTake: _take)
          else if (_playing == ParkActivity.coinRush)
            _CoinRush(
              pacing: pacing,
              random: widget.random,
              onFinish: _finished,
            )
          else if (_playing == ParkActivity.priceDash)
            _PriceDash(
              pacing: pacing,
              random: widget.random,
              onFinish: _finished,
            )
          else
            _ActivityMenu(
              onPlay: (activity) => setState(() => _playing = activity),
              onTalk: widget.onTalk,
            ),
        ],
      ),
    );
  }
}

class _ActivityMenu extends StatelessWidget {
  const _ActivityMenu({required this.onPlay, required this.onTalk});

  final void Function(ParkActivity activity) onPlay;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The games here are free. Pick one.',
          style: AppTheme.numeric(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        for (final activity in ParkActivity.values) ...[
          _ActivityCard(activity: activity, onPlay: () => onPlay(activity)),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onTalk,
            icon: const Icon(Icons.chat_bubble_rounded, size: 16),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            label: Text(
              'Sit and talk instead',
              style: AppTheme.numeric(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onPlay});

  final ParkActivity activity;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final accent = activity == ParkActivity.coinRush
        ? const Color(0xFFFFD45C)
        : const Color(0xFF7FD3FF);
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                activity == ParkActivity.coinRush
                    ? Icons.touch_app_rounded
                    : Icons.local_offer_rounded,
                color: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      activity.blurb,
                      style: AppTheme.numeric(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.onTake});

  final ParkReward reward;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reward.outcome,
          style: AppTheme.numeric(
            color: Colors.white,
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RewardChip(
              label: '+${reward.gold} gold',
              color: const Color(0xFFFFD45C),
            ),
            _RewardChip(
              label: '+${reward.literacy} literacy',
              color: const Color(0xFF9BE870),
            ),
            _RewardChip(
              label: '+${reward.xp} XP',
              color: const Color(0xFF7FD3FF),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.greenPrimary,
              foregroundColor: AppTheme.deepForest,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onTake,
            child: Text(
              'Head back out',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTheme.numeric(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coin Rush
// ---------------------------------------------------------------------------

/// One thing on its way down the play area.
class _Falling {
  _Falling({required this.id, required this.kind, required this.x});

  final int id;
  final FallingKind kind;

  /// Across the play area, 0 to 1.
  final double x;

  /// Down the play area, 0 to 1.
  double t = 0;

  bool tapped = false;
}

/// Tap the coins, leave the fees.
///
/// Movement is driven by a [Ticker] rather than a timer, so it stops with the
/// frames when the app leaves the screen. The round clock is a timer, which
/// does not, so it is paused by hand. See [PausesInBackground].
class _CoinRush extends StatefulWidget {
  const _CoinRush({required this.pacing, required this.onFinish, this.random});

  final ParkPacing pacing;
  final void Function(ParkReward reward) onFinish;
  final Random? random;

  @override
  State<_CoinRush> createState() => _CoinRushState();
}

class _CoinRushState extends State<_CoinRush>
    with SingleTickerProviderStateMixin, PausesInBackground {
  static const double _areaHeight = 210;

  late final Random _random = widget.random ?? Random();
  late final Ticker _ticker = createTicker(_onFrame);
  Timer? _clock;

  final List<_Falling> _items = <_Falling>[];
  int _nextId = 0;
  Duration _lastFrame = Duration.zero;
  double _sinceSpawn = 0;

  int _secondsLeft = 0;
  int _collected = 0;
  int _fees = 0;
  int _missed = 0;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.pacing.seconds;
    _ticker.start();
    _startClock();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish();
    });
  }

  @override
  void onAppBackgrounded() {
    _clock?.cancel();
    _clock = null;
  }

  @override
  void onAppForegrounded() {
    if (_over || _clock != null) return;
    // The ticker restarted itself with the frames; the clock did not.
    _lastFrame = Duration.zero;
    _startClock();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _onFrame(Duration elapsed) {
    if (_over) return;
    final dt = _lastFrame == Duration.zero
        ? 0.0
        : (elapsed - _lastFrame).inMicroseconds / 1000000.0;
    _lastFrame = elapsed;
    // A long frame, which is what coming back from the background looks like,
    // must not teleport everything off the bottom at once.
    final step = dt.clamp(0.0, 0.05);

    _sinceSpawn += step;
    final gap = widget.pacing.spawnMillis / 1000;
    var spawned = false;
    if (_sinceSpawn >= gap) {
      _sinceSpawn = 0;
      _items.add(
        _Falling(
          id: _nextId++,
          kind: rollFalling(_random),
          x: 0.08 + _random.nextDouble() * 0.84,
        ),
      );
      spawned = true;
    }

    var changed = spawned;
    for (final item in _items) {
      item.t += step / widget.pacing.fallSeconds;
    }
    final gone = _items.where((i) => i.t >= 1).toList(growable: false);
    for (final item in gone) {
      if (!item.tapped && item.kind != FallingKind.fee) _missed++;
      _items.remove(item);
      changed = true;
    }
    if (changed || step > 0) setState(() {});
  }

  void _tap(_Falling item) {
    if (item.tapped || _over) return;
    setState(() {
      item.tapped = true;
      final value = valueOf(item.kind);
      if (item.kind == FallingKind.fee) {
        _fees++;
        _collected = max(0, _collected + value);
        AppSoundService.play(AppSoundEffect.error);
      } else {
        _collected += value;
        AppSoundService.play(AppSoundEffect.needPickup);
      }
      _items.remove(item);
    });
  }

  void _finish() {
    if (_over) return;
    _over = true;
    _clock?.cancel();
    _ticker.stop();
    widget.onFinish(
      scoreCoinRush(
        collected: _collected,
        feesTapped: _fees,
        coinsMissed: _missed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Tally(label: 'TIME', value: '${_secondsLeft}s'),
            const SizedBox(width: 8),
            _Tally(label: 'COINS', value: '$_collected'),
            const SizedBox(width: 8),
            _Tally(label: 'FEES', value: '$_fees'),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: _areaHeight,
            width: double.infinity,
            color: const Color(0xFF18252B),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    for (final item in _items)
                      Positioned(
                        left: item.x * (constraints.maxWidth - 46),
                        top: item.t * (_areaHeight - 46),
                        child: GestureDetector(
                          onTap: () => _tap(item),
                          behavior: HitTestBehavior.opaque,
                          child: _FallingChip(kind: item.kind),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Coins and gems are yours. Fees cost you.',
          style: AppTheme.numeric(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FallingChip extends StatelessWidget {
  const _FallingChip({required this.kind});

  final FallingKind kind;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (kind) {
      FallingKind.coin => (
        const Color(0xFFFFD45C),
        Icons.savings_rounded,
        '+2',
      ),
      FallingKind.gem => (const Color(0xFF9BE870), Icons.diamond_rounded, '+5'),
      FallingKind.fee => (
        const Color(0xFFFF8474),
        Icons.receipt_long_rounded,
        'fee',
      ),
    };
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          Text(
            label,
            style: AppTheme.numeric(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.caps(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTheme.numeric(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price Dash
// ---------------------------------------------------------------------------

/// Which pack is cheaper per unit, against a clock.
class _PriceDash extends StatefulWidget {
  const _PriceDash({required this.pacing, required this.onFinish, this.random});

  final ParkPacing pacing;
  final void Function(ParkReward reward) onFinish;
  final Random? random;

  @override
  State<_PriceDash> createState() => _PriceDashState();
}

class _PriceDashState extends State<_PriceDash> with PausesInBackground {
  late final List<PricePair> _questions;
  Timer? _clock;
  int _index = 0;
  int _correct = 0;
  int _secondsLeft = 0;
  bool? _lastWasRight;

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? Random();
    final pool = List<PricePair>.from(kPricePairs)..shuffle(random);
    _questions = pool.take(widget.pacing.rounds).toList(growable: false);
    _secondsLeft = widget.pacing.questionSeconds;
    _startClock();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      // Out of time counts as a miss, which is the point of a dash.
      if (_secondsLeft <= 0) _answer(null);
    });
  }

  @override
  void onAppBackgrounded() {
    _clock?.cancel();
    _clock = null;
  }

  @override
  void onAppForegrounded() {
    if (_clock == null && mounted && _index < _questions.length) _startClock();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _answer(bool? choseBig) {
    final pair = _questions[_index];
    final right = choseBig != null && choseBig == pair.bigIsCheaper;
    if (right) {
      _correct++;
      AppSoundService.play(AppSoundEffect.success);
    } else {
      AppSoundService.play(AppSoundEffect.error);
    }
    setState(() => _lastWasRight = right);

    if (_index + 1 >= _questions.length) {
      _clock?.cancel();
      widget.onFinish(
        scorePriceDash(correct: _correct, total: _questions.length),
      );
      return;
    }
    setState(() {
      _index++;
      _secondsLeft = widget.pacing.questionSeconds;
    });
    _startClock();
  }

  @override
  Widget build(BuildContext context) {
    final pair = _questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The item leads, the tallies follow. Also keeps the all-caps tally
        // labels away from the Pixelify title, whose capitals are confusable
        // enough that `caps_legibility_test` bans the combination.
        Text(
          pair.item,
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Tally(
              label: 'QUESTION',
              value: '${_index + 1}/${_questions.length}',
            ),
            const SizedBox(width: 8),
            _Tally(label: 'TIME', value: '${_secondsLeft}s'),
            const SizedBox(width: 8),
            _Tally(label: 'RIGHT', value: '$_correct'),
          ],
        ),
        const SizedBox(height: 12),
        _PackButton(
          label: pair.smallLabel,
          price: pair.smallPrice,
          onTap: () => _answer(false),
        ),
        const SizedBox(height: 8),
        _PackButton(
          label: pair.bigLabel,
          price: pair.bigPrice,
          onTap: () => _answer(true),
        ),
        const SizedBox(height: 8),
        Text(
          _lastWasRight == null
              ? 'Work out what each one costs per ${pair.unit}.'
              : _lastWasRight!
              ? 'Right.'
              : 'Not that one.',
          style: AppTheme.numeric(
            color: _lastWasRight == false
                ? const Color(0xFFFF8474)
                : Colors.white.withValues(alpha: 0.75),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PackButton extends StatelessWidget {
  const _PackButton({
    required this.label,
    required this.price,
    required this.onTap,
  });

  final String label;
  final double price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.numeric(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: AppTheme.numeric(
                  color: const Color(0xFFFFD45C),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
