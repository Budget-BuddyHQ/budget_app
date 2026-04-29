import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../navigation/fade_page_route.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/game_toast.dart';
import '../arcade/bill_dodger.dart';
import '../arcade/budget_challenge.dart';
import '../arcade/stock_market_page.dart';

class MinigamesPage extends StatelessWidget {
  const MinigamesPage({
    super.key,
    this.activeTabIndex = 1,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openBillDodger(BuildContext context) async {
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      FadePageRoute(
        builder: (_) => const BillDodgerScreen(),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Arcade rewards saved',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.sports_esports_rounded,
      accent: const Color(0xFFE1BB72),
    );
  }

  Future<void> _openBudgetChallenge(BuildContext context) async {
    final result = await Navigator.of(context).push<BudgetChallengeCloseResult>(
      FadePageRoute(
        builder: (_) => const BudgetChallengeScreen(),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Budget challenge complete',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.shopping_cart_rounded,
      accent: const Color(0xFF78C69B),
    );
  }

  Future<void> _openStockMarket(BuildContext context) async {
    await Navigator.of(context).push(
      FadePageRoute(
        builder: (_) => const StockMarketPage(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    HapticFeedback.lightImpact();
    GameToast.show(
      context,
      title: 'Coming soon',
      message: '$title will slot into this minigames wing in a future update.',
      icon: Icons.hourglass_top_rounded,
      accent: const Color(0xFFD49B7E),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minigames = <_MinigameCardData>[
      const _MinigameCardData(
        title: 'Bill Dodger',
        description:
            'Collect needs, dodge wants, and sharpen fast spending calls.',
        badge: 'FEATURED ARCADE',
        accent: Color(0xFFE1BB72),
        icon: Icons.sports_esports_rounded,
        cta: 'Play Bill Dodger',
      ),
      const _MinigameCardData(
        title: 'Budget Challenge',
        description:
            'Build the best cart under pressure and protect your budget.',
        badge: 'PUZZLE RUN',
        accent: Color(0xFF78C69B),
        icon: Icons.shopping_cart_rounded,
        cta: 'Play Budget Challenge',
      ),
      const _MinigameCardData(
        title: 'Market Board',
        description:
            'Buy stock lots, ride the swings, and cash out for gold.',
        badge: 'NEW SIDE MODE',
        accent: Color(0xFF58C7FF),
        icon: Icons.show_chart_rounded,
        cta: 'Open Market Board',
      ),
      const _MinigameCardData(
        title: 'Subscription Sweep',
        description:
            'Spot recurring charges before they leak your monthly plan.',
        badge: 'IN PROTOTYPE',
        accent: Color(0xFFD49B7E),
        icon: Icons.receipt_long_rounded,
        cta: 'Coming Soon',
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
          const _MinigameBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              children: [
                _PageHeader(
                  title: 'Minigames',
                  subtitle:
                      'Quick budget drills and side modes live here.',
                ),
                const SizedBox(height: 18),
                _MinigameHero(
                  onBillDodger: () => _openBillDodger(context),
                  onBudgetChallenge: () => _openBudgetChallenge(context),
                  onStockMarket: () => _openStockMarket(context),
                ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'Arcade Lineup',
                  subtitle:
                      'Pick a mode and jump straight in.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 680 ? 2 : 1;
                    final childAspectRatio = width >= 1180
                        ? 1.55
                        : width >= 680
                            ? 1.08
                            : 1.14;

                    return GridView.builder(
                      itemCount: minigames.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final game = minigames[index];
                        return _MinigameCard(
                          data: game,
                          onPressed: switch (index) {
                            0 => () => _openBillDodger(context),
                            1 => () => _openBudgetChallenge(context),
                            2 => () => _openStockMarket(context),
                            _ => () => _showComingSoon(context, game.title),
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinigameCardData {
  const _MinigameCardData({
    required this.title,
    required this.description,
    required this.badge,
    required this.accent,
    required this.icon,
    required this.cta,
  });

  final String title;
  final String description;
  final String badge;
  final Color accent;
  final IconData icon;
  final String cta;
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

class _MinigameHero extends StatelessWidget {
  const _MinigameHero({
    required this.onBillDodger,
    required this.onBudgetChallenge,
    required this.onStockMarket,
  });

  final VoidCallback onBillDodger;
  final VoidCallback onBudgetChallenge;
  final VoidCallback onStockMarket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF173C2F).withValues(alpha: 0.96),
            const Color(0xFF214D3E).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 700;

          final buttons = Column(
            children: [
              CustomButton(
                label: 'Play Bill Dodger',
                onPressed: onBillDodger,
                prefixIcon: const Icon(
                  Icons.sports_esports_rounded,
                  color: Color(0xFF76FF03),
                  size: 18,
                ),
                style: const CustomButtonStyle.secondary(),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: 'Play Budget Challenge',
                onPressed: onBudgetChallenge,
                prefixIcon: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                style: const CustomButtonStyle.tertiary(),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: 'Open Market Board',
                onPressed: onStockMarket,
                prefixIcon: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF58C7FF),
                  size: 18,
                ),
                style: const CustomButtonStyle.tertiary(),
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment:
                stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'ARCADE LANE',
                style: TextStyle(
                  color: const Color(0xFFFFD45C).withValues(alpha: 0.96),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Short runs. Fast feedback.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Arcade games stay here so the main adventure page can stay focused.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: stacked ? WrapAlignment.center : WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroBadge(
                    label: 'Bill Dodger',
                    accent: Color(0xFFE1BB72),
                  ),
                  _HeroBadge(
                    label: 'Budget Challenge',
                    accent: Color(0xFF78C69B),
                  ),
                  _HeroBadge(
                    label: 'Market Board',
                    accent: Color(0xFF58C7FF),
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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

class _MinigameCard extends StatelessWidget {
  const _MinigameCard({
    required this.data,
    required this.onPressed,
  });

  final _MinigameCardData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final usesPrimary = data.title == 'Bill Dodger';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: data.accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 230;
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.badge,
                  style: TextStyle(
                    color: data.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(height: 12),
                    Icon(data.icon, color: data.accent),
                  ],
                );
              }

              return Row(
                children: [
                  Flexible(child: badge),
                  const Spacer(),
                  Icon(data.icon, color: data.accent),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              data.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: data.cta,
            onPressed: onPressed,
            prefixIcon: Icon(
              data.icon,
              size: 18,
              color: usesPrimary
                  ? const Color(0xFF1A4D3D)
                  : const Color(0xFF76FF03),
            ),
            style: usesPrimary
                ? const CustomButtonStyle.secondary()
                : const CustomButtonStyle.tertiary(),
          ),
        ],
      ),
    );
  }
}

class _MinigameBackdrop extends StatelessWidget {
  const _MinigameBackdrop();

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
                Color(0xFF0D251D),
                Color(0xFF14362B),
              ],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -30,
          child: _GlowOrb(
            color: const Color(0xFFE3C56D).withValues(alpha: 0.08),
            size: 180,
          ),
        ),
        Positioned(
          bottom: 180,
          left: -40,
          child: _GlowOrb(
            color: const Color(0xFF6CB6DA).withValues(alpha: 0.08),
            size: 150,
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
