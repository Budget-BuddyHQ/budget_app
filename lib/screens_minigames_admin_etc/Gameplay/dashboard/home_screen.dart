import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../constants/app_assets.dart';
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

  Future<void> _openLeaderboard(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final turtleSkin = skinFromId(stats.equippedSkin);

        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          appBar: AppBar(
            backgroundColor: const Color(0xFF071711),
            elevation: 0,
            centerTitle: false,
            titleSpacing: 18,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Buddy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  stats.levelTitle,
                  style: const TextStyle(
                    color: Color(0xFF85EFAC),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton.filledTonal(
                  tooltip: 'Leaderboard',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF85EFAC,
                    ).withValues(alpha: 0.12),
                    foregroundColor: const Color(0xFFFFD45C),
                  ),
                  onPressed: () => _openLeaderboard(context),
                  icon: const Icon(Icons.emoji_events_rounded),
                ),
              ),
            ],
          ),
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
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeight = constraints.maxHeight < 650;
                    final heroHeight =
                        (constraints.maxHeight * (compactHeight ? 0.36 : 0.40))
                            .clamp(210.0, 300.0)
                            .toDouble();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 124),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: heroHeight,
                            child: _AdventureLaunchHero(
                              stats: stats,
                              turtleSkin: turtleSkin,
                              profileImageUrl: stats.profileImageUrl,
                              compact: compactHeight,
                              onOpenAdventure: () =>
                                  onNavSelected?.call(AppTabIndex.adventure),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CurrentObjectiveCard(
                            stats: stats,
                            compact: compactHeight,
                            onPlayNow: () => _launchDailyChallenge(context),
                            onOpenAdventure: () =>
                                onNavSelected?.call(AppTabIndex.adventure),
                            onOpenArcade: () =>
                                onNavSelected?.call(AppTabIndex.minigames),
                            onOpenAcademy: () =>
                                onNavSelected?.call(AppTabIndex.academy),
                            onCustomize: () =>
                                onNavSelected?.call(AppTabIndex.customize),
                          ),
                        ],
                      ),
                    );
                  },
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

class _AdventureLaunchHero extends StatelessWidget {
  const _AdventureLaunchHero({
    required this.stats,
    required this.turtleSkin,
    required this.profileImageUrl,
    required this.compact,
    required this.onOpenAdventure,
  });

  final UserStats stats;
  final AvatarSkin turtleSkin;
  final String profileImageUrl;
  final bool compact;
  final VoidCallback? onOpenAdventure;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenAdventure == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onOpenAdventure!();
            },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF15392D), Color(0xFF071711)],
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
              blurRadius: 34,
              spreadRadius: -8,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final veryTight = constraints.maxHeight < 240;
            return Stack(
              children: [
                if (!veryTight)
                  Positioned(
                    right: constraints.maxWidth < 520 ? 8 : 128,
                    top: 18,
                    child: Opacity(
                      opacity: 0.52,
                      child: AmbientLottieCard(
                        assetPath: AppAssets.turtleMovingAnimation,
                        semanticLabel: 'Moving turtle decoration',
                        width: constraints.maxWidth < 520 ? 88 : 126,
                        height: constraints.maxWidth < 520 ? 72 : 96,
                        padding: const EdgeInsets.all(6),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        borderColor: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: _HeroAvatar(
                    turtleSkin: turtleSkin,
                    profileImageUrl: profileImageUrl,
                    size: veryTight ? 70 : 92,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth < 520
                          ? constraints.maxWidth * 0.78
                          : constraints.maxWidth * 0.58,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF85EFAC,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(
                                0xFF85EFAC,
                              ).withValues(alpha: 0.20),
                            ),
                          ),
                          child: Text(
                            'Level ${stats.level}  |  ${stats.gold} Gold',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF85EFAC),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: veryTight ? 8 : 12),
                        Text(
                          'Adventure Soon',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: veryTight ? 27 : 34,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        if (!veryTight) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Scout the emerald route and clear your next RPG encounter.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              height: 1.32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        SizedBox(height: veryTight ? 10 : 16),
                        _ActionButton(
                          label: 'Enter World',
                          accent: const Color(0xFF85EFAC),
                          icon: Icons.explore_rounded,
                          onTap: onOpenAdventure,
                        ),
                      ],
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

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({
    required this.turtleSkin,
    required this.profileImageUrl,
    required this.size,
  });

  final AvatarSkin turtleSkin;
  final String profileImageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF071711).withValues(alpha: 0.74),
        border: Border.all(color: const Color(0xFF85EFAC), width: 2.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: profileImageUrl.isNotEmpty
            ? Image.network(
                profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.asset(turtleSkin.assetPath, fit: BoxFit.contain),
              )
            : Image.asset(turtleSkin.assetPath, fit: BoxFit.contain),
      ),
    );
  }
}

class _CurrentObjectiveCard extends StatelessWidget {
  const _CurrentObjectiveCard({
    required this.stats,
    required this.compact,
    required this.onPlayNow,
    required this.onOpenAdventure,
    required this.onOpenArcade,
    required this.onOpenAcademy,
    required this.onCustomize,
  });

  final UserStats stats;
  final bool compact;
  final VoidCallback onPlayNow;
  final VoidCallback? onOpenAdventure;
  final VoidCallback? onOpenArcade;
  final VoidCallback? onOpenAcademy;
  final VoidCallback? onCustomize;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: EdgeInsets.all(compact ? 14 : 18),
      radius: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tight = compact;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: tight ? 42 : 50,
                    height: tight ? 42 : 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF85EFAC).withValues(alpha: 0.26),
                      ),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFF85EFAC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Objective',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Daily run | Academy | Arcade tools',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.64),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!tight) ...[
                    const SizedBox(width: 12),
                    AmbientLottieCard(
                      assetPath: AppAssets.arcadeLoopAnimation,
                      semanticLabel: 'Arcade decoration',
                      width: 92,
                      height: 70,
                      padding: const EdgeInsets.all(6),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      borderColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ],
                ],
              ),
              if (!tight) ...[
                const SizedBox(height: 14),
                Text(
                  'Enter the adventure, then use a quick practice loop if you need more gold or literacy points.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    height: 1.34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              SizedBox(height: tight ? 12 : 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: tight ? 9 : 12,
                  value: stats.levelProgress.clamp(0.08, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF85EFAC),
                  ),
                ),
              ),
              SizedBox(height: tight ? 12 : 16),
              _ObjectiveActionBar(
                compact: tight,
                onAdventure: onOpenAdventure,
                onDaily: onPlayNow,
                onArcade: onOpenArcade,
                onAcademy: onOpenAcademy,
                onCustomize: onCustomize,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ObjectiveActionBar extends StatelessWidget {
  const _ObjectiveActionBar({
    required this.compact,
    required this.onAdventure,
    required this.onDaily,
    required this.onArcade,
    required this.onAcademy,
    required this.onCustomize,
  });

  final bool compact;
  final VoidCallback? onAdventure;
  final VoidCallback onDaily;
  final VoidCallback? onArcade;
  final VoidCallback? onAcademy;
  final VoidCallback? onCustomize;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _ObjectiveIconButton(
        label: compact ? 'World' : 'Adventure',
        icon: Icons.explore_rounded,
        accent: const Color(0xFF85EFAC),
        onTap: onAdventure,
      ),
      _ObjectiveIconButton(
        label: 'Daily',
        icon: Icons.play_arrow_rounded,
        accent: const Color(0xFFFFD45C),
        onTap: onDaily,
      ),
      _ObjectiveIconButton(
        label: 'Arcade',
        icon: Icons.sports_esports_rounded,
        accent: const Color(0xFF58C7FF),
        onTap: onArcade,
      ),
      _ObjectiveIconButton(
        label: 'Academy',
        icon: Icons.school_rounded,
        accent: const Color(0xFF85EFAC),
        onTap: onAcademy,
      ),
      _ObjectiveIconButton(
        label: 'Style',
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFFFFD45C),
        onTap: onCustomize,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Row(
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                Expanded(child: buttons[index]),
                if (index != buttons.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < buttons.length; index++) ...[
              Expanded(child: buttons[index]),
              if (index != buttons.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ObjectiveIconButton extends StatelessWidget {
  const _ObjectiveIconButton({
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
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconOnly = constraints.maxWidth < 70;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: accent, size: 22),
                  if (!iconOnly) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final IconData icon;
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
        height: 56,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF062C21)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF062C21),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}
