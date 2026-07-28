import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/life_board_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_board_models.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

/// The Life Board — a working slice of the main game's framework: roll to move
/// around a looping life board, manage a self-contained cash balance, level
/// three RPG stats, and buy tycoon assets that pay income each lap. Cash out to
/// bank a gold reward into the real economy.
///
/// It owns its own [LifeBoardController], so the game state resets each visit
/// and never touches the player's saved gold until they cash out.
class LifeBoardPage extends StatefulWidget {
  const LifeBoardPage({super.key});

  @override
  State<LifeBoardPage> createState() => _LifeBoardPageState();
}

class _LifeBoardPageState extends State<LifeBoardPage> {
  late final LifeBoardController _game = LifeBoardController();
  bool _cashedOut = false;

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  Future<void> _cashOut() async {
    if (_cashedOut) return;
    _cashedOut = true;
    final reward = _game.goldReward;

    if (reward > 0) {
      await context.read<UserStatsController>().applyChallengePayload({
        'gold_earned': reward,
        'xp_earned': 8 + _game.laps * 2,
        'title': 'Life Board',
        'description':
            'Cashed out after ${_game.turns} turns with a net worth of '
            '${_game.netWorth} coins.',
      });
    }
    if (!mounted) return;
    GameToast.show(
      context,
      title: 'Cashed out',
      message: reward > 0
          ? 'Banked $reward gold from your Life Board run.'
          : 'Play a few turns to earn a gold reward next time.',
      icon: Icons.savings_rounded,
      accent: const Color(0xFFE1BB72),
    );
    Navigator.of(context).pop();
  }

  Future<void> _maybeShowOffer() async {
    final offer = _game.pendingOffer;
    if (offer == null) return;
    final buy = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OfferDialog(offer: offer, cash: _game.cash),
    );
    if (buy == true) {
      _game.acceptOffer();
    } else {
      _game.declineOffer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _game,
      builder: (context, _) {
        // Surface an opportunity as a modal right after the roll resolves.
        if (_game.pendingOffer != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOffer());
        }
        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          appBar: AppBar(
            backgroundColor: const Color(0xFF071711),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Life Board',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              TextButton.icon(
                onPressed: _cashOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE1BB72),
                ),
                label: const Text(
                  'Cash out',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _MoneyHeader(
                  cash: _game.cash,
                  netWorth: _game.netWorth,
                  passiveIncome: _game.passiveIncome,
                  laps: _game.laps,
                ),
                const SizedBox(height: 14),
                _StatBars(
                  energy: _game.energy,
                  knowledge: _game.knowledge,
                  reputation: _game.reputation,
                ),
                const SizedBox(height: 18),
                _BoardGrid(tiles: _game.tiles, position: _game.position),
                const SizedBox(height: 16),
                _EventBanner(message: _game.eventMessage),
                const SizedBox(height: 16),
                _RollBar(
                  lastRoll: _game.lastRoll,
                  disabled: _game.pendingOffer != null,
                  onRoll: _game.roll,
                ),
                if (_game.ownedAssets.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _OwnedAssets(assets: _game.ownedAssets),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoneyHeader extends StatelessWidget {
  const _MoneyHeader({
    required this.cash,
    required this.netWorth,
    required this.passiveIncome,
    required this.laps,
  });

  final int cash;
  final int netWorth;
  final int passiveIncome;
  final int laps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Stat(label: 'Cash', value: '$cash', color: const Color(0xFFE1BB72)),
          _Stat(
            label: 'Net worth',
            value: '$netWorth',
            color: const Color(0xFF85EFAC),
          ),
          _Stat(
            label: 'Income / lap',
            value: '+$passiveIncome',
            color: const Color(0xFF58C7FF),
          ),
          _Stat(label: 'Laps', value: '$laps', color: const Color(0xFFB388FF)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBars extends StatelessWidget {
  const _StatBars({
    required this.energy,
    required this.knowledge,
    required this.reputation,
  });

  final int energy;
  final int knowledge;
  final int reputation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Bar(
          label: 'Energy',
          value: energy,
          color: const Color(0xFFB388FF),
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 10),
        _Bar(
          label: 'Knowledge',
          value: knowledge,
          color: const Color(0xFF58C7FF),
          icon: Icons.menu_book_rounded,
        ),
        const SizedBox(height: 10),
        _Bar(
          label: 'Reputation',
          value: reputation,
          color: const Color(0xFFFF8FB1),
          icon: Icons.emoji_events_rounded,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.tiles, required this.position});

  final List<LifeTile> tiles;
  final int position;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit tiles into rows that adapt to the width; the token sits on the
        // current tile.
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 560 ? 8 : 4;
        final tileSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < tiles.length; i++)
              _BoardCell(
                tile: tiles[i],
                size: tileSize,
                isHere: i == position,
              ),
          ],
        );
      },
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.tile,
    required this.size,
    required this.isHere,
  });

  final LifeTile tile;
  final double size;
  final bool isHere;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tile.color.withValues(alpha: isHere ? 0.28 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tile.color.withValues(alpha: isHere ? 0.95 : 0.28),
          width: isHere ? 2.4 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHere ? Icons.person_pin_circle_rounded : tile.icon,
            color: tile.color,
            size: size * 0.34,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              tile.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _RollBar extends StatelessWidget {
  const _RollBar({
    required this.lastRoll,
    required this.disabled,
    required this.onRoll,
  });

  final int lastRoll;
  final bool disabled;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            lastRoll == 0 ? '–' : '$lastRoll',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton.icon(
            onPressed: disabled ? null : onRoll,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF85EFAC),
              foregroundColor: const Color(0xFF08251A),
              padding: const EdgeInsets.symmetric(vertical: 18),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
            ),
            icon: const Icon(Icons.casino_rounded),
            label: const Text(
              'Roll the dice',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnedAssets extends StatelessWidget {
  const _OwnedAssets({required this.assets});

  final List<TycoonAsset> assets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your businesses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final asset in assets)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD45C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD45C).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(asset.icon, color: const Color(0xFFFFD45C), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${asset.name}  +${asset.incomePerLap}/lap',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OfferDialog extends StatelessWidget {
  const _OfferDialog({required this.offer, required this.cash});

  final TycoonAsset offer;
  final int cash;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF10281F),
      title: Row(
        children: [
          Icon(offer.icon, color: const Color(0xFFFFD45C)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Business opportunity',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: Text(
        'Buy the ${offer.name} for ${offer.cost} coins? It pays '
        '${offer.incomePerLap} coins every lap.\n\nYou have $cash coins.',
        style: const TextStyle(color: Colors.white70, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: Colors.white60),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFD45C),
            foregroundColor: const Color(0xFF3C2B00),
          ),
          child: const Text(
            'Buy',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
