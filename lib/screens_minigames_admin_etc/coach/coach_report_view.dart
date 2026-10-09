import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../../models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import '../../models_Like_Skins_and_lessons_templates/money_snapshot_source.dart';
import '../../themes_colors/app_theme.dart';
import '../../widgets_custom_lotties/fitted_label.dart';
import '../../models_Like_Skins_and_lessons_templates/knowledge_tracing.dart';
import '../../models_Like_Skins_and_lessons_templates/review_schedule.dart';
import '../../widgets_custom_lotties/how_to_budget.dart';
import '../../widgets_custom_lotties/life_money_panel.dart';
import '../../widgets_custom_lotties/age_scaled_note.dart';
import '../Gameplay/academy/lesson_screen.dart';
import '../../models_Like_Skins_and_lessons_templates/coach_memory.dart';
import '../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../models_Like_Skins_and_lessons_templates/skill_lessons.dart';
import '../../widgets_custom_lotties/market_visuals.dart';

/// The budget and habit analyzer, as a screen.
///
/// Everything here comes from [analyzeMoney]. This file decides how a finding
/// *looks*; it does not decide what counts as one, which is why the rules can
/// be tested against a player who has pinned six habits and logged one
/// without anybody having to build that player in a widget test.
///
/// **Asked for as:** *"for the coach I want it to send back to the lesson
/// where the users can improve ... make sure that the things that improved
/// and finished disappear and congratulate them for doing so."* So anything
/// to work on points at the lesson that teaches it (the weak topics in
/// [_ImproveCard], the "Practice in the Academy" button on a finding), and
/// [CoachMemory] remembers what was flagged last time: when something stops
/// being flagged it leaves the list and shows up in [_FixedCard] instead.
class CoachReportView extends StatefulWidget {
  const CoachReportView({super.key, this.snapshot});

  /// Overrides the player's real history. See
  /// [MoneyHabitsScreen.debugSnapshot].
  final MoneySnapshot? snapshot;

  @override
  State<CoachReportView> createState() => _CoachReportViewState();
}

class _CoachReportViewState extends State<CoachReportView> {
  CoachMemory? _memory;

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  // Without device storage (a locked-down browser, a test harness) the Coach
  // still works; it just cannot remember last time, so it congratulates
  // nothing rather than failing to open.
  Future<void> _loadMemory() async {
    try {
      final memory = await CoachMemory.load();
      if (mounted) setState(() => _memory = memory);
    } catch (_) {
      // No memory this session.
    }
  }

  /// Weak quiz topics, as the "to improve" items [CoachMemory] tracks.
  static Map<String, String> _skillItems(List<String> weakSkills) => {
    for (final skill in weakSkills) 'skill:$skill': QuizSkills.label(skill),
  };

  /// Records what is flagged now. Runs after the frame, because it can change
  /// what this screen shows and a build must not set state.
  void _remember(MoneyReport report, List<String> weakSkills) {
    final memory = _memory;
    if (memory == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (memory.update(report.findings, extra: _skillItems(weakSkills))) {
        await memory.save();
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _dismissFixed() async {
    final memory = _memory;
    if (memory == null) return;
    memory.dismissFixed();
    await memory.save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<UserStatsController>().stats;
    final snap = widget.snapshot ?? buildMoneySnapshot(stats);
    final report = analyzeMoney(snap);
    _remember(report, stats.weakSkills);
    final fixed = _memory?.fixedFindings ?? const <FixedFinding>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _CoachHeader(report: report),
        const SizedBox(height: 16),
        if (fixed.isNotEmpty) ...[
          _FixedCard(fixed: fixed, onDismiss: _dismissFixed),
          const SizedBox(height: 16),
        ],
        _ImproveCard(weakSkills: stats.weakSkills),
        const AgeScaledNote(
          what: 'Findings',
          margin: EdgeInsets.only(bottom: 12),
        ),
        _DiagnosisCard(knowledge: KnowledgeState.fromMap(stats.knowledgeMap)),
        _ReviewCard(schedule: ReviewSchedule.fromMap(stats.reviewScheduleMap)),
        if (!report.isNewcomer) ...[
          _ScoreGrid(scores: report.scores),
          const SizedBox(height: 18),
        ],
        _LivesCard(lives: snap.lives),
        for (final finding in report.findings) ...[
          _FindingCard(finding: finding),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        Text(
          // Said out loud, because an app that scores you owes you this.
          'Everything here is worked out from what you have done in this app '
          '— habits logged, lessons taken, lives played. Nothing is shared.',
          style: GoogleFonts.quicksand(
            color: AppTheme.textMuted,
            fontSize: 11.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.report});

  final MoneyReport report;

  @override
  Widget build(BuildContext context) {
    final weakest = report.weakest;
    final chip = AppTheme.tintedChip(AppTheme.greenPrimary, alpha: 0.14);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.greenPrimary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: chip.ink, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: FittedLabel(
                  'What your money habits say',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.isNewcomer
                ? 'Give it a few days of real use and this page will have '
                      'something honest to tell you.'
                : weakest == null
                ? 'Nothing stands out yet.'
                : weakest.weakness,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.4,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the finished lives say when they are read together.
///
/// **Why this is on the Coach.** The main game is now school, work, a home and a
/// household, and each life ends with a diagnostic of its own. None of them can
/// say what is true across several. This is the row of numbers that can: how
/// many lives were studied for, how many ended owning a home, how many ended
/// owing. The findings below it are the same reading, in words.
///
/// Hidden until at least one life has kept its detail, because a row of zeroes
/// for a player who has only older lives would say they had never studied or
/// owned anything, which nobody knows.
class _LivesCard extends StatelessWidget {
  const _LivesCard({required this.lives});

  final List<LifeReading> lives;

  @override
  Widget build(BuildContext context) {
    if (lives.isEmpty) return const SizedBox.shrink();

    final total = lives.length;
    final studied = lives.where((l) => l.degrees > 0).length;
    final homes = lives.where((l) => l.ownedHome).length;
    final owing = lives.where((l) => l.loansOwed > 0).length;
    final promoted = lives.where((l) => l.promotions > 0).length;

    final chip = AppTheme.tintedChip(const Color(0xFF69C6FF), alpha: 0.12);

    return Container(
      key: const ValueKey('coach-lives-card'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: chip.ink.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: chip.ink),
              const SizedBox(width: 8),
              Expanded(
                child: FittedLabel(
                  'Your lives, read together',
                  style: GoogleFonts.pixelifySans(
                    color: chip.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              // Two across on a phone and four on a wide screen, so a tile is
              // never squeezed narrower than its own label.
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              const gap = 8.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _LifeStat(
                    width: width,
                    value: '$studied of $total',
                    label: 'lives studied',
                  ),
                  _LifeStat(
                    width: width,
                    value: '$promoted of $total',
                    label: 'were promoted',
                  ),
                  _LifeStat(
                    width: width,
                    value: '$homes of $total',
                    label: 'ended owning a home',
                  ),
                  _LifeStat(
                    width: width,
                    value: '$owing of $total',
                    label: 'ended owing money',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            total == 1
                ? 'Read from the one life that kept its detail. A pattern '
                      'needs two.'
                : 'Read from your newest $total lives that kept their detail.',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeStat extends StatelessWidget {
  const _LifeStat({
    required this.width,
    required this.value,
    required this.label,
  });

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedLabel(
            value,
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          FittedLabel(
            label,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The five areas, scored separately.
///
/// Deliberately not averaged into one number: somebody can be extremely
/// consistent and save nothing, or save well and understand none of it, and
/// a single score hides the only interesting part — which of them is weak.
class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.scores});

  final Map<MoneyDimension, int> scores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in scores.entries) ...[
          _ScoreRow(dimension: entry.key, score: entry.value),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.dimension, required this.score});

  final MoneyDimension dimension;
  final int score;

  @override
  Widget build(BuildContext context) {
    // Red below a third, amber below two thirds, green above. The bands are
    // wide on purpose — this is meant to point at the weak one, not to be
    // optimised to 100.
    final color = score < 34
        ? const Color(0xFFFF8474)
        : score < 67
        ? AppTheme.warningOrange
        : AppTheme.greenPrimary;
    return Row(
      children: [
        SizedBox(
          width: 108,
          child: FittedLabel(
            dimension.label,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: AppTheme.numeric(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// One finding: what was noticed, the number behind it, and one thing to do.
class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  final MoneyFinding finding;

  static (Color, IconData, String) _style(MoneyFindingKind kind) =>
      switch (kind) {
        MoneyFindingKind.fix => (
          const Color(0xFFFF8474),
          Icons.priority_high_rounded,
          'Worth fixing',
        ),
        MoneyFindingKind.watch => (
          AppTheme.warningOrange,
          Icons.visibility_rounded,
          'Keep an eye on',
        ),
        MoneyFindingKind.strength => (
          AppTheme.greenPrimary,
          Icons.check_circle_rounded,
          'Going well',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final (accent, icon, badge) = _style(finding.kind);
    final chip = AppTheme.tintedChip(accent, alpha: 0.13);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: chip.ink, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  badge.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caps(
                    color: chip.ink,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            finding.title,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // The evidence, not the advice. A finding that cannot show the
          // number out of your own data is a slogan.
          Text(
            finding.evidence,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  finding.action,
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (finding.kind != MoneyFindingKind.strength &&
              finding.concept != null &&
              unitIdForConcept(finding.concept!) != null) ...[
            const SizedBox(height: 10),
            _GoButton(
              label: 'Practice in the Academy',
              icon: Icons.school_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LessonScreen(
                    initialUnitId: unitIdForConcept(finding.concept!),
                  ),
                ),
              ),
            ),
          ],
          if (finding.showsBudgetHowTo) ...[
            const SizedBox(height: 10),
            const HowToBudgetButton(),
          ],
          if (finding.concept != null) ...[
            const SizedBox(height: 10),
            _ConceptChip(concept: finding.concept!),
          ],
        ],
      ),
    );
  }
}

/// The idea behind a finding — the hook into the Academy, and through it to
/// the lesson's source. The curriculum refuses to ship an uncited fact;
/// advice does not get a free pass either.
class _ConceptChip extends StatelessWidget {
  const _ConceptChip({required this.concept});

  final FinanceConcept concept;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(concept.accent, alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: concept.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LifeEmoji(concept.emoji, size: 12),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              concept.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.quicksand(
                color: chip.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the player is about to forget.
///
/// **Why an app for children has a forgetting curve in it.** The Academy
/// recorded that somebody scored 90% on compound growth in March and then
/// never mentioned it again. That is a record of learning rather than a
/// system for it: recall decays, and the way to beat the decay is to be
/// asked again shortly before you would have lost it. Without that, a quiz
/// score is a photograph of one good afternoon.
///
/// The scheduling is a simplified SM-2 — the algorithm behind Anki — with two
/// deliberate departures for this audience, both explained in
/// `review_schedule.dart`: an ease floor so a struggling player is never put
/// in a daily punishment loop, and an interval ceiling so nothing vanishes
/// for years.
///
/// It runs entirely on the device. Every input is already stored, nothing
/// leaves the phone, and it works on a school bus with no signal.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.schedule});

  final ReviewSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final due = schedule.dueOn(today);

    // Nothing studied at all: the scheduler has no opinion yet, and inventing
    // one would be the app talking to fill space.
    if (schedule.toMap().isEmpty) return const SizedBox.shrink();

    final nextIn = schedule.daysUntilNextDue(today);
    final accent = due.isEmpty
        ? AppTheme.greenPrimary
        : const Color(0xFF58C7FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: FittedLabel(
                  due.isEmpty ? 'Nothing to review yet' : 'Time to review',
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            due.isEmpty
                ? nextIn == null
                      ? 'Take a quiz and this starts tracking when you are '
                            'likely to forget it.'
                      : 'You are up to date. The next idea comes back in '
                            '$nextIn ${nextIn == 1 ? 'day' : 'days'}.'
                : 'These are timed to come back just before you would have '
                      'forgotten them, not on a fixed loop.',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (due.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              // Capped at four. The list is sorted by how overdue each one is,
              // so the top of it is the useful part — and a wall of sixteen
              // chips is a chore rather than a prompt.
              children: [
                for (final state in due.take(4))
                  _ConceptChip(concept: state.concept),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Why somebody is stuck, rather than what they are stuck on.
///
/// **The difference this makes.** Telling a learner "you keep getting
/// compound growth wrong" is a restatement of their own experience. It is
/// what a scoreboard says. What a tutor says is *why* — and for a subject
/// built in layers the answer is nearly always something earlier: compound
/// growth cannot land while "pay yourself first" has not, because there is
/// nothing to compound.
///
/// So this walks the prerequisite graph in `knowledge_tracing.dart` and names
/// the **earliest** idea that is missing. Sending somebody back to the thing
/// they are visibly failing, when the real gap is two steps upstream, is how
/// learners decide they are bad at maths.
///
/// The mastery figures behind it are Bayesian, not scores: a 2/4 that could
/// easily have been guessed counts for much less than a 6/12 that could not.
class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.knowledge});

  final KnowledgeState knowledge;

  @override
  Widget build(BuildContext context) {
    // Nothing assessed: no beliefs to report, and inventing one would be
    // worse than silence.
    if (knowledge.toMap().isEmpty) return const SizedBox.shrink();

    final diagnosis = knowledge.nextToTeach();
    final mastered = knowledge.mastered.length;

    // Nothing going wrong is worth saying, briefly. A diagnostic panel that
    // only ever appears with bad news teaches people to dread opening it.
    if (diagnosis == null) {
      return _DiagnosisShell(
        accent: AppTheme.greenPrimary,
        icon: Icons.verified_rounded,
        title: 'Nothing is blocking you',
        body: mastered == 0
            ? 'Keep going — nothing has come up as a gap so far.'
            : 'You have $mastered ${mastered == 1 ? 'idea' : 'ideas'} solid '
                  'and nothing underneath them is shaky.',
        chips: const <FinanceConcept>[],
      );
    }

    final root = diagnosis.rootCause;
    final symptom = diagnosis.struggling;
    final unitId = unitIdForConcept(root);

    return _DiagnosisShell(
      accent: const Color(0xFFFFB084),
      icon: Icons.account_tree_rounded,
      title: diagnosis.isUpstream
          ? 'Start one step earlier'
          : 'The gap is right here',
      body: diagnosis.isUpstream
          // Naming both ends matters. The learner knows they are failing the
          // symptom; what they cannot see is the link to the cause, and the
          // link is the whole insight.
          ? '${symptom.label} keeps going wrong, and the reason is further '
                'back: ${root.label} has not landed yet. Fixing that first '
                'makes the rest of it make sense.'
          : '${root.label} is the thing to work on. What it depends on is '
                'already solid, so this really is where the gap is.',
      chips: diagnosis.chain,
      // No unit teaches this concept: stays a diagnosis with nowhere to send
      // anyone, which is honest, so no button rather than a dead one.
      fixLabel: unitId == null ? null : 'Go to ${root.label}',
      onFix: unitId == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LessonScreen(initialUnitId: unitId),
              ),
            ),
    );
  }
}

/// Shared frame for the two diagnosis states.
///
/// Extracted rather than duplicated because the two branches differ only in
/// color and words — and a copy-pasted panel is how the "nothing wrong"
/// state quietly stops matching the "here is the problem" one.
class _DiagnosisShell extends StatelessWidget {
  const _DiagnosisShell({
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
    required this.chips,
    this.fixLabel,
    this.onFix,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;
  final List<FinanceConcept> chips;

  /// Button copy and action for jumping straight to the lesson that teaches
  /// the root cause. Null together: a diagnosis with nothing to send anyone
  /// to is still shown, just without a button that would go nowhere.
  final String? fixLabel;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: FittedLabel(
                  title,
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (chips.length > 1) ...[
            const SizedBox(height: 10),
            // The chain, shown as the path it is. Seeing "Compound growth →
            // Pay yourself first → Needs vs wants" is the explanation; a
            // single chip would just be a second thing to go and read.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final concept in chips.reversed)
                  _ConceptChip(concept: concept),
              ],
            ),
          ],
          if (onFix != null) ...[
            const SizedBox(height: 12),
            Material(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onFix,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          fixLabel!,
                          style: GoogleFonts.quicksand(
                            color: accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "You fixed it" — what the Coach used to flag and no longer does.
class _FixedCard extends StatelessWidget {
  const _FixedCard({required this.fixed, required this.onDismiss});

  final List<FixedFinding> fixed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('coach-fixed-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.greenPrimary, width: 2),
        boxShadow: AppTheme.ledgeShadow(AppTheme.greenPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BuddySaysCard(
            mood: BuddyMood.happy,
            title: fixed.length == 1
                ? 'You fixed it!'
                : 'You fixed ${fixed.length} things!',
            message:
                'The Coach is not flagging these any more. That is real '
                'progress — nice work.',
          ),
          const SizedBox(height: 12),
          for (final f in fixed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.greenPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f.id.startsWith('skill:')
                          ? '${f.title}: no longer a weak spot'
                          : f.title,
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _GoButton(
            label: 'Nice!',
            icon: Icons.celebration_rounded,
            onTap: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// The topics answered wrong and not yet put right, each with the lesson
/// that teaches it. A topic leaves this list as soon as it is answered right
/// in a quiz, a test or a practice run.
class _ImproveCard extends StatelessWidget {
  const _ImproveCard({required this.weakSkills});

  final List<String> weakSkills;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, Lesson)>[
      for (final skill in weakSkills)
        if (lessonForSkill(skill) case final lesson?)
          (QuizSkills.label(skill), lesson),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    const accent = Color(0xFFFFC36B);
    return Container(
      key: const ValueKey('coach-improve-card'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where to improve',
            style: GoogleFonts.pixelifySans(
              color: accent,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Topics you got wrong. Each goes away once you get it right.',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final (label, lesson) in rows.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Lesson: ${lesson.title}',
                          style: GoogleFonts.quicksand(
                            color: AppTheme.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GoButton(
                    label: 'Go to lesson',
                    icon: Icons.menu_book_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LessonScreen(initialLessonId: lesson.id),
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

class _GoButton extends StatelessWidget {
  const _GoButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.greenPrimary,
        side: const BorderSide(color: AppTheme.greenPrimary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
