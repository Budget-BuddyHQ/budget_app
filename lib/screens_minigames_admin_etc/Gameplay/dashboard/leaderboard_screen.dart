import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _loadLeaderboard();
  }

  Future<List<LeaderboardEntry>> _loadLeaderboard() {
    final currentUserId = context.read<UserStatsController>().stats.id;
    return SupabaseService.instance.fetchLeaderboard(
      limit: 20,
      currentUserId: currentUserId,
    );
  }

  Future<void> _refresh() async {
    final nextFuture = _loadLeaderboard();
    setState(() {
      _leaderboardFuture = nextFuture;
    });
    await nextFuture;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserStatsController>().stats;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2E1E),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF0F2E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2F9E68),
        onRefresh: _refresh,
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF85EFAC),
                ),
              );
            }

            final leaders = snapshot.data ?? const <LeaderboardEntry>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Top Finance Wizards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  leaders.isEmpty
                      ? 'No cloud leaderboard data is available yet, so you are seeing cached progress only.'
                      : 'Rankings now come from saved user stats instead of hardcoded demo names.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _CurrentUserSummary(
                  username: currentUser.username,
                  literacyPoints: currentUser.literacyPoints,
                  xp: currentUser.xp,
                  gold: currentUser.gold,
                ),
                const SizedBox(height: 16),
                if (leaders.isEmpty)
                  const _EmptyLeaderboardState()
                else
                  ...leaders.map(
                    (leader) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LeaderboardRow(
                        leader: leader,
                        currentUserProfileImageUrl: currentUser.profileImageUrl,
                      ),
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

class _CurrentUserSummary extends StatelessWidget {
  const _CurrentUserSummary({
    required this.username,
    required this.literacyPoints,
    required this.xp,
    required this.gold,
  });

  final String username;
  final int literacyPoints;
  final int xp;
  final int gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF163526),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF85EFAC).withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your saved progress',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _StatChip(label: 'LP', value: '$literacyPoints'),
          _StatChip(label: 'XP', value: '$xp'),
          _StatChip(label: 'Gold', value: '$gold'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboardState extends StatelessWidget {
  const _EmptyLeaderboardState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF163526).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Once more players save stats to Supabase, rankings will appear here automatically.',
        style: TextStyle(
          color: Colors.white,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.leader,
    required this.currentUserProfileImageUrl,
  });

  final LeaderboardEntry leader;
  final String currentUserProfileImageUrl;

  Widget _initialAvatar() {
    final initial = leader.username.isNotEmpty
        ? leader.username[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF85EFAC),
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColor(leader.rank);
    final highlightBorder =
        leader.isCurrentUser ? const Color(0xFFF4D06F) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF163526).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlightBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 14),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E4D3D),
                ),
                child: ClipOval(
                  child: Builder(
                    builder: (context) {
                      // Every row shows its own avatar from the leaderboard
                      // view; the signed-in user falls back to their local
                      // profile image, everyone else to an initial.
                      final url = leader.profileImageUrl.isNotEmpty
                          ? leader.profileImageUrl
                          : (leader.isCurrentUser
                                ? currentUserProfileImageUrl
                                : '');
                      if (url.isNotEmpty) {
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (_, _, _) => _initialAvatar(),
                        );
                      }
                      return _initialAvatar();
                    },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.username,
                  style: TextStyle(
                    color: leader.isCurrentUser
                        ? const Color(0xFFF4D06F)
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${leader.xp} XP • ${leader.gold} gold',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            leader.scoreLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
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

