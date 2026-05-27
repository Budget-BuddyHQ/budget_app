import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../minigames_pages/react_challenge_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.dashboard,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _launchDailyChallenge(BuildContext context) async {
    final stats = context.read<UserStatsController>().stats;
    final result = await Navigator.of(context).push<ReactGameCloseResult>(
      MaterialPageRoute(
        builder: (_) => ReactGameScreen(
          gameId: 'daily_budget_battle',
          difficulty: 'normal',
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
      title: result.status == 'victory'
          ? 'Daily Challenge Cleared'
          : 'Challenge Complete',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.workspace_premium_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final turtleSkin = skinFromId(stats.equippedSkin);

        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: Stack(
            children: [
              const _DashboardBackdrop(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
                  children: [
                    _DashboardHeader(
                      stats: stats,
                      turtleSkin: turtleSkin,
                      profileImageUrl: stats.profileImageUrl,
                    ),
                    const SizedBox(height: 18),
                    _DailyChallengeCard(
                      onPlayNow: () => _launchDailyChallenge(context),
                      onOpenAdventure: () =>
                          onNavSelected?.call(AppTabIndex.adventure),
                      onOpenArcade: () =>
                          onNavSelected?.call(AppTabIndex.minigames),
                    ),
                    const SizedBox(height: 18),
                    _LiteracyProgressCard(stats: stats),
                    const SizedBox(height: 18),
                    _QuickAccessRow(
                      onArcade: () => onNavSelected?.call(AppTabIndex.minigames),
                      onCustomize: () =>
                          onNavSelected?.call(AppTabIndex.customize),
                      onAcademy: () =>
                          onNavSelected?.call(AppTabIndex.academy),
                    ),
                    const SizedBox(height: 18),
                    _LeaderboardPreview(
                      currentUserId: stats.id,
                      onOpenFull: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF071711), Color(0xFF0C241B), Color(0xFF113127)],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: _GlowOrb(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.18),
            size: 190,
          ),
        ),
        Positioned(
          top: 320,
          left: -70,
          child: _GlowOrb(
            color: const Color(0xFF58C7FF).withValues(alpha: 0.10),
            size: 180,
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.stats,
    required this.turtleSkin,
    required this.profileImageUrl,
  });

  final UserStats stats;
  final AvatarSkin turtleSkin;
  final String profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;
          final avatar = Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  turtleSkin.accent.withValues(alpha: 0.36),
                  const Color(0xFF0D2B20),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF85EFAC).withValues(alpha: 0.85),
                width: 2.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.28),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          turtleSkin.assetPath,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(turtleSkin.assetPath, fit: BoxFit.contain),
              ),
            ),
          );

          final copy = Column(
            crossAxisAlignment:
                stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${stats.username}',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stats.levelTitle,
                style: const TextStyle(
                  color: Color(0xFF85EFAC),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gold: ${stats.gold}  •  Literacy: ${stats.literacyPoints}',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final illustration = const AmbientLottieCard(
            assetPath: 'assets/animations/turtlemoving.json',
            semanticLabel: 'Animated Budget Buddy turtle illustration',
            height: 150,
            width: 160,
            padding: EdgeInsets.all(12),
          );

          if (stacked) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 16),
                copy,
                const SizedBox(height: 16),
                illustration,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(child: copy),
              const SizedBox(width: 16),
              illustration,
            ],
          );
        },
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.onPlayNow,
    required this.onOpenAdventure,
    required this.onOpenArcade,
  });

  final VoidCallback onPlayNow;
  final VoidCallback? onOpenAdventure;
  final VoidCallback? onOpenArcade;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Challenge',
            style: TextStyle(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.96),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Budget Battle: defend your coin stash against surprise spending traps.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start with the featured challenge, then branch into the adventure tab for longer runs or the arcade tab for shorter practice loops.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 460;
              final playButton = _ActionButton(
                label: 'Play Daily Challenge',
                accent: const Color(0xFF85EFAC),
                icon: Icons.play_arrow_rounded,
                onTap: onPlayNow,
              );
              final adventureButton = _ActionButton(
                label: 'Open Adventure',
                accent: const Color(0xFFFFD45C),
                icon: Icons.explore_rounded,
                onTap: onOpenAdventure,
                filled: false,
              );
              final arcadeButton = _ActionButton(
                label: 'Open Arcade',
                accent: const Color(0xFF58C7FF),
                icon: Icons.sports_esports_rounded,
                onTap: onOpenArcade,
                filled: false,
              );

              if (stacked) {
                return Column(
                  children: [
                    playButton,
                    const SizedBox(height: 10),
                    adventureButton,
                    const SizedBox(height: 10),
                    arcadeButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: playButton),
                  const SizedBox(width: 12),
                  Expanded(child: adventureButton),
                  const SizedBox(width: 12),
                  Expanded(child: arcadeButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiteracyProgressCard extends StatelessWidget {
  const _LiteracyProgressCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Literacy Points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.literacyPoints} LP',
            style: const TextStyle(
              color: Color(0xFFFFD45C),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are ${(stats.levelProgress * 100).round()}% of the way to the next Finance Wizard level.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 13,
              value: stats.levelProgress.clamp(0.08, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF85EFAC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.onArcade,
    required this.onCustomize,
    required this.onAcademy,
  });

  final VoidCallback onArcade;
  final VoidCallback onCustomize;
  final VoidCallback onAcademy;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _QuickAccessCard(
        label: 'Arcade',
        icon: Icons.sports_esports_rounded,
        accent: const Color(0xFF58C7FF),
        onTap: onArcade,
      ),
      _QuickAccessCard(
        label: 'Customize',
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFFFFD45C),
        onTap: onCustomize,
      ),
      _QuickAccessCard(
        label: 'Academy',
        icon: Icons.school_rounded,
        accent: const Color(0xFF85EFAC),
        onTap: onAcademy,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview({
    required this.currentUserId,
    required this.onOpenFull,
  });

  final String currentUserId;
  final VoidCallback onOpenFull;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: SupabaseService.instance.fetchLeaderboard(
        limit: 3,
        currentUserId: currentUserId,
      ),
      builder: (context, snapshot) {
        final leaders = snapshot.data ?? const <LeaderboardEntry>[];

        return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Global Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenFull,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF85EFAC),
                    ),
                  ),
                )
              else if (leaders.isEmpty)
                Text(
                  'Leaderboard data will appear here as soon as saved profiles are available.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                )
              else
                ...leaders.map(
                  (leader) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LeaderboardTile(leader: leader),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: onTap == null
                  ? Colors.white.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.62),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.filled = true,
  });

  final String label;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ? Colors.transparent : accent.withValues(alpha: 0.42),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? const Color(0xFF062C21) : accent),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: filled ? const Color(0xFF062C21) : accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.leader});

  final LeaderboardEntry leader;

  @override
  Widget build(BuildContext context) {
    final medal = switch (leader.rank) {
      1 => const Color(0xFFFFD45C),
      2 => const Color(0xFFD2DBE2),
      _ => const Color(0xFFCD7F32),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: leader.isCurrentUser
            ? const Color(0xFF85EFAC).withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: leader.isCurrentUser
              ? const Color(0xFF85EFAC).withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: medal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              leader.username,
              style: TextStyle(
                color: leader.isCurrentUser
                    ? const Color(0xFF85EFAC)
                    : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            leader.scoreLabel,
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.40,
              spreadRadius: size * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

