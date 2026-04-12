import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../models/avatar_skin.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import 'game_canvas.dart';

class GameHubPage extends StatelessWidget {
  const GameHubPage({
    super.key,
    this.activeTabIndex = 1,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _startAdventure(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GameCanvas(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final turtleSkin = skinFromId(stats.equippedSkin);

        final cards = <_HubCardData>[
          _HubCardData(
            title: 'Open World',
            subtitle:
                'Explore the map, collide with enemies, and trigger finance encounters.',
            icon: Icons.explore_rounded,
            accent: const Color(0xFF85EFAC),
            buttonLabel: 'Start Adventure',
            onTap: () => _startAdventure(context),
          ),
          _HubCardData(
            title: 'Bill Dodger',
            subtitle:
                'Test your reflexes in the arcade and dodge spending traps.',
            icon: Icons.flash_on_rounded,
            accent: const Color(0xFFFFD45C),
            buttonLabel: 'Play',
            onTap: () => Navigator.of(context).pushNamed('/bill-dodger'),
          ),
          _HubCardData(
            title: 'React Challenge',
            subtitle:
                'Jump into the featured browser-powered challenge for bonus rewards.',
            icon: Icons.web_asset_rounded,
            accent: const Color(0xFF58C7FF),
            buttonLabel: 'Launch',
            onTap: () => Navigator.of(context).pushNamed('/leaderboard'),
          ),
          _HubCardData(
            title: 'More Minigames',
            subtitle:
                'New budget trials are coming soon as the MVP grows toward June.',
            icon: Icons.auto_awesome_rounded,
            accent: const Color(0xFFFFB084),
            buttonLabel: 'Coming Soon',
            onTap: () {
              HapticFeedback.lightImpact();
              GameToast.show(
                context,
                title: 'Coming soon',
                message:
                    'More world activities are being prepared for the next milestone.',
                icon: Icons.schedule_rounded,
                accent: const Color(0xFFFFB084),
              );
            },
          ),
        ];

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
                    final horizontalPadding = constraints.maxWidth >= 1400
                        ? 28.0
                        : constraints.maxWidth >= 900
                            ? 20.0
                            : 14.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        126,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GameHubHero(
                              turtleSkin: turtleSkin,
                              username: stats.username,
                              gold: stats.gold,
                              literacyPoints: stats.literacyPoints,
                              onStartAdventure: () => _startAdventure(context),
                            ),
                            const SizedBox(height: 20),
                            const _SectionTitle(
                              title: 'Portal Activities',
                              subtitle:
                                  'Pick a lane, warm up your finance reflexes, then step into the world map.',
                            ),
                            const SizedBox(height: 14),
                            _ResponsiveCardGrid(cards: cards),
                          ],
                        ),
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

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({
    required this.cards,
  });

  final List<_HubCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount;
        double childAspectRatio;

        if (width >= 1650) {
          crossAxisCount = 4;
          childAspectRatio = 1.55;
        } else if (width >= 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.28;
        } else if (width >= 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.10;
        } else if (width >= 620) {
          crossAxisCount = 2;
          childAspectRatio = 1.18;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 1.35;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _HubCard(
              title: card.title,
              subtitle: card.subtitle,
              icon: card.icon,
              accent: card.accent,
              buttonLabel: card.buttonLabel,
              onTap: card.onTap,
            );
          },
        );
      },
    );
  }
}

class _HubCardData {
  const _HubCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String buttonLabel;
  final VoidCallback onTap;
}

class _GameHubHero extends StatelessWidget {
  const _GameHubHero({
    required this.turtleSkin,
    required this.username,
    required this.gold,
    required this.literacyPoints,
    required this.onStartAdventure,
  });

  final AvatarSkin turtleSkin;
  final String username;
  final int gold;
  final int literacyPoints;
  final VoidCallback onStartAdventure;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vertical = constraints.maxWidth < 640;
          final avatarSize = vertical ? 92.0 : 120.0;

          final avatar = Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  turtleSkin.accent.withValues(alpha: 0.82),
                  const Color(0xFF0D2B20),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: turtleSkin.accent.withValues(alpha: 0.20),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(vertical ? 12 : 16),
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
                vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'Game Hub',
                style: TextStyle(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.96),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ready for the next run, $username?',
                textAlign: vertical ? TextAlign.center : TextAlign.start,
                softWrap: true,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: vertical ? 22 : 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Use the portal to enter the open world, challenge monsters, and build financial instincts with fast feedback.',
                textAlign: vertical ? TextAlign.center : TextAlign.start,
                softWrap: true,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment:
                    vertical ? WrapAlignment.center : WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    label: 'Gold',
                    value: '$gold',
                    accent: const Color(0xFFFFD45C),
                  ),
                  _InfoPill(
                    label: 'Literacy',
                    value: '$literacyPoints',
                    accent: const Color(0xFF58C7FF),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: vertical ? double.infinity : 220,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onStartAdventure();
                  },
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF85EFAC), Color(0xFF52D18A)],
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF062C21),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Start Adventure',
                          style: TextStyle(
                            color: Color(0xFF062C21),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

          if (vertical) {
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

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.26)),
                ),
                child: Center(
                  child: Text(
                    buttonLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
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
      constraints: const BoxConstraints(minWidth: 92),
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
              fontSize: 16,
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
    return SizedBox(
      width: double.infinity,
      child: Column(
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
      ),
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
            color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
            size: 190,
          ),
        ),
        Positioned(
          bottom: 180,
          left: -60,
          child: _GlowOrb(
            color: const Color(0xFF58C7FF).withValues(alpha: 0.10),
            size: 170,
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
