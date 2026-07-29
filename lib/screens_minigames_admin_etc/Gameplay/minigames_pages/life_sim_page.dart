import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

/// **Life** — the main game, in the BitLife format: a scrolling life feed up
/// top, a fixed bottom menu, and a big central Age button that advances time
/// and surfaces money-decision events. (A map to explore comes later.)
///
/// Owns its own [LifeSimController], so state resets each visit and never
/// touches the player's saved gold until they retire.
class LifeSimPage extends StatefulWidget {
  const LifeSimPage({super.key});

  @override
  State<LifeSimPage> createState() => _LifeSimPageState();
}

class _LifeSimPageState extends State<LifeSimPage> {
  late final LifeSimController _life = LifeSimController();
  final ScrollController _feedController = ScrollController();
  bool _cashedOut = false;

  @override
  void dispose() {
    _life.dispose();
    _feedController.dispose();
    super.dispose();
  }

  void _scrollFeedToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_feedController.hasClients) {
        _feedController.animateTo(
          _feedController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _retire() async {
    if (_cashedOut) return;
    _cashedOut = true;
    _life.retire();
    final reward = _life.goldReward;

    if (reward > 0) {
      await context.read<UserStatsController>().applyChallengePayload({
        'gold_earned': reward,
        'xp_earned': 8 + _life.yearsLived,
        'title': 'Life',
        'description':
            'Lived to ${_life.age} with a net worth of ${_life.netWorth} coins.',
      });
    }
    if (!mounted) return;
    GameToast.show(
      context,
      title: 'Life banked',
      message: reward > 0
          ? 'You earned $reward gold from this life run.'
          : 'Live a few more years to earn a gold reward.',
      icon: Icons.savings_rounded,
      accent: const Color(0xFFE1BB72),
    );
    Navigator.of(context).pop();
  }

  void _invest() {
    if (_life.money < 100) {
      GameToast.show(
        context,
        title: 'Not enough cash',
        message: 'You need 100 coins to invest.',
        icon: Icons.info_outline_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }
    _life.invest(100);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _life,
      builder: (context, _) {
        final event = _life.currentEvent;
        _scrollFeedToEnd();
        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1D17),
            foregroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 12,
            title: _HeaderBar(
              age: _life.age,
              stage: _life.stage,
              money: _life.money,
              job: _life.job,
            ),
            actions: [
              TextButton.icon(
                onPressed: _retire,
                icon: const Icon(Icons.flag_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE1BB72),
                ),
                label: const Text(
                  'Retire',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _LifeFeed(
                  controller: _feedController,
                  history: _life.history,
                  netWorth: _life.netWorth,
                  investments: _life.investments,
                  smarts: _life.smarts,
                  health: _life.health,
                  event: event,
                  onChoose: _life.chooseOption,
                ),
              ),
              _BottomMenu(
                happiness: _life.happiness,
                blocked: event != null,
                onStudy: _life.study,
                onInvest: _invest,
                onFun: _life.haveFun,
                onAge: _life.ageUp,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.age,
    required this.stage,
    required this.money,
    required this.job,
  });

  final int age;
  final LifeStage stage;
  final int money;
  final String job;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF173B2E),
          child: Icon(Icons.face_rounded, color: Color(0xFF85EFAC)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Age $age · ${stage.label}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              Text(
                job,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$money',
              style: const TextStyle(
                color: Color(0xFFE1BB72),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              'coins',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LifeFeed extends StatelessWidget {
  const _LifeFeed({
    required this.controller,
    required this.history,
    required this.netWorth,
    required this.investments,
    required this.smarts,
    required this.health,
    required this.event,
    required this.onChoose,
  });

  final ScrollController controller;
  final List<LifeLogEntry> history;
  final int netWorth;
  final int investments;
  final int smarts;
  final int health;
  final LifeEvent? event;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        _MiniStatsRow(
          netWorth: netWorth,
          investments: investments,
          smarts: smarts,
          health: health,
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Tap the green + to age up and start your story.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          for (var i = 0; i < history.length; i++) ...[
            if (i == 0 || history[i].age != history[i - 1].age)
              _AgeHeader(age: history[i].age),
            _FeedLine(text: history[i].text),
          ],
        if (event != null) ...[
          const SizedBox(height: 14),
          _EventCard(event: event!, onChoose: onChoose),
        ],
      ],
    );
  }
}

class _MiniStatsRow extends StatelessWidget {
  const _MiniStatsRow({
    required this.netWorth,
    required this.investments,
    required this.smarts,
    required this.health,
  });

  final int netWorth;
  final int investments;
  final int smarts;
  final int health;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Pill(label: 'Net worth', value: '$netWorth', color: const Color(0xFF85EFAC)),
        _Pill(label: 'Invested', value: '$investments', color: const Color(0xFF58C7FF)),
        _Pill(label: 'Smarts', value: '$smarts', color: const Color(0xFF69C6FF)),
        _Pill(label: 'Health', value: '$health', color: const Color(0xFFFF8A80)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeHeader extends StatelessWidget {
  const _AgeHeader({required this.age});

  final int age;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        'Age: $age years',
        style: const TextStyle(
          color: Color(0xFF85EFAC),
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _FeedLine extends StatelessWidget {
  const _FeedLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.86),
          height: 1.4,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onChoose});

  final LifeEvent event;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF58C7FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF58C7FF).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(event.icon, color: const Color(0xFF58C7FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'What do you do?',
                style: TextStyle(
                  color: Color(0xFF58C7FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.prompt,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < event.choices.length; i++) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => onChoose(i),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
                child: Text(
                  event.choices[i].label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (i != event.choices.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  const _BottomMenu({
    required this.happiness,
    required this.blocked,
    required this.onStudy,
    required this.onInvest,
    required this.onFun,
    required this.onAge,
  });

  final int happiness;
  final bool blocked;
  final VoidCallback onStudy;
  final VoidCallback onInvest;
  final VoidCallback onFun;
  final VoidCallback onAge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1D17),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.sentiment_very_satisfied_rounded,
                    color: Color(0xFFFFD45C),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: happiness.clamp(0, 100) / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD45C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Happiness $happiness%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MenuButton(
                    label: 'School',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF58C7FF),
                    onTap: blocked ? null : onStudy,
                  ),
                  _MenuButton(
                    label: 'Assets',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF85EFAC),
                    onTap: blocked ? null : onInvest,
                  ),
                  _AgeButton(onTap: blocked ? null : onAge),
                  _MenuButton(
                    label: 'Fun',
                    icon: Icons.celebration_rounded,
                    color: const Color(0xFFFFD45C),
                    onTap: blocked ? null : onFun,
                  ),
                  _MenuButton(
                    label: 'Health',
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFFF8A80),
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeButton extends StatelessWidget {
  const _AgeButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? const Color(0xFF43D07E)
                  : Colors.white.withValues(alpha: 0.1),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF43D07E).withValues(alpha: 0.4),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_rounded,
              color: enabled ? const Color(0xFF06251A) : Colors.white38,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Age',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? color : Colors.white24, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
