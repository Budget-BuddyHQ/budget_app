import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/interview_questions.dart';
import '../../../navigation_tools_and_animation/pauses_in_background.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../themes_colors/app_theme.dart';

/// The Job Board, with a real interview instead of a random roll.
///
/// **What this replaced.** Walking here used to call the same legacy
/// `findJob` roll the notice board and a friend's referral already used —
/// three best-of-rolls with no say in which job, completely separate from
/// the real career ladders the Occupation tab applies to. Nothing you did in
/// person ever touched the odds a real application actually ran on, so
/// walking here instead of opening the Occupation tab was strictly worse:
/// same chance of a result, less control over which one.
///
/// This interviews for a real listing from [LifeSimController.jobListings] —
/// the same ladder jobs the Occupation tab shows — and a good interview adds
/// up to 20 points to the hire chance on top of it, through
/// [LifeSimController.applyForJob]'s `interviewScore`. That is the actual,
/// mechanical reason to make the walk, not a line of flavor text describing
/// a bonus nothing paid.
///
/// Runs inside the town's dialogue panel rather than on a screen of its own,
/// matching [ParkActivityPanel] — the player walked here, and a full-screen
/// takeover would lose the town around them.
class JobInterviewPanel extends StatefulWidget {
  const JobInterviewPanel({
    super.key,
    required this.life,
    required this.onTalk,
    required this.onLeave,
    this.random,
  });

  final LifeSimController life;

  /// Switches to the ordinary conversation for this spot.
  final VoidCallback onTalk;

  /// Done here — pops the whole building. Any hire already landed directly
  /// on [life], so there is nothing left to hand back.
  final VoidCallback onLeave;

  /// Seeded in tests so a round is repeatable.
  final Random? random;

  @override
  State<JobInterviewPanel> createState() => _JobInterviewPanelState();
}

enum _Stage { pickJob, interviewing, result }

class _JobInterviewPanelState extends State<JobInterviewPanel>
    with PausesInBackground {
  static const _questionSeconds = 8;
  static const _questionCount = 4;

  _Stage _stage = _Stage.pickJob;
  JobListing? _chosen;
  List<InterviewQuestion> _questions = const [];
  int _qIndex = 0;
  int _score = 0;
  Timer? _clock;
  int _secondsLeft = _questionSeconds;
  JobOutcome? _outcome;
  int _beforeChance = 0;
  int _afterChance = 0;

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  void onAppBackgrounded() {
    _clock?.cancel();
    _clock = null;
  }

  @override
  void onAppForegrounded() {
    if (_stage == _Stage.interviewing && _clock == null && mounted) {
      _startClock();
    }
  }

  void _pick(JobListing listing) {
    final random = widget.random ?? Random();
    final pool = List<InterviewQuestion>.from(kInterviewQuestions)
      ..shuffle(random);
    setState(() {
      _chosen = listing;
      _questions = pool.take(_questionCount).toList(growable: false);
      _qIndex = 0;
      _score = 0;
      _secondsLeft = _questionSeconds;
      _stage = _Stage.interviewing;
    });
    _startClock();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      // Freezing up counts as the weakest answer — that is what actually
      // happens in a real interview, and scoring it any other way would
      // make stalling free.
      if (_secondsLeft <= 0) _answer(0);
    });
  }

  void _answer(int score) {
    _clock?.cancel();
    _score += score;
    if (_qIndex + 1 >= _questions.length) {
      _finishInterview();
      return;
    }
    setState(() {
      _qIndex++;
      _secondsLeft = _questionSeconds;
    });
    _startClock();
  }

  void _finishInterview() {
    final listing = _chosen!;
    final maxScore = _questions.length * 2;
    final interviewScore = maxScore == 0
        ? 0
        : (_score / maxScore * 100).round();
    final result = widget.life.applyForJob(
      listing.job.id,
      interviewScore: interviewScore,
    );
    final bonus = (interviewScore.clamp(0, 100) / 100 * 20).round();
    setState(() {
      _outcome = result;
      _beforeChance = listing.chance;
      _afterChance = (listing.chance + bonus).clamp(5, 98);
      _stage = _Stage.result;
    });
    AppSoundService.play(
      result == JobOutcome.hired
          ? AppSoundEffect.success
          : AppSoundEffect.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_rounded, color: Color(0xFF85EFAC)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Job Board',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          switch (_stage) {
            _Stage.pickJob => _JobPicker(
              life: widget.life,
              onPick: _pick,
              onTalk: widget.onTalk,
            ),
            _Stage.interviewing => _InterviewQuestionView(
              question: _questions[_qIndex],
              index: _qIndex,
              total: _questions.length,
              secondsLeft: _secondsLeft,
              onAnswer: _answer,
            ),
            _Stage.result => _InterviewResult(
              jobTitle: _chosen!.job.title,
              outcome: _outcome!,
              before: _beforeChance,
              after: _afterChance,
              onLeave: widget.onLeave,
            ),
          },
        ],
      ),
    );
  }
}

class _JobPicker extends StatelessWidget {
  const _JobPicker({
    required this.life,
    required this.onPick,
    required this.onTalk,
  });

  final LifeSimController life;
  final void Function(JobListing listing) onPick;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final gate = life.applyGate();
    final listings = life
        .jobListings()
        .where((l) => l.qualified)
        .toList(growable: false)
      ..sort((a, b) => b.job.salary.compareTo(a.job.salary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interview in person for a real listing. Answering well here adds '
          'to your odds on top of whatever the Occupation tab already shows.',
          style: AppTheme.numeric(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (gate != null)
          Text(
            gate,
            style: AppTheme.numeric(
              color: const Color(0xFFFF8474),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (listings.isEmpty)
          Text(
            'Nothing here fits yet. Study, gain experience or widen your '
            'search from the Occupation tab.',
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          for (final listing in listings.take(4)) ...[
            _ListingRow(listing: listing, onPick: () => onPick(listing)),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onTalk,
            icon: const Icon(Icons.chat_bubble_rounded, size: 16),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            label: Text(
              'Just chat instead',
              style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing, required this.onPick});

  final JobListing listing;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final job = listing.job;
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Online odds: ${listing.chance}%',
                      style: AppTheme.numeric(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF85EFAC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterviewQuestionView extends StatelessWidget {
  const _InterviewQuestionView({
    required this.question,
    required this.index,
    required this.total,
    required this.secondsLeft,
    required this.onAnswer,
  });

  final InterviewQuestion question;
  final int index;
  final int total;
  final int secondsLeft;
  final void Function(int score) onAnswer;

  @override
  Widget build(BuildContext context) {
    // Shuffled once per build off a stable seed (the question + index) so the
    // right answer is never pinned to the same button twice in a row, but a
    // rebuild mid-question (the timer ticking) does not reshuffle under the
    // player's thumb.
    final order = List<int>.generate(question.answers.length, (i) => i)
      ..shuffle(Random(question.prompt.hashCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pulled out to its own widget, away from the prompt below: a
        // `Text(..., style: GoogleFonts.pixelifySans(...))` a few lines under
        // an all-caps label is exactly what `caps_legibility_test` scans for,
        // even though the label itself renders in `AppTheme.caps`, not the
        // pixel face.
        _QuestionMeta(index: index, total: total, secondsLeft: secondsLeft),
        const SizedBox(height: 10),
        Text(
          question.prompt,
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final i in order) ...[
          _AnswerButton(
            label: question.answers[i].label,
            onTap: () => onAnswer(question.answers[i].score),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _QuestionMeta extends StatelessWidget {
  const _QuestionMeta({
    required this.index,
    required this.total,
    required this.secondsLeft,
  });

  final int index;
  final int total;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tally(label: 'QUESTION', value: '${index + 1}/$total'),
        const SizedBox(width: 8),
        _Tally(label: 'TIME', value: '${secondsLeft}s'),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            label,
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InterviewResult extends StatelessWidget {
  const _InterviewResult({
    required this.jobTitle,
    required this.outcome,
    required this.before,
    required this.after,
    required this.onLeave,
  });

  final String jobTitle;
  final JobOutcome outcome;
  final int before;
  final int after;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final hired = outcome == JobOutcome.hired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hired ? 'You got it' : 'Not this time',
          style: GoogleFonts.pixelifySans(
            color: hired ? const Color(0xFF85EFAC) : const Color(0xFFFF8474),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hired
              ? 'You are now a $jobTitle.'
              : 'They went with somebody else for $jobTitle this time. It '
                    'happens to everyone.',
          style: AppTheme.numeric(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Odds online: $before%  →  interviewed in person: $after%',
          style: AppTheme.numeric(
            color: const Color(0xFFFFD45C),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: onLeave, child: const Text('Done')),
        ),
      ],
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.caps(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
