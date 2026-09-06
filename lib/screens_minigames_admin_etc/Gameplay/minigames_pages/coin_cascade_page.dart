import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/coin_cascade_models.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/pixel_kit.dart';

/// Coin Cascade — the arcade's game for everybody.
///
/// The rules fit on the card: swap two neighbours, line up three, needs pay
/// your bills, wants raise them, savings win the run. A four-year-old can play
/// it by matching pictures and will absorb the shape of the lesson anyway;
/// a teenager will notice they are being asked to budget their *moves*.
///
/// The engine ([CoinCascadeGame]) is pure Dart and separately tested. This
/// file is the presentation: it drives the cascade one step at a time so the
/// board can be watched falling rather than teleporting to its final state.
///
/// **What the run is worth is paid here**, not by the caller. See
/// [CascadeCloseResult] for the bug that made that necessary.

/// What a finished session was worth, handed back to the arcade hub.
///
/// **The bug this exists to close.** The page used to pop the
/// `CoinCascadeGame` itself, and `MinigamesPage._openCoinCascade` announced
/// "+N gold" in a toast — then called `recordArcadeRun`, whose own
/// documentation says in as many words that it *must not touch gold or XP*.
/// Nothing anywhere called `applyChallengePayload`. So the game computed a
/// payout, printed it twice — once on the result card, once in the toast —
/// and paid none of it, for every run anybody had ever played.
///
/// That is the literal answer to "I don't even know what to work for in that
/// game". There was nothing to work for, and the game had been telling
/// players there was.
class CascadeCloseResult {
  const CascadeCloseResult({
    required this.game,
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyEarned,
    required this.isRush,
    required this.isNewRushBest,
  });

  final CoinCascadeGame game;
  final int goldEarned;
  final int xpEarned;
  final int literacyEarned;
  final bool isRush;
  final bool isNewRushBest;
}

class CoinCascadePage extends StatefulWidget {
  const CoinCascadePage({super.key, this.debugInitialGame});

  /// A board to open on instead of a fresh level 1.
  ///
  /// Same shape as `LifeSimPage.debugInitialLife`, and there for the same
  /// reason: the interesting states of this screen are the ones at the *end*
  /// of a run, and there is no way to reach them from a render test without
  /// playing a game that has randomness in it.
  final CoinCascadeGame? debugInitialGame;

  @override
  State<CoinCascadePage> createState() => _CoinCascadePageState();
}

class _CoinCascadePageState extends State<CoinCascadePage> {
  late CoinCascadeGame _game;

  /// Cell the player has picked, waiting for its partner.
  Point<int>? _selected;

  /// True while a cascade is resolving. Input is ignored during it — a swap
  /// accepted mid-fall would be applied to a board the player cannot see.
  bool _busy = false;

  /// Cells clearing right now, so they can flash before they vanish.
  Set<Point<int>> _clearing = const {};

  /// The banner over the board: "3x chain!", "+4 saved", and so on.
  String? _flash;
  Color _flashColor = AppTheme.greenPrimary;
  Timer? _flashTimer;

  bool _finished = false;

  /// Highest level the player has ever cleared, loaded from their save.
  ///
  /// The old comment defending a session-scoped version argued that
  /// persisting it would hand a returning player level 7 with no idea what
  /// the earlier rules were. That worry is real and this is not the thing
  /// that causes it: the picker still opens on the ladder in order, so an
  /// unlocked level is somewhere you *may* go rather than where you are put.
  /// What the session scope actually did was delete thirteen levels of
  /// progress every time somebody left the arcade.
  int _clearedThrough = 0;

  /// The next level that is playable. Always at least 1.
  int get _unlocked => (_clearedThrough + 1).clamp(1, kCascadeLevels.length);

  // --- Payday Rush ------------------------------------------------------
  //
  // Two timers rather than one. They are genuinely different clocks: the
  // countdown is the run's length and ticks once a second for the display,
  // and the bill schedule fires every few seconds regardless of what the
  // display is doing. Deriving one from the other would tie how often the
  // month arrives to how often the number on screen changes, which is the
  // kind of coupling that turns a UI tweak into a difficulty change.
  Timer? _rushTicker;
  Timer? _rushBills;
  int _rushSecondsLeft = 0;

  bool get _isRush => _game.level.mode == CascadeMode.rush;

  /// Totals for the run that just ended, so the result card can show them.
  int _awardedGold = 0;
  int _awardedXp = 0;
  int _awardedLiteracy = 0;
  bool _newRushBest = false;

  /// True between the run ending and the payout coming back.
  ///
  /// `_award` writes to the account, which is a network call. The card is on
  /// screen before it returns, and drawing zeros in that window would be a
  /// worse lie than the one this whole change is fixing: a player would see
  /// "+0 gold" and a note telling them replays pay less, on a level they had
  /// just cleared for the first time.
  bool _awardPending = false;

  @override
  void initState() {
    super.initState();
    _clearedThrough = context
        .read<UserStatsController>()
        .stats
        .cascadeClearedThrough;
    _game =
        widget.debugInitialGame ?? CoinCascadeGame(level: kCascadeLevels.first);
    _finished = _game.status != CascadeStatus.playing;
  }

  void _startLevel(int number) {
    _stopRushClocks();
    setState(() {
      _finished = false;
      _selected = null;
      _clearing = const {};
      _flash = null;
      _awardedGold = 0;
      _awardedXp = 0;
      _awardedLiteracy = 0;
      _newRushBest = false;
      _awardPending = false;
      _game = CoinCascadeGame(level: cascadeLevelFor(number));
    });
  }

  void _startRush() {
    _stopRushClocks();
    setState(() {
      _finished = false;
      _selected = null;
      _clearing = const {};
      _flash = null;
      _awardedGold = 0;
      _awardedXp = 0;
      _awardedLiteracy = 0;
      _newRushBest = false;
      _awardPending = false;
      _game = CoinCascadeGame(level: kCascadeRush);
      _rushSecondsLeft = kCascadeRush.seconds;
    });

    _rushTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _rushSecondsLeft--);
      if (_rushSecondsLeft <= 0) _endRush();
    });
    _rushBills = Timer.periodic(kRushBillInterval, (_) {
      if (!mounted || _finished) return;
      setState(_game.dropScheduledBill);
      // A bill can push the run past its capacity, which ends it — the same
      // loss condition as the ladder, arriving on a clock instead of a turn.
      _checkFinished();
    });
  }

  void _stopRushClocks() {
    _rushTicker?.cancel();
    _rushTicker = null;
    _rushBills?.cancel();
    _rushBills = null;
  }

  /// The clock ran out. Not a loss — a Rush is scored, not passed.
  void _endRush() {
    _stopRushClocks();
    if (_finished) return;
    _finished = true;
    AppSoundService.play(AppSoundEffect.celebration);
    unawaited(_award());
    setState(() {});
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _stopRushClocks();
    super.dispose();
  }

  void _say(String message, Color colour) {
    _flashTimer?.cancel();
    setState(() {
      _flash = message;
      _flashColor = colour;
    });
    _flashTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  Future<void> _tapCell(int col, int row) async {
    if (_busy || _game.status != CascadeStatus.playing) return;

    final current = _selected;
    if (current == null) {
      AppSoundService.play(AppSoundEffect.selection);
      setState(() => _selected = Point(col, row));
      return;
    }

    if (current.x == col && current.y == row) {
      setState(() => _selected = null);
      return;
    }

    final adjacent = (current.x - col).abs() + (current.y - row).abs() == 1;
    if (!adjacent) {
      // Treat a far tap as picking a new tile rather than as an error. On a
      // small phone a mis-tap is common, and a buzz for it teaches the player
      // to be careful with a mechanic that has no penalty.
      AppSoundService.play(AppSoundEffect.selection);
      setState(() => _selected = Point(col, row));
      return;
    }

    setState(() => _selected = null);
    await _attemptSwap(current.x, current.y, col, row);
  }

  Future<void> _attemptSwap(int c1, int r1, int c2, int r2) async {
    if (!_game.trySwap(c1, r1, c2, r2)) {
      HapticFeedback.selectionClick();
      _say('No match there', AppTheme.textMuted);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    await _resolve();
    if (!mounted) return;
    setState(() => _busy = false);
    _checkFinished();
  }

  /// Steps the cascade with a pause between links, so each one is visible.
  Future<void> _resolve() async {
    var cascade = 0;
    while (true) {
      // Peek before clearing: the cells about to go get a flash frame, which
      // is what makes a match read as an event rather than as tiles blinking
      // out of existence.
      final outcome = _game.step(cascade: cascade);
      if (outcome.isEmpty) break;

      setState(() {
        _clearing = {for (final c in outcome.clears) ...c.cells};
      });
      AppSoundService.play(
        cascade == 0 ? AppSoundEffect.needPickup : AppSoundEffect.success,
      );
      _describe(outcome, cascade);

      await Future<void>.delayed(const Duration(milliseconds: 190));
      if (!mounted) return;
      setState(() => _clearing = const {});
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      cascade++;
    }
  }

  void _describe(CascadeOutcome outcome, int cascade) {
    if (cascade > 0) {
      _say('${cascade + 1}x chain!', const Color(0xFFFFD45C));
      return;
    }
    if (outcome.savings > 0) {
      _say('+${outcome.savings} saved', const Color(0xFF69C6FF));
    } else if (outcome.billsAdded > 0) {
      _say('Wants cost you +${outcome.billsAdded}', const Color(0xFFFF8FB1));
    } else if (outcome.billsPaid > 0) {
      _say('Bills down ${outcome.billsPaid}', AppTheme.greenPrimary);
    } else if (outcome.coins > 0) {
      _say('+${outcome.coins} coins', const Color(0xFFFFD45C));
    }
  }

  void _checkFinished() {
    if (_finished || _game.status == CascadeStatus.playing) return;
    _finished = true;
    _stopRushClocks();
    unawaited(_award());
    AppSoundService.play(
      _game.status == CascadeStatus.won
          ? AppSoundEffect.celebration
          : AppSoundEffect.error,
    );
    // The result sheet is pushed rather than shown as a dialog so the board
    // stays visible behind it — a player wants to see the board they finished
    // on, not a scrim over it.
    Future<void>.delayed(const Duration(milliseconds: 380), () {
      if (mounted) setState(() {});
    });
  }

  void _restart() => _isRush ? _startRush() : _startLevel(_game.level.number);

  /// Pays out the run, and saves the ladder progress it earned.
  ///
  /// **Why the split between a first clear and a replay.** Level 1 takes
  /// about ninety seconds and can be cleared over and over; paying it in full
  /// every time would make grinding the easiest level the fastest way to earn
  /// in the whole app, which teaches the opposite of everything else here.
  /// Paying a replay *nothing* is the other failure — it turns "play the bit
  /// you enjoy" into a waste of time, and the ladder is meant to be
  /// replayable.
  ///
  /// So a first clear pays properly and a replay pays a token. It is the same
  /// rule the town uses for encounters that have already been resolved, and
  /// for the same reason: reward the progress, not the repetition.
  ///
  /// Literacy points are first-clear only, with no token version. They are
  /// the app's measure of *what you have learned*, and each level teaches one
  /// specific twist — bills arriving faster, wants costing double. Replaying
  /// a level you have solved does not teach you its rule a second time.
  Future<void> _award() async {
    setState(() => _awardPending = true);
    final controller = context.read<UserStatsController>();
    final game = _game;
    final report = game.report;

    final CascadePayout payout;
    var newBest = false;

    if (_isRush) {
      final previousBest = controller.stats.bestArcadeScore(
        'coin_cascade_rush',
      );
      newBest = game.savings > (previousBest ?? 0);
      payout = cascadePayoutFor(game, newRushBest: newBest);
      await controller.recordArcadeRun(
        gameId: 'coin_cascade_rush',
        score: game.savings,
      );
    } else {
      final firstClear =
          game.status == CascadeStatus.won &&
          game.level.number > _clearedThrough;
      payout = cascadePayoutFor(game, firstClear: firstClear);
      if (firstClear) {
        _clearedThrough = game.level.number;
      }
      await controller.recordArcadeRun(
        gameId: 'coin_cascade',
        score: game.score,
      );
    }

    // One payload for the money and the progress together, so a player who
    // closes the app mid-save cannot end up with the gold and not the unlock
    // or the other way round.
    await controller.applyChallengePayload(<String, dynamic>{
      'gold_earned': payout.gold,
      'xp_earned': payout.xp,
      'literacy_points_earned': payout.literacy,
      'title': 'Coin Cascade',
      'description': _isRush
          ? 'Payday Rush: ${report.savesPercent}% of the board went to '
                'savings.'
          : 'Coin Cascade level ${game.level.number}.',
      'spending_habits': <String, dynamic>{'cascade_cleared': _clearedThrough},
    });

    if (!mounted) return;
    setState(() {
      _awardedGold = payout.gold;
      _awardedXp = payout.xp;
      _awardedLiteracy = payout.literacy;
      _newRushBest = newBest;
      _awardPending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // `_finished` as well as the status: a Rush ends on the clock, and the
    // clock is not something the engine knows about, so its status is still
    // `playing` when the run is over.
    final done = _finished || _game.status != CascadeStatus.playing;

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: AppTheme.deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Coin Cascade',
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'How to play',
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CascadeHud(game: _game),
            _LevelBanner(
              level: _game.level,
              unlocked: _unlocked,
              secondsLeft: _isRush ? _rushSecondsLeft : null,
              onPick: _startLevel,
              onRush: _startRush,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _Board(
                      game: _game,
                      selected: _selected,
                      clearing: _clearing,
                      onTap: _tapCell,
                      onSwipe: (from, to) async {
                        if (_busy || done) return;
                        setState(() => _selected = null);
                        await _attemptSwap(from.x, from.y, to.x, to.y);
                      },
                    ),
                  ),
                  if (_flash != null)
                    IgnorePointer(
                      child: _FlashBanner(text: _flash!, colour: _flashColor),
                    ),
                  if (done)
                    _ResultCard(
                      game: _game,
                      gold: _awardedGold,
                      xp: _awardedXp,
                      literacy: _awardedLiteracy,
                      awardPending: _awardPending,
                      isNewRushBest: _newRushBest,
                      hasNext:
                          !_isRush &&
                          _game.status == CascadeStatus.won &&
                          _game.level.number < kCascadeLevels.length,
                      onNext: () => _startLevel(_game.level.number + 1),
                      onAgain: _restart,
                      onLeave: () => Navigator.of(context).pop(
                        CascadeCloseResult(
                          game: _game,
                          goldEarned: _awardedGold,
                          xpEarned: _awardedXp,
                          literacyEarned: _awardedLiteracy,
                          isRush: _isRush,
                          isNewRushBest: _newRushBest,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _CascadeFooter(
              game: _game,
              onBuyMoves: () {
                if (!_game.buyMoves()) return;
                AppSoundService.play(AppSoundEffect.success);
                _say(
                  '+${CoinCascadeGame.extraMovesPerPurchase} moves',
                  AppTheme.greenPrimary,
                );
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: PixelFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match three',
                style: GoogleFonts.pixelifySans(
                  color: PixelFrameStyle.slate.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              for (final kind in TileKind.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kind.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _helpFor(kind),
                          style: GoogleFonts.quicksand(
                            color: PixelFrameStyle.slate.inkMuted,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: PixelButton(
                  label: 'Got it',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _helpFor(TileKind kind) => switch (kind) {
    TileKind.need => 'Needs pay your bills down. Cover these first.',
    TileKind.want => 'Wants score big — and add to what you owe.',
    TileKind.save => 'Savings are how you win. Fill the goal bar.',
    TileKind.coin => 'Coins buy extra moves when you run low.',
    TileKind.bill => 'Bills turn up on their own. Clear them or they pile up.',
  };
}

/// Score, goal, bills and moves.
/// The level name, its one-line rule, and a way back to earlier levels.
///
/// The rule is on screen the whole time rather than shown once at the start.
/// "Every want match adds twice the bills" is the thing the player is supposed
/// to be reasoning about, and a rule you have to remember from a dialog is a
/// rule you play the first two minutes without.
class _LevelBanner extends StatelessWidget {
  const _LevelBanner({
    required this.level,
    required this.unlocked,
    required this.secondsLeft,
    required this.onPick,
    required this.onRush,
  });

  final CascadeLevel level;
  final int unlocked;

  /// Null outside Payday Rush.
  final int? secondsLeft;
  final ValueChanged<int> onPick;
  final VoidCallback onRush;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(const Color(0xFFFFD45C), alpha: 0.18);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: chip.fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Slightly brighter border and thicker stroke for visibility
            color: const Color(0xFFFFD45C).withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedLabel(
                    level.mode == CascadeMode.rush
                        ? level.name
                        : 'Level ${level.number} · ${level.name}',
                    style: GoogleFonts.pixelifySans(
                      color: chip.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.rule,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The clock, where the level number would otherwise be. It is the
            // only number that matters in a Rush and it belongs next to the
            // rule that explains it, not buried in the meters above.
            if (secondsLeft != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '0:${secondsLeft!.clamp(0, 999).toString().padLeft(2, '0')}',
                  style: GoogleFonts.pixelifySans(
                    color: secondsLeft! <= 10 ? AppTheme.errorRed : chip.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            PopupMenuButton<int>(
              tooltip: 'Pick a level',
              icon: Icon(Icons.list_rounded, size: 24, color: chip.ink),
              // -1 is Payday Rush. A sentinel rather than a second menu,
              // because a mode is a thing you pick from the same list as a
              // level — the alternative was a second control on a banner that
              // already has to fit on a phone.
              onSelected: (value) => value == -1 ? onRush() : onPick(value),
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  value: -1,
                  child: Text('⏱  ${kCascadeRush.name}  ·  90s'),
                ),
                const PopupMenuDivider(),
                for (final l in kCascadeLevels)
                  PopupMenuItem<int>(
                    value: l.number,
                    enabled: l.number <= unlocked,
                    child: Text(
                      'Level ${l.number} · ${l.name}'
                      '${l.number <= unlocked ? '' : '  (locked)'}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CascadeHud extends StatelessWidget {
  const _CascadeHud({required this.game});

  final CoinCascadeGame game;

  @override
  Widget build(BuildContext context) {
    final goal = (game.savings / game.savingsGoal).clamp(0.0, 1.0);
    final billed = (game.bills / game.billCapacity).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Meter(
                  emoji: TileKind.save.emoji,
                  label: 'Savings goal',
                  value: '${game.savings}/${game.savingsGoal}',
                  fraction: goal,
                  accent: TileKind.save.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Meter(
                  emoji: TileKind.bill.emoji,
                  label: 'Bills owed',
                  value: '${game.bills}/${game.billCapacity}',
                  fraction: billed,
                  accent: TileKind.bill.color,
                  // Bills fill *toward* a loss, so a full bar is bad. The
                  // colour is the only thing carrying that, which is why it
                  // is the one red thing on the screen.
                  danger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Pip(
                emoji: '🎯',
                label: 'Moves',
                value: '${game.movesLeft}',
                accent: game.movesLeft <= 3
                    ? const Color(0xFFFF8474)
                    : AppTheme.greenPrimary,
              ),
              const SizedBox(width: 8),
              _Pip(
                emoji: TileKind.coin.emoji,
                label: 'Coins',
                value: '${game.coins}',
                accent: const Color(0xFFFFD45C),
              ),
              const SizedBox(width: 8),
              _Pip(
                emoji: '⭐',
                label: 'Score',
                value: '${game.score}',
                accent: const Color(0xFF69C6FF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.emoji,
    required this.label,
    required this.value,
    required this.fraction,
    required this.accent,
    this.danger = false,
  });

  final String emoji;
  final String label;
  final String value;
  final double fraction;
  final Color accent;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(accent, alpha: 0.14);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: FittedLabel(
                  label,
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: GoogleFonts.pixelifySans(
                  color: chip.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 320),
              builder: (context, t, _) => LinearProgressIndicator(
                value: t,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(
                  danger && t > 0.7 ? const Color(0xFFFF8474) : accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String emoji;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(accent, alpha: 0.12);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: chip.fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Flexible(
              child: FittedLabel(
                '$label $value',
                style: GoogleFonts.pixelifySans(
                  color: chip.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The grid.
///
/// Laid out as a `Stack` of positioned tiles keyed by [Tile.id] rather than as
/// a `GridView`. The ids are stable across gravity, so `AnimatedPositioned`
/// makes a tile that dropped two rows actually *fall* two rows — in a grid of
/// index-keyed children the same event is a cross-fade between two squares,
/// which reads as the board flickering.
class _Board extends StatelessWidget {
  const _Board({
    required this.game,
    required this.selected,
    required this.clearing,
    required this.onTap,
    required this.onSwipe,
  });

  final CoinCascadeGame game;
  final Point<int>? selected;
  final Set<Point<int>> clearing;
  final void Function(int col, int row) onTap;
  final void Function(Point<int> from, Point<int> to) onSwipe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit the whole board in the space available, whichever axis is
        // tighter. A board that scrolls is a board you cannot plan on.
        final cell = min(
          constraints.maxWidth / game.columns,
          constraints.maxHeight / game.rows,
        );
        final width = cell * game.columns;
        final height = cell * game.rows;

        final tiles = <Widget>[];
        for (var row = 0; row < game.rows; row++) {
          for (var col = 0; col < game.columns; col++) {
            final tile = game.tileAt(col, row);
            if (tile == null) continue;
            final at = Point(col, row);
            tiles.add(
              AnimatedPositioned(
                key: ValueKey<int>(tile.id),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: col * cell,
                top: row * cell,
                width: cell,
                height: cell,
                child: _TileView(
                  tile: tile,
                  size: cell,
                  selected: selected == at,
                  clearing: clearing.contains(at),
                  onTap: () => onTap(col, row),
                  onSwipe: (delta) {
                    final to = Point(col + delta.x, row + delta.y);
                    if (!game.inBounds(to.x, to.y)) return;
                    onSwipe(at, to);
                  },
                ),
              ),
            );
          }
        }

        return Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Stack(children: tiles),
          ),
        );
      },
    );
  }
}

class _TileView extends StatefulWidget {
  const _TileView({
    required this.tile,
    required this.size,
    required this.selected,
    required this.clearing,
    required this.onTap,
    required this.onSwipe,
  });

  final Tile tile;
  final double size;
  final bool selected;
  final bool clearing;
  final VoidCallback onTap;
  final void Function(Point<int> delta) onSwipe;

  @override
  State<_TileView> createState() => _TileViewState();
}

class _TileViewState extends State<_TileView> {
  Offset _dragOffset = Offset.zero;
  bool _swiped = false;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(widget.tile.kind.color, alpha: 0.26);

    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (_) {
        _dragOffset = Offset.zero;
        _swiped = false;
      },
      onPanUpdate: (details) {
        if (_swiped) return;

        _dragOffset += details.delta;

        // Trigger swap once dragged past 25% of cell size
        final threshold = widget.size * 0.25;

        if (_dragOffset.dx.abs() > threshold ||
            _dragOffset.dy.abs() > threshold) {
          _swiped = true;
          if (_dragOffset.dx.abs() > _dragOffset.dy.abs()) {
            widget.onSwipe(Point(_dragOffset.dx > 0 ? 1 : -1, 0));
          } else {
            widget.onSwipe(Point(0, _dragOffset.dy > 0 ? 1 : -1));
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.all(widget.size * 0.06),
        child: AnimatedScale(
          scale: widget.clearing ? 1.25 : (widget.selected ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: widget.clearing ? 0.25 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: chip.fill,
                borderRadius: BorderRadius.circular(widget.size * 0.22),
                border: Border.all(
                  color: widget.selected
                      ? Colors.white
                      : widget.tile.kind.color.withValues(alpha: 0.45),
                  width: widget.selected ? 2.5 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  widget.tile.kind.emoji,
                  style: TextStyle(fontSize: widget.size * 0.44),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashBanner extends StatelessWidget {
  const _FlashBanner({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(colour, alpha: 0.22, target: 3.0);

    return Align(
      alignment: const Alignment(0, -0.82),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: chip.fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colour.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          style: GoogleFonts.pixelifySans(
            color: chip.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CascadeFooter extends StatelessWidget {
  const _CascadeFooter({required this.game, required this.onBuyMoves});

  final CoinCascadeGame game;
  final VoidCallback onBuyMoves;

  @override
  Widget build(BuildContext context) {
    final affordable = game.canBuyMoves;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // The one line of coaching on the screen, and it says the thing
              // the whole game is about.
              'Needs pay bills · Wants cost you · Savings win',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: PixelButton(
              label:
                  '+${CoinCascadeGame.extraMovesPerPurchase} · '
                  '${CoinCascadeGame.extraMoveCost}🪙',
              height: 46,
              onPressed: affordable ? onBuyMoves : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.game,
    required this.gold,
    required this.xp,
    required this.literacy,
    required this.awardPending,
    required this.isNewRushBest,
    required this.hasNext,
    required this.onNext,
    required this.onAgain,
    required this.onLeave,
  });

  final CoinCascadeGame game;

  /// What was actually paid into the account.
  ///
  /// **Not `game.goldEarned`.** That getter is the engine's own idea of what
  /// a run is worth, and it is what this card used to print — while nothing
  /// anywhere paid it. These come back from `_award`, after the payload has
  /// been applied, so the number on the card is the number in the wallet.
  final int gold;
  final int xp;
  final int literacy;

  /// True while the payout is still being written. See
  /// `_CoinCascadePageState._awardPending`.
  final bool awardPending;

  final bool isNewRushBest;

  /// False on the last level, on any loss, and in Payday Rush, so "Next"
  /// never offers a level that does not exist or one the player has not
  /// earned.
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onAgain;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final won = game.status == CascadeStatus.won;
    final rush = game.isTimed;
    final report = game.report;
    final style = PixelFrameStyle.slate;

    final String title;
    final String blurb;
    if (rush) {
      title = isNewRushBest ? 'New best!' : 'Time is up';
      blurb = game.bills >= game.billCapacity
          ? 'The bills buried you with ${game.savings} saved. They arrive '
                'whether or not you are ready — that is the whole mode.'
          : 'You banked ${game.savings} in ninety seconds.';
    } else if (won) {
      title = 'Goal reached!';
      blurb =
          'You covered your needs and still put ${game.savings} into savings.';
    } else {
      title = 'Out of moves';
      blurb = game.bills >= game.billCapacity
          ? 'The bills got ahead of you. Next time, clear needs before wants.'
          : 'You saved ${game.savings} of ${game.savingsGoal}. Coins buy '
                'extra moves — spend them earlier.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: PixelFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pixelifySans(
                    color: style.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  blurb,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: style.inkMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // The run, read back as a budget.
                //
                // This is the part that makes Coin Cascade *teach* rather than
                // merely encode. The mechanics were always 50/30/20; nothing
                // ever said so, so whether a player learned anything depended
                // on them noticing the pattern unprompted.
                const SizedBox(height: 16),
                _BudgetSplit(report: report),
                const SizedBox(height: 10),
                Text(
                  report.headline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: style.ink,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final line in report.detail) ...[
                  const SizedBox(height: 8),
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      color: style.inkMuted,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    for (final reward in <String>[
                      if (gold > 0) '+$gold gold',
                      if (xp > 0) '+$xp XP',
                      if (literacy > 0) '+$literacy LP',
                    ])
                      Text(
                        reward,
                        style: GoogleFonts.pixelifySans(
                          color: style.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                if (!rush && won && literacy == 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Replay pay — you had cleared this level already. '
                    'The next one pays in full.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      color: style.inkMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PixelButton(
                        // The primary action after a win is the next level, not
                        // a replay — a player who just cleared something wants
                        // the new rule, not the one they have solved.
                        label: hasNext ? 'Next' : 'Again',
                        onPressed: hasNext ? onNext : onAgain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PixelButton(
                        label: 'Done',
                        tone: PixelButtonTone.danger,
                        onPressed: onLeave,
                      ),
                    ),
                  ],
                ),
                if (hasNext) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAgain,
                    style: TextButton.styleFrom(
                      foregroundColor: style.inkMuted,
                    ),
                    child: const Text('Replay this level'),
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

/// Three bars: needs, wants, savings, as a share of the run.
///
/// Widths before numbers, because a proportion is a *shape* and the shape is
/// the part worth remembering. The percentages sit on the labels for anyone
/// who wants them, and the bars use the tile colours the player has been
/// looking at for the last two minutes — so the connection between "the pink
/// ones" and "wants" is made by the picture rather than by a sentence.
class _BudgetSplit extends StatelessWidget {
  const _BudgetSplit({required this.report});

  final CascadeReport report;

  @override
  Widget build(BuildContext context) {
    if (report.allocated == 0) return const SizedBox.shrink();

    return Column(
      children: [
        for (final part in <({String label, int percent, Color colour})>[
          (
            label: 'Needs',
            percent: report.needsPercent,
            colour: TileKind.need.color,
          ),
          (
            label: 'Wants',
            percent: report.wantsPercent,
            colour: TileKind.want.color,
          ),
          (
            label: 'Savings',
            percent: report.savesPercent,
            colour: TileKind.save.color,
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    part.label,
                    style: GoogleFonts.quicksand(
                      color: PixelFrameStyle.slate.inkMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: part.percent / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(part.colour),
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${part.percent}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.quicksand(
                      color: PixelFrameStyle.slate.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
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
