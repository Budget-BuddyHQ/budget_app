import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_education.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../models_Like_Skins_and_lessons_templates/outing_rules.dart';
import '../../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/concept_powers.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_tutorial_steps.dart';
import '../../../models_Like_Skins_and_lessons_templates/ranked_run.dart';
import '../../../models_Like_Skins_and_lessons_templates/volunteer_places.dart';
import '../../../utils/number_format.dart';
import '../../../themes_colors/app_theme.dart';
import '../../onboarding/coach_mark.dart';
import '../../../widgets_custom_lotties/confetti_burst.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../adventure/adventure_world_screen.dart';
import 'life_activities_sheet.dart';
import 'life_advisory.dart';
import 'life_assets_sheet.dart';
import 'life_character_sheet.dart';
import 'life_epilogue_screen.dart';
import 'life_money_flow_sheet.dart';
import 'life_occupation_sheet.dart';
import 'life_people_sheet.dart';
import 'life_ui_kit.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/life_money_panel.dart';
import '../../../widgets_custom_lotties/payday_card.dart';
import '../../../widgets_custom_lotties/pixel_kit.dart';
import '../../../widgets_custom_lotties/pixel_panel.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_seed.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_network.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_wellbeing.dart';

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

  /// Whether a decision card is on screen. It is a pop-up, and a pop-up must
  /// only ever be opened once for one event.
  bool _eventDialogOpen = false;

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

  /// Whether the current run counts toward the coach's reading.
  ///
  /// Chosen once, on the character sheet. Players deliberately wreck a life
  /// for an unusual ending or for quick gold, and the analyzer was reading
  /// those as them getting worse with money.
  bool _graded = true;

  /// The seed this life was rolled from, shown on the epilogue so a player
  /// can replay the same start.
  LifeSeed? _seed;

  Future<void> _createCharacter() async {
    // Life is for nine and up. Nothing inside it is filtered by the account's
    // age any more: this is the one gate, and the advisory below is the one
    // warning. See `life_advisory.dart`.
    final band = context.read<UserStatsController>().stats.ageBand;
    if (!band.canPlayLife) {
      await showLifeAgeGate(context);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final settings = context.read<AppSettingsController>();
    if (!settings.hasSeenLifeAdvisory) {
      final go = await showLifeAdvisory(context);
      if (!mounted) return;
      if (!go) {
        Navigator.of(context).pop();
        return;
      }
      await settings.markLifeAdvisorySeen();
      if (!mounted) return;
    }
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
      // Whether this run counts, chosen on the character sheet.
      _graded = character.graded;
      _seed = character.seed;
      _life = LifeSimController(
        // The seed now decides the whole life, not just who you are.
        //
        // It used to set the name, family and town only, while every event
        // and surprise cost came from an unseeded `Random()` — so two
        // players on the same seed lived different lives, and Ranked's
        // "same start everybody else got" held for the first screen and
        // nothing after it. Seeding the controller makes a seed replayable:
        // the same seed and the same choices give the same life.
        random: Random(character.seed.value),
        name: character.name,
        gender: character.gender,
        origin: character.origin,
        startMoney: character.origin.familyMoney,
        // Born into a family: a mother, a father, perhaps brothers, sisters and
        // grandparents. See `life_people.dart`.
        withFamily: true,
        // No account-age filters. Gambling is off for everyone through
        // `kLifeGamblingEnabled`, and the rest is what the advisory describes.
      );
    });
    _maybeStartFirstTour();
  }

  @override
  void dispose() {
    for (final id in const <String>[
      'life_money',
      'life_costs',
      'life_event',
      'life_town',
      'life_menus',
      'life_menu_work',
      'life_menu_assets',
      'life_menu_people',
      'life_menu_activities',
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
    final bestsBeaten = await controller.recordLifeRun(
      summary,
      graded: _graded,
    );
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
    // ...and filed, which it never used to be. The score was shown on the
    // epilogue and then thrown away with the screen, so Ranked had no memory
    // and nothing to rank. See `recordRankedRun`.
    if (score != null) {
      await controller.recordRankedRun(
        score: score.total,
        grade: score.grade,
        ageReached: life.age,
      );
      if (!mounted) return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LifeEpilogueScreen(
          summary: summary,
          bestsBeaten: bestsBeaten,
          rankedScore: score,
          seed: _seed,
          graded: _graded,
        ),
      ),
    );
  }

  void _registerTourTargets() {
    TutorialTargets.register('life_money', _tourMoneyKey);
    // The "Where does my money go?" row is inside the money panel.
    TutorialTargets.register('life_costs', _tourMoneyKey);
    TutorialTargets.register('life_event', _tourEventKey);
    TutorialTargets.register('life_town', _tourTownKey);
    TutorialTargets.register('life_menus', _tourMenuKey);
    // One step per menu, all pointing at the tab bar they live in.
    TutorialTargets.register('life_menu_work', _tourMenuKey);
    TutorialTargets.register('life_menu_assets', _tourMenuKey);
    TutorialTargets.register('life_menu_people', _tourMenuKey);
    TutorialTargets.register('life_menu_activities', _tourMenuKey);
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
  /// overlay would center every card and explain nothing.
  void _maybeStartFirstTour() {
    if (!mounted || _tourRunning) return;
    final settings = context.read<AppSettingsController>();
    if (!settings.isLifeTourDue) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
  }

  void _openOccupation(LifeSimController life) {
    HapticFeedback.lightImpact();
    openOccupation(
      context,
      life,
      onPerson: (person) => openPerson(context, life, person),
    );
  }

  void _openAssets(LifeSimController life) {
    HapticFeedback.lightImpact();
    openAssets(
      context,
      life,
      onBudget: () => _openBudget(life),
      onPowers: () => _openPowers(life),
      onConcepts: () => _openConcepts(life),
    );
  }

  void _openPeople(LifeSimController life) {
    HapticFeedback.lightImpact();
    openPeople(context, life);
  }

  void _openActivities(LifeSimController life) {
    HapticFeedback.lightImpact();
    openActivities(
      context,
      life,
      onVolunteer: () => _openVolunteer(life),
      onSkills: () => _openSkills(life),
    );
  }

  /// Puts the year's decision in front of the player as a pop-up.
  ///
  /// **Asked for as:** the BitLife pop-up decision card, *"whenever an event
  /// occurs, a pop-up modal interrupts the main screen with two to four choices
  /// and a Surprise Me button."* It used to sit in the feed, where it could be
  /// scrolled past and where the feed kept moving behind it. It is now the one
  /// thing on the screen until it is answered.
  Future<void> _maybeShowEventDialog(LifeSimController life) async {
    if (!mounted || _eventDialogOpen) return;
    final event = life.currentEvent;
    if (event == null) return;
    _eventDialogOpen = true;
    final choice = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventDialog(key: _tourEventKey, event: event),
    );
    _eventDialogOpen = false;
    if (!mounted || choice == null) return;
    // The world may have moved on while the pop-up was open.
    if (life.currentEvent != event) return;
    HapticFeedback.selectionClick();
    life.chooseOption(choice);
    // The lesson goes first, and the form it leads to (a college application, the
    // job board) opens after it, so nothing lands on top of anything.
    await _drainLesson(life);
    if (!mounted) return;
    await _runFollowUp(life);
  }

  /// Opens the screen a decision asked for. See `LifeFollowUp`.
  Future<void> _runFollowUp(LifeSimController life) async {
    switch (life.takeFollowUp()) {
      case LifeFollowUp.openCollege:
        await showLifeSheet<void>(
          context,
          builder: (_) => ProgramSheet(life: life, stage: SchoolStage.college),
        );
      case LifeFollowUp.openTrades:
        await showLifeSheet<void>(
          context,
          builder: (_) => ProgramSheet(life: life, stage: SchoolStage.trade),
        );
      case LifeFollowUp.openJobs:
        await showLifeSheet<void>(
          context,
          builder: (_) => JobBoardSheet(life: life),
        );
      case LifeFollowUp.openHousing:
        await showLifeSheet<void>(
          context,
          builder: (_) => HousingSheet(life: life),
        );
      case LifeFollowUp.none:
        break;
    }
  }

  /// A check-up from the Payday card, with the result said out loud: the
  /// card is about cause and effect, so the effect should not be silent.
  void _seeDoctor(LifeSimController life) {
    HapticFeedback.lightImpact();
    final blocked = doctorUnavailable(life);
    if (blocked != null) {
      GameToast.show(
        context,
        title: 'Not right now',
        message: blocked,
        icon: Icons.medical_services_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }
    final before = life.health;
    life.visitDoctor();
    final gained = life.health - before;
    GameToast.show(
      context,
      title: gained > 0 ? 'Feeling better' : 'No check-up',
      message: gained > 0
          ? '+$gained Health. Keep it up and you will stop missing work.'
          : 'A check-up costs 60 coins, and there was not enough.',
      icon: Icons.medical_services_rounded,
      accent: gained > 0 ? AppTheme.greenPrimary : const Color(0xFFFFB084),
    );
  }

  Future<void> _openBudget(LifeSimController life) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Without this a tall sheet runs under the status bar and its
      // heading is unreadable.
      useSafeArea: true,
      // A visible grab bar, so the way out is on screen.
      showDragHandle: true,
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
      // Without this a tall sheet runs under the status bar and its
      // heading is unreadable.
      useSafeArea: true,
      // A visible grab bar, so the way out is on screen.
      showDragHandle: true,
      builder: (_) => _PowersSheet(life: life),
    );
  }

  Future<void> _openConcepts(LifeSimController life) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Without this a tall sheet runs under the status bar and its
      // heading is unreadable.
      useSafeArea: true,
      // A visible grab bar, so the way out is on screen.
      showDragHandle: true,
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
  Future<void> _drainLesson(LifeSimController life) async {
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Without this a tall sheet runs under the status bar and its
      // heading is unreadable.
      useSafeArea: true,
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

  /// Skill practice. Until this existed, `LifeSimController.practice` had no
  /// UI at all — the whole skill/career ladder was unreachable by the player
  /// even though the events gating on it were already in the pool.
  /// One person, and what you can do about them.
  ///
  /// A screen of its own rather than two rows in a list, because the thing
  /// worth showing is the *relationship* — how close you are, how long since
  /// you saw them, and which way it is heading. None of that fits on a menu
  /// row, and without it the two actions are just two buttons.
  /// Where to give your time.
  ///
  /// A sheet rather than a menu row, because there is a real decision in it
  /// now — six hours at the food bank against two on a litter pick is a
  /// trade, and a trade needs its options side by side to be one.
  Future<void> _openVolunteer(LifeSimController life) async {
    HapticFeedback.lightImpact();
    final place = await showModalBottomSheet<VolunteerPlace>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Without this a tall sheet runs under the status bar and its
      // heading is unreadable.
      useSafeArea: true,
      // A visible grab bar, so the way out is on screen.
      showDragHandle: true,
      builder: (_) => _VolunteerSheet(age: life.age),
    );
    if (place == null || !mounted) return;
    life.volunteer(place);
  }

  Future<void> _openSkills(LifeSimController life) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Without this a tall sheet runs under the status bar and its
      // heading is unreadable.
      useSafeArea: true,
      // A visible grab bar, so the way out is on screen.
      showDragHandle: true,
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
        if (event != null && !_eventDialogOpen) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _maybeShowEventDialog(life),
          );
        }
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
                money: life.netWorth,
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
                    relationships: life.relationships,
                    dead: life.dead,
                    weather: life.weather,
                    strictness: life.strictness,
                    outing: life.outingPermission,
                    life: life,
                    onOpenBudget: () => _openBudget(life),
                    onOpenMoney: () => _openAssets(life),
                    onOpenConcepts: () => _openConcepts(life),
                    onOpenPeople: () => _openPeople(life),
                    onFindJob: () => _openOccupation(life),
                    onSeeDoctor: () => _seeDoctor(life),
                    moneyKey: _tourMoneyKey,
                  ),
                ),
                _BottomMenu(
                  key: _tourMenuKey,
                  ageKey: _tourAgeKey,
                  happiness: life.happiness,
                  health: life.health,
                  smarts: life.smarts,
                  looks: life.looks,
                  blocked: event != null || life.finished,
                  stage: life.stage,
                  student: life.isStudent && !life.hasJob,
                  onOccupation: () => _openOccupation(life),
                  onRelationships: () => _openPeople(life),
                  onActivities: () => _openActivities(life),
                  onAssets: () => _openAssets(life),
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
                color: const Color(0xFF9BE870),
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

  /// The header's second line, as one or two lines of text.
  ///
  /// A person with a real job gets their age and then the job on its own line.
  /// Anybody without one gets the single "Age 8 · Child" it always had.
  static List<String> _subtitleLines({
    required int age,
    required LifeStage stage,
    required String job,
  }) {
    final trimmed = job.trim();
    const placeholders = <String>{
      'newborn',
      'baby',
      'child',
      'student',
      'unemployed',
      'none',
      '',
    };
    if (placeholders.contains(trimmed.toLowerCase())) {
      return <String>['Age $age · ${stage.label}'];
    }
    return <String>['Age $age', trimmed];
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
            backgroundColor: const Color(0xFF243440),
            child: Icon(gender.icon, color: const Color(0xFF9BE870), size: 20),
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
              // The age, and under it the job on a line of its own. The title
              // column is what the app bar has left after the avatar, the balance
              // and the Town and Retire buttons, and job titles are now ladders
              // ("Management Trainee"). Run together on one line they were cut to
              // "Mana…"; on two, each line is short enough to show whole, and the
              // job scales down a little before it is ever shortened.
              ..._subtitleLines(age: age, stage: stage, job: job).map(
                (line) => FittedLabel(
                  line,
                  minScale: 0.7,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.66),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Constrained rather than free: a six-figure balance late in a
            // long life is wide enough in the pixel font to push this row
            // past the screen on a 320px phone, and the balance is the one
            // thing in the header that must stay readable.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 84),
              // The balance is the number this header exists to show, so
              // it gets the face that measures legible rather than the one
              // that looks best on a poster — see `AppTheme.numeric`. The
              // display art it used to use has 13 of 45 confusable digit
              // pairs. `FittedBox` keeps a six-figure fortune inside the
              // same 96px the pixel font was clamped to.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  groupedNumber(money),
                  style: AppTheme.numeric(
                    color: const Color(0xFFFFD45C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
            // Net worth, not cash. Cash is one of five things this number adds
            // up, and it can sit at zero while the number beside it grows. It
            // read as coins that fell to nothing and could not be got back.
            const Text(
              'net worth',
              style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
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
    required this.relationships,
    required this.dead,
    required this.weather,
    required this.strictness,
    required this.outing,
    required this.life,
    required this.onOpenBudget,
    required this.onOpenMoney,
    required this.onOpenConcepts,
    required this.onOpenPeople,
    required this.onFindJob,
    required this.onSeeDoctor,
    required this.moneyKey,
  });

  /// For the Payday card: opens Occupation when there is no job.
  final VoidCallback onFindJob;

  /// For the Payday card: a check-up when missed work came from poor health.
  final VoidCallback onSeeDoctor;

  /// Anchor for the in-game tour. The feed owns the money panel, so it is the
  /// only place that can hand a key to it.
  final GlobalKey moneyKey;

  final ScrollController controller;
  final List<LifeLogEntry> history;
  final List<String> relationships;
  final bool dead;

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

  /// Opens the People tab's sheet. The feed shows who is in your life as one
  /// line rather than as a chip for each of them.
  final VoidCallback onOpenPeople;

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
          onOpenWhereItGoes: () => openMoneyFlow(context, life),
        ),
        // This year's pay, where it went, and any work missed. See
        // [PaydayCard] for why it is a card and not a feed line.
        PaydayCard(
          life: life,
          onOpenBudget: onOpenBudget,
          onFindJob: onFindJob,
          onSeeDoctor: onSeeDoctor,
        ),
        const SizedBox(height: 12),
        // Above the cost, not after it: running yourself down costs shifts,
        // and the player should be able to see that coming while there is
        // still a year left to act in. See `life_wellbeing.dart`.
        _StrainBanner(life: life),
        _YourLifeStrip(flags: life.flags),
        if (relationships.isNotEmpty) ...[
          const SizedBox(height: 10),
          // One line, not a chip per person. A family, a partner, children and
          // friends is a dozen names, and a dozen chips filled the top of the
          // feed and pushed the story of the year below the fold. They are all
          // one tap away, with how close each is, in the People sheet.
          _PeopleStrip(names: relationships, onTap: onOpenPeople),
        ],
        if (life.networkReading.contacts > 0) ...[
          const SizedBox(height: 10),
          _NetworkChip(reading: life.networkReading),
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

/// Who is in your life, as one line that opens the People sheet.
class _PeopleStrip extends StatelessWidget {
  const _PeopleStrip({required this.names, required this.onTap});

  final List<String> names;
  final VoidCallback onTap;

  /// "Aisha and Marcus", "Aisha, Marcus and 7 more". First names only: the
  /// surname is the player's own, and a line of three full names does not fit.
  String get _summary {
    final firsts = [for (final n in names) n.split(' ').first];
    if (firsts.length == 1) return firsts.first;
    if (firsts.length == 2) return '${firsts[0]} and ${firsts[1]}';
    return '${firsts[0]}, ${firsts[1]} and ${firsts.length - 2} more';
  }

  @override
  Widget build(BuildContext context) {
    final count = names.length;
    return Semantics(
      button: true,
      label:
          '$count ${count == 1 ? 'person' : 'people'} in your life. '
          'Opens the people sheet.',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: _personChip.fill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            key: const ValueKey('feed-people-strip'),
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: _personChip.ink,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedLabel(
                      _summary,
                      style: TextStyle(
                        color: _personChip.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: AppTheme.numeric(
                      color: _personChip.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _personChip.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                // legible rather than being swapped for a color that does not
                // mean anything.
                final tint = flag.isTrouble
                    ? const Color(0xFFFF8FB1)
                    : const Color(0xFF9BE870);
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

/// The warning that neglect is about to cost shifts.
///
/// **Why it is on the main screen.** A penalty the player never saw coming is
/// a punishment. This is the other half of `life_wellbeing.dart`: it climbs
/// through "running a little low" and "you will miss about N weeks" before
/// anything is taken, and every line ends with what to do about it. Nothing is
/// shown for a child, an unemployed adult, or somebody who is fine.
class _StrainBanner extends StatelessWidget {
  const _StrainBanner({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    final notice = life.strainNotice;
    if (notice == null) return const SizedBox.shrink();

    final severe =
        life.jobAtRisk || life.workStrain.level == StrainLevel.severe;
    final accent = severe ? const Color(0xFFFF8474) : const Color(0xFFF2C66D);
    final chip = AppTheme.tintedChip(accent, alpha: 0.16);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: chip.fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                severe
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                color: chip.ink,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notice,
                style: GoogleFonts.quicksand(
                  color: chip.ink,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who you know, in one line under the stats.
class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.reading});

  final NetworkReading reading;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(const Color(0xFF58C7FF), alpha: 0.16);
    final count = reading.contacts;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: chip.fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, size: 13, color: chip.ink),
            const SizedBox(width: 6),
            Text(
              'Network: ${reading.label} · $count '
              '${count == 1 ? 'contact' : 'contacts'}',
              style: TextStyle(
                color: chip.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
            style: AppTheme.numeric(
              color: const Color(0xFF9BE870),
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
              color: const Color(0xFF9BE870).withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            LifeStageInfo.forAge(age).label,
            style: GoogleFonts.quicksand(
              color: const Color(0xFF9BE870).withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the life story, with a colored emoji marker for what kind
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
  const _EventCard({required this.event, required this.onChoose});

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

  /// The card's color, taken from the money idea the event teaches.
  ///
  /// Every event used to be the same blue, so the most-seen surface in the
  /// game — you meet one of these every year of every life — looked
  /// identical whether you were being offered a credit card or a puppy.
  /// Tinting by concept means a run has visual variety *and* the color
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
        color: const Color(0xFF151F25),
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
              color: accent.withValues(alpha: 0.18),
              border: Border(
                bottom: BorderSide(
                  color: accent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131F24).withValues(alpha: 0.55),
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
                  // An opaque fill and an ink measured against it. A see-through
                  // tint over the card read at 3.2 to 1 in the contrast audit.
                  color: AppTheme.tintedChip(
                    accent,
                    on: const Color(0xFF151F25),
                  ).fill,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _letters[index % _letters.length],
                  style: GoogleFonts.pixelifySans(
                    color: AppTheme.tintedChip(
                      accent,
                      on: const Color(0xFF151F25),
                    ).ink,
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
                  style: AppTheme.numeric(
                    color: choice.money < 0
                        ? const Color(0xFFFF8FB1)
                        : const Color(0xFF9BE870),
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

/// The bar along the bottom: four stat bars and five tabs.
///
/// **Asked for as:** the BitLife layout, *"Occupation, Assets, Relationships,
/// Activities, and a big Age button in the middle, with four stat bars,
/// Happiness, Health, Smarts and Looks, above them."* Each tab opens a whole
/// screen, not a short menu.
class _BottomMenu extends StatelessWidget {
  const _BottomMenu({
    super.key,
    required this.ageKey,
    required this.happiness,
    required this.health,
    required this.smarts,
    required this.looks,
    required this.blocked,
    required this.stage,
    required this.student,
    required this.onOccupation,
    required this.onRelationships,
    required this.onActivities,
    required this.onAssets,
    required this.onAge,
  });

  /// Anchor for the in-game tour's "press this to age up" step.
  final GlobalKey ageKey;

  final int happiness;
  final int health;
  final int smarts;
  final int looks;
  final bool blocked;

  /// A child's first tab reads "School" and a working adult's reads
  /// "Occupation", though both open the same screen.
  final LifeStage stage;

  /// Whether the character is at school and has no job of their own.
  final bool student;

  final VoidCallback onOccupation;
  final VoidCallback onRelationships;
  final VoidCallback onActivities;
  final VoidCallback onAssets;
  final VoidCallback onAge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131F24),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: LifeStatBars(
                happiness: happiness,
                health: health,
                smarts: smarts,
                looks: looks,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _MenuButton(
                      label: student ? 'School' : 'Occupation',
                      icon: Icons.work_rounded,
                      color: const Color(0xFF58C7FF),
                      onTap: blocked ? null : onOccupation,
                    ),
                  ),
                  Expanded(
                    child: _MenuButton(
                      label: 'Assets',
                      icon: Icons.home_work_rounded,
                      color: const Color(0xFF9BE870),
                      onTap: blocked ? null : onAssets,
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
                      label: 'People',
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFFF8FB1),
                      onTap: blocked ? null : onRelationships,
                    ),
                  ),
                  Expanded(
                    child: _MenuButton(
                      label: 'Activities',
                      icon: Icons.apps_rounded,
                      color: const Color(0xFFB388FF),
                      onTap: blocked ? null : onActivities,
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

/// The year's decision, as a pop-up with a Surprise me button.
class _EventDialog extends StatelessWidget {
  const _EventDialog({super.key, required this.event});

  final LifeEvent event;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EventCard(
                  event: event,
                  onChoose: (i) => Navigator.of(context).pop(i),
                ),
                const SizedBox(height: 10),
                // Picks for you. It is the same as choosing blind, which is a
                // fair way to play and sometimes the honest one.
                TextButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(Random().nextInt(event.choices.length)),
                  icon: const Icon(Icons.casino_rounded, size: 18),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  label: Text(
                    'Surprise me!',
                    style: GoogleFonts.pixelifySans(
                      fontWeight: FontWeight.w700,
                    ),
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

/// Where skills actually get practiced.
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
        color: Color(0xFF131F24),
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
                          life.practice(skill);
                          setState(() {});
                        },
                ),
                const SizedBox(height: 10),
              ],
              if (life.traits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'TRAITS',
                  style: AppTheme.caps(
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
            style: AppTheme.numeric(
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
  ({String text, Color color, IconData icon}) get _feedback {
    if (!_balanced) {
      final diff = 100 - _total;
      return (
        text: diff > 0
            ? 'You have $diff% left to allocate.'
            : 'You are ${-diff}% over — a budget has to add up to 100%.',
        color: const Color(0xFFFF8FB1),
        icon: Icons.error_outline_rounded,
      );
    }
    if (_savings == 0) {
      return (
        text: 'Nothing saved. Any surprise expense becomes debt.',
        color: const Color(0xFFFF8FB1),
        icon: Icons.warning_amber_rounded,
      );
    }
    if (_wants <= 5) {
      return (
        text:
            'Almost no room for fun. Strict budgets like this are the ones '
            'people quit.',
        color: const Color(0xFFFFD45C),
        icon: Icons.sentiment_dissatisfied_rounded,
      );
    }
    if (_savings >= 20 && _needs <= 55) {
      return (
        text:
            'Solid. Saving $_savings% builds a fund that can absorb a bad '
            'month.',
        color: const Color(0xFF6CD34A),
        icon: Icons.check_circle_rounded,
      );
    }
    if (_needs > 60) {
      return (
        text:
            'Needs are eating $_needs%. That is the number to attack — '
            'cheaper rent or more income, not smaller treats.',
        color: const Color(0xFFFFD45C),
        icon: Icons.info_outline_rounded,
      );
    }
    return (
      text:
          'Workable. Saving $_savings% is a start — push it up when your pay '
          'does.',
      color: const Color(0xFF69C6FF),
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
                  color: Color(0xFF9BE870),
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
                  style: AppTheme.numeric(
                    color: _balanced
                        ? const Color(0xFF6CD34A)
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
              color: const Color(0xFF69C6FF),
              guide: 50,
              onChanged: (v) => setState(() => _needs = v),
            ),
            _BudgetRow(
              label: 'Wants',
              hint: 'Eating out, games, going places',
              value: _wants,
              coins: _coins(_wants),
              color: const Color(0xFFFFD45C),
              guide: 30,
              onChanged: (v) => setState(() => _wants = v),
            ),
            _BudgetRow(
              label: 'Savings',
              hint: 'Emergency fund and your future',
              value: _savings,
              coins: _coins(_savings),
              color: const Color(0xFF6CD34A),
              guide: 20,
              onChanged: (v) => setState(() => _savings = v),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fb.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: fb.color.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(fb.icon, color: fb.color, size: 18),
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
                      style: AppTheme.numeric(
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
                child: Container(color: const Color(0xFF6CD34A)),
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
    required this.color,
    required this.guide,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int value;
  final int coins;
  final Color color;
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
              color: color,
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
              style: AppTheme.numeric(
                color: color,
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
                color: Color(0xFF9BE870),
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
                style: AppTheme.numeric(
                  color: const Color(0xFF9BE870),
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
    // same color, over the slate panel. Resolved opaque so the icon can be
    // measured against it.
    final outingChip = AppTheme.tintedChip(
      outing.allowed ? const Color(0xFF6CD34A) : const Color(0xFFFF8FB1),
      alpha: 0.12,
      on: PixelFrameStyle.slate.surface,
      target: 3.0,
    );

    // Asked for as: the Life menu is "hard to navigate... unlike Finance
    // Brawl, which is quite addicting." This panel was the worst offender —
    // a full card of weather, family and a consequence box, shown at full
    // size on *every* year whether or not any of it was worth a second
    // look. Most years nothing here is: the weather is fine, the family is
    // whatever it always is, and the character can go out. So the common
    // case is one line — the same weight as [_PeopleStrip] below it — and
    // the full card, with the two fact tiles and the explanation, is kept
    // for the year it is actually earning its space: one where the
    // character *cannot* go out, and the reason is worth a sentence rather
    // than an icon.
    if (outing.allowed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: PixelFrameStyle.slate.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              weather.icon,
              size: 15,
              color: AppTheme.legibleOn(
                weather.accent,
                PixelFrameStyle.slate.surface,
                target: 3.0,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedLabel(
                weather.label,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.family_restroom_rounded,
              size: 15,
              color: const Color(0xFF9BE870),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedLabel(
                strictness.label,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.directions_walk_rounded,
              size: 15,
              color: outingChip.ink,
            ),
          ],
        ),
      );
    }

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
                  accent: const Color(0xFF9BE870),
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
                  outing.reason?.icon ?? Icons.lock_rounded,
                  size: 15,
                  color: outingChip.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    outing.message,
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
/// Three shades of one color, which measured 4.26:1 — see
/// [AppTheme.tintedChip] for why that keeps happening.
final _personChip = AppTheme.tintedChip(const Color(0xFFFF8FB1), alpha: 0.14);

/// What a [_YearFact] tile actually sits on: a 5% white veil over the slate
/// panel. Named because two colors in that tile have to be measured against
/// it and neither can be judged against the page.
final Color _yearFactSurface = AppTheme.flatten(
  Colors.white.withValues(alpha: 0.05),
  PixelFrameStyle.slate.surface,
);

/// Aim above the bar rather than at it.
///
/// [_yearFactSurface] is the tile's *nominal* color, but the feed stacks
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
        color: Color(0xFF131F24),
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
                  // Reported as a screen with no way out. A swipe closed it,
                  // but nothing on screen said so.
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white70,
                    tooltip: 'Close',
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
      style: AppTheme.caps(
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

/// Choosing where to give your time.
///
/// Every row states its **hours** as prominently as its rewards, because the
/// hours are the price and this whole feature exists to stop volunteering
/// reading as free. See [VolunteerPlace] for what each option is arguing.
class _VolunteerSheet extends StatelessWidget {
  const _VolunteerSheet({required this.age});

  final int age;

  @override
  Widget build(BuildContext context) {
    final places = volunteerPlacesFor(age);
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
                const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFFFFD45C),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Where do you want to help?',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'None of these pay. They cost different amounts of your time '
              'and give back different things.',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            for (final place in places) ...[
              _VolunteerRow(place: place),
              const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _VolunteerRow extends StatelessWidget {
  const _VolunteerRow({required this.place});

  final VolunteerPlace place;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(place.accent, alpha: 0.16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () => Navigator.of(context).pop(place),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: place.accent.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              Icon(place.icon, color: place.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedLabel(
                      place.label,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.blurb,
                      style: GoogleFonts.quicksand(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag('${place.hours}h a week', chip.ink, chip.fill),
                        if (place.happiness != 0)
                          _Tag(
                            '${place.happiness > 0 ? '+' : ''}'
                            '${place.happiness} Happy',
                            const Color(0xFF9BE870),
                            const Color(0x2285EFAC),
                          ),
                        if (place.smarts != 0)
                          _Tag(
                            '+${place.smarts} Smarts',
                            const Color(0xFF69C6FF),
                            const Color(0x2269C6FF),
                          ),
                        if (place.health != 0)
                          _Tag(
                            '${place.health > 0 ? '+' : ''}'
                            '${place.health} Health',
                            place.health > 0
                                ? const Color(0xFF9BE870)
                                : const Color(0xFFFF8474),
                            place.health > 0
                                ? const Color(0x2285EFAC)
                                : const Color(0x22FF8474),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.ink, this.fill);

  final String text;
  final Color ink;
  final Color fill;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: GoogleFonts.quicksand(
        color: ink,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
