import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../themes_colors/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;
  bool _showFriends = false;
  bool _byGold = false;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _loadLeaderboard();
  }

  Future<List<LeaderboardEntry>> _loadLeaderboard() {
    final currentUserId = context.read<UserStatsController>().stats.id;
    if (_showFriends) {
      return SupabaseService.instance.fetchFriendsLeaderboard(
        currentUserId: currentUserId,
        byGold: _byGold,
      );
    }
    return SupabaseService.instance.fetchLeaderboard(
      limit: 20,
      currentUserId: currentUserId,
      byGold: _byGold,
    );
  }

  void _setMode({required bool friends}) {
    if (friends == _showFriends) return;
    setState(() {
      _showFriends = friends;
      _leaderboardFuture = _loadLeaderboard();
    });
  }

  void _setMetric({required bool byGold}) {
    if (byGold == _byGold) return;
    setState(() {
      _byGold = byGold;
      _leaderboardFuture = _loadLeaderboard();
    });
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
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        title: Text('Leaderboard', style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.deepForest,
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
                child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
              );
            }

            final leaders = snapshot.data ?? const <LeaderboardEntry>[];
            final podium = leaders.take(3).toList(growable: false);
            final rest = leaders.skip(3).toList(growable: false);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _byGold ? 'Richest Players' : 'Top Finance Wizards',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showFriends
                      ? 'Ranked among friends who\'ve added your code (or you\'ve added theirs).'
                      : leaders.isEmpty
                      ? 'No cloud leaderboard data is available yet, so you are seeing cached progress only.'
                      : _byGold
                      ? 'Ranked by gold — every trade, quest, and case pays off here.'
                      : 'Rankings now come from saved user stats instead of hardcoded demo names.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _LeaderboardModeToggle(
                  showFriends: _showFriends,
                  onChanged: (friends) => _setMode(friends: friends),
                ),
                const SizedBox(height: 10),
                _MetricToggle(
                  byGold: _byGold,
                  onChanged: (byGold) => _setMetric(byGold: byGold),
                ),
                const SizedBox(height: 14),
                _CurrentUserSummary(
                  username: currentUser.username,
                  literacyPoints: currentUser.literacyPoints,
                  xp: currentUser.xp,
                  gold: currentUser.gold,
                ),
                const SizedBox(height: 20),
                if (leaders.isEmpty)
                  _EmptyLeaderboardState(showingFriends: _showFriends)
                else ...[
                  _HallOfFamePodium(
                    top3: podium,
                    byGold: _byGold,
                    currentUserProfileImageUrl: currentUser.profileImageUrl,
                  ),
                  const SizedBox(height: 22),
                  ...rest.map(
                    (leader) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LeaderboardRow(
                        leader: leader,
                        byGold: _byGold,
                        currentUserProfileImageUrl: currentUser.profileImageUrl,
                      ),
                    ),
                  ),
                ],
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
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.35),
        ),
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
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
  const _StatChip({required this.label, required this.value});

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
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardModeToggle extends StatelessWidget {
  const _LeaderboardModeToggle({
    required this.showFriends,
    required this.onChanged,
  });

  final bool showFriends;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(label: 'Global', active: !showFriends, onTap: () => onChanged(false)),
          ),
          Expanded(
            child: _ModeTab(label: 'Friends', active: showFriends, onTap: () => onChanged(true)),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.pixelifySans(
            color: active ? AppTheme.deepForest : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({required this.byGold, required this.onChanged});

  final bool byGold;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Finance Wizards',
              active: !byGold,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Most Gold',
              active: byGold,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboardState extends StatelessWidget {
  const _EmptyLeaderboardState({required this.showingFriends});

  final bool showingFriends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF163526).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        showingFriends
            ? 'No friends yet — add one from your Profile using their friend code, and ask them to add yours back.'
            : 'Once more players save stats to Supabase, rankings will appear here automatically.',
        style: const TextStyle(
          color: Colors.white,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Top-3 podium: 1st centered and tallest, 2nd on the left, 3rd on the
/// right — the classic hall-of-fame layout, so the leaderboard reads as a
/// stage rather than just the top of a list with bigger font.
class _HallOfFamePodium extends StatelessWidget {
  const _HallOfFamePodium({
    required this.top3,
    required this.byGold,
    required this.currentUserProfileImageUrl,
  });

  final List<LeaderboardEntry> top3;
  final bool byGold;
  final String currentUserProfileImageUrl;

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) {
      return const SizedBox.shrink();
    }
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumPlace(
            entry: second,
            rank: 2,
            standHeight: 64,
            medalColor: const Color(0xFFC0C0C0),
            avatarSize: 52,
            byGold: byGold,
            currentUserProfileImageUrl: currentUserProfileImageUrl,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumPlace(
            entry: first,
            rank: 1,
            standHeight: 96,
            medalColor: const Color(0xFFF4D06F),
            avatarSize: 66,
            crowned: true,
            byGold: byGold,
            currentUserProfileImageUrl: currentUserProfileImageUrl,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumPlace(
            entry: third,
            rank: 3,
            standHeight: 48,
            medalColor: const Color(0xFFCD7F32),
            avatarSize: 46,
            byGold: byGold,
            currentUserProfileImageUrl: currentUserProfileImageUrl,
          ),
        ),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.rank,
    required this.standHeight,
    required this.medalColor,
    required this.avatarSize,
    required this.byGold,
    required this.currentUserProfileImageUrl,
    this.crowned = false,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double standHeight;
  final Color medalColor;
  final double avatarSize;
  final bool byGold;
  final bool crowned;
  final String currentUserProfileImageUrl;

  @override
  Widget build(BuildContext context) {
    final leader = entry;

    Widget avatar() {
      final placeholder = Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E4D3D),
          border: Border.all(color: medalColor, width: 3),
        ),
        child: leader == null
            ? null
            : Center(
                child: Text(
                  leader.username.isNotEmpty
                      ? leader.username[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.pixelifySans(
                    color: medalColor,
                    fontWeight: FontWeight.w700,
                    fontSize: avatarSize * 0.36,
                  ),
                ),
              ),
      );
      if (leader == null) {
        return placeholder;
      }
      final url = leader.profileImageUrl.isNotEmpty
          ? leader.profileImageUrl
          : (leader.isCurrentUser ? currentUserProfileImageUrl : '');
      if (url.isEmpty) {
        return placeholder;
      }
      return ClipOval(
        child: Image.network(
          url,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
        ),
      );
    }

    final value = leader == null
        ? '—'
        : (byGold ? '${leader.gold}g' : leader.scoreLabel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crowned)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.emoji_events_rounded, color: Color(0xFFF4D06F), size: 26),
          ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatar(),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF0E2A1F), width: 2),
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.pixelifySans(
                    color: const Color(0xFF0E2A1F),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          leader?.username ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: leader?.isCurrentUser ?? false
                ? const Color(0xFFF4D06F)
                : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.pixelifySans(
            color: medalColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        // The stand itself — height is what actually sells "podium" versus
        // just three cards in a row.
        Container(
          height: standHeight,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.16),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border(
              top: BorderSide(color: medalColor.withValues(alpha: 0.55), width: 2),
              left: BorderSide(color: medalColor.withValues(alpha: 0.25), width: 1),
              right: BorderSide(color: medalColor.withValues(alpha: 0.25), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.leader,
    required this.byGold,
    required this.currentUserProfileImageUrl,
  });

  final LeaderboardEntry leader;
  final bool byGold;
  final String currentUserProfileImageUrl;

  Widget _initialAvatar() {
    final initial = leader.username.isNotEmpty
        ? leader.username[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.pixelifySans(
          color: Color(0xFF85EFAC),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColor(leader.rank);
    final highlightBorder = leader.isCurrentUser
        ? const Color(0xFFF4D06F)
        : Colors.transparent;

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
                  child: Icon(Icons.emoji_events, color: medalColor, size: 20),
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
                  byGold
                      ? '${leader.literacyPoints} LP • ${leader.xp} XP'
                      : '${leader.xp} XP • ${leader.gold} gold',
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
            byGold ? '${leader.gold}g' : leader.scoreLabel,
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
