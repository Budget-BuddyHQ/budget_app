import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import '../reusable_widgets/progress_metrics_widgets.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    super.key,
    this.activeTabIndex = 4,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final savingsRate =
            ((stats.gold / 3400) * 100).clamp(1, 100).toDouble();
        final pointsToNextLevel = 120 - (stats.xp % 120);

        return Scaffold(
          backgroundColor: const Color(0xFF1A4D3D),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: SafeArea(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF254E3F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF3B6B59)),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 36,
                                backgroundColor: Color(0xFF85EFAC),
                                child: Icon(
                                  Icons.person,
                                  size: 38,
                                  color: Color(0xFF1A4D3D),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stats.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stats.levelTitle,
                                style: const TextStyle(
                                  color: Color(0xFF85EFAC),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Current Balance: \$${stats.gold}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'Personality Type: ${stats.personalityType}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cloud Stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ResponsiveMetricGrid(
                          children: [
                            FinanceMetricCard(
                              background: const Color(0xFF254E3F),
                              border: const Color(0xFF3B6B59),
                              accent: const Color(0xFF85EFAC),
                              title: 'Literacy Points',
                              value: '${stats.literacyPoints}',
                              subtitle: 'Knowledge Score',
                              icon: Icons.psychology,
                            ),
                            FinanceMetricCard(
                              background: const Color(0xFF254E3F),
                              border: const Color(0xFF3B6B59),
                              accent: const Color(0xFF85EFAC),
                              title: 'Savings Rate',
                              value: '${savingsRate.toStringAsFixed(0)}%',
                              subtitle: 'of goal',
                              icon: Icons.savings,
                              progressValue: savingsRate / 100,
                            ),
                            FinanceMetricCard(
                              background: const Color(0xFF254E3F),
                              border: const Color(0xFF3B6B59),
                              accent: const Color(0xFFF4D06F),
                              title: 'XP',
                              value: '${stats.xp}',
                              subtitle: 'Experience Bank',
                              icon: Icons.auto_awesome,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF254E3F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF3B6B59)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level ${stats.level} Progress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$pointsToNextLevel XP until the next wizard title.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: stats.levelProgress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF85EFAC),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stats.wizardAdvice,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              if (controller.statusMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  controller.statusMessage!,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
