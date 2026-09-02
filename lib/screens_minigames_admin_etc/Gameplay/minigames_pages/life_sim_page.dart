import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../models_Like_Skins_and_lessons_templates/outing_rules.dart';
import '../../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/concept_powers.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_tutorial_steps.dart';
import '../../../models_Like_Skins_and_lessons_templates/ranked_run.dart';
import '../../../themes_colors/app_theme.dart';
import '../../onboarding/coach_mark.dart';
import '../../../widgets_custom_lotties/confetti_burst.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../adventure/adventure_world_screen.dart';
import 'life_character_sheet.dart';
import 'life_epilogue_screen.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/life_money_panel.dart';
import '../../../widgets_custom_lotties/money_glyphs.dart';
import '../../../widgets_custom_lotties/pixel_kit.dart';
import '../../../widgets_custom_lotties/pixel_panel.dart';

/// **Life** — the main game, in the BitLife format: a scrolling life feed up
/// top, a fixed bottom menu, and a big central Age button that advances time
/// and surfaces money-decision events. (A map to explore comes later.)
///
/// Owns its own [LifeSimController], so state resets each visit and never
/// touches the player's saved gold until they retire.
class LifeSimPage extends StatefulWidget {
  const LifeSimPage({super.key, this.debugInitialLife, this.ranked = false});

  /// Ranked run: same simulation, scored at the end.
  ///
  /// A flag rather than a separate screen, because the *rules* are identical
  /// -- ranked is not a different game, it is the same one with the question
  /// narrowed to "how much can you build". Forking the screen would mean two
  /// copies of the life sim drifting apart, which is a much worse problem
  /// than one boolean.
  final bool ranked;

  /// Skips character creation and plays this life instead.
  ///
  /// A test seam, and one that was worth adding: because the page pushes
  /// the character sheet in a post-frame callback, a layout sweep that
  /// pumped `LifeSimPage` was only ever measuring the *creation* screen.
  /// The feed — the money panel, the stat meters, the event card, the
  /// chain chips, every part that actually reflows — had no viewport
  /// coverage at all while appearing to have eight viewports' worth.
  ///
  /// Null in the app. Nothing reads it outside `initState`.
  final LifeSimController? debugInitialLife;

  @override
  State<LifeSimPage> createState() => _LifeSimPageState();
}

class _LifeSimPageState extends State<LifeSimPage> {
  // Anchors for the in-game tour. Registered with [TutorialTargets] rather
  // rather than positioned by hand, so the spotlight follows the real
  // widget at whatever size / text scale / scroll offset youp are at. a
  // hardcoded rect is correct on exactly one device and points at empty
  // space on all the others
  final GlobalKey _tourMoneyKey = GlobalKey();
  final GlobalKey _tourEventKey = GlobalKey();
  final GlobalKey _tourTownKey = GlobalKey();
  final GlobalKey _tourMenuKey = GlobalKey();
  final GlobalKey _tourAgeKey = GlobalKey();

  bool _tourRunning = false;
  LifeSimController? _life;
  final ScrollController _feedController = ScrollController();
  bool _cashedOut = false;

  @override
  void initState() {
    super.initState();
    final injected = widget.debugInitialLife;
    if (injected != null) {
      _life = injected;
      return;
    }
    // character creation first, same as starting a new bitlife
    WidgetsBinding.instance.addPostFrameCallback((_) => _createCharacter());
  }

  Future<void> _createCharacter() async {
    final character = await Navigator.of(context).push<LifeCharacter>(
      MaterialPageRoute(builder: (_) => const LifeCharacterSheet()),
    );
    if (!mounted) return;
    if (character == null) {
      // backed out of creation, so leave Life altogether
      Navigator.of(context).pop();
      return;
    }
    // new life = fresh world. town progress (visited spots, coins picked
    // up) is stored per *player* not per run, so without this your second
    // life starts with every building already ticked and every coin gone.
    // town would be a finished checklist for every
    // character after the first.
    if (mounted) {
      await context.read<UserStatsController>().resetTownProgress();
    }
    if (!mounted) return;

    setState(() {
      _life = LifeSimController(
        name: character.name,
        gender: character.gender,
        origin: character.origin,
        startMoney: character.origin.familyMoney,
      );
    });
    _maybeStartFirstTour();
  }

  @override
  void dispose() {
    for (final id in const <String>[
      'life_money',
      'life_event',
      'life_town',
      'life_menus',
      'life_age',
    ]) {
      TutorialTargets.unregister(id);
    }
    _life?.dispose();
    _feedController.dispose();
    super.dispose();
  }

  void _scrollFeedToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_feedController.hasClients) {
        _feedController.animateTo(
          _feedController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _finish(LifeSimController life) async {
    if (_cashedOut) return;
    _cashedOut = true;
    final died = life.dead;
    life.retire();
    final reward = life.goldReward;
    // Snapshot now — the controller is disposed once this page navigates
    // away, so the epilogue screen needs its own frozen copy of the numbers.
    final summary = LifeSummary.fromController(life);

    final controller = context.read<UserStatsController>();
    if (reward > 0) {
      await controller.applyChallengePayload({
        'gold_earned': reward,
        'xp_earned': 8 + life.yearsLived,
        'title': 'Life',
        'description':
            '${life.name} lived to ${life.age} with a net worth of '
            '${life.netWorth} coins.',
      });
    }
    // Adds this ending to the collection shown on the Adventure hub.
    await controller.recordLifeEnding(summary.archetype.name);
    // ...and files the run itself, which is what Past Lives and the
    // personal bests are built from. Must come after the gold award above
    // so the record's reward figure matches what was actually paid out.
    final bestsBeaten = await controller.recordLifeRun(summary);
    if (!mounted) return;
    GameToast.show(
      context,
      title: died ? 'Life complete' : 'Life banked',
      message: reward > 0
          ? 'You earned $reward gold from this life.'
          : 'Live a few more years to earn a gold reward.',
      icon: Icons.savings_rounded,
      accent: const Color(0xFFE1BB72),
    );
    // Scored from the controller before it is disposed, for the same reason
    // the summary is snapshotted above.
    final score = widget.ranked ? scoreRankedRun(life.rankedResult) : null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LifeEpilogueScreen(
          summary: summary,
          bestsBeaten: bestsBeaten,
          rankedScore: score,
        ),
      ),
    );
  }

  void _invest(LifeSimController life) {
    if (life.money < 100) {
      GameToast.show(
        context,
        title: 'Not enough cash',
        message: 'You need 100 coins to invest.',
        icon: Icons.info_outline_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }
    life.invest(100);
  }

  /// Opens one of the four category menus.
  ///
  /// This is the structural difference between "a button that does a thing"
  /// and a life sim: a menu can hold six actions with costs and conditions
  /// where a bottom-bar slot can only hold one. Actions are built fresh on
  /// open so their enabled/disabled state reflects the character *now*.
  void _registerTourTargets() {
    TutorialTargets.register('life_money', _tourMoneyKey);
    TutorialTargets.register('life_event', _tourEventKey);
    TutorialTargets.register('life_town', _tourTownKey);
    TutorialTargets.register('life_menus', _tourMenuKey);
    TutorialTargets.register('life_age', _tourAgeKey);
  }

  /// Opens the in-game tour.
  ///
  /// A route rather than an overlay entry: the tour has to sit above the
  /// screen's own bottom sheets and dialogs, and a route is the only thing
  /// that reliably does. `opaque: false` keeps the game visible underneath,
  /// which is the entire point of a coach mark.
  Future<void> _startTour() async {
    if (_tourRunning || !mounted) return;
    setState(() => _tourRunning = true);
    _registerTourTargets();
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (routeContext, _, _) => CoachMarkOverlay(
          steps: kLifeTutorialSteps,
          onFinished: () => Navigator.of(routeContext).maybePop(),
          // Nothing to switch to: this tour runs over one screen, not over
          // the tab bar.
          onWantTab: (_) async {},
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _tourRunning = false);
    await context.read<AppSettingsController>().markLifeTourSeen();
  }

  /// Runs the in-game tour the first time somebody actually reaches a life.
  ///
  /// Deliberately *after* character creation rather than on entering the
  /// route: a tour that spotlights the money panel while the player is still
  /// picking a name is pointing at widgets that do not exist yet, and the
  /// overlay would centre every card and explain nothing.
  void _maybeStartFirstTour() {
    if (!mounted || _tourRunning) return;
    final settings = context.read<AppSettingsController>();
    if (!settings.isLifeTourDue) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
  }

  Future<void> _openMenu(LifeSimController life, _LifeMenu menu) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LifeMenuSheet(
        menu: menu,
        life: life,
        onSkills: () {
          Navigator.of(sheetContext).pop();
          _openSkills(life);
        },
        onInvest: () {
          Navigator.of(sheetContext).pop();
          _invest(life);
        },
        onBudget: () => _openBudget(life),
        onConcepts: () => _openConcepts(life),
        onPowers: () => _openPowers(life),
      ),
    );
  }

  /// The budgeting exercise — the app's core skill, made playable.
  Future<void> _openBudget(LifeSimController life) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BudgetSheet(life: life),
    );
    if (mounted) _drainLesson(life);
  }

  /// The running list of money ideas this life has surfaced.
  Future<void> _openPowers(LifeSimController life) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PowersSheet(life: life),
    );
  }

  Future<void> _openConcepts(LifeSimController life) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConceptsSheet(
        concepts: life.conceptsMet,
        simpleWording: _simpleWording,
      ),
    );
  }

  /// Shows any lesson the controller queued, then clears it.
  ///
  /// Called after every interaction that can teach (a choice, a budget, a
  /// shock) rather than watching for changes, so the explainer always lands
  /// *after* the player has seen the outcome — not on top of it.
  void _drainLesson(LifeSimController life) {
    // Read before takeLesson() clears the pending concept — both describe
    // the same lesson.
    final isNewConcept = life.pendingLessonIsNew;
    final lesson = life.takeLesson();
    if (lesson == null || !mounted) return;
    if (isNewConcept) {
      // A congrats moment for meeting a money idea for the *first* time —
      // not on every repeat, and not when the concept behind it is bad
      // news (a repeat interest-cost lesson from carrying debt should not
      // look like a celebration).
      ConfettiBurst.show(context);
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Deliberately not dismissible by tapping the scrim or swiping down.
      // Every other sheet in this file is a menu the player can back out
      // of freely; this one is the actual teaching moment, and a swipe-off
      // habit would make it as skippable as a toast. "Got it" is the only
      // way out, so reading it is unavoidable rather than optional.
      isDismissible: false,
      enableDrag: false,
      builder: (_) =>
          _MoneyLessonSheet(concept: lesson, simpleWording: _simpleWording),
    );
  }

  /// Reading level for money explainers, from the **player's** self-declared
  /// age band — not the character's in-game age.
  bool get _simpleWording =>
      context.read<UserStatsController>().stats.ageBand.prefersSimpleWording;

  /// Skill practice. Until this existed, `LifeSimController.practise` had no
  /// UI at all — the whole skill/career ladder was unreachable by the player
  /// even though the events gating on it were already in the pool.
  Future<void> _openSkills(LifeSimController life) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SkillsSheet(life: life),
    );
  }

  @override
  Widget build(BuildContext context) {
    final life = _life;
    if (life == null) {
      // Character creation is on top; this is just the backdrop.
      return const Scaffold(
        backgroundColor: AppTheme.deepForest,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF43D07E)),
        ),
      );
    }

    return AnimatedBuilder(
      animation: life,
      builder: (context, _) {
        final event = life.currentEvent;
        _scrollFeedToEnd();
        return PopScope(
          // A life is *not* saved anywhere — LifeSimController is
          // in-memory only, by design (see its class doc). Backing out
          // therefore destroys the run silently, which is a genuinely
          // expensive accident after twenty simulated years. canPop: false
          // routes both the AppBar arrow and the Android system back
          // gesture through the same confirmation.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmQuit(life);
            if (leave && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.deepForest,
            appBar: AppBar(
              backgroundColor: AppTheme.darkForest,
              foregroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 12,
              title: _HeaderBar(
                name: life.name,
                gender: life.gender,
                age: life.age,
                stage: life.stage,
                money: life.money,
                job: life.job,
              ),
              actions: [
                // Not an always-on button any more: whether you can leave the
                // house depends on age, health, how strict your family is and
                // what the weather is doing (see `outing_rules.dart`). When
                // it's blocked the button stays visible and *says why* rather
                // than disappearing — being told "not until you're 14" is
                // part of the game, not an error.
                Builder(
                  builder: (context) {
                    final permission = life.outingPermission;
                    return IconButton(
                      key: _tourTownKey,
                      tooltip: permission.allowed
                          ? 'Explore the town'
                          : permission.message,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (!permission.allowed) {
                          GameToast.show(
                            context,
                            title: 'You cannot go out',
                            message: permission.message,
                            icon:
                                permission.reason?.icon ?? Icons.block_rounded,
                            accent: const Color(0xFFFF8FB1),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            // Hand the run over, so what you decide out
                            // there changes the character and not only the
                            // account.
                            builder: (_) => AdventureWorldScreen(life: life),
                          ),
                        );
                      },
                      icon: Icon(
                        permission.allowed
                            ? Icons.explore_rounded
                            : Icons.lock_rounded,
                        color: permission.allowed ? null : Colors.white38,
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () => _finish(life),
                  icon: Icon(
                    life.dead ? Icons.done_rounded : Icons.flag_rounded,
                    size: 18,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE1BB72),
                  ),
                  label: Text(
                    life.dead ? 'Finish' : 'Retire',
                    style: GoogleFonts.pixelifySans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _LifeFeed(
                    controller: _feedController,
                    history: life.history,
                    smarts: life.smarts,
                    health: life.health,
                    looks: life.looks,
                    relationships: life.relationships,
                    dead: life.dead,
                    event: event,
                    // Choose, then surface the money idea behind that choice
                    // (if it had one) once the outcome is on screen.
                    weather: life.weather,
                    strictness: life.strictness,
                    outing: life.outingPermission,
                    life: life,
                    onOpenBudget: () => _openBudget(life),
                    onOpenMoney: () => _openMenu(life, _LifeMenu.assets),
                    onOpenConcepts: () => _openConcepts(life),
                    moneyKey: _tourMoneyKey,
                    eventKey: _tourEventKey,
                    onChoose: (index) {
                      life.chooseOption(index);
                      _drainLesson(life);
                    },
                  ),
                ),
                _BottomMenu(
                  key: _tourMenuKey,
                  ageKey: _tourAgeKey,
                  happiness: life.happiness,
                  blocked: event != null || life.finished,
                  stage: life.stage,
                  onCareer: () => _openMenu(life, _LifeMenu.career),
                  onRelationships: () =>
                      _openMenu(life, _LifeMenu.relationships),
                  onActivities: () => _openMenu(life, _LifeMenu.activities),
                  onAssets: () => _openMenu(life, _LifeMenu.assets),
                  // Ageing can fire an expense shock, which teaches too.
                  onAge: () {
                    life.ageUp();
                    _drainLesson(life);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// "Are you sure?" before abandoning a run.
  ///
  /// Worth interrupting for precisely because the alternative is silent and
  /// total: a life lives in memory only, so leaving the screen ends it with
  /// no way back. The dialog says that in as many words rather than a bare
  /// "Discard?", and offers Retire as the way to *keep* something — retiring
  /// pays out gold and XP, quitting pays nothing.
  Future<bool> _confirmQuit(LifeSimController life) async {
    if (life.finished) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panelStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Quit this life?',
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${life.name} is ${life.age}. This run is not saved — quitting '
          'now loses it, and you keep no gold or XP from it.\n\n'
          'Retire instead to cash out what you have earned.',
          style: GoogleFonts.quicksand(
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep playing',
              style: GoogleFonts.pixelifySans(
                color: const Color(0xFF85EFAC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Quit anyway',
              style: GoogleFonts.pixelifySans(
                color: const Color(0xFFFF8FB1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.name,
    required this.gender,
    required this.age,
    required this.stage,
    required this.money,
    required this.job,
  });

  final String name;
  final Gender gender;
  final int age;
  final LifeStage stage;
  final int money;
  final String job;

  /// Drops the job segment while it is only restating the life stage.
  ///
  /// Before there is a real career the "job" is a placeholder that means
  /// the same thing as the stage — a Baby's job is "Newborn", a Child's is
  /// "Student". Printing both made the line too long for the header and it
  /// truncated, spending the space on the least informative word.
  static String _subtitleFor({
    required int age,
    required LifeStage stage,
    required String job,
  }) {
    const placeholders = <String>{
      'newborn',
      'baby',
      'child',
      'student',
      'unemployed',
      'none',
      '',
    };
    final trimmed = job.trim();
    if (placeholders.contains(trimmed.toLowerCase())) {
      return 'Age $age · ${stage.label}';
    }
    // Job instead of stage, not as well as. "Age 34 · Adult · Shop Assistant"
    // wanted 180px in the 106px this column gets on a 320px phone — past even
    // FittedLabel's scaling floor, so it truncated. And the dropped word was
    // the useless one: a job title says "adult" more precisely than the word
    // adult does.
    //
    // Then trimmed to a character budget rather than left to scale. This slot
    // is the app bar's title column beside a name, a balance and two buttons;
    // at 320px it is about 106px wide and even the shortened line came in two
    // over. A budget in the *string* fits whatever the layout does, which a
    // scaling floor does not.
    return 'Age $age · ${_fitJob(trimmed, age)}';
  }

  /// Shortens a job title to what the header can actually show.
  ///
  /// Cuts on a word boundary where there is one, so "Senior Financial
  /// Wellness Consultant" becomes "Senior Financial…" rather than "Senior
  /// Financial We…".
  static String _fitJob(String job, int age) {
    // The whole line has to come in under about 19 characters at this size
    // — measured, not guessed: "Age 34 · Shop Assistant" is 23 and lays out
    // at 108px against the 106 available. The prefix has already spent nine
    // of them, and the ellipsis costs one more.
    final budget = 19 - 'Age $age · '.length;
    if (job.length <= budget) return job;
    final cut = job.substring(0, budget - 1);
    final lastSpace = cut.lastIndexOf(' ');
    final kept = lastSpace > budget ~/ 2 ? cut.substring(0, lastSpace) : cut;
    return '$kept…';
  }

  @override
  Widget build(BuildContext context) {
    // This sits in an `AppBar.title`, which hands it whatever is left after
    // the back button and the two action buttons — on a 320px phone that is
    // narrow enough that the avatar plus the balance alone overran it by
    // 1.1px, with the name squeezed to nothing in between. The avatar is
    // decoration (a gender icon); the name and the balance are content, so
    // the avatar is what gives way.
    return LayoutBuilder(
      builder: (context, constraints) =>
          _row(showAvatar: constraints.maxWidth >= 210),
    );
  }

  Widget _row({required bool showAvatar}) {
    return Row(
      children: [
        if (showAvatar) ...[
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF173B2E),
            child: Icon(gender.icon, color: const Color(0xFF85EFAC), size: 20),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedLabel(
                name,
                style: GoogleFonts.pixelifySans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              // "Age 0 · Baby · Newborn" was three segments where two said
              // the same thing — the job of a Baby is always "Newborn", so
              // the line was padded out with a redundant word and then
              // truncated to "Age 0 · Baby · Newb…" for the privilege.
              // Drop the job while it merely restates the life stage; once
              // there is a real one ("Barista"), it earns its place.
              FittedLabel(
                _subtitleFor(age: age, stage: stage, job: job),
                // A lower floor than the default 0.62. This is secondary text
                // under a name that already has the space it needs, and a
                // long job title on a narrow phone is better small than cut.
                minScale: 0.5,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Constrained rather than free: a six-figure balance late in a
            // long life is wide enough in the pixel font to push this row
            // past the screen on a 320px phone, and the balance is the one
            // thing in the header that must stay readable.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              // The balance is the number this header exists to show, so it
              // gets the display face. `FittedBox` keeps a six-figure fortune
              // inside the same 96px the pixel font was clamped to.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: MoneyGlyphs('$money', height: 20),
              ),
            ),
            const Text(
              'coins',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _LifeFeed extends StatelessWidget {
  const _LifeFeed({
    required this.controller,
    required this.history,
    required this.smarts,
    required this.health,
    required this.looks,
    required this.relationships,
    required this.dead,
    required this.event,
    required this.onChoose,
    required this.weather,
    required this.strictness,
    required this.outing,
    required this.life,
    required this.onOpenBudget,
    required this.onOpenMoney,
    required this.onOpenConcepts,
    required this.moneyKey,
    required this.eventKey,
  });

  /// Anchors for the in-game tour. The feed owns the money panel and the
  /// event card, so it is the only place that can hand a key to either.
  final GlobalKey moneyKey;
  final GlobalKey eventKey;

  final ScrollController controller;
  final List<LifeLogEntry> history;
  final int smarts;
  final int health;
  final int looks;
  final List<String> relationships;
  final bool dead;
  final LifeEvent? event;
  final ValueChanged<int> onChoose;

  /// This year's conditions, surfaced so the outing rules are visible
  /// rather than only showing up as a locked button.
  final Weather weather;
  final HouseholdStrictness strictness;
  final OutingPermission outing;

  /// The whole run, for the money panel. Passed as one object rather than
  /// as another six scalars — the panel reads eight fields and would
  /// otherwise double this constructor.
  final LifeSimController life;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenMoney;
  final VoidCallback onOpenConcepts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        _ThisYearPanel(
          weather: weather,
          strictness: strictness,
          outing: outing,
        ),
        const SizedBox(height: 12),
        // Directly under the year card, above the feed. Money is the
        // subject of this game, so it sits where the eye lands first
        // rather than behind a menu — see [LifeMoneyPanel].
        LifeMoneyPanel(
          key: moneyKey,
          life: life,
          onOpenBudget: onOpenBudget,
          onOpenMoney: onOpenMoney,
          onOpenConcepts: onOpenConcepts,
        ),
        const SizedBox(height: 12),
        _MiniStatsRow(smarts: smarts, health: health, looks: looks),
        _YourLifeStrip(flags: life.flags),
        if (relationships.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final person in relationships)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _personChip.fill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: _personChip.ink,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        person,
                        style: TextStyle(
                          color: _personChip.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Tap the green + to age up and start your story.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          for (var i = 0; i < history.length; i++) ...[
            if (i == 0 || history[i].age != history[i - 1].age)
              _AgeHeader(age: history[i].age),
            _FeedLine(text: history[i].text, kind: history[i].kind),
          ],
        if (event != null) ...[
          const SizedBox(height: 14),
          _EventCard(key: eventKey, event: event!, onChoose: onChoose),
        ],
        if (dead) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_florist_rounded,
                  color: Color(0xFFB388FF),
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your life has ended',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap Finish to bank what this life earned you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// What you currently *have* — the dog, the car, the card, the debt.
///
/// This is the chain system made visible. Storylines were added so a run
/// would stop reading as a shuffled deck of unrelated beats, but a chain the
/// player cannot see is indistinguishable from coincidence: the vet bill
/// six years after adopting the dog only lands as a consequence if you were
/// aware, in between, that you had a dog. So the flags that represent
/// something you would say you *own* get a chip; the ones that are pure
/// bookkeeping do not. See `LifeFlag.chipLabel`.
///
/// Renders nothing at all when the list is empty, which is most of
/// childhood — an empty labelled box would be worse than no box.
class _YourLifeStrip extends StatelessWidget {
  const _YourLifeStrip({required this.flags});

  final Set<LifeFlag> flags;

  @override
  Widget build(BuildContext context) {
    final shown = flags.where((f) => f.chipLabel != null).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final flag in shown)
            Builder(
              builder: (context) {
                // The trouble tint (#FF8FB1) reads at only 4.26:1 over its own
                // 14% wash — under AA, and it is the chip a player most needs
                // to read. `tintedChip` keeps the hue and lifts the ink until
                // it clears the threshold, so "Card debt" stays pink and stays
                // legible rather than being swapped for a colour that does not
                // mean anything.
                final tint = flag.isTrouble
                    ? const Color(0xFFFF8FB1)
                    : const Color(0xFF85EFAC);
                // `on:` is the surface the wash sits over. The strip is laid
                // directly on the scrolling background, which composites to
                // roughly [AppTheme.panel] once the screen's veils are added —
                // measuring it against `deepForest` (the default) reported a
                // darker backdrop than the player actually sees and let the
                // tint through unchanged at 4.26:1.
                final chip = AppTheme.tintedChip(
                  tint,
                  alpha: 0.14,
                  on: AppTheme.panel,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tint.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LifeEmoji(flag.chipEmoji, size: 11),
                      const SizedBox(width: 5),
                      Text(
                        flag.chipLabel!,
                        style: GoogleFonts.quicksand(
                          color: chip.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// The three character stats, as meters rather than as numbers in pills.
///
/// Net worth and investments used to sit in this row too. They moved into
/// [LifeMoneyPanel], which shows the same figures broken out by *where the
/// money is* — repeating them here would have made money look like one more
/// stat out of five instead of the subject of the game.
class _MiniStatsRow extends StatelessWidget {
  const _MiniStatsRow({
    required this.smarts,
    required this.health,
    required this.looks,
  });

  final int smarts;
  final int health;
  final int looks;

  @override
  Widget build(BuildContext context) {
    const stats = <(String, String, Color)>[
      ('\u{1F9E0}', 'Smarts', Color(0xFF69C6FF)),
      ('\u{2764}', 'Health', Color(0xFFFF8A80)),
      ('\u{1F31F}', 'Looks', Color(0xFFFF8FB1)),
    ];
    final values = <int>[smarts, health, looks];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across whenever they fit, stacked full-width below that —
        // measured rather than guessed from a phone breakpoint, for the
        // same reason [LifeMoneyPanel] measures its own tiles.
        final width = constraints.maxWidth >= 300
            ? (constraints.maxWidth - 2 * 8) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < stats.length; i++)
              SizedBox(
                width: width,
                child: _StatMeter(
                  emoji: stats[i].$1,
                  label: stats[i].$2,
                  color: stats[i].$3,
                  value: values[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One stat as an emoji, a name, a number, and a filled bar.
///
/// The bar is what makes it a stat rather than a fact. "46" means nothing
/// on its own; a bar not quite half full is legible to a four-year-old,
/// which is the youngest end of this app's audience.
class _StatMeter extends StatelessWidget {
  const _StatMeter({
    required this.emoji,
    required this.label,
    required this.color,
    required this.value,
  });

  final String emoji;
  final String label;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    // Opaque, so the figure below can be measured against a known colour
    // instead of against "whatever the feed put behind this meter".
    final chip = AppTheme.tintedChip(color, alpha: 0.12, target: 3.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LifeEmoji(emoji, size: 12),
              const SizedBox(width: 5),
              Flexible(
                child: FittedLabel(
                  label,
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$value',
                style: GoogleFonts.pixelifySans(
                  color: chip.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              // The controller clamps stats to 0..100, so this cannot
              // exceed 1 today — clamping again means a future stat with a
              // different ceiling degrades to a full bar instead of
              // asserting.
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeHeader extends StatelessWidget {
  const _AgeHeader({required this.age});

  final int age;

  /// The life stage as a face, so scrolling back through a long run reads
  /// as chapters rather than as one continuous list of numbers.
  static String emojiForAge(int age) => switch (LifeStageInfo.forAge(age)) {
    LifeStage.baby => '\u{1F476}',
    LifeStage.child => '\u{1F9D2}',
    LifeStage.teen => '\u{1F9D1}',
    LifeStage.youngAdult => '\u{1F393}',
    LifeStage.adult => '\u{1F9D1}\u{200D}\u{1F4BC}',
    LifeStage.senior => '\u{1F9D3}',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          LifeEmoji(emojiForAge(age), size: 15),
          const SizedBox(width: 7),
          Text(
            'Age $age',
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFF85EFAC),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 10),
          // A rule across the rest of the row, so each year is visibly a
          // section break instead of just another slightly greener line.
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF85EFAC).withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            LifeStageInfo.forAge(age).label,
            style: GoogleFonts.quicksand(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the life story, with a coloured emoji marker for what kind
/// of thing it was.
///
/// The feed used to be an undifferentiated column of sentences — a doctor's
/// visit, a pay rise and a surprise bill all looked identical, so scanning
/// back through a life told you nothing without reading every word. The
/// marker is tagged at the point the line is written (see [LifeLogKind]),
/// so it is always right rather than keyword-guessed.
class _FeedLine extends StatelessWidget {
  const _FeedLine({required this.text, this.kind});

  final String text;
  final LifeLogKind? kind;

  @override
  Widget build(BuildContext context) {
    final marker = kind;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (marker?.accent ?? Colors.white).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(7),
            ),
            child: marker == null
                // No tag rather than a wrong one. A plain dot reads as
                // "just something that happened", which is accurate.
                ? Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  )
                : LifeEmoji(marker.emoji, size: 12),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The decision of the year — the single most-looked-at surface in the game.
///
/// Two things were added here beyond styling. A **chain badge**, so a beat
/// that follows from an earlier choice says so ("Because of the dog") —
/// without it the continuity the chain system creates is invisible and the
/// vet bill reads as a random misfortune rather than as a consequence. And a
/// **money tag on any option whose price is already in its own label**, so
/// comparing two priced options is a glance rather than a read. Options
/// whose cost is *not* stated in the label stay untagged: the surprise is
/// often the lesson, and putting a number on it would give the answer away.
class _EventCard extends StatelessWidget {
  const _EventCard({super.key, required this.event, required this.onChoose});

  final LifeEvent event;
  final ValueChanged<int> onChoose;

  /// A short "this follows from…" line for a chain beat.
  static String? _becauseOf(LifeFlag? flag) => switch (flag) {
    null => null,
    LifeFlag.hasPet => 'Because of the dog',
    LifeFlag.hasCar => 'Because of the car',
    LifeFlag.hasCreditCard || LifeFlag.cardDebtSpiral => 'Because of the card',
    LifeFlag.hasStudentLoan => 'Because of the loan',
    LifeFlag.investsIndex ||
    LifeFlag.heldThroughCrash ||
    LifeFlag.soldInCrash => 'Because of the fund',
    LifeFlag.hasSideHustle || LifeFlag.hustleGrew => 'Because of the business',
    LifeFlag.rentsWithFriend => 'Because of the flatshare',
    _ => 'Following on',
  };

  /// Whether this option's own label already names its price.
  ///
  /// Matching on the label rather than on `choice.money != 0` is deliberate:
  /// showing a tag on every option that moves money would turn every event
  /// into a priced menu and remove the consequence from most of the game.
  static bool _priceIsAlreadyStated(LifeChoice choice) {
    final label = choice.label.toLowerCase();
    return RegExp(r'\d').hasMatch(label) &&
        (label.contains('coin') ||
            label.contains('pay') ||
            label.contains('buy') ||
            label.contains('put'));
  }

  /// The card's colour, taken from the money idea the event teaches.
  ///
  /// Every event used to be the same blue, so the most-seen surface in the
  /// game — you meet one of these every year of every life — looked
  /// identical whether you were being offered a credit card or a puppy.
  /// Tinting by concept means a run has visual variety *and* the colour
  /// carries meaning: debt events are consistently pink, growth events
  /// consistently blue, and the palette matches the concept chips the money
  /// panel already shows.
  Color get _accent {
    for (final choice in event.choices) {
      final concept = choice.teaches;
      if (concept != null) return concept.accent;
    }
    return const Color(0xFF58C7FF);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF10241E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A picture band rather than a 20px glyph on a heading row. The
          // icon is the only art an event has, so it gets to be the size of
          // art instead of the size of punctuation.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.30),
                  accent.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1D17).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(event.icon, color: accent, size: 28),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedLabel(
                        'What do you do?',
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_becauseOf(event.requiresFlag) case final because?)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const LifeEmoji('\u{1F517}', size: 10),
                              const SizedBox(width: 5),
                              Flexible(
                                child: FittedLabel(
                                  because,
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < event.choices.length; i++) ...[
                  _ChoiceRow(
                    index: i,
                    choice: event.choices[i],
                    accent: accent,
                    showPrice: _priceIsAlreadyStated(event.choices[i]),
                    onTap: () => onChoose(i),
                  ),
                  if (i != event.choices.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One option, as a tappable card rather than a row of button text.
///
/// **What is deliberately *not* here.** No stat deltas, no "this costs you 8
/// happiness" preview. The sim hides outcomes on purpose — you are supposed
/// to decide on judgement and then live with it, which is the entire
/// pedagogy — so the only figure ever shown is a price the option's own
/// wording already stated out loud. Making the trade-offs visible would turn
/// every event into a priced menu and delete the lesson.
///
/// The lettered badge is what replaced that: it gives each option a distinct
/// anchor and a sense of a list you are choosing *between*, without leaking
/// anything about which one is better.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.index,
    required this.choice,
    required this.accent,
    required this.showPrice,
    required this.onTap,
  });

  final int index;
  final LifeChoice choice;
  final Color accent;
  final bool showPrice;
  final VoidCallback onTap;

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _letters[index % _letters.length],
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  choice.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              if (showPrice && choice.money != 0) ...[
                const SizedBox(width: 10),
                Text(
                  '${choice.money > 0 ? '+' : ''}${choice.money}',
                  style: GoogleFonts.pixelifySans(
                    color: choice.money < 0
                        ? const Color(0xFFFF8FB1)
                        : const Color(0xFF85EFAC),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  const _BottomMenu({
    super.key,
    required this.ageKey,
    required this.happiness,
    required this.blocked,
    required this.stage,
    required this.onCareer,
    required this.onRelationships,
    required this.onActivities,
    required this.onAssets,
    required this.onAge,
  });

  /// Anchor for the in-game tour's "press this to age up" step. Passed down
  /// rather than registered here, because the button is what the step is
  /// about and the bar around it is a different step.
  final GlobalKey ageKey;

  final int happiness;
  final bool blocked;

  /// Kept for stage-specific labelling — a child's left slot reads "School"
  /// rather than "Career", though both open the same menu.
  final LifeStage stage;

  /// Each of these opens a *menu*, not a single action. That's the whole
  /// change: five bottom-bar slots could only ever hold five things, so the
  /// sim was mostly "press Age and react". Four categories holding four to
  /// six actions each is what makes a turn a decision.
  final VoidCallback onCareer;
  final VoidCallback onRelationships;
  final VoidCallback onActivities;
  final VoidCallback onAssets;
  final VoidCallback onAge;

  static String _moodEmoji(int happiness) => switch (happiness) {
    >= 80 => '\u{1F604}',
    >= 60 => '\u{1F642}',
    >= 40 => '\u{1F610}',
    >= 20 => '\u{1F641}',
    _ => '\u{1F62B}',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1D17),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  // A face that actually changes. The static "very
                  // satisfied" icon sat next to a 12% bar and said the
                  // opposite of the number beside it.
                  LifeEmoji(_moodEmoji(happiness), size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: happiness.clamp(0, 100) / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD45C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Happiness $happiness%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _MenuButton(
                      label:
                          stage == LifeStage.baby ||
                              stage == LifeStage.child ||
                              stage == LifeStage.teen
                          ? 'School'
                          : 'Career',
                      icon: Icons.work_rounded,
                      color: const Color(0xFF58C7FF),
                      onTap: blocked ? null : onCareer,
                    ),
                  ),
                  Expanded(
                    child: _MenuButton(
                      label: 'People',
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFFF8FB1),
                      onTap: blocked ? null : onRelationships,
                    ),
                  ),
                  Expanded(
                    child: _AgeButton(
                      key: ageKey,
                      onTap: blocked ? null : onAge,
                    ),
                  ),
                  Expanded(
                    child: _MenuButton(
                      label: 'Do',
                      icon: Icons.self_improvement_rounded,
                      color: const Color(0xFFB388FF),
                      onTap: blocked ? null : onActivities,
                    ),
                  ),
                  Expanded(
                    child: _MenuButton(
                      label: 'Money',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF85EFAC),
                      onTap: blocked ? null : onAssets,
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

class _AgeButton extends StatelessWidget {
  const _AgeButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? const Color(0xFF43D07E)
                  : Colors.white.withValues(alpha: 0.1),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF43D07E).withValues(alpha: 0.4),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_rounded,
              color: enabled ? const Color(0xFF06251A) : Colors.white38,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Age',
          style: GoogleFonts.pixelifySans(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // Expanded, so the four menu slots share whatever is left beside the
    // fixed Age button instead of each demanding their intrinsic width.
    // Five rigid children with `spaceEvenly` overflowed the bar by 3.4px at
    // 320 wide — `spaceEvenly` distributes *leftover* space and does
    // nothing at all when there is none.
    //
    // horizontal: 4, and it is worth saying why, because it read 192 for a
    // while and that is what broke the bar. inside an Expanded, 192 a side
    // wants 384px for a slot that gets about 178 — so the child was handed
    // zero width. the FittedLabel scaled to nothing and vanished, the Icon
    // painted outside its box (a Column only reports overflow on its *main*
    // axis, which is vertical, so nothing errored), and Money got pushed off
    // the end. icons with no labels and a missing fifth button, no warning.
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? color : Colors.white24, size: 24),
              const SizedBox(height: 4),
              FittedLabel(
                label,
                alignment: Alignment.center,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white30,
                  fontSize: 10,
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

/// Where skills actually get practised.
///
/// The skill/career ladder (music → gigs → record deal → tour, and the
/// sports/business equivalents) was already gating events on skill levels,
/// but nothing in the UI could raise a skill — so those events were
/// unreachable. This is that missing input.
class _SkillsSheet extends StatefulWidget {
  const _SkillsSheet({required this.life});

  final LifeSimController life;

  @override
  State<_SkillsSheet> createState() => _SkillsSheetState();
}

class _SkillsSheetState extends State<_SkillsSheet> {
  @override
  Widget build(BuildContext context) {
    final life = widget.life;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1D17),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Skills',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                life.isDependent
                    ? 'Practise now and career doors open later.'
                    : 'Each session costs 20 coins and a little happiness.',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.66),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              for (final skill in LifeSkill.values) ...[
                _SkillRow(
                  skill: skill,
                  level: life.skillLevel(skill),
                  onPractise: life.finished
                      ? null
                      : () {
                          life.practise(skill);
                          setState(() {});
                        },
                ),
                const SizedBox(height: 10),
              ],
              if (life.traits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'TRAITS',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final trait in life.traits)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFB388FF,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFFB388FF,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trait.icon,
                              size: 13,
                              color: const Color(0xFFB388FF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trait.label,
                              style: const TextStyle(
                                color: Color(0xFFB388FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.level,
    required this.onPractise,
  });

  final LifeSkill skill;
  final int level;
  final VoidCallback? onPractise;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB388FF);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(skill.icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.label,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: level / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$level',
            style: GoogleFonts.pixelifySans(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onPractise,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: const Color(0xFF1A0B33),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Practise',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four BitLife-style menu categories.
enum _LifeMenu {
  career('Career', Icons.work_rounded, Color(0xFF58C7FF)),
  relationships('People', Icons.favorite_rounded, Color(0xFFFF8FB1)),
  activities('Activities', Icons.self_improvement_rounded, Color(0xFFB388FF)),
  assets('Money', Icons.trending_up_rounded, Color(0xFF85EFAC));

  const _LifeMenu(this.label, this.icon, this.accent);
  final String label;
  final IconData icon;
  final Color accent;
}

/// One row inside a menu: what it does, what it costs, and whether it can
/// be tapped right now.
class _LifeAction {
  const _LifeAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.onTap,
    required this.performs,
    this.cost,
    this.disabledReason,
  });

  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  /// The controller action this row runs, or null for a row that is not a
  /// gated action at all — "Net worth", "Quit your job", the ideas list.
  ///
  /// **Required, and nullable on purpose.** This started as an optional
  /// field and the optionality was the bug: the Money menu's "Invest 100
  /// coins" row set `disabledReason` from whether you held 100 coins and
  /// never asked about age, so a two-year-old got a live-looking button that
  /// silently did nothing when pressed. Making it `required` means a new row
  /// cannot be written without answering the question, and `null` is an
  /// answer somebody had to type rather than a default they inherited.
  ///
  /// The gate itself is applied in one place — see [gatedBy] and its single
  /// call site — so no row has to remember to apply it.
  final LifeAction? performs;

  /// Coin cost shown as a chip. Null for free actions — and several of the
  /// best actions here are free on purpose.
  final int? cost;

  /// When set, the row is greyed out and explains *why* rather than just
  /// being dead. Local reasons only ("Not enough coins", "You need a job
  /// first"); the age gate is layered on top by [gatedBy].
  final String? disabledReason;

  bool get enabled => disabledReason == null;

  /// This row with [life]'s age rules applied over whatever local reason it
  /// already had.
  ///
  /// The age gate wins when both apply: telling a nine-year-old they are
  /// short of coins, when the real answer is that nine-year-olds cannot do
  /// this at all, sends them off to earn money for something that still will
  /// not work.
  _LifeAction gatedBy(LifeSimController life) {
    final gate = performs == null ? null : life.gateFor(performs!);
    if (gate == null) return this;
    return _LifeAction(
      label: label,
      detail: detail,
      icon: icon,
      onTap: onTap,
      performs: performs,
      cost: cost,
      disabledReason: gate,
    );
  }
}

/// A category menu. Closes itself after any action so the player sees the
/// result land in the life feed behind it.
class _LifeMenuSheet extends StatelessWidget {
  const _LifeMenuSheet({
    required this.menu,
    required this.life,
    required this.onSkills,
    required this.onInvest,
    required this.onBudget,
    required this.onConcepts,
    required this.onPowers,
  });

  final _LifeMenu menu;
  final LifeSimController life;
  final VoidCallback onSkills;
  final VoidCallback onInvest;
  final VoidCallback onBudget;
  final VoidCallback onConcepts;
  final VoidCallback onPowers;

  List<_LifeAction> _actions(BuildContext context) {
    void run(void Function() action) {
      action();
      Navigator.of(context).pop();
    }

    final young = life.isDependent;

    return [for (final row in _rows(context, run, young)) row.gatedBy(life)];
  }

  /// The rows themselves, before the age gate.
  ///
  /// Split out so [_actions] can apply `gatedBy` to *every* row in one
  /// expression. Age rules come from the controller and never from here — the
  /// menu is a view, and duplicating the rules in it meant they went
  /// unenforced everywhere else and drifted, which is how a three-year-old
  /// ended up able to hit the books, work out at the gym, walk to the library
  /// alone and buy index funds.
  ///
  /// So a row here only ever states its *local* reason — not enough coins, no
  /// job to quit — and names what it performs. Nothing in this method calls
  /// `gateFor`, and nothing in it needs to.
  List<_LifeAction> _rows(
    BuildContext context,
    void Function(void Function()) run,
    bool young,
  ) {
    switch (menu) {
      case _LifeMenu.career:
        return [
          // First in the list on purpose. Without a job there is no salary,
          // and without a salary the budget, the emergency fund and the
          // paycheck line — the whole point of the game — never switch on.
          _LifeAction(
            label: 'Look for work',
            detail: life.hasJob
                ? 'You already have a job. Quit first to change track.'
                : 'Apply for an entry-level job. Smarts widens what is open '
                      'to you.',
            icon: Icons.badge_rounded,
            onTap: () => run(life.findJob),
            performs: LifeAction.findJob,
            // Only the "you already have one" half. The age half arrives
            // from `gatedBy`, which is also where its wording lives.
            disabledReason: life.hasJob ? 'You already have a job' : null,
          ),
          _LifeAction(
            label: young ? 'Hit the books' : 'Take a course',
            detail: young
                ? 'Study after school. +6 Smarts.'
                : 'Pay to learn something new. +6 Smarts.',
            icon: Icons.menu_book_rounded,
            cost: young ? null : 30,
            onTap: () => run(life.study),
            performs: LifeAction.study,
          ),
          _LifeAction(
            label: 'Work harder',
            detail: 'Extra hours for a shot at a raise. Costs happiness.',
            icon: Icons.trending_up_rounded,
            onTap: () => run(life.workHarder),
            performs: null,
            disabledReason: life.hasJob ? null : 'You need a job first',
          ),
          _LifeAction(
            label: 'Ask for a raise',
            detail: 'Asking is free. Being told no is not fun.',
            icon: Icons.record_voice_over_rounded,
            onTap: () => run(life.askForRaise),
            performs: null,
            disabledReason: life.hasJob ? null : 'You need a job first',
          ),
          _LifeAction(
            label: 'Quit your job',
            detail: 'Freedom now, no paycheck next year.',
            icon: Icons.logout_rounded,
            onTap: () => run(life.quitJob),
            performs: null,
            disabledReason: life.hasJob ? null : 'You have no job to quit',
          ),
        ];

      case _LifeMenu.relationships:
        final people = life.relationships;
        if (people.isEmpty) {
          return const [];
        }
        return [
          for (final person in people) ...[
            _LifeAction(
              label: 'Spend time with $person',
              detail: 'Costs nothing. +8 Happiness.',
              icon: Icons.emoji_people_rounded,
              onTap: () => run(() => life.spendTimeWith(person)),
              performs: LifeAction.spendTime,
            ),
            _LifeAction(
              label: 'Buy $person a gift',
              detail: 'Costs coins, and gives less happiness than time does.',
              icon: Icons.card_giftcard_rounded,
              cost: 50,
              onTap: () => run(() => life.giveGift(person)),
              performs: LifeAction.buyGift,
              disabledReason: life.money >= 50 ? null : 'Not enough coins',
            ),
          ],
        ];

      case _LifeMenu.activities:
        return [
          _LifeAction(
            label: 'Go out',
            // Said the wrong number for a long time: `haveFun` gives +6, not
            // +10. The +10 was the value before the town existed, and when
            // the menu version was reduced to make walking there worth it,
            // this label was not.
            detail:
                'An afternoon out. +6 Happiness. The park in town is '
                'better, and free.',
            icon: Icons.celebration_rounded,
            cost: young ? null : 40,
            onTap: () => run(life.haveFun),
            performs: LifeAction.goOut,
            disabledReason: young || life.money >= 40
                ? null
                : 'Not enough coins',
          ),
          _LifeAction(
            label: 'Go to the gym',
            detail: 'Free. +8 Health, +3 Looks.',
            icon: Icons.fitness_center_rounded,
            onTap: () => run(life.exercise),
            performs: LifeAction.exercise,
          ),
          _LifeAction(
            label: 'Visit the library',
            // Same again: `visitLibrary` gives +2. Reading at home is the
            // version you do without leaving the house — worth something,
            // and worth less than the walk.
            detail:
                'Read at home. +2 Smarts. The library in town pays '
                'double.',
            icon: Icons.local_library_rounded,
            onTap: () => run(life.visitLibrary),
            performs: LifeAction.library,
          ),
          _LifeAction(
            label: 'See a doctor',
            // Deliberately *not* reduced the way the library and the park
            // were. Health is load-bearing in the hunger and illness loop --
            // it is the only reliable way back up from a bad run -- and
            // making the reachable-from-anywhere version worse would punish
            // exactly the player who is already in trouble.
            detail: 'A check-up. +12 Health.',
            icon: Icons.medical_services_rounded,
            cost: young ? null : 60,
            onTap: () => run(life.visitDoctor),
            performs: LifeAction.doctor,
            disabledReason: young || life.money >= 60
                ? null
                : 'Not enough coins',
          ),
          _LifeAction(
            label: 'Work a side job',
            detail: 'Earn 40-100 coins. Costs Happiness and Health.',
            icon: Icons.work_history_rounded,
            onTap: () => run(life.workSideJob),
            performs: LifeAction.sideJob,
          ),
          _LifeAction(
            label: 'Volunteer',
            detail: 'No pay at all. +9 Happiness, +2 Smarts.',
            icon: Icons.volunteer_activism_rounded,
            onTap: () => run(life.volunteer),
            performs: LifeAction.volunteer,
          ),
          _LifeAction(
            label: 'Gamble 100 coins',
            detail: 'A 42% chance to double it. The odds are against you.',
            icon: Icons.casino_rounded,
            cost: 100,
            onTap: () => run(life.takeARisk),
            performs: LifeAction.gamble,
            disabledReason: life.money >= 100 ? null : 'Not enough coins',
          ),
          _LifeAction(
            label: 'Practise a skill',
            detail: 'Music, sport, business — the career ladders.',
            icon: Icons.auto_awesome_rounded,
            onTap: onSkills,
            performs: LifeAction.practise,
          ),
        ];

      case _LifeMenu.assets:
        return [
          // Top of the Money menu on purpose: budgeting is the skill this
          // app exists to teach, so it should be the first thing in here,
          // above investing.
          _LifeAction(
            label: life.budgetSet ? 'Adjust your budget' : 'Set your budget',
            detail: life.canBudget
                ? '${life.needsPct}% needs · ${life.wantsPct}% wants · '
                      '${life.savingsPct}% savings. '
                      'Emergency fund: ${life.emergencyFund} '
                      '(${life.emergencyMonths.toStringAsFixed(1)} months).'
                : 'Split your pay across needs, wants and savings.',
            icon: Icons.pie_chart_rounded,
            onTap: () {
              Navigator.of(context).pop();
              onBudget();
            },
            performs: null,
            disabledReason: life.canBudget
                ? null
                : 'You need a paying job first',
          ),
          _LifeAction(
            label: 'Invest 100 coins',
            detail: 'Moves cash into investments. Compounds every year.',
            icon: Icons.savings_rounded,
            cost: 100,
            onTap: onInvest,
            // This is the row the whole `performs` mechanism exists for. It
            // used to state only `life.money >= 100` and never ask about age,
            // so a two-year-old holding 150 coins got a button that looked
            // live and did nothing when pressed — `invest` checks the gate
            // itself and returns silently. A dead control that looks alive is
            // worse than a blocked one that explains itself.
            performs: LifeAction.invest,
            disabledReason: life.money >= 100 ? null : 'You need 100 coins',
          ),
          _LifeAction(
            label: 'Net worth',
            detail:
                'Cash ${life.money} + invested ${life.investments} + fund '
                '${life.emergencyFund}'
                '${life.debt > 0 ? ' − debt ${life.debt}' : ''} = '
                '${life.netWorth}.',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () => Navigator.of(context).pop(),
            performs: null,
          ),
          // Directly above the ideas list, because it is what the ideas
          // list is *for*. Meeting a concept used to end at a chip on a
          // screen; this is the row that turns it into something.
          _LifeAction(
            label: life.activePowers.isEmpty
                ? 'Use a money idea'
                : 'Money ideas at work '
                      '(${life.activePowers.length}/'
                      '${LifeSimController.maxActivePowers})',
            detail: life.armablePowers.isEmpty && life.activePowers.isEmpty
                ? 'Meet an idea first — they show up as your choices raise '
                      'them.'
                : life.activePowers.isEmpty
                ? '${life.armablePowers.length} ready to switch on.'
                : life.activePowers.map((a) => a.power.name).join(', '),
            icon: Icons.bolt_rounded,
            onTap: () {
              Navigator.of(context).pop();
              onPowers();
            },
            performs: null,
            disabledReason:
                life.armablePowers.isEmpty && life.activePowers.isEmpty
                ? 'No ideas met yet'
                : null,
          ),
          _LifeAction(
            label: 'Money ideas you have met',
            detail: life.conceptsMet.isEmpty
                ? 'Play on — ideas show up as your choices raise them.'
                : '${life.conceptsMet.length} so far: '
                      '${life.conceptsMet.take(3).map((c) => c.label).join(', ')}'
                      '${life.conceptsMet.length > 3 ? '…' : ''}',
            icon: Icons.school_rounded,
            onTap: () {
              Navigator.of(context).pop();
              onConcepts();
            },
            performs: null,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    // Stable partition rather than a sort: the order inside each group is
    // deliberate (Look for work is first in Career because without a job
    // none of the money systems switch on), and a comparator would scramble
    // it for no gain.
    final open = <_LifeAction>[
      for (final a in actions)
        if (a.enabled) a,
    ];
    final locked = <_LifeAction>[
      for (final a in actions)
        if (!a.enabled) a,
    ];
    // "When you are older" is only true when age is the *only* thing in the
    // way. The Money menu at five locks "Set your budget" because there is no
    // job yet and "Use a money idea" because none have been met — neither of
    // which growing up fixes on its own, and a heading that says otherwise is
    // telling a child to wait for something that will not arrive.
    final onlyAgeLocks = locked.every(
      (a) => a.performs != null && life.gateFor(a.performs!) != null,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(menu.icon, color: menu.accent, size: 24),
                const SizedBox(width: 10),
                Text(
                  menu.label,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (actions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Nobody yet. People turn up as you live — keep aging up.',
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              for (final action in open) ...[
                _LifeActionRow(action: action, accent: menu.accent),
                const SizedBox(height: 8),
              ],
              // Everything you cannot do yet, under one heading, at the
              // bottom.
              //
              // The menu used to interleave them, so a five-year-old opening
              // Activities met eight rows of which seven were grey — reported
              // as "half of these options are irrelevant", which is the right
              // reading of a screen that puts one live button fourth in a
              // list of locks.
              //
              // They are not removed, because at that age being told what you
              // cannot do *is* the content: it is what makes the early years
              // read as childhood rather than as an adult life with less
              // money. But the things you can actually do now come first, and
              // the rest is a list you scroll to rather than one you wade
              // through.
              if (locked.isNotEmpty) ...[
                if (open.isNotEmpty) const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    onlyAgeLocks ? 'When you are older' : 'Not yet',
                    style: GoogleFonts.pixelifySans(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final action in locked) ...[
                  _LifeActionRow(action: action, accent: menu.accent),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LifeActionRow extends StatelessWidget {
  const _LifeActionRow({required this.action, required this.accent});

  final _LifeAction action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: action.enabled ? 1 : 0.45,
      child: InkWell(
        onTap: action.enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Icon(action.icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            action.label,
                            style: GoogleFonts.pixelifySans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Says out loud that the town has a door for this.
                        //
                        // Reported as the menu and the map being a confusing
                        // mix, and they were: the library, the clinic, the
                        // park and the job board are all *places*, and the
                        // menu carried a button for each with nothing saying
                        // they were the same thing. Two routes to one
                        // outcome is fine — the map is not always open to
                        // you, and making somebody walk across a town to be
                        // treated would be a worse game. Two routes with no
                        // acknowledgement that they meet is what made it
                        // read as duplication.
                        if (action.performs != null &&
                            LifeSimController.hasTownEquivalent(
                              action.performs!,
                            )) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'in town',
                              style: GoogleFonts.quicksand(
                                color: accent,
                                fontSize: 9.5,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.disabledReason ?? action.detail,
                      style: GoogleFonts.quicksand(
                        color: action.enabled
                            ? AppTheme.textMuted
                            : const Color(0xFFFF8474),
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (action.cost != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD45C).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '-${action.cost}',
                    style: GoogleFonts.pixelifySans(
                      color: const Color(0xFFFFD45C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// **The budgeting exercise.** The player splits their take-home pay across
/// needs, wants and savings, and has to make it total exactly 100%.
///
/// This is the piece the app was missing. Everything else in Budget Buddy
/// showed the *results* of money decisions; nothing made the player actually
/// do the allocation that budgeting consists of. Deliberate design choices:
///
/// * **It must add up to 100.** The Save button stays disabled until it
///   does. That constraint *is* the lesson — a budget is a fixed pie, so
///   every increase somewhere is a cut somewhere else, and you feel that
///   trade-off with your thumb.
/// * **There is no single right answer.** 50/30/20 is shown as a reference
///   line, not a win condition, and the feedback names the trade-off rather
///   than grading. Starving "wants" to 0 is punished by the sim (see
///   `LifeSimController._applyBudget`) precisely because an unlivable
///   budget is one you abandon in week two.
/// * **The consequences arrive later**, through the year-end apply and the
///   random expense shock — so the player connects the split they chose to
///   what happened to them, which is what makes it stick.
class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.life});

  final LifeSimController life;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late int _needs = widget.life.needsPct;
  late int _wants = widget.life.wantsPct;
  late int _savings = widget.life.savingsPct;

  int get _total => _needs + _wants + _savings;
  bool get _balanced => _total == 100;

  /// What each slice is worth in coins, so the percentages stay attached to
  /// real money instead of floating as abstract numbers.
  int _coins(int pct) => (widget.life.salary * pct / 100).round();

  /// Names the trade-off the current split makes. Intentionally never says
  /// "correct" — it describes consequences and lets the player decide.
  ({String text, Color colour, IconData icon}) get _feedback {
    if (!_balanced) {
      final diff = 100 - _total;
      return (
        text: diff > 0
            ? 'You have $diff% left to allocate.'
            : 'You are ${-diff}% over — a budget has to add up to 100%.',
        colour: const Color(0xFFFF8FB1),
        icon: Icons.error_outline_rounded,
      );
    }
    if (_savings == 0) {
      return (
        text: 'Nothing saved. Any surprise expense becomes debt.',
        colour: const Color(0xFFFF8FB1),
        icon: Icons.warning_amber_rounded,
      );
    }
    if (_wants <= 5) {
      return (
        text:
            'Almost no room for fun. Strict budgets like this are the ones '
            'people quit.',
        colour: const Color(0xFFFFD45C),
        icon: Icons.sentiment_dissatisfied_rounded,
      );
    }
    if (_savings >= 20 && _needs <= 55) {
      return (
        text:
            'Solid. Saving $_savings% builds a fund that can absorb a bad '
            'month.',
        colour: const Color(0xFF4BD2A3),
        icon: Icons.check_circle_rounded,
      );
    }
    if (_needs > 60) {
      return (
        text:
            'Needs are eating $_needs%. That is the number to attack — '
            'cheaper rent or more income, not smaller treats.',
        colour: const Color(0xFFFFD45C),
        icon: Icons.info_outline_rounded,
      );
    }
    return (
      text:
          'Workable. Saving $_savings% is a start — push it up when your pay '
          'does.',
      colour: const Color(0xFF69C6FF),
      icon: Icons.info_outline_rounded,
    );
  }

  void _save() {
    final ok = widget.life.setBudget(
      needs: _needs,
      wants: _wants,
      savings: _savings,
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fb = _feedback;
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF85EFAC),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your budget',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$_total%',
                  style: GoogleFonts.pixelifySans(
                    color: _balanced
                        ? const Color(0xFF4BD2A3)
                        : const Color(0xFFFF8FB1),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'You take home ${widget.life.salary} coins a year. Decide where '
              'it goes.',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            _BudgetBar(needs: _needs, wants: _wants, savings: _savings),
            const SizedBox(height: 18),
            _BudgetRow(
              label: 'Needs',
              hint: 'Rent, food, transport, bills',
              value: _needs,
              coins: _coins(_needs),
              colour: const Color(0xFF69C6FF),
              guide: 50,
              onChanged: (v) => setState(() => _needs = v),
            ),
            _BudgetRow(
              label: 'Wants',
              hint: 'Eating out, games, going places',
              value: _wants,
              coins: _coins(_wants),
              colour: const Color(0xFFFFD45C),
              guide: 30,
              onChanged: (v) => setState(() => _wants = v),
            ),
            _BudgetRow(
              label: 'Savings',
              hint: 'Emergency fund and your future',
              value: _savings,
              coins: _coins(_savings),
              colour: const Color(0xFF4BD2A3),
              guide: 20,
              onChanged: (v) => setState(() => _savings = v),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fb.colour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: fb.colour.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(fb.icon, color: fb.colour, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fb.text,
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _needs = 50;
                      _wants = 30;
                      _savings = 20;
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Use 50/30/20',
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _balanced ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF43D07E),
                      foregroundColor: const Color(0xFF06251A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save budget',
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single stacked bar of the three slices, so the split is legible before
/// reading a single number.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.needs,
    required this.wants,
    required this.savings,
  });

  final int needs;
  final int wants;
  final int savings;

  @override
  Widget build(BuildContext context) {
    final total = needs + wants + savings;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (needs > 0)
              Expanded(
                flex: needs,
                child: Container(color: const Color(0xFF69C6FF)),
              ),
            if (wants > 0)
              Expanded(
                flex: wants,
                child: Container(color: const Color(0xFFFFD45C)),
              ),
            if (savings > 0)
              Expanded(
                flex: savings,
                child: Container(color: const Color(0xFF4BD2A3)),
              ),
            // Any unallocated remainder shows as a gap, so "you have 15%
            // left" is visible as well as stated.
            if (total < 100)
              Expanded(
                flex: 100 - total,
                child: Container(color: Colors.white.withValues(alpha: 0.10)),
              ),
          ],
        ),
      ),
    );
  }
}

/// One adjustable slice. Stepper buttons rather than a Slider: 5% steps hit
/// round numbers every time, which keeps the arithmetic in the player's head
/// doable — the whole point of the exercise.
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.coins,
    required this.colour,
    required this.guide,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int value;
  final int coins;
  final Color colour;
  final int guide;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 38,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'guide $guide%',
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                FittedLabel(
                  '$hint · $coins coins',
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: value <= 0 ? null : () => onChanged(value - 5),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value%',
              textAlign: TextAlign.center,
              style: GoogleFonts.pixelifySans(
                color: colour,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: value >= 100 ? null : () => onChanged(value + 5),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: enabled ? 0.10 : 0.03),
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.20 : 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: Colors.white.withValues(alpha: enabled ? 0.85 : 0.25),
        ),
      ),
    );
  }
}

/// The teaching moment itself: shown right after a decision lands, naming
/// the idea the player just bumped into.
class _MoneyLessonSheet extends StatelessWidget {
  const _MoneyLessonSheet({required this.concept, required this.simpleWording});

  final FinanceConcept concept;
  final bool simpleWording;

  @override
  Widget build(BuildContext context) {
    // `isDismissible`/`enableDrag: false` on the sheet only block the scrim
    // tap and the swipe gesture — an Android hardware/gesture back would
    // still pop the route underneath both of those. PopScope closes that
    // last gap, so "Got it" really is the only way out.
    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        decoration: const BoxDecoration(
          color: AppTheme.panelStrong,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: concept.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: concept.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(concept.icon, color: concept.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Money idea',
                        style: GoogleFonts.quicksand(
                          color: concept.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        concept.label,
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              concept.explainerFor(simple: simpleWording),
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFFFD45C),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      concept.tryThis,
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: concept.accent,
                  foregroundColor: const Color(0xFF06251A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.pixelifySans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

/// Every money idea this life has surfaced — a running record so the player
/// can see the learning accumulate rather than each lesson vanishing.
class _ConceptsSheet extends StatelessWidget {
  const _ConceptsSheet({required this.concepts, required this.simpleWording});

  final List<FinanceConcept> concepts;
  final bool simpleWording;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                color: Color(0xFF85EFAC),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Money ideas you have met',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${concepts.length}/${FinanceConcept.values.length}',
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFF85EFAC),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (concepts.isEmpty)
            Text(
              'None yet. Keep playing — money ideas show up when your choices '
              'run into them.',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: concepts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final concept = concepts[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: concept.accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(concept.icon, color: concept.accent, size: 19),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                concept.label,
                                style: GoogleFonts.pixelifySans(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                concept.explainerFor(simple: simpleWording),
                                style: GoogleFonts.quicksand(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
  }
}

/// This year at a glance: the weather, the household you were born into,
/// and whether you are allowed out.
///
/// Two jobs. It fills what was a large blank area under the stats on a
/// young character (the feed has one line in it at age 0), and it makes the
/// outing rules *visible* — before this the only evidence of weather or
/// household strictness was a padlock on a button, so the mechanic
/// existed without ever being explained.
///
/// Drawn with [PixelPanel] rather than a `BoxDecoration`, so it uses the
/// hand-made pixel kit the project already ships.
class _ThisYearPanel extends StatelessWidget {
  const _ThisYearPanel({
    required this.weather,
    required this.strictness,
    required this.outing,
  });

  final Weather weather;
  final HouseholdStrictness strictness;
  final OutingPermission outing;

  @override
  Widget build(BuildContext context) {
    // Mint when you may go out, pink when you may not — on a 12% wash of that
    // same colour, over the slate panel. Resolved opaque so the icon can be
    // measured against it.
    final outingChip = AppTheme.tintedChip(
      outing.allowed ? const Color(0xFF4BD2A3) : const Color(0xFFFF8FB1),
      alpha: 0.12,
      on: PixelFrameStyle.slate.surface,
      target: 3.0,
    );

    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelIcon(AppAssets.kitIconStar, size: 14),
              const SizedBox(width: 7),
              Text(
                'This year',
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFFE9C46A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _YearFact(
                  icon: weather.icon,
                  accent: weather.accent,
                  label: 'Weather',
                  value: weather.label,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _YearFact(
                  icon: Icons.family_restroom_rounded,
                  accent: const Color(0xFF85EFAC),
                  label: 'Family',
                  value: strictness.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // The consequence line. Says what you can do and, when you
          // cannot, exactly what would have to change — being told "not
          // until you are 14" is content, not an error.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: outingChip.fill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  outing.allowed
                      ? Icons.directions_walk_rounded
                      : (outing.reason?.icon ?? Icons.lock_rounded),
                  size: 15,
                  color: outingChip.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    outing.allowed
                        ? 'You can head into town whenever you like.'
                        : outing.message,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 11.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
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

/// The relationship chip: pink text and a pink heart on a 14% pink wash.
/// Three shades of one colour, which measured 4.26:1 — see
/// [AppTheme.tintedChip] for why that keeps happening.
final _personChip = AppTheme.tintedChip(const Color(0xFFFF8FB1), alpha: 0.14);

/// What a [_YearFact] tile actually sits on: a 5% white veil over the slate
/// panel. Named because two colours in that tile have to be measured against
/// it and neither can be judged against the page.
final Color _yearFactSurface = AppTheme.flatten(
  Colors.white.withValues(alpha: 0.05),
  PixelFrameStyle.slate.surface,
);

/// Aim above the bar rather than at it.
///
/// [_yearFactSurface] is the tile's *nominal* colour, but the feed stacks
/// another faint veil or two above the panel before this tile is drawn, so
/// the real surface renders a shade lighter than the constant says. Aiming
/// exactly at 4.5 left the weather icon at 4.09 on screen — close enough to
/// look fixed in code and still fail in the app.
const double _yearFactTarget = 5.4;

class _YearFact extends StatelessWidget {
  const _YearFact({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            // The tile is a white veil over the slate panel, so an accent
            // picked to sit on the dark page is not necessarily readable
            // here — the "unsettled weather" orange measured 3.68:1.
            color: AppTheme.legibleOn(
              accent,
              _yearFactSurface,
              target: _yearFactTarget,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                FittedLabel(
                  value,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

/// Arming a money idea.
///
/// The screen half of `concept_powers.dart`. The rule it has to make obvious
/// is the one the whole design rests on: the list of things you can switch on
/// *is* the list of ideas you have understood. Somebody looking at an empty
/// sheet should read it as "go and learn something", not as "this feature is
/// broken".
class _PowersSheet extends StatefulWidget {
  const _PowersSheet({required this.life});

  final LifeSimController life;

  @override
  State<_PowersSheet> createState() => _PowersSheetState();
}

class _PowersSheetState extends State<_PowersSheet> {
  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    final active = life.activePowers;
    final armable = life.armablePowers;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1D17),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFFFD45C),
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: FittedLabel(
                      'Money ideas at work',
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'An idea you understand is worth something. Switch one on and '
                'it changes how the next few years go. '
                '${LifeSimController.maxActivePowers} at a time.',
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              if (active.isNotEmpty) ...[
                _PowersHeading(label: 'Running now'),
                for (final running in active) ...[
                  _PowerCard(
                    power: running.power,
                    yearsLeft: running.yearsLeftAt(life.age),
                    onArm: null,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],

              _PowersHeading(
                label: active.isEmpty ? 'Ready to switch on' : 'Also ready',
              ),
              if (armable.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    active.isEmpty
                        ? 'You have not met any money ideas yet. They turn up '
                              'as your choices raise them — in an event, in '
                              'the town, or in a lesson.'
                        : 'Every idea you have met is already running.',
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                for (final power in armable) ...[
                  _PowerCard(
                    power: power,
                    yearsLeft: null,
                    onArm: life.canArmPower
                        ? () {
                            if (life.armPower(power.concept)) {
                              setState(() {});
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],

              if (armable.isNotEmpty && !life.canArmPower) ...[
                const SizedBox(height: 4),
                Text(
                  'Both slots are full. Wait for one to run out — choosing '
                  'which idea to lean on is the point.',
                  style: GoogleFonts.quicksand(
                    color: AppTheme.warningOrange,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PowersHeading extends StatelessWidget {
  const _PowersHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.pixelifySans(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({
    required this.power,
    required this.yearsLeft,
    required this.onArm,
  });

  final ConceptPower power;

  /// Non-null when this one is already running.
  final int? yearsLeft;

  /// Null when it cannot be armed — either it is running, or both slots are
  /// full.
  final VoidCallback? onArm;

  @override
  Widget build(BuildContext context) {
    final running = yearsLeft != null;
    final accent = power.concept.accent;
    final chip = AppTheme.tintedChip(accent, alpha: running ? 0.2 : 0.12);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: accent.withValues(alpha: running ? 0.55 : 0.28),
          width: running ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LifeEmoji(power.concept.emoji, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: FittedLabel(
                  power.name,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                running ? '$yearsLeft yr left' : '${power.years} yr',
                style: GoogleFonts.pixelifySans(
                  color: chip.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            power.blurb,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Which idea this is. The power is the reward for having met it, so
          // the name of the idea belongs on the card rather than being
          // something you have to remember.
          Text(
            'From ${power.concept.label}',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!running) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onArm,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: const Color(0xFF06251A),
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: Text(
                  onArm == null ? 'Both slots full' : 'Switch it on',
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
