import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../../services/database_service.dart';
import '../profile/user_profile_screen.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'challenges_screen.dart';
import 'invest_screen.dart';
import 'main_game_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _currentIndex;
  StreamSubscription<UserProgressRecord>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4) as int;
    _bindRealtimeProgress();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  void _bindRealtimeProgress() {
    final user = UserProgressState.instance;
    final seedRecord = UserProgressRecord(
      id: user.userId,
      username: user.username,
      xp: user.xp,
      gold: user.gold,
      literacyScore: user.literacyPoints,
      spendingHabits: user.spendingHabits,
      personalityType: user.personalityType,
      updatedAt: DateTime.now().toUtc(),
    );

    DatabaseService.instance.primeLocalRecord(seedRecord);
    unawaited(
      DatabaseService.instance.ensureUserProgressRow(
        userId: user.userId,
        defaults: seedRecord,
      ),
    );

    _progressSubscription = DatabaseService.instance
        .watchUserProgress(user.userId)
        .listen((record) {
      UserProgressState.instance.applyRemoteProgress(
        gold: record.gold,
        xp: record.xp,
        literacyScore: record.literacyScore,
        username: record.username,
        personalityType: record.personalityType,
        spendingHabits: record.spendingHabits,
      );
    });
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        MainGameScreen(
          activeTabIndex: 0,
          onNavSelected: _selectTab,
        ),
        _BudgetLedgerScreen(
          activeTabIndex: 1,
          onNavSelected: _selectTab,
        ),
        InvestScreen(
          activeTabIndex: 2,
          onNavSelected: _selectTab,
        ),
        ChallengesScreen(
          activeTabIndex: 3,
          onNavSelected: _selectTab,
        ),
        UserProfileScreen(
          activeTabIndex: 4,
          onNavSelected: _selectTab,
        ),
      ],
    );
  }
}

class _BudgetLedgerScreen extends StatelessWidget {
  const _BudgetLedgerScreen({
    required this.activeTabIndex,
    required this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int> onNavSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final entries = UserProgressState.instance.ledgerEntries;

        return Scaffold(
          backgroundColor: const Color(0xFF1A4D3D),
          bottomNavigationBar: CustomBottomNav(
            activeIndex: activeTabIndex,
            onSelected: onNavSelected,
          ),
          body: SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              itemCount: entries.length + 1,
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Ledger',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Every coin earned or spent now has a home in the app UI, ready to grow into a dedicated transaction table next.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  );
                }

                final entry = entries[index - 1];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF254E3F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B6B59)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: entry.isCredit
                            ? const Color(0xFF85EFAC).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.08),
                        child: Icon(
                          entry.isCredit ? Icons.add : Icons.remove,
                          color: entry.isCredit
                              ? const Color(0xFF85EFAC)
                              : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.meta,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        entry.amount,
                        style: TextStyle(
                          color: entry.isCredit
                              ? const Color(0xFF85EFAC)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
