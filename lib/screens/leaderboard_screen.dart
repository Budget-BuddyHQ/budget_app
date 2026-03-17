import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaders = [
      _Leader(rank: 1, name: 'MoneyMaster99', points: 2450),
      _Leader(rank: 2, name: 'BudgetPro', points: 2280),
      _Leader(rank: 3, name: 'Username3189', points: 2150, isCurrentUser: true),
      _Leader(rank: 4, name: 'SaverSally', points: 2020),
      _Leader(rank: 5, name: 'InvestorMax', points: 1890),
      _Leader(rank: 6, name: 'CashKnight', points: 1720),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F2E1E),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF0F2E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Finance Wizards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: leaders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final leader = leaders[index];
                  return _LeaderboardRow(leader: leader);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final _Leader leader;

  const _LeaderboardRow({required this.leader});

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColor(leader.rank);
    final highlightBorder =
        leader.isCurrentUser ? const Color(0xFFF4D06F) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF163526).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlightBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '#${leader.rank}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 14),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1E4D3D),
                child: Text(
                  leader.name.characters.first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (medalColor != null)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Icon(
                    Icons.emoji_events,
                    color: medalColor,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              leader.name,
              style: TextStyle(
                color: leader.isCurrentUser
                    ? const Color(0xFFF4D06F)
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            leader.points.toString(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color? _medalColor(int rank) {
    if (rank == 1) return const Color(0xFFF4D06F);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return null;
  }
}

class _Leader {
  final int rank;
  final String name;
  final int points;
  final bool isCurrentUser;

  const _Leader({
    required this.rank,
    required this.name,
    required this.points,
    this.isCurrentUser = false,
  });
}
