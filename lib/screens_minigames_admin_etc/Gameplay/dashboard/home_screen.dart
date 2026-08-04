import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../adventure/adventure_world_screen.dart';
import '../../../config/dev_preview_flags.dart';
import '../../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../../controllers_that_updates_stats/daily_plan_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../models_Like_Skins_and_lessons_templates/daily_quest.dart';
import '../../../constants/app_assets.dart';
import 'daily_plan_card.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../../widgets_custom_lotties/feedback_prompt_sheet.dart';
import '../../../widgets_custom_lotties/idle_hover_icon.dart';
import '../../../widgets_custom_lotties/profile_avatar.dart';
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

  Future<void> _openAdventureWorld(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdventureWorldScreen()));
  }

  Future<void> _openLeaderboard(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
  }

  /// Sends the player to the quest's target surface. The completion for
  /// learning quests is credited when the underlying lesson/game reports
  /// progress, but for now tapping also marks the quest done so the checklist
  /// always advances — the modes route through the existing tab switcher.
  void _openQuest(BuildContext context, DailyQuest quest) {
    // Optimistically credit the daily plan; the actual lesson/game still
    // awards its own XP through its own flow.
    context.read<DailyPlanController>().completeQuest(quest.id);

    switch (quest.surface) {
      case QuestSurface.academyLesson:
      case QuestSurface.academyPractice:
        onNavSelected?.call(AppTabIndex.academy);
      case QuestSurface.arcade:
        onNavSelected?.call(AppTabIndex.minigames);
      case QuestSurface.adventure:
        onNavSelected?.call(AppTabIndex.adventure);
    }
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
                Text(
                  'Budget Buddy',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
                                  _openAdventureWorld(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PlayLifePromo(
                            onPlay: () =>
                                Navigator.of(context).pushNamed('/life'),
                          ),
                          const SizedBox(height: 10),
                          DailyPlanCard(
                            compact: compactHeight,
                            onOpenQuest: (quest) => _openQuest(context, quest),
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
              // "Is now a reasonable moment" lives in
              // AppSettingsController.isFeedbackPromptDue (launch count +
              // cooldown) so it works with or without Supabase configured.
              if (kFeedbackEnabled) const _FeedbackPromptTrigger(),
            ],
          ),
        );
      },
    );
  }
}

/// Invisible — checks once per Home mount (tabs are kept alive in an
/// `IndexedStack`, so this only runs once per app session) whether the
/// occasional feedback prompt is due, and shows it if so. Split out from
/// [HomeScreen] itself just so that screen can stay a plain
/// [StatelessWidget]; this is the only part of Home that needs `initState`.
class _FeedbackPromptTrigger extends StatefulWidget {
  const _FeedbackPromptTrigger();

  @override
  State<_FeedbackPromptTrigger> createState() =>
      _FeedbackPromptTriggerState();
}

class _FeedbackPromptTriggerState extends State<_FeedbackPromptTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    if (!mounted) return;
    final settings = context.read<AppSettingsController>();
    if (!settings.isFeedbackPromptDue) {
      return;
    }
    await settings.recordFeedbackPromptShown();
    if (!mounted) return;
    await FeedbackPromptSheet.show(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Home-screen promo for the main game (Life), so it's front-and-centre rather
/// than buried like a minigame.
class _PlayLifePromo extends StatelessWidget {
  const _PlayLifePromo({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C5038), Color(0xFF0C2A1E)],
          ),
          border: Border.all(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const IdleHoverIcon(
                // A heartbeat pulse instead of a bob — fits the icon itself
                // rather than just reusing the same motion everywhere.
                idleAmplitude: 0,
                pulseAmplitude: 0.14,
                period: Duration(milliseconds: 1400),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF85EFAC),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Play Life',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFD45C,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'MAIN GAME',
                          style: TextStyle(
                            color: Color(0xFFFFD45C),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grow up, make money decisions, explore the town.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const IdleHoverIcon(
              phaseShift: 0.5,
              idleAmplitude: 0,
              continuousSpin: true,
              period: Duration(seconds: 8),
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF85EFAC),
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AppAssets.homeTileBackground,
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.none,
          ),
        ),
        // The tile art is a small repeating icon pattern meant as ambient
        // texture, but the thin gaps between cards used to expose it at
        // near-full strength — a crisp, chopped-off sliver of icons in every
        // gap read as visual debris rather than intentional decoration.
        // A much heavier dim turns it into a soft wash instead.
        Positioned.fill(
          child: Container(
            color: const Color(0xFF071711).withValues(alpha: 0.82),
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
                        motif: AmbientMotif.turtle,
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
    return IdleHoverIcon(
      idleAmplitude: 1.5,
      hoverScale: 1.05,
      child: ProfileAvatar(
        imageUrl: profileImageUrl,
        fallbackSkin: turtleSkin,
        size: size,
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
                      motif: AmbientMotif.arcade,
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

/// The main CTA on the home hero — deliberately more theatrical than a plain
/// button, since it's the single most-tapped element on the screen.
///
/// Three animations run together: a continuous diagonal shine sweeping
/// across the button, a slow breathing glow behind it, and — on press — a
/// 3D tilt-and-snap "flip" (a perspective rotation that dips away from the
/// finger then springs back with an elastic overshoot) instead of a plain
/// scale-down. Desktop/web additionally gets a hover lift.
class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _loopController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 200),
  );

  bool _hovering = false;

  @override
  void dispose() {
    _loopController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _setHover(bool value) {
    if (_hovering != value) setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _loopController.isAnimating) {
      _loopController.stop();
    } else if (!reduceMotion && !_loopController.isAnimating) {
      _loopController.repeat();
    }

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => _pressController.forward(),
        onTapCancel: () => _pressController.reverse(),
        onTapUp: (_) => _pressController.reverse(),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onTap!();
              },
        child: AnimatedBuilder(
          animation: Listenable.merge([_loopController, _pressController]),
          builder: (context, child) {
            final loop = _loopController.value;
            // Elastic overshoot on the way back gives the "snap" feel; the
            // press-down half stays a plain curve so it doesn't overshoot
            // while the finger is still down.
            final pressCurve =
                _pressController.status == AnimationStatus.reverse
                ? Curves.elasticOut.transform(1 - _pressController.value)
                : Curves.easeOut.transform(_pressController.value);
            final tilt = pressCurve * 0.22;
            final dip = pressCurve * 5;
            final lift = reduceMotion ? 0.0 : (_hovering ? -3.0 : 0.0);
            final breathe = reduceMotion
                ? 0.0
                : math.sin(loop * 2 * math.pi) * 0.5 + 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..translateByDouble(0.0, dip + lift, 0.0, 1.0)
                ..rotateX(-tilt),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: _hovering ? 0.55 : 0.0,
                    ),
                    width: 1.4,
                  ),
                  boxShadow: reduceMotion
                      ? null
                      : [
                          BoxShadow(
                            color: widget.accent.withValues(
                              alpha: 0.28 + breathe * 0.24,
                            ),
                            blurRadius: 16 + breathe * 14,
                            spreadRadius: -2 + breathe * 2,
                          ),
                        ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  // Stack defaults non-positioned children to top-start, so
                  // the shrink-wrapped icon+label Row below was hugging the
                  // left edge instead of sitting in the middle of the
                  // button — this is what actually centers it.
                  alignment: Alignment.center,
                  children: [
                    if (!reduceMotion)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _ShineSweep(progress: loop),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      // These buttons sit in a Row of equal-width slots, so
                      // on a narrow phone the label has to be allowed to
                      // shrink rather than push the icon off the edge.
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: const Color(0xFF062C21),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                color: Color(0xFF062C21),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A diagonal light band sweeping left-to-right on a loop — the "shine"
/// effect used on game CTAs to keep an idle button from reading as inert.
class _ShineSweep extends StatelessWidget {
  const _ShineSweep({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Travels from just off the left edge to just off the right edge,
        // with a pause at each end so the sweep reads as a deliberate pulse
        // rather than a constant scroll.
        final t = Curves.easeInOutCubic.transform(
          (progress * 1.6).clamp(0.0, 1.0) % 1.0,
        );
        final travel = constraints.maxWidth * 1.6;
        final x = -constraints.maxWidth * 0.3 + travel * t;
        return Transform.translate(
          offset: Offset(x, 0),
          child: Transform.rotate(
            angle: -0.5,
            child: Container(
              width: constraints.maxWidth * 0.22,
              height: constraints.maxHeight * 2.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
