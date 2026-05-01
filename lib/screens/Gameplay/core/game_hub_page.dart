import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/user_stats_controller.dart';
import '../../../models/avatar_skin.dart';
import '../../../navigation/app_tab_index.dart';
import '../../../navigation/fade_page_route.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../widgets/custom_button.dart';
import 'main_game_page.dart';
import 'minigames_page.dart';

class GameHubPage extends StatelessWidget {
  const GameHubPage({
    super.key,
    this.activeTabIndex = AppTabIndex.adventure,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  ValueChanged<int>? _detailNavHandler(BuildContext context) {
    final parentNav = onNavSelected;
    if (parentNav == null) {
      return null;
    }

    return (index) {
      Navigator.of(context).pop();
      if (index != activeTabIndex) {
        parentNav(index);
      }
    };
  }

  Future<void> _openMainGameplay(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      FadePageRoute(
        builder: (_) => MainGamePage(
          activeTabIndex: activeTabIndex,
          onNavSelected: _detailNavHandler(context),
        ),
      ),
    );
  }

  Future<void> _openMinigames(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      FadePageRoute(
        builder: (_) => MinigamesPage(
          activeTabIndex: activeTabIndex,
          onNavSelected: _detailNavHandler(context),
        ),
      ),
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
                  onSelected: onNavSelected!,
                ),
          body: Stack(
            children: [
              const _GameHubBackdrop(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth >= 1200
                        ? 26.0
                        : constraints.maxWidth >= 860
                            ? 20.0
                            : 16.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        126,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HubHero(
                            username: stats.username,
                            gold: stats.gold,
                            literacyPoints: stats.literacyPoints,
                            levelTitle: stats.levelTitle,
                            turtleSkin: turtleSkin,
                            onOpenMainGameplay: () => _openMainGameplay(context),
                            onOpenMinigames: () => _openMinigames(context),
                          ),
                          const SizedBox(height: 20),
                          const _SectionHeading(
                            title: 'Choose Your Lane',
                            subtitle:
                                'Adventure and arcade are fully split now, so each lane can stay focused without crowding the other.',
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, laneConstraints) {
                              final stacked = laneConstraints.maxWidth < 860;
                              final cards = [
                                _DestinationCard(
                                  title: 'Main Gameplay',
                                  subtitle:
                                      'Enter the open-world adventure, battle through finance encounters, and keep the main loop centered on progression.',
                                  accent: const Color(0xFF85EFAC),
                                  icon: Icons.explore_rounded,
                                  eyebrow: 'ADVENTURE CORE',
                                  bullets: const [
                                    'Open-world run',
                                    'React challenge',
                                    'Adventure progress',
                                  ],
                                  buttonLabel: 'Open Main Gameplay',
                                  onTap: () => _openMainGameplay(context),
                                ),
                                _DestinationCard(
                                  title: 'Minigames',
                                  subtitle:
                                      'Jump into React Challenge, Bill Dodger, Budget Challenge, and the rest of the arcade lineup without crowding the adventure flow.',
                                  accent: const Color(0xFFE1BB72),
                                  icon: Icons.sports_esports_rounded,
                                  eyebrow: 'ARCADE WING',
                                  bullets: const [
                                    'Bill Dodger',
                                    'Budget Challenge',
                                    'More modes soon',
                                  ],
                                  buttonLabel: 'Open Minigames',
                                  onTap: () => _openMinigames(context),
                                ),
                              ];

                              if (stacked) {
                                return Column(
                                  children: [
                                    for (var index = 0; index < cards.length; index++) ...[
                                      cards[index],
                                      if (index != cards.length - 1)
                                        const SizedBox(height: 14),
                                    ],
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: cards[0]),
                                  const SizedBox(width: 14),
                                  Expanded(child: cards[1]),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const _SectionHeading(
                            title: 'Quick Snapshot',
                            subtitle:
                                'The split keeps long-form progression separate from short arcade loops, while preserving the same look and pacing across the app.',
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, quickConstraints) {
                              final stacked = quickConstraints.maxWidth < 720;
                              final widgets = [
                                _MetricCard(
                                  label: 'Current Gold',
                                  value: '\$${stats.gold}',
                                  accent: const Color(0xFFE3C56D),
                                  icon: Icons.account_balance_wallet_rounded,
                                ),
                                _MetricCard(
                                  label: 'Literacy Points',
                                  value: '${stats.literacyPoints}',
                                  accent: const Color(0xFF58C7FF),
                                  icon: Icons.psychology_alt_rounded,
                                ),
                                _MetricCard(
                                  label: 'Current Rank',
                                  value: stats.levelTitle,
                                  accent: const Color(0xFF85EFAC),
                                  icon: Icons.workspace_premium_rounded,
                                ),
                              ];

                              if (stacked) {
                                return Column(
                                  children: [
                                    for (var index = 0; index < widgets.length; index++) ...[
                                      widgets[index],
                                      if (index != widgets.length - 1)
                                        const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  for (var index = 0; index < widgets.length; index++) ...[
                                    Expanded(child: widgets[index]),
                                    if (index != widgets.length - 1)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              );
                            },
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

class _HubHero extends StatelessWidget {
  const _HubHero({
    required this.username,
    required this.gold,
    required this.literacyPoints,
    required this.levelTitle,
    required this.turtleSkin,
    required this.onOpenMainGameplay,
    required this.onOpenMinigames,
  });

  final String username;
  final int gold;
  final int literacyPoints;
  final String levelTitle;
  final AvatarSkin turtleSkin;
  final VoidCallback onOpenMainGameplay;
  final VoidCallback onOpenMinigames;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;

          final avatar = Container(
            width: stacked ? 96 : 118,
            height: stacked ? 96 : 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  turtleSkin.accent.withValues(alpha: 0.78),
                  const Color(0xFF0D2B20),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: turtleSkin.accent.withValues(alpha: 0.20),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(stacked ? 12 : 16),
              child: ClipOval(
                child: Image.asset(
                  turtleSkin.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );

          final content = Column(
            crossAxisAlignment:
                stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'GAMEPLAY PORTAL',
                style: TextStyle(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.96),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pick your next run, $username.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: stacked ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adventure now stays locked on world progression, while the arcade tab handles the faster challenge sessions.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: stacked ? WrapAlignment.center : WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroPill(
                    label: 'Gold',
                    value: '\$$gold',
                    accent: const Color(0xFFE3C56D),
                  ),
                  _HeroPill(
                    label: 'Literacy',
                    value: '$literacyPoints',
                    accent: const Color(0xFF58C7FF),
                  ),
                  _HeroPill(
                    label: 'Rank',
                    value: levelTitle,
                    accent: const Color(0xFF85EFAC),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, buttonConstraints) {
                  final buttonStacked = stacked || buttonConstraints.maxWidth < 440;

                  final mainButton = CustomButton(
                    label: 'Main Gameplay',
                    onPressed: onOpenMainGameplay,
                    prefixIcon: const Icon(
                      Icons.explore_rounded,
                      size: 18,
                      color: Color(0xFF1A4D3D),
                    ),
                    style: const CustomButtonStyle.secondary(),
                  );
                  final miniButton = CustomButton(
                    label: 'Minigames',
                    onPressed: onOpenMinigames,
                    prefixIcon: const Icon(
                      Icons.sports_esports_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    style: const CustomButtonStyle.tertiary(),
                  );

                  if (buttonStacked) {
                    return Column(
                      children: [
                        mainButton,
                        const SizedBox(height: 10),
                        miniButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: mainButton),
                      const SizedBox(width: 12),
                      Expanded(child: miniButton),
                    ],
                  );
                },
              ),
            ],
          );

          if (stacked) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 18),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 18),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.bullets,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String eyebrow;
  final List<String> bullets;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Text(
                eyebrow,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          CustomButton(
            label: buttonLabel,
            onPressed: onTap,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: accent == const Color(0xFF85EFAC)
                  ? const Color(0xFF76FF03)
                  : Colors.white,
            ),
            style: accent == const Color(0xFF85EFAC)
                ? const CustomButtonStyle.secondary()
                : const CustomButtonStyle.tertiary(),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
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

class _HeroPill extends StatelessWidget {
  const _HeroPill({
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
      constraints: const BoxConstraints(minWidth: 96),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
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

class _GameHubBackdrop extends StatelessWidget {
  const _GameHubBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF071711), Color(0xFF0D211A), Color(0xFF133529)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _GlowOrb(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.12),
            size: 210,
          ),
        ),
        Positioned(
          bottom: 190,
          left: -60,
          child: _GlowOrb(
            color: const Color(0xFF58C7FF).withValues(alpha: 0.08),
            size: 180,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

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
