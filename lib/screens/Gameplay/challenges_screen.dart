import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../navigation/fade_page_route.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'bill_dodger.dart';
import 'react_challenge_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({
    super.key,
    this.activeTabIndex = 3,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openDailyBattle(BuildContext context) async {
    final controller = context.read<UserStatsController>();
    final stats = controller.stats;

    final result = await Navigator.of(context).push<ReactGameCloseResult>(
      FadePageRoute(
        builder: (_) => ReactChallengeScreen(
          gameId: 'daily_budget_battle',
          difficulty: 'medium',
          playerLevel: stats.level,
          userId: stats.id,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: result.status == 'victory' ? 'Daily battle won' : 'Battle complete',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.workspace_premium_rounded,
    );
  }

  Future<void> _openBillDodger(BuildContext context) async {
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      FadePageRoute(
        builder: (_) => const BillDodgerScreen(),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Arcade rewards saved',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.gamepad_rounded,
      accent: const Color(0xFFFFC36B),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    GameToast.show(
      context,
      title: 'Coming soon',
      message: '$title is the next mission we can wire into a full mini-game.',
      icon: Icons.hourglass_top_rounded,
      accent: const Color(0xFFFFC36B),
    );
  }

  @override
  Widget build(BuildContext context) {
    const challengeCards = <_ChallengeCardData>[
      _ChallengeCardData(
        title: 'Bill Dodger',
        description: 'Smooth arcade movement with faster money decisions.',
        reward: 200,
        isBillDodger: true,
      ),
      _ChallengeCardData(
        title: 'Daily Budget Battle',
        description: 'A cloud-synced React challenge that rewards clean choices.',
        reward: 180,
        usesReactBridge: true,
      ),
      _ChallengeCardData(
        title: 'Emergency Fund Boss',
        description: 'Protect your stash against a wave of surprise expenses.',
        reward: 240,
      ),
      _ChallengeCardData(
        title: 'Credit Score Gauntlet',
        description: 'Keep the score rising by picking the healthiest credit moves.',
        reward: 210,
      ),
      _ChallengeCardData(
        title: 'Subscription Slayer',
        description: 'Hunt hidden recurring charges before they drain the treasury.',
        reward: 150,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A211A),
      bottomNavigationBar: onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: activeTabIndex,
              onSelected: onNavSelected,
            ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          itemCount: challengeCards.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF173C2F).withOpacity(0.96),
                      const Color(0xFF214D3E).withOpacity(0.92),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Boss Battles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Each challenge is now presented like a mission card so mobile players can scan rewards instantly.',
                      style: TextStyle(color: Colors.white70, height: 1.45),
                    ),
                  ],
                ),
              );
            }

            final card = challengeCards[index - 1];
            final accent = card.isBillDodger
                ? const Color(0xFFFFC36B)
                : const Color(0xFF85EFAC);

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${card.reward} gold reward',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        card.isBillDodger
                            ? Icons.gamepad_rounded
                            : Icons.emoji_events_rounded,
                        color: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.isBillDodger
                              ? 'Arcade mode'
                              : card.usesReactBridge
                                  ? 'Cloud-synced challenge'
                                  : 'Story mission',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 146,
                        child: CustomButton(
                          label: card.isBillDodger ? 'Play Now' : 'Start',
                          onPressed: card.isBillDodger
                              ? () => _openBillDodger(context)
                              : card.usesReactBridge
                                  ? () => _openDailyBattle(context)
                                  : () => _showComingSoon(context, card.title),
                          style: card.isBillDodger
                              ? const CustomButtonStyle.secondary()
                              : const CustomButtonStyle.primary(),
                          prefixIcon: Icon(
                            card.isBillDodger
                                ? Icons.gamepad_rounded
                                : Icons.bolt_rounded,
                            size: 18,
                            color: card.isBillDodger
                                ? const Color(0xFF76FF03)
                                : const Color(0xFF1A4D3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeCardData {
  const _ChallengeCardData({
    required this.title,
    required this.description,
    required this.reward,
    this.usesReactBridge = false,
    this.isBillDodger = false,
  });

  final String title;
  final String description;
  final int reward;
  final bool usesReactBridge;
  final bool isBillDodger;
}

