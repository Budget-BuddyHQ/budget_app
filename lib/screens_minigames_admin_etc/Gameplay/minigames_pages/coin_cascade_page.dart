import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
class CoinCascadePage extends StatefulWidget {
  const CoinCascadePage({super.key});

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

  /// Highest level cleared this session.
  ///
  /// Session-scoped rather than saved, deliberately: a run is a few minutes
  /// and the ladder is seven levels, so persisting it would mostly mean a
  /// returning player is handed level 7 and no idea what the earlier rules
  /// were. The rules *are* the curriculum, in order.
  int _unlocked = 1;

  @override
  void initState() {
    super.initState();
    _game = CoinCascadeGame(level: kCascadeLevels.first);
  }

  void _startLevel(int number) {
    setState(() {
      _finished = false;
      _selected = null;
      _clearing = const {};
      _flash = null;
      _game = CoinCascadeGame(level: cascadeLevelFor(number));
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
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

    final adjacent =
        (current.x - col).abs() + (current.y - row).abs() == 1;
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
    if (_game.status == CascadeStatus.won) _recordWin();
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

  void _restart() => _startLevel(_game.level.number);

  /// Called when a level is beaten: unlock the next one.
  void _recordWin() {
    final next = _game.level.number + 1;
    if (next > _unlocked && next <= kCascadeLevels.length) {
      _unlocked = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _game.status != CascadeStatus.playing;

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
              onPick: _startLevel,
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
                      hasNext: _game.status == CascadeStatus.won &&
                          _game.level.number < kCascadeLevels.length,
                      onNext: () => _startLevel(_game.level.number + 1),
                      onAgain: _restart,
                      onLeave: () => Navigator.of(context).pop(_game),
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
    required this.onPick,
  });

  final CascadeLevel level;
  final int unlocked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(const Color(0xFFFFD45C), alpha: 0.14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: chip.fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD45C).withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedLabel(
                    'Level ${level.number} · ${level.name}',
                    style: GoogleFonts.pixelifySans(
                      color: chip.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.rule,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<int>(
              tooltip: 'Pick a level',
              icon: Icon(Icons.list_rounded, size: 20, color: chip.ink),
              onSelected: onPick,
              itemBuilder: (context) => [
                for (final l in kCascadeLevels)
                  PopupMenuItem<int>(
                    value: l.number,
                    // Later levels stay listed but disabled, so the ladder is
                    // visible from level one — you can see what is coming.
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

class _TileView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(tile.kind.color, alpha: 0.26);

    return GestureDetector(
      onTap: onTap,
      // Swipe as well as tap-tap. Under about eight a drag is the natural
      // gesture and the two-tap version is a rule to learn; over about twelve
      // the taps are more precise. Supporting both costs one callback.
      onPanEnd: (details) {
        final v = details.velocity.pixelsPerSecond;
        if (v.distance < 120) return;
        onSwipe(
          v.dx.abs() > v.dy.abs()
              ? Point(v.dx > 0 ? 1 : -1, 0)
              : Point(0, v.dy > 0 ? 1 : -1),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: AnimatedScale(
          scale: clearing ? 1.25 : (selected ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: clearing ? 0.25 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: chip.fill,
                borderRadius: BorderRadius.circular(size * 0.22),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : tile.kind.color.withValues(alpha: 0.45),
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  tile.kind.emoji,
                  style: TextStyle(fontSize: size * 0.44),
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
              label: '+${CoinCascadeGame.extraMovesPerPurchase} · '
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
    required this.hasNext,
    required this.onNext,
    required this.onAgain,
    required this.onLeave,
  });

  final CoinCascadeGame game;

  /// False on the last level and on any loss, so "Next" never offers a level
  /// that does not exist or one the player has not earned.
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onAgain;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final won = game.status == CascadeStatus.won;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: PixelFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? 'Goal reached!' : 'Out of moves',
                style: GoogleFonts.pixelifySans(
                  color: PixelFrameStyle.slate.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? 'You covered your needs and still put '
                          '${game.savings} into savings.'
                    : game.bills >= game.billCapacity
                    ? 'The bills got ahead of you. Next time, clear needs '
                          'before wants.'
                    : 'You saved ${game.savings} of ${game.savingsGoal}. '
                          'Coins buy extra moves — spend them earlier.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: PixelFrameStyle.slate.inkMuted,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '+${game.goldEarned} gold',
                style: GoogleFonts.pixelifySans(
                  color: PixelFrameStyle.slate.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                    foregroundColor: PixelFrameStyle.slate.inkMuted,
                  ),
                  child: const Text('Replay this level'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
