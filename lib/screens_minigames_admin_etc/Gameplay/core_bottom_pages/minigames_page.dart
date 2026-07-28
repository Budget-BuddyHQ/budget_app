import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../navigation_tools_and_animation/fade_page_route.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../minigames_pages/bill_dodger.dart';
import '../minigames_pages/finance_brawl_game.dart';
import '../minigames_pages/react_challenge_screen.dart';
import '../minigames_pages/stock_market_page.dart';
import 'arcade_catalog.dart';

class MinigamesPage extends StatelessWidget {
  const MinigamesPage({
    super.key,
    this.activeTabIndex = AppTabIndex.minigames,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _launch(BuildContext context, ArcadeGame game) async {
    HapticFeedback.selectionClick();
    switch (game.id) {
      case 'react_challenge':
        await _openReactChallenge(context);
      case 'bill_dodger':
        await _openBillDodger(context);
      case 'market_board':
        await _openStockMarket(context);
      case 'finance_brawl':
        await _openFinanceBrawl(context);
    }
  }

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

    await controller.recordArcadeRun(
      gameId: 'react_challenge',
      score: result.goldEarned,
    );
    if (!context.mounted) {
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
    final controller = context.read<UserStatsController>();
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      FadePageRoute(builder: (_) => const BillDodgerScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    await controller.recordArcadeRun(
      gameId: 'bill_dodger',
      score: result.finalScore,
    );
    if (!context.mounted) {
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

  Future<void> _openStockMarket(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(FadePageRoute(builder: (_) => const StockMarketPage()));
  }

  Future<void> _openFinanceBrawl(BuildContext context) async {
    final controller = context.read<UserStatsController>();
    final result = await Navigator.of(context).push<FinanceBrawlCloseResult>(
      FadePageRoute(builder: (_) => const FinanceBrawlScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    await controller.recordArcadeRun(
      gameId: 'finance_brawl',
      score: result.xpEarned,
    );
    if (!context.mounted) {
      return;
    }

    GameToast.show(
      context,
      title: 'Horde cleared',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.gavel_rounded,
      accent: const Color(0xFFE1BB72),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;

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
                    final width = constraints.maxWidth;
                    final pad = width >= 760 ? 22.0 : 16.0;
                    // Tile width target keeps cards readable from a 320pt
                    // phone up to a tablet in landscape.
                    final columns = ((width - (pad * 2)) / 300).floor().clamp(
                      1,
                      3,
                    );

                    // Lead with whatever the player has touched least, so the
                    // hub keeps pointing somewhere new rather than always
                    // showing the same hero card.
                    final sorted = [...arcadeCatalog]
                      ..sort(
                        (a, b) => stats
                            .arcadePlays(a.id)
                            .compareTo(stats.arcadePlays(b.id)),
                      );
                    final featured = sorted.first;

                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                          sliver: SliverList.list(
                            children: [
                              _ArcadeHeader(stats: stats),
                              const SizedBox(height: 16),
                              _FeaturedCard(
                                game: featured,
                                best: stats.bestArcadeScore(featured.id),
                                plays: stats.arcadePlays(featured.id),
                                onPlay: () => _launch(context, featured),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'ALL GAMES',
                                style: GoogleFonts.baloo2(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, 130),
                          sliver: SliverGrid.builder(
                            itemCount: arcadeCatalog.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 168,
                                ),
                            itemBuilder: (context, index) {
                              final game = arcadeCatalog[index];
                              return _GameCard(
                                game: game,
                                best: stats.bestArcadeScore(game.id),
                                plays: stats.arcadePlays(game.id),
                                onPlay: () => _launch(context, game),
                              );
                            },
                          ),
                        ),
                      ],
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

class _ArcadeHeader extends StatelessWidget {
  const _ArcadeHeader({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final totalPlays = arcadeCatalog.fold<int>(
      0,
      (sum, game) => sum + stats.arcadePlays(game.id),
    );
    final played = arcadeCatalog
        .where((game) => stats.arcadePlays(game.id) > 0)
        .length;

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
                'Arcade',
                style: GoogleFonts.baloo2(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalPlays == 0
                    ? 'Five ways to practise money without spending any.'
                    : '$totalPlays runs • $played of ${arcadeCatalog.length} games tried',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _GoldPill(gold: stats.gold),
      ],
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD45C).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFD45C).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.paid_rounded, color: Color(0xFFFFD45C), size: 16),
          const SizedBox(width: 6),
          Text(
            '$gold',
            style: const TextStyle(
              color: Color(0xFFFFD45C),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// The large "start here" card at the top of the hub.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.game,
    required this.best,
    required this.plays,
    required this.onPlay,
  });

  final ArcadeGame game;
  final int? best;
  final int plays;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play ${game.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onPlay,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(game.accent, radius: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _GameArt(game: game, size: 62),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plays == 0 ? 'TRY NEXT' : 'PICK UP AGAIN',
                          style: GoogleFonts.baloo2(
                            color: game.accent,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.baloo2(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                game.tagline,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: game.difficulty.label,
                    color: game.difficulty.color,
                  ),
                  _MetaChip(label: game.length.label, color: Colors.white70),
                  _MetaChip(label: game.teaches, color: game.accent),
                  if (best != null)
                    _MetaChip(
                      label: '${game.scoreLabel}: $best',
                      color: const Color(0xFFFFD45C),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.best,
    required this.plays,
    required this.onPlay,
  });

  final ArcadeGame game;
  final int? best;
  final int plays;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play ${game.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPlay,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(game.accent, radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _GameArt(game: game, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.baloo2(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  game.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetaChip(
                    label: game.difficulty.label,
                    color: game.difficulty.color,
                    dense: true,
                  ),
                  const SizedBox(width: 6),
                  _MetaChip(
                    label: game.length.label,
                    color: Colors.white60,
                    dense: true,
                  ),
                  const Spacer(),
                  Icon(Icons.play_arrow_rounded, color: game.accent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                best == null
                    ? 'Not played yet'
                    : '${game.scoreLabel}: $best  •  $plays ${plays == 1 ? 'run' : 'runs'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: best == null
                      ? Colors.white.withValues(alpha: 0.42)
                      : const Color(0xFFFFD45C),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameArt extends StatelessWidget {
  const _GameArt({required this.game, required this.size});

  final ArcadeGame game;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            game.accent.withValues(alpha: 0.28),
            game.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: game.accent.withValues(alpha: 0.34),
          width: 2,
        ),
      ),
      child: Icon(game.icon, color: game.accent, size: size * 0.48),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    this.dense = false,
  });

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(Color accent, {required double radius}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF173B2E),
        Color.lerp(const Color(0xFF10281F), accent, 0.12)!,
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

class _MinigameBackdrop extends StatelessWidget {
  const _MinigameBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.arcadeTileBackground,
          repeat: ImageRepeat.repeat,
          filterQuality: FilterQuality.none,
        ),
        Container(color: const Color(0xFF071711).withValues(alpha: 0.50)),
      ],
    );
  }
}
