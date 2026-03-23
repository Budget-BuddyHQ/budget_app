import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../../services/database_service.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
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
        _SectionScaffold(
          activeTabIndex: 1,
          onNavSelected: _selectTab,
          title: 'Budget Ledger',
          subtitle: 'Every coin earned and spent is easier to review once it lives in PostgreSQL.',
          child: const _BudgetLedgerSection(),
        ),
        _SectionScaffold(
          activeTabIndex: 2,
          onNavSelected: _selectTab,
          title: 'Invest Lab',
          subtitle: 'Use personality-aware tips to balance savings, risk, and long-term growth.',
          child: const _InvestSection(),
        ),
        _SectionScaffold(
          activeTabIndex: 3,
          onNavSelected: _selectTab,
          title: 'Challenges',
          subtitle: 'Adaptive boss battles can now react to your recent results and habits.',
          child: const _ChallengesSection(),
        ),
        _SectionScaffold(
          activeTabIndex: 4,
          onNavSelected: _selectTab,
          title: 'Profile',
          subtitle: 'Your Finance Wizard identity updates live from Supabase.',
          child: const _ProfileSection(),
        ),
      ],
    );
  }
}

class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({
    required this.activeTabIndex,
    required this.onNavSelected,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int activeTabIndex;
  final ValueChanged<int> onNavSelected;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A4D3D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        activeIndex: activeTabIndex,
        onSelected: onNavSelected,
      ),
    );
  }
}

class _BudgetLedgerSection extends StatelessWidget {
  const _BudgetLedgerSection();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final entries = UserProgressState.instance.ledgerEntries;

        return ListView.separated(
          itemCount: entries.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _InfoPanel(
                title: 'Transaction Ledger',
                body: 'This tab now tracks local coin history and is structured so those rows can move into a dedicated Postgres transaction table next.',
                icon: Icons.receipt_long,
              );
            }

            final entry = entries[index - 1];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF244B3C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: entry.isCredit
                        ? const Color(0xFF85EFAC).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.10),
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
                        const SizedBox(height: 2),
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
        );
      },
    );
  }
}

class _InvestSection extends StatelessWidget {
  const _InvestSection();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final user = UserProgressState.instance;
        return ListView(
          children: [
            _InfoPanel(
              title: 'Wizard\'s Strategy',
              body: user.wizardAdvice,
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 12),
            _InsightTile(
              title: 'Personality Type',
              body: user.personalityType,
              accent: const Color(0xFF85EFAC),
            ),
            const SizedBox(height: 12),
            const _InsightTile(
              title: 'Portfolio Reminder',
              body: 'A transaction ledger plus spending_habits JSONB makes adaptive investment coaching much easier later.',
              accent: Color(0xFFF4D06F),
            ),
          ],
        );
      },
    );
  }
}

class _ChallengesSection extends StatelessWidget {
  const _ChallengesSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _InfoPanel(
          title: 'Adaptive Challenge Queue',
          body: 'Once question history lands in Postgres, this tab can rank easier and harder boss battles from real mistakes instead of hard-coded difficulty.',
          icon: Icons.emoji_events,
        ),
        SizedBox(height: 12),
        _InsightTile(
          title: 'Bridge Status',
          body: 'The React WebView now has a dedicated sync path to PostgreSQL/Supabase, so challenge results can update the dashboard in real time.',
          accent: Color(0xFF85EFAC),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final user = UserProgressState.instance;
        final syncMessage = user.cloudStatusMessage ??
            DatabaseService.instance.configurationMessage;

        return ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF244B3C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFF85EFAC),
                    child: Icon(Icons.person, color: Color(0xFF1A4D3D), size: 34),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Username3189',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.levelTitle,
                    style: const TextStyle(color: Color(0xFF85EFAC)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    syncMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF244B3C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF85EFAC).withValues(alpha: 0.18),
            child: Icon(icon, color: const Color(0xFF85EFAC)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
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
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF244B3C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}
