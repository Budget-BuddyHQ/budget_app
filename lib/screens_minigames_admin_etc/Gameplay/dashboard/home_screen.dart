import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../config/dev_preview_flags.dart';
import '../../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../../controllers_that_updates_stats/daily_plan_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../models_Like_Skins_and_lessons_templates/daily_quest.dart';
import '../../../constants/app_assets.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../../widgets_custom_lotties/coach_spot.dart';
import '../../../widgets_custom_lotties/feedback_prompt_sheet.dart';
import '../../../widgets_custom_lotties/idle_hover_icon.dart';
import '../../../widgets_custom_lotties/mentor_tip_card.dart';
import '../../../widgets_custom_lotties/money_glyphs.dart';
import '../../../widgets_custom_lotties/profile_avatar.dart';
import '../../../widgets_custom_lotties/reef_scene.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import 'leaderboard_screen.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.dashboard,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  /// The town is part of a life, not a separate mode — so this starts a
  /// Life run rather than dropping straight onto the map. Once you're in a
  /// life, the Life screen's "Explore the town" action opens the world.
  /// That keeps one rule: you walk the town *as* the character you're
  /// currently living, which is the whole point of pairing them.
  Future<void> _openAdventureWorld(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).pushNamed('/life');
  }

  /// Switches to the Daily *tab*; never pushes a copy of it.
  ///
  /// Home used to push a fresh `MoneyHabitsScreen`, which put a second live
  /// instance on top of the one already in `MainNavigation`'s `IndexedStack`
  /// at [AppTabIndex.daily] — each with its own `TabController`, so which
  /// inner tab you were looking at depended on which of the two routes you
  /// arrived through. Where there is no tab bar to drive (Home mounted on
  /// its own, as the tests do) it falls back to the named route, which lands
  /// on the same single instance inside `DashboardShell`.
  void _openDaily(BuildContext context) {
    HapticFeedback.lightImpact();
    final selector = onNavSelected;
    if (selector != null) {
      selector(AppTabIndex.daily);
      return;
    }
    Navigator.of(context).pushNamed('/daily');
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
          backgroundColor: AppTheme.deepForest,
          // No AppBar here on purpose. MainNavigation's `_TopIconBar` (the
          // Learn — Budget Buddy — Profile strip) already sits above every
          // tab, so this was duplicating the wordmark. "Level N | Gold"
          // duplicated the hero card's own chip about 4 pixels below it, and
          // the trophy button duplicated _LeaderboardPromoCard further down.
          // stacking a second ~80px toolbar on the global one *on top of*
          // all that duplication is what "too much white space at the top"
          // actually was. removing it loses nothing, its all still in the
          // body somewhere
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: Stack(
            children: [
              const Positioned.fill(child: _DashboardBackdrop()),
              SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeight = constraints.maxHeight < 650;
                    final heroHeight =
                        (constraints.maxHeight * (compactHeight ? 0.38 : 0.40))
                            .clamp(compactHeight ? 225.0 : 240.0, 300.0)
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
                          // hero already starts a life (and youp get to the
                          // town from inside one) so a separate "Play
                          // Life" card underneath was a second button doing
                          // the same job — removed so Home has one obvious
                          // primary action instead of two competing ones.
                          const SizedBox(height: 10),
                          _TodayCard(onOpen: () => _openDaily(context)),
                          // The coach, on the screen everybody lands on.
                          //
                          // Above the mentor tip on purpose. `MentorTipCard`
                          // is general advice that is true for everyone;
                          // this is one sentence about *this* player's own
                          // numbers, and when both are on screen the
                          // specific one has to come first or it reads as a
                          // footnote to the generic one.
                          //
                          // Renders nothing at all for a new account — see
                          // `MoneyReport.isNewcomer`. A coach with no
                          // history to read should be quiet rather than
                          // encouraging.
                          const CoachSpot(
                            margin: EdgeInsets.only(top: 10),
                          ),
                          const SizedBox(height: 10),
                          MentorTipCard(
                            simpleWording: stats.ageBand.prefersSimpleWording,
                          ),
                          const SizedBox(height: 10),
                          _DestinationsCard(
                            stats: stats,
                            compact: compactHeight,
                            // Was a same-named button that opened the
                            // React Challenge game directly, bypassing the
                            // actual Daily tab entirely — two different
                            // "Daily"s. Now it just goes to the tab; the
                            // game lives there instead (see
                            // money_habits_screen.dart's _DailyChallengeCard).
                            onPlayNow: () =>
                                onNavSelected?.call(AppTabIndex.daily),
                            onOpenAdventure: () =>
                                onNavSelected?.call(AppTabIndex.adventure),
                            onOpenArcade: () =>
                                onNavSelected?.call(AppTabIndex.minigames),
                            onOpenAcademy: () =>
                                onNavSelected?.call(AppTabIndex.academy),
                            onCustomize: () =>
                                onNavSelected?.call(AppTabIndex.customize),
                          ),
                          const SizedBox(height: 10),
                          // The trophy icon in the AppBar was the only way
                          // in and easy to miss — this gives the leaderboard
                          // its own card with the same visual weight as the
                          // other feature promos above it.
                          _LeaderboardPromoCard(
                            gold: stats.gold,
                            onOpen: () => _openLeaderboard(context),
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
  State<_FeedbackPromptTrigger> createState() => _FeedbackPromptTriggerState();
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

/// Today's plan, on Home, as one line of consequence rather than a menu.
///
/// **What it replaced.** A card headed "Pick a money habit" that opened the
/// habit tracker by *pushing a second live copy* of the screen already
/// sitting in the tab stack at [AppTabIndex.daily] — two instances, two
/// TabControllers, and which inner tab you landed on depended on which of
/// the two routes you came in through. It also gave the habit tracker a
/// promo slot on Home while the actual daily plan — an ordered, needs-based,
/// streak-bearing checklist that `DailyPlanController` had been rebuilding
/// on every stats change since it was written — had no slot anywhere at all.
///
/// So this shows the plan and nothing else: how far through today you are,
/// and the single next thing. Everything else about today is one tap away on
/// the tab this opens, which is the point of having a tab.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onOpen});

  final VoidCallback onOpen;

  static const Color _flame = Color(0xFFFF8A5B);

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<DailyPlanController>().plan;
    final streak = plan?.streakDays ?? 0;
    final next = plan?.nextQuest;
    final accent = streak > 0 ? _flame : AppTheme.greenPrimary;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.getPuffyDecoration(
          accent: accent,
          fillColor: const Color(0xFF12352C),
          restAlpha: 0.18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: streak > 0 ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.34)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 15,
                        color: accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: AppTheme.numeric(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedLabel(
                    'Today',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (plan != null)
                  Text(
                    '${plan.completedCount}/${plan.quests.length}',
                    style: AppTheme.numeric(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: accent, size: 26),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: plan?.progress ?? 0,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 12),
            if (next != null)
              _NextQuestRow(quest: next)
            else
              Text(
                plan == null
                    ? 'Working out today\'s plan…'
                    : 'Everything on today\'s plan is done. Back tomorrow.',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The one quest Home shows: the first incomplete one.
///
/// Only one, on purpose. The whole list lives on the Daily tab; repeating it
/// here would make Home a second copy of that screen, which is the mistake
/// this card exists to undo.
class _NextQuestRow extends StatelessWidget {
  const _NextQuestRow({required this.quest});

  final DailyQuest quest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: quest.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: quest.accent.withValues(alpha: 0.3)),
          ),
          child: IdleHoverIcon(
            rotationAmplitude: 0.12,
            child: Icon(quest.icon, color: quest.accent, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedLabel(
                quest.title,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              // Two lines rather than a fitted one line, for the same
              // reason as the quest rows on the Daily tab: this is a
              // sentence, and FittedLabel is for labels.
              Text(
                quest.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2A20),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFD45C).withValues(alpha: 0.30),
            ),
          ),
          child: Text(
            '+${quest.xpReward}',
            style: AppTheme.numeric(
              color: const Color(0xFFFFD45C),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardPromoCard extends StatelessWidget {
  const _LeaderboardPromoCard({required this.gold, required this.onOpen});

  final int gold;
  final VoidCallback onOpen;

  static const _gold = Color(0xFFFFD45C);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.getPuffyDecoration(
          accent: _gold,
          fillColor: const Color(0xFF3B301A),
          restAlpha: 0.18,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: _gold,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedLabel(
                    'Leaderboard',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Shortened rather than ellipsised. `$gold` can be seven
                  // digits, so the sentence length varies with the player's
                  // balance — the long version fit at 1,200 gold and
                  // truncated at 999,999. Naming the two boards was the
                  // expendable half; the card opens straight onto them.
                  Text(
                    'You have $gold gold — see where that ranks.',
                    maxLines: 2,
                    style: GoogleFonts.quicksand(
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
            const Icon(Icons.chevron_right_rounded, color: _gold, size: 30),
          ],
        ),
      ),
    );
  }
}

/// The water the whole page sits in.
///
/// **What this replaced and why.** It used to be a small repeating icon
/// pattern dimmed to 28% opacity. The thin gaps between cards exposed it as a
/// crisp, chopped-off sliver of unrelated icons, which read as visual debris
/// — the comment that used to live here said as much, and the fix at the
/// time was to dim it harder, which only made it a grey wash with debris in
/// it. A tiled pattern behind a column of cards has nothing to say; open
/// water does, because it is a *place*, and the mascot is a turtle.
///
/// Deliberately the [ReefWater.abyss] grade rather than the brighter lagoon
/// used inside the hero: this is behind body text and buttons for the whole
/// scroll, and background that competes with foreground is the actual
/// failure mode here, not background that is too plain.
class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return const ReefScene(
      water: ReefWater.abyss,
      seed: 11,
      // **No near floor here, and that is the whole point.** The first
      // version of this drew the full reef — sand, seaweed, coral — behind
      // the scroll, and the result was worse than the tiled pattern it
      // replaced: a bright cream slab and a row of lit-up plants running
      // straight through the "Current Objective" card, so the busiest thing
      // on the page was the part nobody is meant to look at. The far
      // silhouettes stay, because haze at 20% reads as depth and cannot
      // compete with anything.
      showFloor: false,
      // Only sets where the far bank sits now that the near floor is off.
      // Kept low so most of the silhouette band ends up behind the bottom
      // nav rather than behind the last card.
      floorHeight: 68,
      fishCount: 3,
      bubbleCount: 11,
      // Slower than the hero's. Two reefs moving at the same rate on one
      // screen fight each other; the far one should barely move.
      period: Duration(seconds: 48),
    );
  }
}

/// The one card at the top of Home, and the only primary action on it.
///
/// **Why it is a diorama rather than a card.** The previous version was a
/// green gradient rectangle with a pill, a heading, a line of body text and a
/// button — the same construction as the four cards underneath it, only
/// bigger, so the page read as five cards of decreasing size rather than as a
/// screen with a subject. What the top of the app was missing was not more
/// text; it was somewhere to be. This is a reef with the player's own turtle
/// in it, and the words sit on top of that.
///
/// The scene is not decoration bolted on: [ReefScene] is the same widget the
/// page backdrop uses, at a brighter water grade and a faster clock, which is
/// what makes the hero read as *nearer* than the water behind it.
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.puffyShadow(
            const Color(0xFF3FD3C4),
            restAlpha: 0.22,
            blurRadius: 36,
            spreadRadius: -8,
            offset: const Offset(0, 18),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final veryTight = constraints.maxHeight < 196;
              final narrow = constraints.maxWidth < 520;
              final phone = constraints.maxWidth < 430;
              // The sea floor has to stay clear of the button, or the CTA
              // sits in a seaweed bed and neither of them reads.
              final floor = (constraints.maxHeight * 0.22).clamp(46.0, 78.0);

              return Stack(
                children: [
                  Positioned.fill(
                    child: ReefScene(
                      seed: 3,
                      floorHeight: floor,
                      fishCount: phone ? 3 : 4,
                      bubbleCount: 7,
                      period: const Duration(seconds: 26),
                    ),
                  ),
                  // A scrim that is heavy on the left and gone by the right.
                  // Body text over open water is the one thing that does not
                  // survive a fish swimming behind it; the right-hand half
                  // stays clear so the reef is still visibly a reef.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF06231F).withValues(alpha: 0.72),
                              const Color(0xFF06231F).withValues(alpha: 0.30),
                              const Color(0xFF06231F).withValues(alpha: 0),
                            ],
                            stops: const [0, 0.46, 0.78],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXLarge,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF8FD8D2,
                            ).withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 14 : 20),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: _HeroAvatar(
                            turtleSkin: turtleSkin,
                            profileImageUrl: profileImageUrl,
                            size: veryTight ? 70 : 92,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: _HudReadout(
                            level: stats.level,
                            gold: stats.gold,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: narrow
                                  ? constraints.maxWidth * 0.78
                                  : constraints.maxWidth * 0.58,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FittedBox rather than trusting the font
                                // sizes below to already fit: at a genuinely
                                // narrow pane (~310px, confirmed against a
                                // real screenshot — narrower than any
                                // viewport this app's tests cover, which
                                // start at 320px) "Explore the Town" at 30px
                                // pixelifySans did not fit the card's own
                                // title column and silently truncated to
                                // "Explore th…". FittedBox scales the whole
                                // line down as one unit so it is always the
                                // full phrase, just smaller, never a
                                // fragment.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    // Was "Adventure Soon" — stale copy from
                                    // before the town map actually existed.
                                    // It is real now, with places to walk
                                    // into, so the card says so.
                                    'Explore the Town',
                                    maxLines: 1,
                                    style: GoogleFonts.pixelifySans(
                                      color: Colors.white,
                                      fontSize: veryTight
                                          ? 25
                                          : (phone ? 30 : 34),
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xCC06231F),
                                          blurRadius: 12,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: veryTight ? 5 : 8),
                                // Always shown. This used to be wrapped in
                                // `if (!veryTight)`, where veryTight is
                                // `maxHeight < 196` — and the hero's own
                                // computed height lands within a couple of
                                // pixels of 196 on a phone. So a hair more or
                                // less available height made a whole
                                // paragraph appear or vanish, which is why a
                                // *wider* window could show *less* text than
                                // a narrow one. Content should not blink in
                                // and out on a 2px threshold.
                                Text(
                                  'Walk the town — every shop is a real '
                                  'money decision.',
                                  maxLines: 2,
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    height: 1.3,
                                    fontSize: veryTight ? 12.5 : 13.5,
                                    fontWeight: FontWeight.w700,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0xCC06231F),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: veryTight ? 10 : 16),
                                _ActionButton(
                                  label: 'Start a Life',
                                  accent: const Color(0xFF7BE9D7),
                                  icon: Icons.explore_rounded,
                                  compact: phone || veryTight,
                                  onTap: onOpenAdventure,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Level and gold, drawn as a HUD rather than written as a sentence.
///
/// This replaced the line `Level 7  |  999999 Gold`, set in a pixel *text*
/// font inside one pill. Two things were wrong with that: a balance is the
/// number a player looks for most often on this screen and it carried
/// exactly the same weight as the word beside it, and the figure gains a
/// character every order of magnitude, so the pill silently changed width
/// with the player's balance.
///
/// The digits now come from [MoneyGlyphs] — the underwater pack's own bold
/// italic numerals, which is real display art rather than a typeface with a
/// pixel name. [MoneyGlyphs.canRender] is checked first because a figure
/// drawn half in art and half in fallback text looks worse than one drawn
/// entirely in text.
class _HudReadout extends StatelessWidget {
  const _HudReadout({required this.level, required this.gold});

  final int level;
  final int gold;

  static const Color _gold = Color(0xFFFFD45C);

  @override
  Widget build(BuildContext context) {
    final goldText = '$gold';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudPill(
          accent: const Color(0xFF8FD8D2),
          child: Text(
            'LV $level',
            style: AppTheme.numeric(
              color: const Color(0xFFCFF6F1),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _HudPill(
          accent: _gold,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.kitIconCoin,
                width: 14,
                height: 14,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(width: 6),
              if (MoneyGlyphs.canRender(goldText))
                MoneyGlyphs(goldText, height: 18)
              else
                Text(
                  goldText,
                  style: GoogleFonts.pixelifySans(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // Darker than the water behind it on purpose. A translucent pill over
        // a moving reef is unreadable the moment a fish passes under it.
        color: const Color(0xFF06231F).withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: child,
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

/// Where you are, and the five places you can go.
///
/// **Why the prose went.** This was "Current Objective", and under that
/// heading it carried the subtitle `Daily run · Academy · Arcade` and the
/// sentence *"Enter the adventure, then use a quick practice loop if you
/// need more gold or literacy points."* — a heading, a list of three of the
/// five buttons directly beneath it, and a paragraph restating what the
/// buttons already said, stacked above the buttons themselves. Three ways of
/// saying the same thing is what makes a screen feel like it is mostly
/// words. The buttons stayed because they are the only quick route to four
/// tabs; everything above them that was describing them did not.
///
/// It also no longer claims to be the objective. Today's plan is the
/// objective, and it now has its own card directly above this one.
class _DestinationsCard extends StatelessWidget {
  const _DestinationsCard({
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

  /// XP in a level, mirroring `UserStats.levelProgress`, which is
  /// `(xp % 120) / 120`. Written here as the same constant rather than a
  /// second guess at the curve.
  static const int _xpPerLevel = 120;

  @override
  Widget build(BuildContext context) {
    final into = stats.xp % _xpPerLevel;
    final toGo = _xpPerLevel - into;

    return _GlassPanel(
      padding: EdgeInsets.all(compact ? 14 : 18),
      radius: 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 42 : 50,
                height: compact ? 42 : 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.26),
                  ),
                ),
                child: Text(
                  '${stats.level}',
                  style: AppTheme.numeric(
                    color: const Color(0xFF85EFAC),
                    fontSize: compact ? 18 : 21,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedLabel(
                      'Level ${stats.level}',
                      style: AppTheme.numeric(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FittedLabel(
                      '$toGo XP to level ${stats.level + 1}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.64),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AmbientLottieCard(
                motif: AmbientMotif.arcade,
                semanticLabel: 'Arcade decoration',
                width: compact ? 58 : 92,
                height: compact ? 46 : 70,
                padding: EdgeInsets.all(compact ? 4 : 6),
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                borderColor: Colors.white.withValues(alpha: 0.08),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: compact ? 9 : 12,
              // Floored so a freshly levelled bar is still visibly a bar
              // rather than an empty track.
              value: stats.levelProgress.clamp(0.04, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF85EFAC),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          _ObjectiveActionBar(
            compact: compact,
            onAdventure: onOpenAdventure,
            onDaily: onPlayNow,
            onArcade: onOpenArcade,
            onAcademy: onOpenAcademy,
            onCustomize: onCustomize,
          ),
        ],
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
        // Icon above label, not beside it.
        //
        // Side by side, the label was dropped whenever the slot fell under
        // 70px — and five equal slots in this card come out at about 60px on
        // any phone, so in practice *every phone* got five unlabelled
        // squares and had to guess which one was Academy. Stacking gives the
        // label the full slot width instead of what is left after an icon,
        // so it survives at every size this app runs at.
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 4),
              FittedLabel(
                label,
                alignment: Alignment.center,
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
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
    this.compact = false,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final IconData icon;
  final bool compact;
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
                height: widget.compact ? 48 : 56,
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
                            size: widget.compact ? 18 : 20,
                          ),
                          SizedBox(width: widget.compact ? 6 : 8),
                          Flexible(
                            child: FittedLabel(
                              widget.label,
                              style: GoogleFonts.pixelifySans(
                                color: Color(0xFF062C21),
                                fontWeight: FontWeight.w700,
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
