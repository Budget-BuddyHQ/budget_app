import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/adventure_state_controller.dart';
import '../../../controllers/user_stats_controller.dart';
import '../../../navigation/app_tab_index.dart';
import '../../../navigation/fade_page_route.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/game_toast.dart';
import '../../../widgets/skeleton_loader.dart';
import 'game_canvas.dart';

class MainGamePage extends StatelessWidget {
  const MainGamePage({
    super.key,
    this.activeTabIndex = AppTabIndex.adventure,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openAdventure(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      FadePageRoute(
        builder: (_) => const GameCanvas(),
      ),
    );
  }

  Future<void> _openAcademy(BuildContext context) async {
    HapticFeedback.lightImpact();
    final selectTab = onNavSelected;
    if (selectTab != null) {
      selectTab(AppTabIndex.academy);
      return;
    }
    await Navigator.of(context).pushNamed('/lessons');
  }

  Future<void> _openMinigames(BuildContext context) async {
    HapticFeedback.lightImpact();
    final selectTab = onNavSelected;
    if (selectTab != null) {
      selectTab(AppTabIndex.minigames);
      return;
    }
    await Navigator.of(context).pushNamed('/minigames');
  }

  void _scoutEncounter(BuildContext context) {
    final adventure = context.read<AdventureStateController>();
    if (adventure.combatVisible) {
      _openAdventure(context);
      return;
    }

    adventure.scoutEncounter();
    GameToast.show(
      context,
      title: 'Encounter scouted',
      message:
          '${adventure.encounterEnemyName} is waiting in ${adventure.currentDistrict}.',
      icon: Icons.track_changes_rounded,
      accent: const Color(0xFF85EFAC),
    );
  }

  void _recover(BuildContext context) {
    final adventure = context.read<AdventureStateController>();
    final previousHealth = adventure.health;
    adventure.recoverHealth();
    final recovered = adventure.health - previousHealth;

    GameToast.show(
      context,
      title: recovered > 0 ? 'Recovered' : 'Already full health',
      message: recovered > 0
          ? '+$recovered health restored for the next run.'
          : 'You are already ready for the next encounter.',
      icon: Icons.favorite_rounded,
      accent: const Color(0xFFFF8A80),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserStatsController, AdventureStateController>(
      builder: (context, controller, adventure, _) {
        final stats = controller.stats;
        final isLoading = controller.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF0A211A),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected!,
                ),
          body: SafeArea(
            child: Stack(
              children: [
                const _MainBackdrop(),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(
                        title: 'Main Gameplay',
                        subtitle:
                            'This tab is now the pure adventure lane: scout encounters, manage readiness, and jump into the world without arcade shortcuts crowding the flow.',
                      ),
                      const SizedBox(height: 18),
                      _MainHeroCard(
                        username: stats.username,
                        levelTitle: stats.levelTitle,
                        district: adventure.currentDistrict,
                        focus: adventure.sessionFocus,
                        onOpenAdventure: () => _openAdventure(context),
                        onOpenAcademy: () => _openAcademy(context),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 760;
                          final cards = [
                            _QuickStatCard(
                              label: 'Campaign',
                              value: 'Chapter ${adventure.chapter}',
                              icon: Icons.map_rounded,
                              accent: const Color(0xFF85EFAC),
                            ),
                            _QuickStatCard(
                              label: 'Readiness',
                              value: '${adventure.readinessScore}% ',
                              icon: Icons.shield_rounded,
                              accent: const Color(0xFF58C7FF),
                            ),
                            _QuickStatCard(
                              label: 'Encounters Won',
                              value: '${adventure.encountersWon}',
                              icon: Icons.emoji_events_rounded,
                              accent: const Color(0xFFE3C56D),
                            ),
                          ];

                          if (stacked) {
                            return Column(
                              children: [
                                for (var index = 0; index < cards.length; index++) ...[
                                  cards[index],
                                  if (index != cards.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              for (var index = 0; index < cards.length; index++) ...[
                                Expanded(child: cards[index]),
                                if (index != cards.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _CampaignStatusCard(
                        chapter: adventure.chapter,
                        district: adventure.currentDistrict,
                        readinessLabel: adventure.readinessLabel,
                        chapterProgress: adventure.chapterProgress,
                        focus: adventure.sessionFocus,
                      ),
                      const SizedBox(height: 16),
                      _FieldToolsCard(
                        combatVisible: adventure.combatVisible,
                        encounterEnemyName: adventure.encounterEnemyName,
                        currentDistrict: adventure.currentDistrict,
                        onScout: () => _scoutEncounter(context),
                        onRecover: () => _recover(context),
                        onOpenAdventure: () => _openAdventure(context),
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle(
                        title: 'Session Roadmap',
                        subtitle:
                            'Adventure stays focused here, while academy study and arcade runs branch off into their own dedicated tabs.',
                      ),
                      const SizedBox(height: 14),
                      _SessionChecklistCard(
                        objectives: adventure.sessionObjectives,
                        streakDays: adventure.streakDays,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 760;
                          final cards = [
                            _ActivityCard(
                              title: 'Academy Sync',
                              subtitle:
                                  'Review the next lesson before your next run when you want more confidence going into encounters.',
                              badge: 'LEARNING SUPPORT',
                              accent: const Color(0xFF58C7FF),
                              icon: Icons.school_rounded,
                              buttonLabel: 'Open Academy',
                              onPressed: () => _openAcademy(context),
                              style: const CustomButtonStyle.tertiary(),
                              iconColor: Colors.white,
                            ),
                            _ActivityCard(
                              title: 'Arcade Wing',
                              subtitle:
                                  'React Challenge, Bill Dodger, Budget Challenge, and Market Board now live in their own separate lane.',
                              badge: 'SEPARATE TAB',
                              accent: const Color(0xFFE3C56D),
                              icon: Icons.sports_esports_rounded,
                              buttonLabel: 'Open Minigames',
                              onPressed: () => _openMinigames(context),
                              style: const CustomButtonStyle.secondary(),
                              iconColor: const Color(0xFF1A4D3D),
                            ),
                          ];

                          if (stacked) {
                            return Column(
                              children: [
                                for (var index = 0; index < cards.length; index++) ...[
                                  cards[index],
                                  if (index != cards.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 12),
                              Expanded(child: cards[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _AdventureStatusCard(
                        encounterEnemyName: adventure.encounterEnemyName,
                        combatVisible: adventure.combatVisible,
                        health: adventure.health,
                        maxHealth: adventure.maxHealth,
                        advice: stats.wizardAdvice,
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.08),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                          child: Column(
                            children: const [
                              SkeletonLoader(height: 90, borderRadius: 24),
                              SizedBox(height: 18),
                              SkeletonLoader(height: 250, borderRadius: 30),
                              SizedBox(height: 18),
                              SkeletonLoader(height: 102, borderRadius: 22),
                              SizedBox(height: 12),
                              SkeletonLoader(height: 180, borderRadius: 22),
                              SizedBox(height: 12),
                              SkeletonLoader(height: 180, borderRadius: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                height: 1.45,
              ),
            ),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
              copy,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.of(context).canPop()) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            Expanded(child: copy),
          ],
        );
      },
    );
  }
}

class _MainHeroCard extends StatelessWidget {
  const _MainHeroCard({
    required this.username,
    required this.levelTitle,
    required this.district,
    required this.focus,
    required this.onOpenAdventure,
    required this.onOpenAcademy,
  });

  final String username;
  final String levelTitle;
  final String district;
  final String focus;
  final VoidCallback onOpenAdventure;
  final VoidCallback onOpenAcademy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF14372B).withValues(alpha: 0.96),
            const Color(0xFF1D4738).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;

          final buttons = Column(
            children: [
              CustomButton(
                label: 'Open Adventure',
                onPressed: onOpenAdventure,
                prefixIcon: const Icon(
                  Icons.explore_rounded,
                  size: 18,
                  color: Color(0xFF76FF03),
                ),
                style: const CustomButtonStyle.secondary(),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: 'Review Academy',
                onPressed: onOpenAcademy,
                prefixIcon: const Icon(
                  Icons.school_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                style: const CustomButtonStyle.tertiary(),
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment:
                stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MAIN GAMEPLAY LOOP',
                  style: TextStyle(
                    color: Color(0xFF85EFAC),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Back to the field, $username.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                focus,
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: stacked ? WrapAlignment.center : WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    label: 'Rank',
                    value: levelTitle,
                    accent: const Color(0xFF85EFAC),
                  ),
                  _InfoChip(
                    label: 'District',
                    value: district,
                    accent: const Color(0xFF58C7FF),
                  ),
                  const _InfoChip(
                    label: 'Session',
                    value: 'Explore + Learn',
                    accent: Color(0xFFE3C56D),
                  ),
                ],
              ),
            ],
          );

          if (stacked) {
            return Column(
              children: [
                copy,
                const SizedBox(height: 18),
                buttons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: copy),
              const SizedBox(width: 18),
              Expanded(flex: 2, child: buttons),
            ],
          );
        },
      ),
    );
  }
}

class _CampaignStatusCard extends StatelessWidget {
  const _CampaignStatusCard({
    required this.chapter,
    required this.district,
    required this.readinessLabel,
    required this.chapterProgress,
    required this.focus,
  });

  final int chapter;
  final String district;
  final String readinessLabel;
  final double chapterProgress;
  final String focus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign Status',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chapter $chapter • $district • $readinessLabel',
            style: const TextStyle(
              color: Color(0xFF85EFAC),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            focus,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: chapterProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldToolsCard extends StatelessWidget {
  const _FieldToolsCard({
    required this.combatVisible,
    required this.encounterEnemyName,
    required this.currentDistrict,
    required this.onScout,
    required this.onRecover,
    required this.onOpenAdventure,
  });

  final bool combatVisible;
  final String encounterEnemyName;
  final String currentDistrict;
  final VoidCallback onScout;
  final VoidCallback onRecover;
  final VoidCallback onOpenAdventure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 420;
              final title = const Text(
                'Field Tools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              );
              final badge = combatVisible
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD45C).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'ENCOUNTER READY',
                        style: TextStyle(
                          color: Color(0xFFFFD45C),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : null;

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (badge != null) ...[
                      const SizedBox(height: 10),
                      badge,
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  if (badge != null) badge,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            combatVisible
                ? '$encounterEnemyName is active in $currentDistrict. Open the adventure to finish the fight.'
                : 'Scout the next threat, recover before another run, or head straight back into the world map.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              final buttons = <Widget>[
                _ActionTile(
                  label: combatVisible ? 'Resume Encounter' : 'Scout Encounter',
                  icon: Icons.track_changes_rounded,
                  accent: const Color(0xFF85EFAC),
                  onTap: onScout,
                ),
                _ActionTile(
                  label: 'Recover',
                  icon: Icons.favorite_rounded,
                  accent: const Color(0xFFFF8A80),
                  onTap: onRecover,
                ),
                _ActionTile(
                  label: 'Open Adventure',
                  icon: Icons.explore_rounded,
                  accent: const Color(0xFF58C7FF),
                  onTap: onOpenAdventure,
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      buttons[i],
                      if (i != buttons.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    Expanded(child: buttons[i]),
                    if (i != buttons.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionChecklistCard extends StatelessWidget {
  const _SessionChecklistCard({
    required this.objectives,
    required this.streakDays,
  });

  final List<String> objectives;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E4A3A).withValues(alpha: 0.94),
            const Color(0xFF14372B).withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Checklist • $streakDays day streak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...objectives.map(
            (objective) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF85EFAC),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      objective,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
    required this.style,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;
  final CustomButtonStyle style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 220;
              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badgeWidget,
                    const SizedBox(height: 10),
                    Icon(icon, color: accent),
                  ],
                );
              }

              return Row(
                children: [
                  Flexible(child: badgeWidget),
                  const Spacer(),
                  Icon(icon, color: accent),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: buttonLabel,
            onPressed: onPressed,
            style: style,
            prefixIcon: Icon(icon, size: 18, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _AdventureStatusCard extends StatelessWidget {
  const _AdventureStatusCard({
    required this.encounterEnemyName,
    required this.combatVisible,
    required this.health,
    required this.maxHealth,
    required this.advice,
  });

  final String encounterEnemyName;
  final bool combatVisible;
  final int health;
  final int maxHealth;
  final String advice;

  @override
  Widget build(BuildContext context) {
    final statusText = combatVisible
        ? 'An encounter with $encounterEnemyName is active right now.'
        : 'No active encounter. The world map is clear for your next run.';
    final healthProgress = maxHealth == 0 ? 0.0 : health / maxHealth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E4A3A).withValues(alpha: 0.94),
            const Color(0xFF14372B).withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adventure Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFFF8A80),
              ),
              const SizedBox(width: 8),
              Text(
                'Health $health / $maxHealth',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: healthProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF8A80),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wizard Advice',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            advice,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
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
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _MainBackdrop extends StatelessWidget {
  const _MainBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF071711),
                Color(0xFF0C2B21),
                Color(0xFF11372C),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF85EFAC).withValues(alpha: 0.10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
