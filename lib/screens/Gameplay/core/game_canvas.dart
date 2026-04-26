import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/adventure_state_controller.dart';
import '../../../game/budget_buddy_game.dart';

class GameCanvas extends StatefulWidget {
  const GameCanvas({super.key});

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas> {
  late final BudgetBuddyGame _game;

  @override
  void initState() {
    super.initState();
    _game = BudgetBuddyGame(
      adventureState: context.read<AdventureStateController>(),
    );
  }

  Future<void> _showPetsModal(BuildContext context, String equippedPet) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B251C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Equipped Pet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF85EFAC).withValues(alpha: 0.26),
                    ),
                  ),
                  child: Text(
                    equippedPet,
                    style: const TextStyle(
                      color: Color(0xFF85EFAC),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAnswer(BuildContext context, int index) async {
    final controller = context.read<AdventureStateController>();
    final correct = await controller.submitAnswer(index);
    if (!mounted) {
      return;
    }

    if (correct) {
      await Future<void>.delayed(const Duration(milliseconds: 320));
      _game.resolveCombat(victory: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      body: SafeArea(
        child: Consumer<AdventureStateController>(
          builder: (context, adventure, _) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF071711),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: GameWidget<BudgetBuddyGame>(
                                game: _game,
                                autofocus: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        right: 18,
                        child: _HudBar(
                          level: adventure.level,
                          xpProgress: adventure.xpProgress,
                          gold: adventure.gold,
                          onBack: () => Navigator.of(context).maybePop(),
                          onPetsTap: () =>
                              _showPetsModal(context, adventure.equippedPet),
                        ),
                      ),
                      if (adventure.combatVisible)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.48),
                            child: SafeArea(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 92, 16, 24),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 440),
                                    child: _CombatOverlay(
                                      controller: adventure,
                                      onAnswer: (index) =>
                                          _handleAnswer(context, index),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HudBar extends StatelessWidget {
  const _HudBar({
    required this.level,
    required this.xpProgress,
    required this.gold,
    required this.onBack,
    required this.onPetsTap,
  });

  final int level;
  final double xpProgress;
  final int gold;
  final VoidCallback onBack;
  final VoidCallback onPetsTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 430;

            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment:
                      stacked ? WrapAlignment.start : WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$gold Gold',
                      style: const TextStyle(
                        color: Color(0xFFFFD45C),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: xpProgress.clamp(0.02, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF85EFAC),
                    ),
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack,
                      ),
                      const Spacer(),
                      _GlassIconButton(
                        icon: Icons.pets_rounded,
                        onTap: onPetsTap,
                        label: 'Pets',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  summary,
                ],
              );
            }

            return Row(
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(child: summary),
                const SizedBox(width: 12),
                _GlassIconButton(
                  icon: Icons.pets_rounded,
                  onTap: onPetsTap,
                  label: 'Pets',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 12 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF85EFAC)),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CombatOverlay extends StatelessWidget {
  const _CombatOverlay({
    required this.controller,
    required this.onAnswer,
  });

  final AdventureStateController controller;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final question = controller.currentQuestion;
    if (question == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0B251C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.encounterEnemyName,
            style: const TextStyle(
              color: Color(0xFFFFD45C),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Combat Quiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.prompt,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List<Widget>.generate(
            question.options.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.answerResolved ? null : () => onAnswer(index),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (controller.combatFeedback != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.combatFeedback!,
              style: TextStyle(
                color: controller.answerResolved
                    ? const Color(0xFF85EFAC)
                    : const Color(0xFFFFB084),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
