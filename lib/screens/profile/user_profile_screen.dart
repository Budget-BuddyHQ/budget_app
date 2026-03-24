import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../../services/database_service.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import '../reusable_widgets/progress_metrics_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    this.activeTabIndex = 4,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<UserProgressRecord> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<UserProgressRecord> _loadProfile() async {
    final user = UserProgressState.instance;
    final fallback = UserProgressRecord(
      id: user.userId,
      username: user.username,
      xp: user.xp,
      gold: user.gold,
      literacyScore: user.literacyPoints,
      spendingHabits: user.spendingHabits,
      personalityType: user.personalityType,
      updatedAt: DateTime.now().toUtc(),
    );

    final record = await DatabaseService.instance.fetchUserProgress(
      user.userId,
      fallback: fallback,
    );

    user.applyRemoteProgress(
      gold: record.gold,
      xp: record.xp,
      literacyScore: record.literacyScore,
      username: record.username,
      personalityType: record.personalityType,
      spendingHabits: record.spendingHabits,
    );

    return record;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProgressRecord>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A4D3D),
            bottomNavigationBar: widget.onNavSelected == null
                ? null
                : CustomBottomNav(
                    activeIndex: widget.activeTabIndex,
                    onSelected: widget.onNavSelected,
                  ),
            body: const SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
              ),
            ),
          );
        }

        final initialRecord = snapshot.data ??
            UserProgressRecord.defaults(UserProgressState.instance.userId);

        return StreamBuilder<UserProgressRecord>(
          stream: DatabaseService.instance.watchUserProgress(initialRecord.id),
          initialData: initialRecord,
          builder: (context, streamSnapshot) {
            final record = streamSnapshot.data ?? initialRecord;
            final level = (record.xp ~/ 150).clamp(1, 999) as int;
            final progressToNextLevel = (record.xp % 150) / 150;
            final pointsToNextLevel = (((record.xp ~/ 150) + 1) * 150) - record.xp;
            final savingsRate =
                ((record.gold / 3400) * 100).clamp(1, 100).toDouble();

            return Scaffold(
              backgroundColor: const Color(0xFF1A4D3D),
              bottomNavigationBar: widget.onNavSelected == null
                  ? null
                  : CustomBottomNav(
                      activeIndex: widget.activeTabIndex,
                      onSelected: widget.onNavSelected,
                    ),
              body: SafeArea(
                child: SingleChildScrollView(
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
                      const SizedBox(height: 6),
                      Text(
                        DatabaseService.instance.configurationMessage,
                        style: const TextStyle(color: Colors.white70),
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
                              record.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level $level Finance Wizard',
                              style: const TextStyle(
                                color: Color(0xFF85EFAC),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Current Balance: \$${record.gold}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Personality Type: ${record.personalityType}',
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
                            value: '${record.literacyScore}',
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
                            value: '${record.xp}',
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
                              'Level $level Progress',
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
                              value: progressToNextLevel,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF85EFAC),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              UserProgressState.instance.wizardAdvice,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
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
      },
    );
  }
}
