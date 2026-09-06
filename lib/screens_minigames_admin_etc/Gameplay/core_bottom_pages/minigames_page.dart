import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../navigation_tools_and_animation/fade_page_route.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/confetti_burst.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/hover_lift.dart';
import '../../../models_Like_Skins_and_lessons_templates/coin_cascade_models.dart';
import '../minigames_pages/coin_cascade_page.dart';
import '../minigames_pages/finance_brawl_game.dart';
import '../minigames_pages/react_challenge_screen.dart';
import '../minigames_pages/stock_market_page.dart';
import 'arcade_catalog.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';

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
      case 'market_board':
        await _openStockMarket(context);
      case 'finance_brawl':
        await _openFinanceBrawl(context);
      case 'coin_cascade':
        await _openCoinCascade(context);
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

    final previousBest = stats.bestArcadeScore('react_challenge');
    await controller.recordArcadeRun(
      gameId: 'react_challenge',
      score: result.goldEarned,
    );
    if (!context.mounted) {
      return;
    }

    final isNewHighScore =
        previousBest != null && result.goldEarned > previousBest;
    if (isNewHighScore) {
      ConfettiBurst.show(context);
    }

    GameToast.show(
      context,
      title: isNewHighScore
          ? 'New high score!'
          : result.status == 'victory'
          ? 'Arcade streak extended'
          : 'Run saved',
      message: '+${result.goldEarned} gold • +${result.xpEarned} XP',
      icon: Icons.bolt_rounded,
      accent: const Color(0xFF6CB6DA),
    );
  }

  Future<void> _openCoinCascade(BuildContext context) async {
    final previousBest = context
        .read<UserStatsController>()
        .stats
        .bestArcadeScore('coin_cascade');

    // **The page now pays the run itself**, and records it, and returns what
    // it paid.
    //
    // This function used to do the recording and print "+N gold" from
    // `game.goldEarned` — a number the engine computed and nothing ever
    // credited, because the only call here was `recordArcadeRun`, whose own
    // documentation says it must not touch gold or XP. Moving the payout into
    // the page is not tidying: the page is the only place that knows whether
    // a level was a first clear or a replay, and whether the run was a Rush,
    // both of which change what it is worth.
    final result = await Navigator.of(context).push<CascadeCloseResult>(
      FadePageRoute(builder: (_) => const CoinCascadePage()),
    );
    if (!context.mounted || result == null) {
      return;
    }

    final game = result.game;
    final beatBest = result.isRush
        ? result.isNewRushBest
        : game.score > (previousBest ?? 0);
    if (beatBest) {
      ConfettiBurst.show(context);
    }

    GameToast.show(
      context,
      title: result.isRush
          ? (result.isNewRushBest ? 'New Payday Rush best!' : 'Rush finished')
          : game.status == CascadeStatus.won
          ? 'Goal reached'
          : 'Run finished',
      message: <String>[
        if (result.isRush)
          '${game.savings} saved'
        else
          '${game.score} points',
        if (result.goldEarned > 0) '+${result.goldEarned} gold',
        if (result.xpEarned > 0) '+${result.xpEarned} XP',
      ].join(' · '),
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF69C6FF),
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

    final controllerStats = controller.stats;
    final previousBest = controllerStats.bestArcadeScore('finance_brawl');
    await controller.recordArcadeRun(
      gameId: 'finance_brawl',
      score: result.xpEarned,
    );
    if (!context.mounted) {
      return;
    }

    final isNewHighScore =
        previousBest != null && result.xpEarned > previousBest;
    if (isNewHighScore) {
      ConfettiBurst.show(context);
    }

    GameToast.show(
      context,
      title: isNewHighScore ? 'New high score!' : 'Horde cleared',
      message: '+${result.goldEarned} gold • +${result.xpEarned} XP',
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
          backgroundColor: AppTheme.deepForest,
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
                                style: GoogleFonts.pixelifySans(
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
                                  // Was 168 — that's the exact sum of every
                                  // fixed row plus a full 2-line tagline with
                                  // zero slack, so any tagline that actually
                                  // wrapped to 2 lines (e.g. Market Board's)
                                  // got its second line silently clipped by
                                  // the Expanded's tight height. This isn't
                                  // the "RenderFlex overflowed" error the
                                  // layout tests catch — Text just paints
                                  // past a box that's too short for it.
                                  mainAxisExtent: 192,
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
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalPlays == 0
                    ? '${arcadeCatalog.length} ways to practise money without spending any.'
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
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFFFFD45C),
              fontWeight: FontWeight.w700,
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
      child: HoverLift(
        accent: game.accent,
        borderRadius: 28,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPlay,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(
              game.accent,
              radius: AppTheme.radiusXLarge,
            ),
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
                            style: GoogleFonts.pixelifySans(
                              color: game.accent,
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FittedLabel(
                            game.title,
                            style: GoogleFonts.pixelifySans(
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
                    color: AppTheme.textMuted,
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
                      cardAccent: game.accent,
                    ),
                    _MetaChip(
                      label: game.length.label,
                      color: AppTheme.textMuted,
                      cardAccent: game.accent,
                    ),
                    _MetaChip(
                      label: game.teaches,
                      color: game.accent,
                      cardAccent: game.accent,
                    ),
                    if (best != null)
                      _MetaChip(
                        label: '${game.scoreLabel}: $best',
                        color: const Color(0xFFFFD45C),
                        cardAccent: game.accent,
                      ),
                  ],
                ),
              ],
            ),
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
      child: HoverLift(
        accent: game.accent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPlay,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(
              game.accent,
              radius: AppTheme.radiusLarge,
            ),
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
                        style: GoogleFonts.pixelifySans(
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
                      // Full-strength muted rather than 70% white: the card
                      // is a *tinted* panel, so knocking the text back with
                      // alpha pulls it toward the card instead of toward a
                      // neutral grey, and it landed at 4.46:1.
                      color: AppTheme.textMuted,
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
                      cardAccent: game.accent,
                      dense: true,
                    ),
                    const SizedBox(width: 6),
                    // Flexible so a long label (e.g. ArcadeLength.none's
                    // "As much time as you need") shrinks and ellipsizes
                    // instead of pushing the row past its width.
                    Flexible(
                      child: _MetaChip(
                        label: game.length.label,
                        color: AppTheme.textMuted,
                        cardAccent: game.accent,
                        dense: true,
                      ),
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
                        ? AppTheme.textMuted
                        : const Color(0xFFFFD45C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
    // The badge is a wash of the accent and the glyph *is* the accent, so the
    // brighter the game's colour the more the icon vanishes into its own
    // badge — the mint one measured 2.6:1.
    //
    // Both gradient stops are resolved to **opaque** colours here rather than
    // left as alpha over whatever is behind. That is what makes the glyph
    // colour below trustworthy: a translucent wash means the real background
    // depends on the card, and the first attempt at this fix aimed at a
    // guessed surface and landed short. The lighter stop is the worst case,
    // so it is the one the glyph is measured against.
    final cardBase = Color.lerp(AppTheme.panel, game.accent, 0.14)!;
    final bright = AppTheme.flatten(
      game.accent.withValues(alpha: 0.28),
      cardBase,
    );
    final faint = AppTheme.flatten(
      game.accent.withValues(alpha: 0.10),
      cardBase,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bright, faint],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: game.accent.withValues(alpha: 0.34),
          width: 2,
        ),
      ),
      child: Icon(
        game.icon,
        color: AppTheme.legibleOn(game.accent, bright, target: 3.0),
        size: size * 0.48,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.cardAccent,
    this.dense = false,
  });

  final String label;
  final Color color;

  /// The accent of the card this chip is sitting on — see [build].
  final Color cardAccent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // The chip sits on a card that is already a *tinted* panel — the card
    // gradient lerps the card's accent in — so "the accent on 12% of the
    // accent" ends up two shades of one colour. Difficulty "Hard" measured
    // 2.4:1.
    //
    // [cardAccent] is the card's colour, not the chip's, and getting that
    // wrong matters: the neutral "5-10 min" chip is near-white, so blending
    // the base over *its* colour invented a pale card that no text could sit
    // on, and the fix looked like it had made things worse.
    final chip = AppTheme.tintedChip(
      color,
      alpha: 0.12,
      on: Color.lerp(AppTheme.panel, cardAccent, 0.14)!,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: FittedLabel(
        label,
        style: TextStyle(
          color: chip.ink,
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
      colors: [AppTheme.panelStrong, Color.lerp(AppTheme.panel, accent, 0.14)!],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withValues(alpha: 0.30)),
    boxShadow: AppTheme.puffyShadow(accent, restAlpha: 0.20),
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
        // Same fix as the home dashboard backdrop: a light dim let the
        // small repeating tile icons read crisply behind the header text
        // and card gaps, which looked like clutter rather than texture.
        Container(color: const Color(0xFF071711).withValues(alpha: 0.82)),
      ],
    );
  }
}
