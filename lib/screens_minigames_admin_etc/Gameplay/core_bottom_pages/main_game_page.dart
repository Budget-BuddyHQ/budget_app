import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/money_glyphs.dart';
import '../../../widgets_custom_lotties/pixel_kit.dart';
import '../../../constants/app_assets.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../minigames_pages/life_sim_page.dart';
import '../minigames_pages/past_lives_screen.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/idle_hover_icon.dart';
import '../../../widgets_custom_lotties/day_night_sky.dart';
import '../../../widgets_custom_lotties/avatar_sprite.dart';
import '../../../widgets_custom_lotties/map_backdrop.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';

/// The "MAIN GAME" pill: a gold wash with a gold label, made legible.
///
/// Computed once at load rather than per build — it is a pure function of two
/// constants, and the whole point is that the fill and the ink stay a pair.
final _mainGameTag = AppTheme.tintedChip(const Color(0xFFFFD45C));

/// The main-game tab: a launcher for **Life** (the BitLife-style main game),
/// with quick jumps to Academy and Arcade. The old open-world map lived here
/// and has been removed.
class MainGamePage extends StatelessWidget {
  const MainGamePage({
    super.key,
    this.activeTabIndex = AppTabIndex.adventure,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _playLife(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).pushNamed('/life');
  }

  /// Replays the in-game tour: clears the "seen" flag and starts a life.
  ///
  /// The hub cannot draw the tour itself — every step spotlights a widget
  /// that only exists inside a run — so it does what the Profile screen does
  /// for the app tour: it sets the state that makes the next screen show it.
  /// Starts a ranked run.
  ///
  /// Pushed directly rather than through the `/life` route, because the route
  /// takes no arguments and ranked needs one. Same screen, same rules — see
  /// `LifeSimPage.ranked`.
  Future<void> _playRanked(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LifeSimPage(ranked: true)),
    );
  }

  Future<void> _replayLifeTour(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await context.read<AppSettingsController>().requestLifeTourReplay();
    if (!context.mounted) return;
    await Navigator.of(context).pushNamed('/life');
  }

  void _openTab(int tab) {
    HapticFeedback.lightImpact();
    onNavSelected?.call(tab);
  }

  /// The one fact worth putting on the Past Lives tile.
  ///
  /// Before any run is finished this has to be a prompt rather than a stat.
  /// "0 lives" reads as broken; it is the same reason the card this replaced
  /// carried an explanation instead of an empty row.
  static String _pastLivesCaption(LifeRecordBook book) {
    final lived = book.totalLives;
    if (lived == 0) return 'Finish one to log it';
    final longest = book.longest;
    if (longest == null) return lived == 1 ? '1 life lived' : '$lived lives';
    return '$lived lived · best ${longest.age}y';
  }

  Future<void> _openPastLives(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PastLivesScreen()));
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
          // The sky behind the main game changes with the hour. Fourteen
          // gradients had been sitting unreferenced in the asset folder while
          // the app painted the same flat green at every time of day — see
          // [DayNightSky] for why it is dimmed and scrimmed rather than shown
          // at full strength.
          body: DayNightSky(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: [
                  Text(
                    'Play',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Level and gold, with the balance in the game's own display
                  // face. This line is the page's only status readout, and a
                  // gold figure drawn as art is the difference between a game
                  // and a settings header.
                  Row(
                    children: [
                      PixelKitIcon(AppAssets.kitIconStar, size: 18),
                      const SizedBox(width: 7),
                      Text(
                        'Level ${stats.level}',
                        style: AppTheme.numeric(
                          color: const Color(0xFFFFD45C),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 16),
                      PixelKitIcon(AppAssets.kitIconCoin, size: 18),
                      const SizedBox(width: 7),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: MoneyGlyphs('${stats.gold}', height: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _LifeHeroCard(
                    onPlay: () => _playLife(context),
                    skin: skinFromId(stats.equippedSkin),
                  ),
                  const SizedBox(height: 16),
                  // Three tiles rather than three full-width rows of prose.
                  //
                  // Each of these used to be a card carrying a title and up
                  // to two lines of explanation, stacked, so the hub was five
                  // paragraphs deep before it showed a single picture -- for
                  // a game, on the screen whose whole job is to make you want
                  // to press something. A tile can carry an image at a size
                  // you can actually read and one word under it, and one word
                  // is all any of these three needs.
                  SizedBox(
                    height: 132,
                    child: Row(
                      children: [
                        Expanded(
                          child: _PictureTile(
                            label: 'Ranked',
                            caption: 'One life, scored',
                            accent: const Color(0xFFFFD45C),
                            art: _TileArt.icon(AppAssets.kitIconTrophy),
                            onTap: () => _playRanked(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PictureTile(
                            label: 'How to play',
                            caption: 'Buddy shows you',
                            accent: const Color(0xFF69C6FF),
                            // Waving in whichever turtle they have on.
                            art: _TileArt.image(
                              AppAssets.turtleMentorPose(
                                'wave',
                                stats.equippedSkin,
                              ),
                            ),
                            onTap: () => _replayLifeTour(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PictureTile(
                            label: 'Past lives',
                            caption: _pastLivesCaption(stats.lifeRecords),
                            accent: const Color(0xFFB388FF),
                            art: _TileArt.icon(AppAssets.kitIconBook),
                            onTap: () => _openPastLives(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _EndingsCollection(
                    discovered: stats.discoveredEndings.toSet(),
                    onPlay: () => _playLife(context),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 118,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ShortcutCard(
                            label: 'Academy',
                            subtitle: 'Lessons & quizzes',
                            icon: Icons.school_rounded,
                            color: const Color(0xFF58C7FF),
                            art: AppAssets.homeTileBackground,
                            onTap: () => _openTab(AppTabIndex.academy),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ShortcutCard(
                            label: 'Arcade',
                            subtitle: 'Mini-games',
                            icon: Icons.sports_esports_rounded,
                            color: const Color(0xFFFF8FB1),
                            art: AppAssets.arcadeTileBackground,
                            onTap: () => _openTab(AppTabIndex.minigames),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The endings collection — every [LifeEndingArchetype] as a slot, filled in
/// once the player actually reaches it.
///
/// This is what turns Life from "a run you finish" into "a set you complete":
/// endings were already computed and shown on the epilogue, but nothing
/// remembered them, so there was no reason to replay for a different one.
class _EndingsCollection extends StatelessWidget {
  const _EndingsCollection({required this.discovered, required this.onPlay});

  final Set<String> discovered;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    const all = LifeEndingArchetype.values;
    final found = all.where((e) => discovered.contains(e.name)).length;
    final complete = found == all.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.getPuffyDecoration(
        accent: const Color(0xFFFFD45C),
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The spinning/glowing treatment, on the one element that
              // earns it: the collection's own trophy.
              IdleHoverIcon(
                idleAmplitude: 0,
                continuousSpin: complete,
                pulseAmplitude: complete ? 0.0 : 0.10,
                period: const Duration(seconds: 6),
                child: Icon(
                  complete
                      ? Icons.workspace_premium_rounded
                      : Icons.auto_stories_rounded,
                  color: const Color(0xFFFFD45C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Endings',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$found / ${all.length}',
                style: AppTheme.numeric(
                  color: const Color(0xFFFFD45C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            complete
                ? 'Every ending found. However you live it, you have seen where it goes.'
                : 'How your life turns out decides the ending you get. Play differently to find the rest.',
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Slot grid sized off available width so it reflows from a
              // narrow phone up to a tablet without a fixed column count.
              final columns = (constraints.maxWidth / 108).floor().clamp(2, 7);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: all.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 92,
                ),
                itemBuilder: (context, index) {
                  final ending = all[index];
                  return _EndingSlot(
                    ending: ending,
                    found: discovered.contains(ending.name),
                  );
                },
              );
            },
          ),
          if (!complete) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF85EFAC),
                  side: BorderSide(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  'Live another life',
                  style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndingSlot extends StatelessWidget {
  const _EndingSlot({required this.ending, required this.found});

  final LifeEndingArchetype ending;
  final bool found;

  @override
  Widget build(BuildContext context) {
    // A found ending shows the face you became; an undiscovered one shows a
    // padlock over the same plate. Keeping the *shape* identical either way
    // is what makes the row read as a collection with gaps in it, rather
    // than as a list that happens to be partly greyed out.
    //
    // The portrait is deliberately not silhouetted when locked: a blacked-out
    // face reads as a bug at this size, where a padlock reads as a lock.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: found
            ? ending.color.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: found
              ? ending.color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: found
                ? Image.asset(
                    ending.portrait,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Icon(ending.icon, color: ending.color, size: 24),
                  )
                : Center(child: PixelKitIcon(AppAssets.kitIconLock, size: 22)),
          ),
          const SizedBox(height: 6),
          FittedLabel(
            found ? ending.label : 'Undiscovered',
            alignment: Alignment.center,
            textAlign: TextAlign.center,
            style: GoogleFonts.pixelifySans(
              color: found
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              fontSize: 10.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hub's one big card, and the app's main call to action.
///
/// It used to be a flat green gradient with four paragraphs of text on it,
/// which is a fair description of a settings page and a poor one of the
/// entrance to a game. Now the card is a *place*: the session's town map
/// behind it, and the player's own character standing in it.
///
/// The character is the load-bearing half. A player who has spent gold on a
/// skin has no other screen that shows it at size, and "the thing I chose is
/// standing in the world I am about to enter" is a far better argument for
/// pressing the button than a sentence describing one.
class _LifeHeroCard extends StatelessWidget {
  const _LifeHeroCard({required this.onPlay, required this.skin});

  final VoidCallback onPlay;
  final AvatarSkin skin;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.32),
          ),
          boxShadow: AppTheme.puffyShadow(
            const Color(0xFF85EFAC),
            restAlpha: 0.2,
          ),
        ),
        child: Stack(
          children: [
            // The town this launch rolled, sharp, because the whole point of
            // the card is that it looks like somewhere.
            Positioned.fill(
              child: Image.asset(
                MapVariant.current.sharp,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                alignment: Alignment.topCenter,
              ),
            ),
            // Dark enough on the left for the copy, clear on the right where
            // the character stands. A flat scrim would have had to be dark
            // enough for the text everywhere, which would have thrown away
            // the art it was laid over.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const <double>[0.0, 0.52, 1.0],
                    colors: <Color>[
                      const Color(0xFF0C2418).withValues(alpha: 0.94),
                      const Color(0xFF0C2418).withValues(alpha: 0.82),
                      const Color(0xFF0C2418).withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 0,
              top: 12,
              child: IgnorePointer(
                child: IdleHoverIcon(
                  idleAmplitude: 2.5,
                  child: AvatarSprite(skin: skin, size: 108),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          // Gold-on-gold: the 18% wash pulls the pill up towards
                          // the label and the pair measured 3.48:1. This is the
                          // "yellow text is hard to see" case, and it is the wash
                          // that causes it rather than the gold.
                          color: _mainGameTag.fill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'MAIN GAME',
                          style: GoogleFonts.pixelifySans(
                            color: _mainGameTag.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Play Life',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Trimmed from a 22-word sentence. The old copy listed all four
                  // stats by name on the one card nobody needs convincing by --
                  // they are about to see every one of them on a bar at the bottom
                  // of the game, labelled.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(
                      'Grow up a year at a time and decide what to do with '
                      'the money.',
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onPlay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF85EFAC),
                      foregroundColor: const Color(0xFF06251A),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 22,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      'Start your life',
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.art,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Scene art behind the card. These backgrounds were already in the repo
  /// and already registered, and nothing was drawing them.
  final String art;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.getPuffyDecoration(
          accent: color,
          fillColor: AppTheme.panelStrong,
          restAlpha: 0.14,
          borderRadius: AppTheme.radiusLarge,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              art,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              alignment: Alignment.center,
            ),
            // Heavier at the bottom, where the two labels are. The art is
            // there to say what the place is, not to be read through.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const <double>[0.0, 0.42, 1.0],
                  colors: <Color>[
                    const Color(0xFF0C2418).withValues(alpha: 0.52),
                    const Color(0xFF0C2418).withValues(alpha: 0.80),
                    const Color(0xFF0C2418).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 26),
                  const Spacer(),
                  Text(
                    label,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a [_PictureTile] shows: a kit icon, or a piece of scene art.
///
/// Two cases rather than one because they want opposite treatment. A 16px kit
/// icon has to be scaled up hard and *must* stay nearest-neighbour or it
/// turns to soup; a mentor illustration is already the right size and wants
/// to sit whole, not cropped.
class _TileArt {
  const _TileArt._(this.asset, this.isIcon);

  const _TileArt.icon(String asset) : this._(asset, true);

  const _TileArt.image(String asset) : this._(asset, false);

  final String asset;
  final bool isIcon;
}

/// One square of the hub's three-up row: a picture, a word, and a fact.
///
/// This replaces a full-width card carrying a heading plus up to two lines of
/// explanatory prose. The prose was not wrong, it was just answering a
/// question nobody had asked yet — you find out what Ranked is by pressing
/// Ranked, and the epilogue explains the scoring at the point it means
/// something. What the hub owes you is a way in you can see.
class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.label,
    required this.caption,
    required this.accent,
    required this.art,
    required this.onTap,
  });

  final String label;
  final String caption;
  final Color accent;
  final _TileArt art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(accent, alpha: 0.16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: chip.fill,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: accent.withValues(alpha: 0.42)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // `SizedBox.expand` is doing real work here, not padding out
              // the tree. A `Column` hands its children a *loose* width, and
              // a bare `Image` with no width or height lays out at the
              // source's intrinsic size under a loose constraint -- so the
              // 16x16 kit icons drew at 16x16 inside a 100px slot and the
              // tiles rendered, to the eye, empty. Forcing the box first
              // gives `BoxFit.contain` something to fit *to*.
              Expanded(
                child: IdleHoverIcon(
                  idleAmplitude: 1.5,
                  child: SizedBox.expand(
                    child: Image.asset(
                      art.asset,
                      fit: BoxFit.contain,
                      filterQuality: art.isIcon
                          ? FilterQuality.none
                          : FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Fitted rather than sized: "How to play" is nearly twice the
              // width of "Ranked" and they share a column width.
              FittedLabel(
                label,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              FittedLabel(
                caption,
                style: GoogleFonts.quicksand(
                  color: chip.ink,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
