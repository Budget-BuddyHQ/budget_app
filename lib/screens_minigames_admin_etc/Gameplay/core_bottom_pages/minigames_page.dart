import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../navigation_tools_and_animation/fade_page_route.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../minigames_pages/bill_dodger.dart';
import '../minigames_pages/budget_challenge.dart';
import '../minigames_pages/react_challenge_screen.dart';
import '../minigames_pages/stock_market_page.dart';
import '../minigames_pages/subscription_sweep.dart';

class MinigamesPage extends StatelessWidget {
  const MinigamesPage({
    super.key,
    this.activeTabIndex = AppTabIndex.minigames,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openReactChallenge(BuildContext context) async {
    final controller = context.read<UserStatsController>();
    final stats = controller.stats;

    final result = await Navigator.of(context).push<ReactGameCloseResult>(
      FadePageRoute(
        builder: (_) => ReactChallengeScreen(
          gameId: 'daily_budget_battle',
          difficulty: 'medium',
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
          ? 'Arcade streak extended'
          : 'Run saved',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.bolt_rounded,
      accent: const Color(0xFF6CB6DA),
    );
  }

  Future<void> _openBillDodger(BuildContext context) async {
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      FadePageRoute(builder: (_) => const BillDodgerScreen()),
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
      FadePageRoute(builder: (_) => const BudgetChallengeScreen()),
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
    await Navigator.of(
      context,
    ).push(FadePageRoute(builder: (_) => const StockMarketPage()));
  }

  Future<void> _openSubscriptionSweep(BuildContext context) async {
    final result = await Navigator.of(context)
        .push<SubscriptionSweepCloseResult>(
          FadePageRoute(builder: (_) => const SubscriptionSweepScreen()),
        );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Sweep complete',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.receipt_long_rounded,
      accent: const Color(0xFFD49B7E),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minigames = <_MinigamePosterData>[
      _MinigamePosterData(
        title: 'React Challenge',
        accent: const Color(0xFF6CB6DA),
        icon: Icons.bolt_rounded,
        onPressed: () => _openReactChallenge(context),
      ),
      _MinigamePosterData(
        title: 'Bill Dodger',
        accent: const Color(0xFFE1BB72),
        icon: Icons.sports_esports_rounded,
        onPressed: () => _openBillDodger(context),
      ),
      _MinigamePosterData(
        title: 'Budget Challenge',
        accent: const Color(0xFF78C69B),
        icon: Icons.shopping_cart_rounded,
        onPressed: () => _openBudgetChallenge(context),
      ),
      _MinigamePosterData(
        title: 'Market Board',
        accent: const Color(0xFF58C7FF),
        icon: Icons.show_chart_rounded,
        onPressed: () => _openStockMarket(context),
      ),
      _MinigamePosterData(
        title: 'Subscription Sweep',
        accent: const Color(0xFFD49B7E),
        icon: Icons.receipt_long_rounded,
        onPressed: () => _openSubscriptionSweep(context),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 22 : 16,
                    16,
                    wide ? 22 : 16,
                    120,
                  ),
                  children: [
                    const _PageHeader(
                      title: 'Arcade',
                      subtitle: 'Choose a quick run and jump in.',
                    ),
                    const SizedBox(height: 14),
                    _ArcadeTopGameBar(games: minigames),
                    SizedBox(height: wide ? 18 : 14),
                    if (wide) ...[
                      _FeaturedArcadeShelf(games: minigames, wide: wide),
                      const SizedBox(height: 20),
                    ],
                    const _SectionTitle(title: 'All Games'),
                    const SizedBox(height: 12),
                    _ArcadePosterGrid(games: minigames, wide: wide),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MinigamePosterData {
  const _MinigamePosterData({
    required this.title,
    required this.accent,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final VoidCallback onPressed;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Navigator.of(context).canPop())
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArcadeTopGameBar extends StatefulWidget {
  const _ArcadeTopGameBar({required this.games});

  final List<_MinigamePosterData> games;

  @override
  State<_ArcadeTopGameBar> createState() => _ArcadeTopGameBarState();
}

class _ArcadeTopGameBarState extends State<_ArcadeTopGameBar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 5,
        radius: const Radius.circular(999),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              for (var index = 0; index < widget.games.length; index++) ...[
                _TopGameButton(data: widget.games[index]),
                if (index != widget.games.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopGameButton extends StatelessWidget {
  const _TopGameButton({required this.data});

  final _MinigamePosterData data;

  @override
  Widget build(BuildContext context) {
    return _PosterTap(
      data: data,
      child: Container(
        constraints: const BoxConstraints(minWidth: 158, minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _posterDecoration(data.accent, radius: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PosterArt(icon: data.icon, accent: data.accent, size: 44),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedArcadeShelf extends StatelessWidget {
  const _FeaturedArcadeShelf({required this.games, required this.wide});

  final List<_MinigamePosterData> games;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        children: [
          Expanded(flex: 3, child: _FeaturePoster(data: games[1])),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _MiniPoster(data: games[0]),
                const SizedBox(height: 12),
                _MiniPoster(data: games[3]),
              ],
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 218,
      child: PageView.builder(
        itemCount: games.length,
        padEnds: false,
        pageSnapping: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index == games.length - 1 ? 0 : 10),
            child: _GamePoster(data: games[index], featured: true),
          );
        },
      ),
    );
  }
}

class _ArcadePosterGrid extends StatelessWidget {
  const _ArcadePosterGrid({required this.games, required this.wide});

  final List<_MinigamePosterData> games;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (var index = 0; index < games.length; index++) ...[
            _MiniPoster(data: games[index]),
            if (index != games.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1120 ? 5 : 3;
        return GridView.builder(
          itemCount: games.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 190,
          ),
          itemBuilder: (context, index) => _GamePoster(data: games[index]),
        );
      },
    );
  }
}

class _FeaturePoster extends StatelessWidget {
  const _FeaturePoster({required this.data});

  final _MinigamePosterData data;

  @override
  Widget build(BuildContext context) {
    return _PosterTap(
      data: data,
      child: Container(
        height: 292,
        padding: const EdgeInsets.all(24),
        decoration: _posterDecoration(data.accent, radius: 30),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _PosterArt(
                icon: data.icon,
                accent: data.accent,
                size: 156,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    height: 0.98,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamePoster extends StatelessWidget {
  const _GamePoster({required this.data, this.featured = false});

  final _MinigamePosterData data;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return _PosterTap(
      data: data,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _posterDecoration(data.accent, radius: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: _PosterArt(
                  icon: data.icon,
                  accent: data.accent,
                  size: featured ? 104 : 86,
                ),
              ),
            ),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: featured ? 21 : 18,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPoster extends StatelessWidget {
  const _MiniPoster({required this.data});

  final _MinigamePosterData data;

  @override
  Widget build(BuildContext context) {
    return _PosterTap(
      data: data,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: _posterDecoration(data.accent, radius: 22),
        child: Row(
          children: [
            _PosterArt(icon: data.icon, accent: data.accent, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: Color(0xFF85EFAC)),
          ],
        ),
      ),
    );
  }
}

class _PosterTap extends StatelessWidget {
  const _PosterTap({required this.data, required this.child});

  final _MinigamePosterData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play ${data.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          HapticFeedback.selectionClick();
          data.onPressed();
        },
        child: child,
      ),
    );
  }
}

class _PosterArt extends StatelessWidget {
  const _PosterArt({
    required this.icon,
    required this.accent,
    required this.size,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 2),
      ),
      child: Icon(icon, color: accent, size: size * 0.48),
    );
  }
}

BoxDecoration _posterDecoration(Color accent, {required double radius}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF173B2E),
        Color.lerp(const Color(0xFF10281F), accent, 0.10)!,
      ],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withValues(alpha: 0.28)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MinigameBackdrop extends StatelessWidget {
  const _MinigameBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.gradientForest),
    );
  }
}
