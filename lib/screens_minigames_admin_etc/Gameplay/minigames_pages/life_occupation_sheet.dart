import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_careers.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_education.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../models_Like_Skins_and_lessons_templates/relationship.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../utils/number_format.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'life_ui_kit.dart';

/// **Occupation:** your school or your job, and everything you can do about it.
///
/// **Asked for as:** the BitLife Occupation tab, *"your current school or job
/// status. Inside, buttons to work harder, ask for a raise, interact with
/// coworkers, apply for promotions, or drop out or resign."* And *"some jobs
/// need degrees,"* with *"the user has options and can choose from a dropdown"*
/// rather than everything being a dice roll.
///
/// One screen that changes with the life it is showing. A student sees grades, a
/// worker sees performance and the next rung, and somebody between the two sees
/// where to go. Every button says what it does, what it costs and how much of the
/// year it has left, and every refusal says why.
const Color _accent = Color(0xFF58C7FF);

Future<void> openOccupation(
  BuildContext context,
  LifeSimController life, {
  required void Function(Relationship person) onPerson,
}) {
  return showLifeSheet<void>(
    context,
    builder: (_) => OccupationSheet(life: life, onPerson: onPerson),
  );
}

class OccupationSheet extends StatelessWidget {
  const OccupationSheet({
    super.key,
    required this.life,
    required this.onPerson,
  });

  final LifeSimController life;
  final void Function(Relationship person) onPerson;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final young = life.age < 16;
        return LifeSheet(
          title: life.isStudent && !life.hasJob ? 'School' : 'Occupation',
          icon: life.isStudent && !life.hasJob
              ? Icons.school_rounded
              : Icons.work_rounded,
          accent: _accent,
          subtitle: life.hasJob
              ? '${life.job} · ${life.salary} a year'
              : life.isStudent
              ? life.educationStatus
              : 'Not working',
          children: [
            if (life.canPickNextStep) _NextStepBanner(life: life),
            if (life.isStudent) _SchoolCard(life: life),
            if (life.hasJob) _JobCard(life: life, onPerson: onPerson),
            if (!life.hasJob && !life.isStudent && !young)
              _NoJobCard(life: life),
            if (young && !life.isStudent)
              const LifeCard(
                child: _Plain(
                  'You are too young for work. School is the job for now, and '
                  'the grades you earn open doors later.',
                ),
              ),
            if (!young) ...[
              const LifeSection('Do something about it'),
              ..._actions(context),
            ],
            const LifeSection('Your education'),
            _EducationCard(life: life),
          ],
        );
      },
    );
  }

  List<Widget> _actions(BuildContext context) {
    final rows = <Widget>[];
    final action = life.hasJob;

    if (action) {
      rows.add(
        _ActionRow(
          icon: Icons.trending_up_rounded,
          label: 'Work harder',
          detail:
              'Builds your performance, which decides raises and promotions. '
              'Costs happiness and health.',
          note: life.budgetFor(LifeAction.workHarder).label,
          reason: life.unavailableFor(LifeAction.workHarder),
          onTap: life.workHarder,
        ),
      );
      rows.add(
        _ActionRow(
          icon: Icons.record_voice_over_rounded,
          label: 'Ask for a raise',
          detail:
              'A share of your pay, not a flat sum. Odds follow your '
              'performance.',
          note: life.budgetFor(LifeAction.askForRaise).label,
          reason: life.unavailableFor(LifeAction.askForRaise),
          onTap: life.askForRaise,
        ),
      );
      final next = life.nextPromotion;
      rows.add(
        _ActionRow(
          icon: Icons.workspace_premium_rounded,
          label: next == null
              ? 'Apply for a promotion'
              : 'Apply for ${next.title}',
          detail: next == null
              ? 'Only jobs on a career ladder can be promoted.'
              : 'Pay rises to about ${promotedSalary(current: life.salary, next: next)}. '
                    'Odds ${life.promotionChance}%.',
          reason: life.promotionBlocker(),
          onTap: () => _promote(context),
        ),
      );
      rows.add(
        _ActionRow(
          icon: Icons.groups_rounded,
          label: 'Go to a networking event',
          detail: life.networkReading.contacts == 0
              ? 'Meet people who know people. Contacts pass on leads and a '
                    'good word to your manager.'
              : 'Your network is ${life.networkReading.label.toLowerCase()}.',
          note: life.budgetFor(LifeAction.network).label,
          reason: life.unavailableFor(LifeAction.network),
          cost: 25,
          onTap: life.attendNetworkingEvent,
        ),
      );
    }

    rows.add(
      _ActionRow(
        icon: Icons.badge_rounded,
        label: life.hasJob ? 'Look for a better job' : 'Find a job',
        detail:
            'See every job on the board, what it needs, and your odds before '
            'you apply.',
        note: life.budgetFor(LifeAction.applyJob).label,
        reason: life.applyGate(),
        onTap: () => _openBoard(context),
      ),
    );

    rows.add(
      _ActionRow(
        icon: Icons.school_rounded,
        label: life.isStudent ? 'Study harder' : 'Take a course',
        detail: life.isStudent
            ? 'Raises Smarts and this year\'s grades.'
            : 'Pay to learn something new. +6 Smarts.',
        note: life.budgetFor(LifeAction.study).label,
        reason: life.unavailableFor(LifeAction.study),
        cost: life.isDependent ? null : 30,
        onTap: life.study,
      ),
    );

    if (!life.isPostSecondaryStudent &&
        life.educationLevel.atLeast(EducationLevel.secondary)) {
      rows.add(
        _ActionRow(
          icon: Icons.account_balance_rounded,
          label: 'Apply to study something',
          detail:
              'College, a trade or graduate school. Pick from a list and see '
              'the cost first.',
          note: life.budgetFor(LifeAction.applyCollege).label,
          reason: life.age < 17 ? 'You need to be 17 to apply' : null,
          onTap: () => _openPrograms(context),
        ),
      );
    }

    if (life.age >= 18 &&
        !life.isStudent &&
        !life.educationLevel.atLeast(EducationLevel.secondary)) {
      rows.add(
        _ActionRow(
          icon: Icons.verified_rounded,
          label: 'Earn your diploma',
          detail: 'A second chance. It opens college and most jobs.',
          cost: 40,
          reason: life.money >= 40 ? null : 'It costs 40 coins',
          onTap: life.earnDiploma,
        ),
      );
    }

    if (life.hasJob) {
      rows.add(
        _ActionRow(
          icon: Icons.logout_rounded,
          label: 'Resign',
          detail: 'Freedom now, no paycheck next year.',
          onTap: () => _confirm(
            context,
            title: 'Resign from ${life.job}?',
            body:
                'Your pay stops straight away. You keep what you have saved '
                'and the experience you have built.',
            confirm: 'Resign',
            onYes: life.quitJob,
          ),
        ),
      );
    }
    if (life.isStudent && life.age >= 16) {
      rows.add(
        _ActionRow(
          icon: Icons.exit_to_app_rounded,
          label: life.isPostSecondaryStudent
              ? 'Leave your course'
              : 'Drop out of school',
          detail: life.isPostSecondaryStudent
              ? 'You keep what you owe, and you do not get the degree.'
              : 'Some doors close. You can earn a diploma later.',
          onTap: () => _confirm(
            context,
            title: life.isPostSecondaryStudent
                ? 'Leave your course?'
                : 'Drop out of school?',
            body: life.isPostSecondaryStudent
                ? 'Any student loan stays with you and starts asking for '
                      'payments. You will not be awarded the degree.'
                : 'Without a diploma, fewer jobs and no college. You can go '
                      'back for a diploma any time after 18.',
            confirm: 'Leave',
            onYes: life.leaveSchool,
          ),
        ),
      );
    }
    return rows;
  }

  void _promote(BuildContext context) {
    final result = life.applyForPromotion();
    final next = life.currentJob;
    switch (result) {
      case PromotionOutcome.promoted:
        GameToast.show(
          context,
          title: 'Promoted',
          message: 'You are now ${next?.title ?? life.job}.',
          icon: Icons.workspace_premium_rounded,
          accent: const Color(0xFF85EFAC),
        );
      case PromotionOutcome.refused:
        GameToast.show(
          context,
          title: 'Not this time',
          message: 'They chose somebody else. Build your record and ask again.',
          icon: Icons.hourglass_bottom_rounded,
          accent: const Color(0xFFF2C66D),
        );
      case PromotionOutcome.blocked:
        break;
    }
  }

  void _openBoard(BuildContext context) {
    showLifeSheet<void>(context, builder: (_) => JobBoardSheet(life: life));
  }

  void _openPrograms(BuildContext context) {
    showLifeSheet<void>(context, builder: (_) => ProgramSheet(life: life));
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirm,
    required VoidCallback onYes,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: AppTheme.panelStrong,
        title: Text(
          title,
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: GoogleFonts.quicksand(
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(
              'Keep going',
              style: GoogleFonts.pixelifySans(
                color: const Color(0xFF85EFAC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(
              confirm,
              style: GoogleFonts.pixelifySans(
                color: const Color(0xFFFF8FB1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (yes == true) onYes();
  }
}

/// Plain body text in a card.
class _Plain extends StatelessWidget {
  const _Plain(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.quicksand(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// One button in the list, with its price, its note and its reason for being off.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.note,
    this.reason,
    this.cost,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final String? note;
  final String? reason;
  final int? cost;

  @override
  Widget build(BuildContext context) {
    return LifeRow(
      icon: icon,
      title: label,
      subtitle: note == null ? detail : '$detail\n$note',
      accent: _accent,
      disabledReason: reason,
      onTap: onTap,
      trailing: cost == null
          ? null
          : LifeChip('-$cost', color: const Color(0xFFFFD45C)),
    );
  }
}

class _NextStepBanner extends StatelessWidget {
  const _NextStepBanner({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LifeCard(
        accent: const Color(0xFFFFD45C),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have finished school',
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const _Plain(
              'What happens next is up to you. Apply to study, or find work.',
            ),
          ],
        ),
      ),
    );
  }
}

/// A student's card: where they are, and how they are doing.
class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    final program = life.currentProgram;
    final quote = program == null
        ? null
        : life.tuitionQuote(program, privateSchool: life.isPrivateSchool);
    return LifeCard(
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program?.name ?? life.schoolStage.label,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            program == null
                ? 'Compulsory school. Study to keep your grades up.'
                : 'Year ${life.yearsInStage + 1} of ${program.years}'
                      '${life.isPrivateSchool ? ' · private college' : ''}',
            style: AppTheme.numeric(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LifeBar(
            label: 'Grades',
            value: life.grades,
            color: valueColor(life.grades),
            trailing: '${gradeLetter(life.grades)}  ${life.grades}',
            icon: Icons.grade_rounded,
            caption: life.grades < 40
                ? 'Falling behind. Studying is the fastest way back.'
                : life.grades >= 85
                ? 'Honour roll territory.'
                : null,
          ),
          if (quote != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                LifeChip(
                  'Tuition ${quote.perYear} a year',
                  color: const Color(0xFFFFD45C),
                ),
                if (quote.scholarship > 0)
                  LifeChip(
                    'Scholarship ${quote.scholarship}',
                    color: const Color(0xFF85EFAC),
                  ),
                if (quote.family > 0)
                  LifeChip(
                    'Family pays ${quote.family}',
                    color: const Color(0xFF85EFAC),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A worker's card: the job, how it is going, and the way up.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.life, required this.onPerson});

  final LifeSimController life;
  final void Function(Relationship person) onPerson;

  @override
  Widget build(BuildContext context) {
    final job = life.currentJob;
    final next = life.nextPromotion;
    final blocker = life.promotionBlocker();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LifeCard(
          accent: _accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      life.job,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${groupedNumber(life.salary)} a year',
                    style: AppTheme.numeric(
                      color: const Color(0xFFFFD45C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (job != null) LifeChip(job.track.label),
                  LifeChip(
                    '${life.yearsInRole} yrs in role',
                    color: const Color(0xFFB388FF),
                  ),
                  if (life.experienceIn(job?.track ?? CareerTrack.service) >
                          0 &&
                      job != null)
                    LifeChip(
                      '${life.experienceIn(job.track)} yrs in the field',
                      color: const Color(0xFF85EFAC),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LifeBar(
                label: 'Performance',
                value: life.performance,
                color: valueColor(life.performance),
                icon: Icons.insights_rounded,
                caption: life.performance < 25
                    ? 'A poor record. Two bad years in a row can lose the job.'
                    : life.performance >= 72
                    ? 'Strong. Good years can earn a raise without asking.'
                    : null,
              ),
            ],
          ),
        ),
        if (job != null) ...[
          const SizedBox(height: 10),
          LifeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null
                      ? 'You are at the top of this ladder'
                      : 'Next rung: ${next.title}',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _Plain(
                  next == null
                      ? 'The only way further is a different line of work.'
                      : blocker ??
                            'You are ready to ask. Odds ${life.promotionChance}%.',
                ),
              ],
            ),
          ),
        ],
        if (life.workPeople.isNotEmpty) ...[
          const LifeSection('People at work'),
          for (final p in life.workPeople.take(4))
            LifeRow(
              icon: p.kind.icon,
              title: p.name,
              subtitle: p.roleLabel,
              accent: p.kind.accent,
              onTap: () => onPerson(p),
              bar: LifeBar(
                label: p.status,
                value: p.closeness,
                color: p.statusColor,
                height: 6,
              ),
            ),
        ],
      ],
    );
  }
}

class _NoJobCard extends StatelessWidget {
  const _NoJobCard({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    return LifeCard(
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not working',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          _Plain(
            life.runTally.timesLaidOff > 0
                ? 'Losing a job is a setback and not the end. Look at the '
                      'board, and think about what would make you stronger '
                      'for the next one.'
                : 'No paycheck means no budget. Getting work is what starts '
                      'the part of the game about keeping money.',
          ),
        ],
      ),
    );
  }
}

/// What has been earned so far, and what is owed for it.
class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    final student = life.loans
        .where((l) => l.kind == LoanKind.student)
        .toList();
    return LifeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            life.educationLevel.label,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (life.credentials.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in life.credentials)
                  LifeChip(
                    c,
                    color: const Color(0xFF85EFAC),
                    icon: Icons.check_circle_rounded,
                  ),
              ],
            ),
          ],
          if (student.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final loan in student)
              _Plain(
                loan.deferred
                    ? 'Student loan: ${loan.balance}, growing at '
                          '${(loan.rate * 100).round()}% while you study. '
                          'Payments start when school ends.'
                    : 'Student loan: ${loan.balance} left, '
                          '${loan.payment} a year at '
                          '${(loan.rate * 100).round()}%.',
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The job board
// ---------------------------------------------------------------------------

/// **The job board.** Every job, what it needs, and the odds of getting it.
///
/// A job you cannot take is shown with everything standing in the way, because a
/// locked job is the clearest map of what to go and do next.
class JobBoardSheet extends StatefulWidget {
  const JobBoardSheet({super.key, required this.life});

  final LifeSimController life;

  @override
  State<JobBoardSheet> createState() => _JobBoardSheetState();
}

class _JobBoardSheetState extends State<JobBoardSheet> {
  CareerTrack? _track;
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        var listings = life.jobListings(track: _track);
        if (_onlyMine) listings = listings.where((l) => l.qualified).toList();
        listings.sort((a, b) {
          if (a.qualified != b.qualified) return a.qualified ? -1 : 1;
          return b.job.salary.compareTo(a.job.salary);
        });
        final gate = life.applyGate();
        return LifeSheet(
          title: 'Job board',
          icon: Icons.badge_rounded,
          accent: _accent,
          subtitle: gate ?? life.budgetFor(LifeAction.applyJob).label,
          children: [
            LifeDropdown<CareerTrack?>(
              label: 'Line of work',
              value: _track,
              accent: _accent,
              items: [
                const LifeDropdownItem<CareerTrack?>(
                  value: null,
                  label: 'Everything',
                ),
                for (final t in CareerTrack.values)
                  LifeDropdownItem<CareerTrack?>(value: t, label: t.label),
              ],
              onChanged: (t) => setState(() => _track = t),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _onlyMine,
              onChanged: (v) => setState(() => _onlyMine = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: _accent,
              title: Text(
                'Only jobs I qualify for',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (listings.isEmpty)
              const LifeCard(
                child: _Plain(
                  'Nothing here fits yet. Study, gain experience or widen the '
                  'search.',
                ),
              ),
            for (final l in listings) _ListingCard(life: life, listing: l),
          ],
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.life, required this.listing});

  final LifeSimController life;
  final JobListing listing;

  @override
  Widget build(BuildContext context) {
    final job = listing.job;
    final ok = listing.qualified;
    final gate = life.applyGate();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: ok ? 1 : 0.8,
        child: LifeCard(
          accent: ok ? const Color(0xFF85EFAC) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${groupedNumber(job.salary)} a year',
                    style: AppTheme.numeric(
                      color: const Color(0xFFFFD45C),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (job.blurb.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  job.blurb,
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  LifeChip(job.track.label, color: const Color(0xFF58C7FF)),
                  if (job.partTime)
                    const LifeChip('Part-time', color: Color(0xFFB388FF)),
                  if (job.rung > 0)
                    LifeChip(
                      'Rung ${job.rung + 1}',
                      color: const Color(0xFFB388FF),
                    ),
                  ..._requirements(),
                ],
              ),
              const SizedBox(height: 10),
              if (ok)
                LifeButton(
                  label: 'Apply',
                  icon: Icons.send_rounded,
                  onPressed: gate == null ? () => _apply(context) : null,
                  note: gate ?? 'Odds: ${listing.odds} (${listing.chance}%)',
                )
              else
                Text(
                  listing.blockers.join('. '),
                  style: GoogleFonts.quicksand(
                    color: errorInk(),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// What the job asks for, each one green if the player has it and red if not.
  List<Widget> _requirements() {
    final job = listing.job;
    final chips = <Widget>[];
    if (job.minLevel != EducationLevel.none) {
      final has = life.educationLevel.atLeast(job.minLevel);
      chips.add(
        LifeChip(
          job.minLevel.label,
          color: has ? const Color(0xFF85EFAC) : const Color(0xFFFF8474),
          icon: has ? Icons.check_rounded : Icons.close_rounded,
        ),
      );
    }
    if (job.fields.isNotEmpty) {
      final has = life.studyFields.intersection(job.fields).isNotEmpty;
      chips.add(
        LifeChip(
          job.fields.map((f) => f.label).join(' or '),
          color: has ? const Color(0xFF85EFAC) : const Color(0xFFFF8474),
          icon: has ? Icons.check_rounded : Icons.close_rounded,
        ),
      );
    }
    if (job.minSmarts > 0) {
      final has = life.smarts >= job.minSmarts;
      chips.add(
        LifeChip(
          'Smarts ${job.minSmarts}',
          color: has ? const Color(0xFF85EFAC) : const Color(0xFFFF8474),
          icon: has ? Icons.check_rounded : Icons.close_rounded,
        ),
      );
    }
    return chips;
  }

  void _apply(BuildContext context) {
    final job = listing.job;
    final result = life.applyForJob(job.id);
    switch (result) {
      case JobOutcome.hired:
        GameToast.show(
          context,
          title: 'You got it',
          message: 'You are now a ${job.title}.',
          icon: Icons.celebration_rounded,
          accent: const Color(0xFF85EFAC),
        );
        Navigator.of(context).maybePop();
      case JobOutcome.rejected:
        GameToast.show(
          context,
          title: 'Not this time',
          message: 'They went with somebody else. It happens to everyone.',
          icon: Icons.hourglass_bottom_rounded,
          accent: const Color(0xFFF2C66D),
        );
      case JobOutcome.blocked:
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Applying to study
// ---------------------------------------------------------------------------

/// **Apply to study.** Pick a level, a program and a school from dropdowns, see
/// what it costs and who pays, see the odds, and only then send it.
class ProgramSheet extends StatefulWidget {
  const ProgramSheet({super.key, required this.life, this.stage});

  final LifeSimController life;

  /// Which tab to open on.
  final SchoolStage? stage;

  @override
  State<ProgramSheet> createState() => _ProgramSheetState();
}

class _ProgramSheetState extends State<ProgramSheet> {
  late SchoolStage _stage;
  String? _programId;
  bool _private = false;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage ?? SchoolStage.college;
  }

  List<StudyProgram> get _programs => programsAt(_stage);

  StudyProgram get _program {
    final list = _programs;
    return list.firstWhere((p) => p.id == _programId, orElse: () => list.first);
  }

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final program = _program;
        final usePrivate = _private && program.stage == SchoolStage.college;
        final quote = life.tuitionQuote(program, privateSchool: usePrivate);
        final gate = life.programGate(program);
        final chance = life.admissionChance(program, privateSchool: usePrivate);
        return LifeSheet(
          title: 'Apply to study',
          icon: Icons.account_balance_rounded,
          accent: _accent,
          subtitle: 'Smarts ${life.smarts} · Grades ${life.grades}',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in const [
                  SchoolStage.college,
                  SchoolStage.trade,
                  SchoolStage.graduate,
                ])
                  ChoiceChip(
                    label: Text(
                      s == SchoolStage.college
                          ? 'College'
                          : s == SchoolStage.trade
                          ? 'Trade school'
                          : 'Graduate school',
                    ),
                    selected: _stage == s,
                    onSelected: (_) => setState(() {
                      _stage = s;
                      _programId = null;
                    }),
                    selectedColor: _accent.withValues(alpha: 0.35),
                    labelStyle: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LifeDropdown<String>(
              label: _stage == SchoolStage.college
                  ? 'Major'
                  : _stage == SchoolStage.trade
                  ? 'Program'
                  : 'Degree',
              value: program.id,
              accent: _accent,
              items: [
                for (final p in _programs)
                  LifeDropdownItem<String>(
                    value: p.id,
                    label: p.name,
                    hint:
                        '${p.years} ${p.years == 1 ? 'year' : 'years'} · ${p.tuition} a year',
                  ),
              ],
              onChanged: (id) => setState(() => _programId = id),
            ),
            if (_stage == SchoolStage.college) ...[
              const SizedBox(height: 10),
              LifeDropdown<bool>(
                label: 'School',
                value: _private,
                accent: _accent,
                items: [
                  LifeDropdownItem<bool>(
                    value: false,
                    label: 'State college',
                    hint: '${program.tuition} a year',
                  ),
                  LifeDropdownItem<bool>(
                    value: true,
                    label: 'Private college',
                    hint:
                        '${program.tuitionFor(privateSchool: true)} a year, and a stronger name',
                  ),
                ],
                onChanged: (v) => setState(() => _private = v),
              ),
            ],
            const SizedBox(height: 12),
            LifeCard(
              accent: _accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Plain(program.blurb),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      LifeChip(
                        '${program.years} ${program.years == 1 ? 'year' : 'years'}',
                        color: const Color(0xFFB388FF),
                      ),
                      LifeChip(
                        program.awards.label,
                        color: const Color(0xFF85EFAC),
                      ),
                      LifeChip(
                        'Smarts ${program.minSmartsFor(privateSchool: usePrivate)}',
                        color:
                            life.smarts >=
                                program.minSmartsFor(privateSchool: usePrivate)
                            ? const Color(0xFF85EFAC)
                            : const Color(0xFFFF8474),
                      ),
                      LifeChip(program.field.label),
                    ],
                  ),
                ],
              ),
            ),
            const LifeSection('What it costs'),
            LifeCard(
              child: Column(
                children: [
                  _CostLine('Price each year', '${quote.perYear}'),
                  if (quote.scholarship > 0)
                    _CostLine(
                      'Scholarship',
                      '-${quote.scholarship}',
                      good: true,
                    ),
                  if (quote.family > 0)
                    _CostLine(
                      'Your family pays',
                      '-${quote.family}',
                      good: true,
                    ),
                  const Divider(color: Colors.white12, height: 18),
                  _CostLine('You pay each year', '${quote.you}', bold: true),
                  _CostLine(
                    'You pay over ${program.years} ${program.years == 1 ? 'year' : 'years'}',
                    '${quote.total}',
                    bold: true,
                  ),
                  const SizedBox(height: 6),
                  const _Plain(
                    'Whatever your cash cannot cover becomes a student loan '
                    'at 5%. It does not ask for payments until you finish, '
                    'but the interest is already running.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LifeButton(
              label: 'Apply',
              icon: Icons.send_rounded,
              onPressed: gate == null
                  ? () => _apply(context, program, usePrivate)
                  : null,
              note: gate ?? 'Odds: ${oddsLabel(chance)} ($chance%)',
            ),
          ],
        );
      },
    );
  }

  void _apply(BuildContext context, StudyProgram program, bool usePrivate) {
    final result = widget.life.applyToProgram(
      program,
      privateSchool: usePrivate,
    );
    switch (result) {
      case ApplyResult.accepted:
        GameToast.show(
          context,
          title: 'Accepted',
          message: 'You are in: ${program.name}.',
          icon: Icons.school_rounded,
          accent: const Color(0xFF85EFAC),
        );
        Navigator.of(context).maybePop();
      case ApplyResult.rejected:
        GameToast.show(
          context,
          title: 'Not this time',
          message: 'They said no. Grades and Smarts change the odds.',
          icon: Icons.hourglass_bottom_rounded,
          accent: const Color(0xFFF2C66D),
        );
      case ApplyResult.blocked:
        break;
    }
  }
}

class _CostLine extends StatelessWidget {
  const _CostLine(
    this.label,
    this.value, {
    this.good = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool good;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final color = good ? const Color(0xFF85EFAC) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.numeric(
              color: color,
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
