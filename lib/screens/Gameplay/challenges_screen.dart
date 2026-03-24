import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'react_game_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({
    super.key,
    this.activeTabIndex = 3,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openDailyBattle(BuildContext context) async {
    final user = UserProgressState.instance;
    final result = await Navigator.push<ReactGameCloseResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ReactChallengeScreen(
          gameId: 'upcoming_daily_battle',
          difficulty: 'medium',
          playerLevel: user.level,
          userId: user.userId,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final syncText = result.syncResult.message ??
        (result.syncResult.synced
            ? 'Progress saved to Postgres.'
            : 'Progress saved locally.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.status.toUpperCase()}: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. $syncText',
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is queued next for full mini-game wiring.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const challengeCards = <_ChallengeCardData>[
      _ChallengeCardData(
        title: 'Daily Budget Battle',
        description: 'Spot 3 wasteful purchases before the timer runs out.',
        reward: 180,
        usesReactBridge: true,
      ),
      _ChallengeCardData(
        title: 'Emergency Fund Boss',
        description: 'Protect your gold stash from surprise expenses.',
        reward: 240,
      ),
      _ChallengeCardData(
        title: 'Credit Score Gauntlet',
        description: 'Choose the smartest moves to keep your score climbing.',
        reward: 210,
      ),
      _ChallengeCardData(
        title: 'Subscription Slayer',
        description: 'Cancel hidden fees before they drain your treasury.',
        reward: 150,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A4D3D),
      bottomNavigationBar: onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: activeTabIndex,
              onSelected: onNavSelected,
            ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          itemCount: challengeCards.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF254E3F),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF3B6B59)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Upcoming Boss Battles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Take on daily tasks and harder boss battles to build gold, XP, and literacy points.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              );
            }

            final card = challengeCards[index - 1];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF254E3F),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF3B6B59)),
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
                          color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${card.reward} gold',
                          style: const TextStyle(
                            color: Color(0xFF85EFAC),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.emoji_events, color: Color(0xFFF4D06F)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.description,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: card.usesReactBridge
                          ? () => _openDailyBattle(context)
                          : () => _showComingSoon(context, card.title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF85EFAC),
                        foregroundColor: const Color(0xFF1A4D3D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Start'),
                    ),
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
  });

  final String title;
  final String description;
  final int reward;
  final bool usesReactBridge;
}
