import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';

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
      limit: 100,
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
    final accent = _byGold ? const Color(0xFFF4D06F) : AppTheme.greenPrimary;

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // A flat solid background was a big part of why this screen read as
      // "bad" next to the rest of the app — everywhere else uses a soft
      // gradient + glow ("puffy") look; this was the one screen still
      // using plain fills.
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.gradientForest),
        child: RefreshIndicator(
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Text(
                    _byGold ? 'Richest Players' : 'Top Finance Wizards',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showFriends
                        ? 'Ranked among friends who\'ve added your code (or you\'ve added theirs).'
                        : leaders.isEmpty
                        ? 'No cloud leaderboard data is available yet, so you are seeing cached progress only.'
                        : _byGold
                        ? 'Ranked by gold — every trade, quest, and case pays off here.'
                        : 'Rankings come from saved user stats, not hardcoded demo names.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Both toggles used to be two nearly-identical stacked
                  // pill bars — visually repetitive with nothing telling
                  // them apart. One panel, two labelled rows, reads as a
                  // single "filters" control instead of two coincidentally
                  // similar widgets.
                  _FilterPanel(
                    showFriends: _showFriends,
                    onFriendsChanged: (friends) => _setMode(friends: friends),
                    byGold: _byGold,
                    onMetricChanged: (byGold) => _setMetric(byGold: byGold),
                  ),
                  const SizedBox(height: 14),
                  _CurrentUserSummary(
                    username: currentUser.username,
                    literacyPoints: currentUser.literacyPoints,
                    xp: currentUser.xp,
                    gold: currentUser.gold,
                    accent: accent,
                  ),
                  const SizedBox(height: 22),
                  if (leaders.isEmpty)
                    _EmptyLeaderboardState(showingFriends: _showFriends)
                  else ...[
                    _HallOfFameStage(
                      top3: podium,
                      byGold: _byGold,
                      currentUserProfileImageUrl: currentUser.profileImageUrl,
                    ),
                    const SizedBox(height: 22),
                    if (rest.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 4),
                        child: Text(
                          'Everyone else',
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ...rest.map(
                      (leader) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LeaderboardRow(
                          leader: leader,
                          byGold: _byGold,
                          currentUserProfileImageUrl:
                              currentUser.profileImageUrl,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One combined panel for both toggles, each row explicitly labelled
/// ("Show" / "Rank by") so the two controls read as related settings on one
/// card instead of two separate, near-identical pill bars.
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.showFriends,
    required this.onFriendsChanged,
    required this.byGold,
    required this.onMetricChanged,
  });

  final bool showFriends;
  final ValueChanged<bool> onFriendsChanged;
  final bool byGold;
  final ValueChanged<bool> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.getPuffyDecoration(
        accent: AppTheme.greenPrimary,
        restAlpha: 0.14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterLabel('SHOW'),
          const SizedBox(height: 6),
          _SegmentedRow(
            leftLabel: 'Global',
            rightLabel: 'Friends',
            activeIsRight: showFriends,
            onChanged: onFriendsChanged,
          ),
          const SizedBox(height: 14),
          _FilterLabel('RANK BY'),
          const SizedBox(height: 6),
          _SegmentedRow(
            leftLabel: 'Finance Wizards',
            rightLabel: 'Most Gold',
            activeIsRight: byGold,
            onChanged: onMetricChanged,
            rightAccent: const Color(0xFFF4D06F),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.quicksand(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.activeIsRight,
    required this.onChanged,
    this.rightAccent,
  });

  final String leftLabel;
  final String rightLabel;
  final bool activeIsRight;
  final ValueChanged<bool> onChanged;
  final Color? rightAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: leftLabel,
              active: !activeIsRight,
              accent: AppTheme.greenPrimary,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: rightLabel,
              active: activeIsRight,
              accent: rightAccent ?? AppTheme.greenPrimary,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedLabel(
          label,
          style: GoogleFonts.pixelifySans(
            color: active ? AppTheme.deepForest : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
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
    required this.accent,
  });

  final String username;
  final int literacyPoints;
  final int xp;
  final int gold;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.getPuffyDecoration(accent: accent, restAlpha: 0.18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Icon(Icons.person_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your saved progress',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatChip(label: 'LP', value: '$literacyPoints'),
          const SizedBox(width: 8),
          _StatChip(label: 'Gold', value: '$gold', isGold: true),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.isGold = false,
  });

  final String label;
  final String value;

  /// Pixel-art coin icon instead of the bare number — this is the one stat
  /// on the whole leaderboard that's actually a currency, so it earns the
  /// same coin glyph used everywhere gold is shown (Home's hero card,
  /// Finance Brawl's HUD).
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGold) ...[
                Image.asset(AppAssets.uiIconCoin, width: 13, height: 13),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
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
      decoration: AppTheme.getPuffyDecoration(
        accent: AppTheme.greenPrimary,
        restAlpha: 0.1,
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

/// The top-3 stage: a single elevated panel holding the podium, instead of
/// three columns floating loose on the page background.
class _HallOfFameStage extends StatelessWidget {
  const _HallOfFameStage({
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

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF4D06F).withValues(alpha: 0.14),
            AppTheme.panelStrong,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: const Color(0xFFF4D06F).withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: AppTheme.puffyShadow(
          const Color(0xFFF4D06F),
          restAlpha: 0.16,
        ),
      ),
      child: Row(
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
          const SizedBox(width: 6),
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
          const SizedBox(width: 6),
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
      ),
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
            child: Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF4D06F),
              size: 26,
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: avatar(),
            ),
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
        // The stand itself — a flat translucent rectangle read as a
        // placeholder, not a podium. A gradient (lighter at the top edge,
        // like a lit surface) plus the glow below sells "3D block" instead
        // of "colored box".
        Container(
          height: standHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.42),
                medalColor.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              top: BorderSide(
                color: medalColor.withValues(alpha: 0.8),
                width: 2,
              ),
              left: BorderSide(
                color: medalColor.withValues(alpha: 0.3),
                width: 1,
              ),
              right: BorderSide(
                color: medalColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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
          color: const Color(0xFF85EFAC),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowAccent = leader.isCurrentUser
        ? const Color(0xFFF4D06F)
        : AppTheme.greenPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppTheme.getPuffyDecoration(
        accent: rowAccent,
        borderRadius: 18,
        restAlpha: leader.isCurrentUser ? 0.22 : 0.08,
        borderOpacity: leader.isCurrentUser ? 0.45 : 0.12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '#${leader.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E4D3D),
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
                      width: 38,
                      height: 38,
                      errorBuilder: (_, _, _) => _initialAvatar(),
                    );
                  }
                  return _initialAvatar();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            byGold ? '${leader.gold}g' : leader.scoreLabel,
            style: TextStyle(color: rowAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
