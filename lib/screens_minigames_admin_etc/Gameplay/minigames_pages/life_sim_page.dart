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
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/confetti_burst.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../adventure/adventure_world_screen.dart';
import 'life_character_sheet.dart';
import 'life_epilogue_screen.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/pixel_panel.dart';

/// **Life** — the main game, in the BitLife format: a scrolling life feed up
/// top, a fixed bottom menu, and a big central Age button that advances time
/// and surfaces money-decision events. (A map to explore comes later.)
///
/// Owns its own [LifeSimController], so state resets each visit and never
/// touches the player's saved gold until they retire.
class LifeSimPage extends StatefulWidget {
  const LifeSimPage({super.key});

  @override
  State<LifeSimPage> createState() => _LifeSimPageState();
}

class _LifeSimPageState extends State<LifeSimPage> {
  LifeSimController? _life;
  final ScrollController _feedController = ScrollController();
  bool _cashedOut = false;

  @override
  void initState() {
    super.initState();
    // Character creation first, exactly like starting a new BitLife.
    WidgetsBinding.instance.addPostFrameCallback((_) => _createCharacter());
  }

  Future<void> _createCharacter() async {
    final character = await Navigator.of(context).push<LifeCharacter>(
      MaterialPageRoute(builder: (_) => const LifeCharacterSheet()),
    );
    if (!mounted) return;
    if (character == null) {
      // Backed out of creation — leave Life entirely.
      Navigator.of(context).pop();
      return;
    }
    // A new life gets a fresh world. Town progress (visited spots, picked-up
    // coins) is stored per-player rather than per-run, so without this a
    // second life would start with every building already ticked off and
    // every coin gone — the town would be a finished checklist for every
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
  }

  @override
  void dispose() {
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LifeEpilogueScreen(summary: summary)),
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
                          icon: permission.reason?.icon ?? Icons.block_rounded,
                          accent: const Color(0xFFFF8FB1),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdventureWorldScreen(),
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
                  style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
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
                  netWorth: life.netWorth,
                  investments: life.investments,
                  smarts: life.smarts,
                  health: life.health,
                  looks: life.looks,
                  relationships: life.relationships,
                  isDependent: life.isDependent,
                  dead: life.dead,
                  event: event,
                  // Choose, then surface the money idea behind that choice
                  // (if it had one) once the outcome is on screen.
                  weather: life.weather,
                  strictness: life.strictness,
                  outing: life.outingPermission,
                  onChoose: (index) {
                    life.chooseOption(index);
                    _drainLesson(life);
                  },
                ),
              ),
              _BottomMenu(
                happiness: life.happiness,
                blocked: event != null || life.finished,
                stage: life.stage,
                onCareer: () => _openMenu(life, _LifeMenu.career),
                onRelationships: () => _openMenu(life, _LifeMenu.relationships),
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
    return 'Age $age · ${stage.label} · $trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF173B2E),
          child: Icon(gender.icon, color: const Color(0xFF85EFAC), size: 20),
        ),
        const SizedBox(width: 10),
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
            Text(
              '$money',
              style: GoogleFonts.pixelifySans(
                color: Color(0xFFE1BB72),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              'coins',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
              ),
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
    required this.netWorth,
    required this.investments,
    required this.smarts,
    required this.health,
    required this.looks,
    required this.relationships,
    required this.isDependent,
    required this.dead,
    required this.event,
    required this.onChoose,
    required this.weather,
    required this.strictness,
    required this.outing,
  });

  final ScrollController controller;
  final List<LifeLogEntry> history;
  final int netWorth;
  final int investments;
  final int smarts;
  final int health;
  final int looks;
  final List<String> relationships;
  final bool isDependent;
  final bool dead;
  final LifeEvent? event;
  final ValueChanged<int> onChoose;

  /// This year's conditions, surfaced so the outing rules are visible
  /// rather than only showing up as a locked button.
  final Weather weather;
  final HouseholdStrictness strictness;
  final OutingPermission outing;

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
        _MiniStatsRow(
          netWorth: netWorth,
          investments: investments,
          smarts: smarts,
          health: health,
          looks: looks,
          isDependent: isDependent,
        ),
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
                    color: const Color(0xFFFF8FB1).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: Color(0xFFFF8FB1),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        person,
                        style: const TextStyle(
                          color: Color(0xFFFF8FB1),
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
            _FeedLine(text: history[i].text),
          ],
        if (event != null) ...[
          const SizedBox(height: 14),
          _EventCard(event: event!, onChoose: onChoose),
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

class _MiniStatsRow extends StatelessWidget {
  const _MiniStatsRow({
    required this.netWorth,
    required this.investments,
    required this.smarts,
    required this.health,
    required this.looks,
    required this.isDependent,
  });

  final int netWorth;
  final int investments;
  final int smarts;
  final int health;
  final int looks;
  final bool isDependent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Pill(
          label: 'Smarts',
          value: '$smarts',
          color: const Color(0xFF69C6FF),
        ),
        _Pill(
          label: 'Health',
          value: '$health',
          color: const Color(0xFFFF8A80),
        ),
        _Pill(label: 'Looks', value: '$looks', color: const Color(0xFFFF8FB1)),
        // Money only starts mattering once the family stops paying the bills.
        if (!isDependent) ...[
          _Pill(
            label: 'Net worth',
            value: '$netWorth',
            color: const Color(0xFF85EFAC),
          ),
          if (investments > 0)
            _Pill(
              label: 'Invested',
              value: '$investments',
              color: const Color(0xFF58C7FF),
            ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.pixelifySans(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        'Age: $age years',
        style: GoogleFonts.pixelifySans(
          color: Color(0xFF85EFAC),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _FeedLine extends StatelessWidget {
  const _FeedLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.86),
          height: 1.4,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onChoose});

  final LifeEvent event;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF58C7FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF58C7FF).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(event.icon, color: const Color(0xFF58C7FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'What do you do?',
                style: GoogleFonts.pixelifySans(
                  color: Color(0xFF58C7FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => onChoose(i),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
                child: Text(
                  event.choices[i].label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (i != event.choices.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  const _BottomMenu({
    required this.happiness,
    required this.blocked,
    required this.stage,
    required this.onCareer,
    required this.onRelationships,
    required this.onActivities,
    required this.onAssets,
    required this.onAge,
  });

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
                  const Icon(
                    Icons.sentiment_very_satisfied_rounded,
                    color: Color(0xFFFFD45C),
                    size: 18,
                  ),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MenuButton(
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
                  _MenuButton(
                    label: 'People',
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFFF8FB1),
                    onTap: blocked ? null : onRelationships,
                  ),
                  _AgeButton(onTap: blocked ? null : onAge),
                  _MenuButton(
                    label: 'Do',
                    icon: Icons.self_improvement_rounded,
                    color: const Color(0xFFB388FF),
                    onTap: blocked ? null : onActivities,
                  ),
                  _MenuButton(
                    label: 'Money',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF85EFAC),
                    onTap: blocked ? null : onAssets,
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
  const _AgeButton({required this.onTap});

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? color : Colors.white24, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
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
    this.cost,
    this.disabledReason,
  });

  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  /// Coin cost shown as a chip. Null for free actions — and several of the
  /// best actions here are free on purpose.
  final int? cost;

  /// When set, the row is greyed out and explains *why* rather than just
  /// being dead.
  final String? disabledReason;

  bool get enabled => disabledReason == null;
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
  });

  final _LifeMenu menu;
  final LifeSimController life;
  final VoidCallback onSkills;
  final VoidCallback onInvest;
  final VoidCallback onBudget;
  final VoidCallback onConcepts;

  List<_LifeAction> _actions(BuildContext context) {
    void run(void Function() action) {
      action();
      Navigator.of(context).pop();
    }

    final young = life.isDependent;

    switch (menu) {
      case _LifeMenu.career:
        return [
          _LifeAction(
            label: young ? 'Hit the books' : 'Take a course',
            detail: young
                ? 'Study after school. +6 Smarts.'
                : 'Pay to learn something new. +6 Smarts.',
            icon: Icons.menu_book_rounded,
            cost: young ? null : 30,
            onTap: () => run(life.study),
          ),
          _LifeAction(
            label: 'Work harder',
            detail: 'Extra hours for a shot at a raise. Costs happiness.',
            icon: Icons.trending_up_rounded,
            onTap: () => run(life.workHarder),
            disabledReason: life.hasJob ? null : 'You need a job first',
          ),
          _LifeAction(
            label: 'Ask for a raise',
            detail: 'Asking is free. Being told no is not fun.',
            icon: Icons.record_voice_over_rounded,
            onTap: () => run(life.askForRaise),
            disabledReason: life.hasJob ? null : 'You need a job first',
          ),
          _LifeAction(
            label: 'Quit your job',
            detail: 'Freedom now, no paycheck next year.',
            icon: Icons.logout_rounded,
            onTap: () => run(life.quitJob),
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
            ),
            _LifeAction(
              label: 'Buy $person a gift',
              detail: 'Costs coins, and gives less happiness than time does.',
              icon: Icons.card_giftcard_rounded,
              cost: 50,
              onTap: () => run(() => life.giveGift(person)),
              disabledReason: life.money >= 50 ? null : 'Not enough coins',
            ),
          ],
        ];

      case _LifeMenu.activities:
        return [
          _LifeAction(
            label: 'Go out',
            detail: 'A night out. +10 Happiness.',
            icon: Icons.celebration_rounded,
            cost: young ? null : 40,
            onTap: () => run(life.haveFun),
            disabledReason: young || life.money >= 40
                ? null
                : 'Not enough coins',
          ),
          _LifeAction(
            label: 'Go to the gym',
            detail: 'Free. +8 Health, +3 Looks.',
            icon: Icons.fitness_center_rounded,
            onTap: () => run(life.exercise),
          ),
          _LifeAction(
            label: 'Visit the library',
            detail: 'Free. +4 Smarts.',
            icon: Icons.local_library_rounded,
            onTap: () => run(life.visitLibrary),
          ),
          _LifeAction(
            label: 'See a doctor',
            detail: 'A check-up. +12 Health.',
            icon: Icons.medical_services_rounded,
            cost: young ? null : 60,
            onTap: () => run(life.visitDoctor),
            disabledReason: young || life.money >= 60
                ? null
                : 'Not enough coins',
          ),
          _LifeAction(
            label: 'Work a side job',
            detail: 'Earn 40-100 coins. Costs Happiness and Health.',
            icon: Icons.work_history_rounded,
            onTap: () => run(life.workSideJob),
            disabledReason: life.age >= 14 ? null : 'You are too young to work',
          ),
          _LifeAction(
            label: 'Volunteer',
            detail: 'No pay at all. +9 Happiness, +2 Smarts.',
            icon: Icons.volunteer_activism_rounded,
            onTap: () => run(life.volunteer),
            disabledReason: life.age >= 10 ? null : 'You are too young',
          ),
          _LifeAction(
            label: 'Gamble 100 coins',
            detail: 'A 42% chance to double it. The odds are against you.',
            icon: Icons.casino_rounded,
            cost: 100,
            onTap: () => run(life.takeARisk),
            disabledReason: life.age < 18
                ? 'You must be 18'
                : (life.money >= 100 ? null : 'Not enough coins'),
          ),
          _LifeAction(
            label: 'Practise a skill',
            detail: 'Music, sport, business — the career ladders.',
            icon: Icons.auto_awesome_rounded,
            onTap: onSkills,
            disabledReason: life.stage == LifeStage.baby
                ? 'You are too young'
                : null,
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
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);

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
            else
              for (final action in actions) ...[
                _LifeActionRow(action: action, accent: menu.accent),
                const SizedBox(height: 8),
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
                    Text(
                      action.label,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelIcon(AppAssets.uiIconStar, size: 14),
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
              color: (outing.allowed
                      ? const Color(0xFF4BD2A3)
                      : const Color(0xFFFF8FB1))
                  .withValues(alpha: 0.12),
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
                  color: outing.allowed
                      ? const Color(0xFF4BD2A3)
                      : const Color(0xFFFF8FB1),
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
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.5),
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
