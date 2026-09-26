import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/age_scaled_note.dart';
import '../../../widgets_custom_lotties/map_backdrop.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson_extras.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson_sources.dart';
import '../../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../../models_Like_Skins_and_lessons_templates/progression_service.dart';
import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/confetti_burst.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'quiz_widgets.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.unit,
    required this.progressionService,
    this.quizAboveAgeConfirmed = false,
  });

  final Lesson lesson;
  final LessonUnit unit;
  final ProgressionService progressionService;

  /// Whether the player already clicked "Read it anyway" on the age-gate
  /// dialog in [LessonScreen] for this unit.
  ///
  /// That dialog already told them this unit assumes an older age group.
  /// Making them read the exact same warning a second time here would just
  /// be noise, so this only changes whether the quiz can be served at all —
  /// see [_quiz].
  final bool quizAboveAgeConfirmed;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _isCompleted = false;
  bool _isSaving = false;

  int _questionIndex = 0;
  int? _selectedOption;
  int _correctCount = 0;

  /// Questions answered wrong this run, kept so the results screen can show
  /// exactly what to revisit instead of only a score.
  final List<QuizQuestion> _missed = <QuizQuestion>[];

  /// Assessment questions for this node, empty for reading lessons.
  ///
  /// Filtered to the player's age band. The bank spans Flesch-Kincaid reading
  /// grades -2.4 to 18.4 and was previously served identically to everybody,
  /// so a six-year-old met questions written for an adult and vice versa.
  ///
  /// [widget.quizAboveAgeConfirmed] skips that filtering entirely: the player
  /// already saw and dismissed the "written for an older age group" dialog in
  /// [LessonScreen] to get here, so the quiz for this unit should match what
  /// they were just warned about and agreed to read, not go silently empty on
  /// top of it. See [ageAppropriateQuestions].
  late final List<QuizQuestion> _quiz = widget.quizAboveAgeConfirmed
      ? quizFor(widget.lesson.id)
      : ageAppropriateQuestions(
          quizFor(widget.lesson.id),
          context.read<UserStatsController>().stats.ageBand,
        );

  Future<void> _completeLesson({List<QuizQuestion> quiz = const []}) async {
    if (_isSaving) {
      return;
    }

    if (_isCompleted) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    widget.progressionService.completeLesson(widget.lesson.id);

    final hasQuiz = quiz.isNotEmpty;
    final bonusXp = hasQuiz ? _correctCount * 2 : 0;
    final xpEarned = 12 + bonusXp;
    final goldEarned = 50 + (hasQuiz ? _correctCount * 5 : 0);

    await context
        .read<UserStatsController>()
        .completeLessonProgress(
          lessonId: widget.lesson.id,
          lessonTitle: widget.lesson.title,
          xpEarned: xpEarned,
          literacyPointsEarned: 20,
          goldEarned: goldEarned,
          quizCorrect: hasQuiz ? _correctCount : null,
          quizTotal: hasQuiz ? quiz.length : null,
          missedSkills: _missed.map((question) => question.skillId),
        );

    if (!mounted) {
      return;
    }

    // Unit 6 pays out real gold and tradeable shares — the point is that
    // finishing the trading lessons hands you something to actually trade on
    // the Market Board rather than just XP.
    final payout = kLessonPayouts[widget.lesson.id];
    if (payout != null) {
      await context.read<UserStatsController>().applyChallengePayload({
        'gold_earned': payout.gold,
        'shares_earned': payout.shares,
        'title': 'Academy: ${widget.lesson.title}',
        'description': payout.blurb,
      });

      if (!mounted) {
        return;
      }
    }

    setState(() {
      _isCompleted = true;
      _isSaving = false;
    });

    final String rewardsText = '+$xpEarned XP, +$goldEarned Gold';

    // No sync status on the end of this.
    //
    // `result.message` is `SyncState.message` — "Added to your account.",
    // and before that "Saved to Supabase." A reward toast is the one moment
    // the player is being told what they just earned, and ending it with a
    // note about which server the row landed on is both noise and a detail
    // no ten-year-old asked about. Where a save genuinely *fails* it is worth
    // saying, and that is `CloudSyncBanner`'s job — a persistent warning on
    // the Profile screen rather than a clause in a 2-second popup that is
    // there whether anything went wrong or not.
    GameToast.show(
      context,
      title: 'Lesson complete',
      message: hasQuiz
          ? 'Scored $_correctCount/${quiz.length}. Earned $rewardsText!'
          : '${widget.lesson.title} saved. Earned $rewardsText!',
      icon: Icons.school_rounded,
      accent: const Color(0xFF2F9E68),
      soundEffect: AppSoundEffect.celebration,
    );

    if (payout != null) {
      GameToast.show(
        context,
        title: 'Payout unlocked',
        message: payout.blurb,
        icon: Icons.savings_rounded,
        accent: const Color(0xFFFFD45C),
      );
    }
  }

  void _selectOption(QuizQuestion question, int optionIndex) {
    if (_selectedOption != null) {
      return;
    }
    final isCorrect = optionIndex == question.correctIndex;
    setState(() {
      _selectedOption = optionIndex;
      if (isCorrect) {
        _correctCount++;
      } else {
        _missed.add(question);
      }
    });
    AppSoundService.play(
      isCorrect ? AppSoundEffect.success : AppSoundEffect.error,
    );
  }

  void _nextQuestion() {
    final justFinished = _questionIndex + 1 >= _quiz.length;
    setState(() {
      _questionIndex++;
      _selectedOption = null;
    });
    // 5/7 or better (~70%+), same bar a player would call "a good run" —
    // fires once, right as the results card appears, not on every rebuild.
    if (justFinished &&
        _quiz.isNotEmpty &&
        _correctCount / _quiz.length >= 0.7) {
      ConfettiBurst.show(context);
    }
  }

  /// The lesson's own sections plus any [kLessonDeepDives] written for it.
  ///
  /// Merged here rather than folded into `_lessonLibrary` because the library
  /// is a 1,700-line `const` map in this file: adding depth to 53 lessons by
  /// editing it in place produces a diff nobody can review, and the extra
  /// passages read better as content in a content file.
  List<_LessonSection> _sectionsFor(_LessonContent content) => <_LessonSection>[
    ...content.sections,
    for (final dive in kLessonDeepDives[widget.lesson.id] ?? const <DeepDive>[])
      _LessonSection(title: dive.title, content: dive.content),
  ];

  _LessonContent _getLessonContent() {
    final custom = _lessonLibrary[widget.lesson.id];
    if (custom != null) {
      return custom;
    }

    return _LessonContent(
      icon: switch (widget.lesson.type) {
        LessonNodeType.lesson => Icons.crop_square_rounded,
        LessonNodeType.quiz => Icons.bolt_rounded,
        LessonNodeType.unitTest => Icons.star_rounded,
      },
      sections: [
        _LessonSection(
          title: widget.lesson.title,
          content: widget.lesson.type == LessonNodeType.quiz
              ? 'This quick quiz checks how well the ideas from the unit are sticking before you move on.'
              : 'This unit test brings the key ideas together so you can confirm your understanding before the next unit.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _getLessonContent();
    final quiz = _quiz;
    final inQuizResults = quiz.isNotEmpty && _questionIndex >= quiz.length;

    return Scaffold(
      backgroundColor: AppTheme.panel,
      appBar: AppBar(
        backgroundColor: AppTheme.panel,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.lesson.title,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          // Reading, not decorative: the lesson body and the quiz options
          // are laid straight onto this. See [MapBackdrop] for why the fix
          // was a blurred copy of the map rather than a darker scrim.
          const MapBackdrop(style: MapBackdropStyle.reading),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Text(
                        '${widget.unit.title} > ${widget.lesson.title}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LessonOverviewCard(
                        icon: content.icon,
                        lessonTitle: widget.lesson.title,
                        estimatedMinutes: widget.lesson.estimatedMinutes,
                      ),
                      // `_quiz` is already `ageAppropriateQuestions(...)`, so
                      // two players on the same lesson are answering
                      // different questions. Saying so is the difference
                      // between a system that works and one anybody can see
                      // working.
                      if (quiz.isNotEmpty && widget.quizAboveAgeConfirmed)
                        const _AboveAgeQuizNote(margin: EdgeInsets.only(top: 12))
                      else if (quiz.isNotEmpty)
                        const AgeScaledNote(
                          what: 'Questions',
                          margin: EdgeInsets.only(top: 12),
                        ),
                      const SizedBox(height: 24),
                      if (quiz.isEmpty && content.objectives.isNotEmpty) ...[
                        _ObjectivesCard(objectives: content.objectives),
                        const SizedBox(height: 8),
                      ],
                      if (quiz.isEmpty)
                        ..._sectionsFor(content).map(
                          (section) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: GoogleFonts.pixelifySans(
                                    color: const Color(0xFFF7FFFB),
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  section.content,
                                  style: GoogleFonts.quicksand(
                                    color: const Color(0xFFF7FFFB),
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (inQuizResults)
                        QuizResultsCard(
                          correct: _correctCount,
                          total: quiz.length,
                          missed: _missed,
                        )
                      else
                        QuizQuestionCard(
                          questionNumber: _questionIndex + 1,
                          totalQuestions: quiz.length,
                          question: quiz[_questionIndex],
                          selectedOption: _selectedOption,
                          onSelect: (optionIndex) =>
                              _selectOption(quiz[_questionIndex], optionIndex),
                        ),
                      if (quiz.isEmpty && content.workedExample != null) ...[
                        const SizedBox(height: 20),
                        _WorkedExampleCard(
                          example: content.workedExample!,
                          stage: context.select<UserStatsController, LifeStage>(
                            (controller) => controller.stats.lifeStage,
                          ),
                        ),
                      ],
                      if (quiz.isEmpty && content.keyTerms.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _KeyTermsCard(terms: content.keyTerms),
                      ],
                      if (quiz.isEmpty && content.takeaway != null) ...[
                        const SizedBox(height: 14),
                        _TakeawayCard(text: content.takeaway!),
                      ],
                      if (quiz.isEmpty) ...[
                        const SizedBox(height: 14),
                        _SourcesCard(lessonId: widget.lesson.id),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1D17),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: _buildActionButton(quiz, inQuizResults),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(List<QuizQuestion> quiz, bool inQuizResults) {
    if (quiz.isEmpty || inQuizResults) {
      return FilledButton(
        onPressed: () => _completeLesson(quiz: quiz),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2F9E68),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              _isCompleted
                  ? 'Return to Units'
                  : _isSaving
                  ? 'Saving Progress...'
                  : 'Complete Lesson',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedOption == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Tap an answer to continue',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isLastQuestion = _questionIndex == quiz.length - 1;
    return FilledButton(
      onPressed: _nextQuestion,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFFD45C),
        foregroundColor: const Color(0xFF3C2B00),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(
        isLastQuestion ? 'See Results' : 'Next Question',
        style: GoogleFonts.pixelifySans(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// Reminder shown on a quiz the player already agreed to take above their
/// usual age band, via the "Read it anyway" dialog in [LessonScreen].
///
/// That dialog is the actual warning; this is just a quiet echo of it inside
/// the quiz itself, so scrolling back up mid-quiz still explains why the
/// questions look different from usual rather than looking unexplained.
class _AboveAgeQuizNote extends StatelessWidget {
  const _AboveAgeQuizNote({this.margin = EdgeInsets.zero});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 13,
            color: const Color(0xFFFFB84D).withValues(alpha: 0.85),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'These questions cover an older age group — you chose to try them anyway.',
              style: GoogleFonts.quicksand(
                color: const Color(0xFFFFB84D).withValues(alpha: 0.9),
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonOverviewCard extends StatelessWidget {
  const _LessonOverviewCard({
    required this.icon,
    required this.lessonTitle,
    required this.estimatedMinutes,
  });

  final IconData icon;
  final String lessonTitle;
  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 420;

          final leading = Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF85EFAC)),
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessonTitle,
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFFF7FFFB),
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$estimatedMinutes min lesson',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [leading, const SizedBox(height: 16), copy],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _ObjectivesCard extends StatelessWidget {
  const _ObjectivesCard({required this.objectives});

  final List<String> objectives;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF85EFAC).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT YOU\'LL LEARN',
            style: AppTheme.caps(
              color: const Color(0xFFB8F5D1),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          for (final objective in objectives) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF85EFAC),
                  size: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    objective,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WorkedExampleCard extends StatelessWidget {
  const _WorkedExampleCard({required this.example, required this.stage});

  final WorkedExample example;
  final LifeStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF69C6FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF69C6FF).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WORKED EXAMPLE',
                style: AppTheme.caps(
                  color: const Color(0xFF9BD9FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                switch (stage) {
                  LifeStage.allowance => 'allowance scale',
                  LifeStage.firstJob => 'part-time scale',
                  LifeStage.independent => 'living-alone scale',
                },
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            example.render(stage),
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyTermsCard extends StatelessWidget {
  const _KeyTermsCard({required this.terms});

  final Map<String, String> terms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KEY TERMS',
            style: AppTheme.caps(
              color: const Color(0xFFFFD45C),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in terms.entries) ...[
            RichText(
              text: TextSpan(
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '${entry.key}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF7FFFB),
                    ),
                  ),
                  TextSpan(text: entry.value),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TakeawayCard extends StatelessWidget {
  const _TakeawayCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD45C).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD45C).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD45C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where this lesson's facts came from, with links.
///
/// **Why every lesson has one.** The app makes claims about interest, credit,
/// pay and tax to an audience that includes children, and "says who?" is a
/// fair question — the most useful habit a money app can model is *check the
/// source*. It also matters that these are primary publishers (federal
/// agencies and the regulators' own education arms) rather than a bank's blog:
/// citing a company that sells the products being explained would undercut
/// the point of citing anything.
///
/// Renders nothing at all when a lesson has no citations rather than an empty
/// heading — but `test/lesson_sources_test.dart` fails the build in that case,
/// so the empty state should never ship.
class _SourcesCard extends StatelessWidget {
  const _SourcesCard({required this.lessonId});

  final String lessonId;

  Future<void> _open(BuildContext context, LessonSource source) async {
    final uri = Uri.parse(source.url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      // A device with no browser, or a link the platform refuses. Showing the
      // URL is more useful than a failure toast: it can still be typed or
      // copied, which is the whole point of publishing a citation.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(source.url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = resolveSources(
      kLessonCitations[lessonId] ?? const <String>[],
    );
    if (sources.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 17,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Sources',
                style: GoogleFonts.pixelifySans(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Checked against the agencies that publish the rules.',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final source in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _open(context, source),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 15,
                        color: Color(0xFF69C6FF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.publisher,
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFF9CDBFF),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              source.title,
                              style: GoogleFonts.quicksand(
                                color: AppTheme.textMuted,
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Content model + library
// ---------------------------------------------------------------------

class _LessonContent {
  const _LessonContent({
    required this.icon,
    this.sections = const [],
    this.objectives = const [],
    this.keyTerms = const {},
    this.takeaway,
    this.workedExample,
  });

  final IconData icon;
  final List<_LessonSection> sections;

  /// "What you'll learn" bullets shown before the content.
  final List<String> objectives;

  /// Vocabulary the lesson introduces, term -> definition.
  final Map<String, String> keyTerms;

  /// One-sentence summary shown at the end of the lesson.
  final String? takeaway;

  /// Builds a worked example using amounts scaled to the reader's life stage,
  /// so a 13-year-old sees allowance-sized numbers and an adult sees rent-sized
  /// ones. Null for lessons where no money amount is involved.
  final WorkedExample? workedExample;
}

/// A money example whose figures are scaled to the reader's [LifeStage].
@immutable
class WorkedExample {
  const WorkedExample(this.build);

  /// Receives a baseline (first-job) monthly income already scaled for the
  /// reader, plus the stage itself for wording.
  final String Function(int monthlyIncome, LifeStage stage) build;

  /// Baseline first-job monthly take-home the examples are written against.
  static const int baselineIncome = 400;

  static int incomeFor(LifeStage stage) =>
      (baselineIncome * stage.exampleScale).round();

  String render(LifeStage stage) => build(incomeFor(stage), stage);
}

// Worked examples. Each receives a monthly income already scaled to the
// reader's life stage, so the same lesson quotes allowance-sized numbers to a
// 13-year-old and rent-sized ones to an adult.

String _fiftyThirtyTwentyExample(int income, LifeStage stage) {
  final needs = (income * 0.5).round();
  final wants = (income * 0.3).round();
  final saving = (income * 0.2).round();
  return 'Say $income dollars reaches you this month. The 50/30/20 split puts '
      '$needs on needs, $wants on wants, and $saving into savings or debt '
      'payoff — decided before any of it moves.';
}

String _payYourselfFirstExample(int income, LifeStage stage) {
  final saved = (income * 0.15).round();
  final rest = income - saved;
  return 'On a $income dollar ${stage.incomeNoun}, moving 15 percent out first '
      'means $saved goes straight to savings and you budget the remaining '
      '$rest. Over a year that is ${saved * 12} dollars you never had to '
      'find at the end of a month.';
}

String _sinkingFundExample(int income, LifeStage stage) {
  // Roughly a month and a half of income, spread over six months.
  final target = (income * 1.5).round();
  final monthly = (target / 6).round();
  return 'A $target dollar cost you know is six months away becomes $monthly a '
      'month starting now. The bill still costs the same — it just stops '
      'landing on one month all at once.';
}

String _savingsGoalExample(int income, LifeStage stage) {
  // 20% of monthly income, spread across ~4 weeks — the "savings" slice of
  // the 50/30/20 split from lesson_1, turned into a weekly number.
  final weeklySaving = ((income * 0.2) / 4).round();
  final target = (income * 0.75).round();
  final weeks = weeklySaving > 0 ? (target / weeklySaving).ceil() : 0;
  return 'Saving $weeklySaving a week toward a $target dollar goal takes about '
      '$weeks weeks. Written down like that, "I want this" becomes "I need '
      '$weeklySaving, $weeks more times."';
}

String _compoundingExample(int income, LifeStage stage) {
  final monthly = (income * 0.1).round();
  final yearOne = monthly * 12;
  // 7% annual growth, contributions monthly, compounded over 10 years.
  var balance = 0.0;
  for (var year = 0; year < 10; year++) {
    balance = (balance + (monthly * 12)) * 1.07;
  }
  return 'Investing $monthly a month adds up to $yearOne in year one. Left to '
      'grow at about 7 percent a year, ten years of those contributions is '
      'roughly ${balance.round()} dollars — and only ${monthly * 120} of that '
      'came out of your pocket.';
}

String _taxWithholdingExample(int income, LifeStage stage) {
  final hourly = stage == LifeStage.allowance ? 12 : 18;
  final hours = stage == LifeStage.allowance ? 50 : 80;
  final gross = hourly * hours;
  final federal = (gross * 0.10).roundToDouble();
  final socialSecurity = gross * 0.062;
  final medicare = gross * 0.0145;
  final net = gross - federal - socialSecurity - medicare;
  return 'Sam earns $hourly dollars an hour for $hours hours, so gross pay is '
      '${gross.toStringAsFixed(0)} dollars. If 10 percent is withheld for '
      'federal income tax, ${federal.toStringAsFixed(2)} dollars comes out. '
      'Social Security at 6.2 percent is ${socialSecurity.toStringAsFixed(2)} '
      'dollars, and Medicare at 1.45 percent is '
      '${medicare.toStringAsFixed(2)} dollars. Take-home pay is about '
      '${net.toStringAsFixed(2)} dollars.';
}

class _LessonSection {
  const _LessonSection({required this.title, required this.content});

  final String title;
  final String content;
}

/// A one-off reward for finishing a specific lesson.
@immutable
class LessonPayout {
  const LessonPayout({
    required this.gold,
    required this.shares,
    required this.blurb,
  });

  final int gold;

  /// Bare ticker → share count. Granted through
  /// `UserStatsController.applyChallengePayload`'s `shares_earned` key, so
  /// these land as real Market Board holdings you can sell.
  final Map<String, double> shares;
  final String blurb;
}

/// Unit 6 only. Deliberately small amounts: enough to have something real to
/// trade with and feel the market move, not enough to skip the game's
/// economy. Each lesson pays once — `_isCompleted` guards a re-award.
const Map<String, LessonPayout> kLessonPayouts = <String, LessonPayout>{
  'lesson_26': LessonPayout(
    gold: 500,
    shares: <String, double>{'SPY': 0.25},
    blurb: '+500 gold and a quarter share of SPY to start your portfolio.',
  ),
  'lesson_27': LessonPayout(
    gold: 400,
    shares: <String, double>{},
    blurb: '+400 gold for learning what actually moves a price.',
  ),
  'lesson_28': LessonPayout(
    gold: 600,
    shares: <String, double>{'SPY': 0.25, 'KO': 0.5},
    blurb: '+600 gold, plus SPY and KO shares — your first diversified mix.',
  ),
  'lesson_29': LessonPayout(
    gold: 450,
    shares: <String, double>{},
    blurb: '+450 gold for understanding what the spread quietly costs you.',
  ),
  'lesson_30': LessonPayout(
    gold: 800,
    shares: <String, double>{'AAPL': 0.2},
    blurb: '+800 gold and a slice of AAPL for going the distance.',
  ),
  'test_6': LessonPayout(
    gold: 1500,
    shares: <String, double>{'SPY': 0.5, 'MSFT': 0.2},
    blurb: 'Unit cleared: +1500 gold, plus SPY and MSFT shares.',
  ),
};

const Map<String, _LessonContent> _lessonLibrary = <String, _LessonContent>{
  // ---------------- Unit 10: Money Is Real (ages 4-6) ----------------
  'lesson_46': _LessonContent(
    icon: Icons.paid_rounded,
    objectives: [
      'Say what money is used for',
      'Recognize that coins and bills stand in for value',
    ],
    keyTerms: {
      'Money': 'coins and bills people trade for things they need or want',
    },
    takeaway:
        'Money is something people trade for things — that\'s its whole job.',
    sections: [
      _LessonSection(
        title: 'Money is for trading',
        content:
            'Money is coins and bills. People use it to trade for things '
            'they need, like food, or things they want, like a toy.',
      ),
      _LessonSection(
        title: 'Where money comes from',
        content:
            'Grown-ups usually earn money by working. Sometimes money is a '
            'gift, like on a birthday.',
      ),
    ],
  ),
  'lesson_47': _LessonContent(
    icon: Icons.storefront_rounded,
    objectives: [
      'Explain that most things at a store cost money',
      'Practice the idea of paying for something',
    ],
    keyTerms: {'Pay': 'giving money to get something in return'},
    takeaway:
        'Almost everything at a store costs money — that\'s how buying works.',
    sections: [
      _LessonSection(
        title: 'Everything has a price',
        content:
            'Toys, snacks, and clothes at a store all cost money. The price '
            'is how much money you need to pay to take it home.',
      ),
      _LessonSection(
        title: 'Not everything costs money',
        content:
            'Some things are free, like sunshine, a hug, or playing outside. '
            'Money is only for things people are selling.',
      ),
    ],
  ),
  'lesson_48': _LessonContent(
    icon: Icons.savings_rounded,
    objectives: [
      'Explain what saving means',
      'Describe how a piggy bank is used',
    ],
    keyTerms: {'Saving': 'keeping money instead of spending it right away'},
    takeaway:
        'Saving just means keeping money for later instead of spending it today.',
    sections: [
      _LessonSection(
        title: 'What saving means',
        content:
            'Saving is putting money away instead of spending it right now, '
            'so it is still there later.',
      ),
      _LessonSection(
        title: 'A piggy bank helps',
        content:
            'A piggy bank is a safe place to keep coins you are saving. '
            'Every coin you add makes your savings a little bigger.',
      ),
    ],
  ),
  // ---------------- Unit 11: Saving and Spending (ages 7-10) ----------------
  'lesson_49': _LessonContent(
    icon: Icons.handyman_rounded,
    objectives: [
      'Explain what an allowance is',
      'Name a way kids can earn money',
    ],
    keyTerms: {
      'Allowance': 'money a kid gets regularly, sometimes for doing chores',
      'Earn': 'get money in exchange for doing something',
    },
    takeaway: 'Earning means getting money for doing something — like a chore.',
    sections: [
      _LessonSection(
        title: 'What is an allowance?',
        content:
            'An allowance is money a kid gets on a regular basis. Some '
            'families tie it to chores, others give a set amount just for '
            'helping out.',
      ),
      _LessonSection(
        title: 'Earning vs. getting a gift',
        content:
            'Earning money means doing something to get it, like washing '
            'dishes. A birthday gift is money too, but it is not earned.',
      ),
    ],
  ),
  'lesson_50': _LessonContent(
    icon: Icons.balance_rounded,
    objectives: [
      'Tell a need from a want',
      'Explain why the difference matters',
    ],
    keyTerms: {
      'Need': 'something you really cannot do without',
      'Want': 'something nice to have, but you could live without it',
    },
    takeaway:
        'A need is something you can\'t really do without — a want is everything else.',
    sections: [
      _LessonSection(
        title: 'What makes something a need',
        content:
            'A need is something your day genuinely does not work without — '
            'food, a place to sleep, clothes that fit.',
      ),
      _LessonSection(
        title: 'What makes something a want',
        content:
            'A want is something fun or nice, but you could still get by '
            'without it, like a new video game.',
      ),
      _LessonSection(
        title: 'Why it matters',
        content:
            'When you cannot buy everything, knowing needs from wants helps '
            'you decide what matters most first.',
      ),
    ],
  ),
  'lesson_51': _LessonContent(
    icon: Icons.checklist_rounded,
    objectives: [
      'Describe what a simple money plan looks like',
      'Practice splitting money between saving and spending',
    ],
    keyTerms: {
      'Plan': 'deciding what to do with your money before you spend any of it',
    },
    takeaway:
        'A simple plan means deciding how much to save before you spend anything.',
    sections: [
      _LessonSection(
        title: 'Decide first, spend later',
        content:
            'A simple money plan just means deciding ahead of time how much '
            'you will save and how much you will spend — before you spend '
            'any of it.',
      ),
      _LessonSection(
        title: 'An example plan',
        content:
            'If you get \$10, you might decide to save \$4 and spend \$6. '
            'Any split works, as long as you decide it first.',
      ),
    ],
  ),
  'lesson_52': _LessonContent(
    icon: Icons.account_balance_rounded,
    objectives: [
      'Explain why banks exist',
      'Describe what a bank does with money kept there',
    ],
    keyTerms: {'Bank': 'a place built to keep people\'s money safe'},
    takeaway:
        'A bank\'s main job is keeping money safer than it would be at home.',
    sections: [
      _LessonSection(
        title: 'Why banks exist',
        content:
            'A bank is a place built to keep money safe. It is much safer '
            'than leaving a big pile of cash lying around the house.',
      ),
      _LessonSection(
        title: 'What a bank does',
        content:
            'When you keep money in a bank, it is still yours — the bank '
            'just holds onto it and keeps track of how much you have.',
      ),
    ],
  ),
  'lesson_1': _LessonContent(
    icon: Icons.account_balance_wallet_rounded,
    workedExample: WorkedExample(_fiftyThirtyTwentyExample),
    objectives: [
      'Define what a budget is and what it is for',
      'Explain why planning beats reacting with money',
      'Apply the 50/30/20 rule to a simple income',
    ],
    keyTerms: {
      'Budget': 'a plan for how your money will be used before you spend it',
      '50/30/20 rule':
          'a starting framework: 50% needs, 30% wants, 20% savings or debt payoff',
    },
    takeaway:
        'A budget is not a punishment — it is a plan that puts you in charge of every dollar before it leaves.',
    sections: [
      _LessonSection(
        title: 'What is budgeting?',
        content:
            'Budgeting is a plan for how your money will be used before you spend it. It helps you choose what matters most instead of reacting to every expense.',
      ),
      _LessonSection(
        title: 'Why it matters',
        content:
            'A budget gives you control, protects your goals, and makes tradeoffs easier because you can see what every dollar is doing.',
      ),
      _LessonSection(
        title: 'A simple starting rule',
        content:
            'Try the 50/30/20 rule: 50% for needs, 30% for wants, and 20% for savings or debt payoff. It is not perfect for everyone, but it is a strong first framework.',
      ),
    ],
  ),
  'lesson_2': _LessonContent(
    icon: Icons.payments_rounded,
    objectives: [
      'Distinguish fixed income from variable income',
      'Explain the difference between gross and net pay',
      'Choose the right income number to build a budget on',
    ],
    keyTerms: {
      'Gross income': 'total pay before taxes and deductions come out',
      'Net income': 'the take-home amount that actually reaches your account',
    },
    takeaway:
        'Always plan with net income — budgets built on gross pay promise money you never actually receive.',
    sections: [
      _LessonSection(
        title: 'Income comes first',
        content:
            'Your budget starts with money coming in. Fixed income is predictable, while variable income changes from paycheck to paycheck.',
      ),
      _LessonSection(
        title: 'Gross vs net',
        content:
            'Use net income for planning. Gross income looks bigger, but net income reflects what actually reaches your account.',
      ),
    ],
  ),
  'lesson_3': _LessonContent(
    icon: Icons.shopping_bag_rounded,
    objectives: [
      'Track spending to reveal real habits and leaks',
      'Sort expenses into needs and wants confidently',
    ],
    keyTerms: {
      'Need': 'an essential cost that keeps life running, like rent or food',
      'Want': 'a nice-to-have that should fit after essentials are covered',
    },
    takeaway:
        'Your bank statement tells the truth about your habits — read it before you plan.',
    sections: [
      _LessonSection(
        title: 'Track spending patterns',
        content:
            'Expenses usually reveal habits faster than intentions do. Looking at recent spending helps you find recurring leaks and spot your essentials.',
      ),
      _LessonSection(
        title: 'Needs and wants',
        content:
            'Needs keep life running. Wants can still matter, but they should fit after the essentials and savings plan are covered.',
      ),
    ],
  ),
  'lesson_4': _LessonContent(
    icon: Icons.savings_rounded,
    workedExample: WorkedExample(_payYourselfFirstExample),
    objectives: [
      'Treat saving as a required bill, not a leftover',
      'Explain why consistency beats occasional big efforts',
    ],
    keyTerms: {
      'Pay yourself first':
          'moving money to savings before any other spending happens',
    },
    takeaway:
        'Small automatic saving repeated weekly beats big saving done occasionally.',
    sections: [
      _LessonSection(
        title: 'Pay yourself first',
        content:
            'Saving works best when it is treated like a required bill instead of whatever is left over at the end of the month.',
      ),
      _LessonSection(
        title: 'Start smaller than feels impressive',
        content:
            'Consistency beats intensity. A small automatic transfer repeated every week usually wins over occasional big efforts.',
      ),
    ],
  ),
  'lesson_savings_goal': _LessonContent(
    icon: Icons.flag_rounded,
    workedExample: WorkedExample(_savingsGoalExample),
    objectives: [
      'Turn a savings goal into a specific number and deadline',
      'Divide a goal into a weekly savings target',
      'Adjust a goal that feels too slow instead of giving up on it',
    ],
    keyTerms: {
      'Savings goal':
          'a specific amount you are saving toward, with a target and a rough deadline',
      'Time-to-goal':
          'how many weeks or months it takes to reach a goal at a given savings rate',
    },
    takeaway:
        'A goal without a number and a timeline is just a wish — divide the price by what you can save each week and it becomes a plan.',
    sections: [
      _LessonSection(
        title: 'Name the number',
        content:
            '"I want to save up for something" is not a plan yet. Write down the exact price and roughly when you want it by — that is what turns a wish into a goal.',
      ),
      _LessonSection(
        title: 'Divide it into weeks',
        content:
            'Take the price and divide it by how much you can realistically save each week. That gives you a real timeline instead of a guess — and a weekly number small enough to actually hit.',
      ),
      _LessonSection(
        title: 'If it feels too slow',
        content:
            'A timeline that feels discouraging has two honest fixes: save a bit more each week, or lower the target. Both beat quietly giving up on the goal.',
      ),
    ],
  ),
  'lesson_5': _LessonContent(
    icon: Icons.pie_chart_rounded,
    objectives: [
      'Assemble a complete budget from income, costs, and goals',
      'Compare the plan against take-home pay and adjust',
      'Build a habit of reviewing the budget regularly',
    ],
    keyTerms: {
      'Fixed cost': 'an expense that stays the same each month, like rent',
      'Flexible spending':
          'costs you can adjust month to month, like eating out',
    },
    takeaway:
        'A budget is a living tool — build it once, then review and adjust it as life changes.',
    sections: [
      _LessonSection(
        title: 'Build the plan',
        content:
            'List income, fixed costs, flexible spending, savings goals, and debt payments in one place. Then compare the total against your take-home pay.',
      ),
      _LessonSection(
        title: 'Review regularly',
        content:
            'Budgets are living tools. Review them often and adjust after changes in income, bills, or priorities.',
      ),
    ],
  ),
  'lesson_6': _LessonContent(
    icon: Icons.credit_card_rounded,
    objectives: [
      'Explain what credit actually costs when a balance is carried',
      'Identify the habits that build a strong payment history',
      'Recognise why a credit limit is not a spending target',
    ],
    keyTerms: {
      'Credit':
          'borrowed money you use now and repay later, usually with interest',
      'APR':
          'the yearly cost of borrowing, so a higher APR means a carried balance grows faster',
      'Minimum payment':
          'the least you can pay to stay current — a floor, not a plan for clearing the balance',
      'Credit utilisation':
          'how much of your available limit you are using; lower generally looks better',
    },
    takeaway:
        'Credit is a tool for timing, not for extra money — anything you buy with it, you still pay for, plus interest if you carry it.',
    sections: [
      _LessonSection(
        title: 'Credit is borrowed trust',
        content:
            'Credit lets you use money now and repay it later. Used well, it builds options. Used carelessly, it becomes expensive debt.',
      ),
      _LessonSection(
        title: 'Healthy credit habits',
        content:
            'Pay on time, keep balances low, and avoid treating credit limits like spending targets.',
      ),
    ],
  ),
  'lesson_7': _LessonContent(
    icon: Icons.show_chart_rounded,
    objectives: [
      'Describe why investing suits long horizons and saving suits short ones',
      'Explain the link between expected return and risk',
      'Say what diversification does and does not protect you from',
    ],
    keyTerms: {
      'Return':
          'the gain or loss an investment produces, usually shown as a percentage',
      'Risk':
          'the uncertainty around that return, including the chance of loss',
      'Diversification':
          'spreading money across many investments so one bad outcome is not decisive',
      'Time horizon': 'how long until you need the money back',
    },
    takeaway:
        'Return and risk are two sides of the same coin — the honest question is not "how do I avoid risk?" but "how much can I carry, for how long?".',
    sections: [
      _LessonSection(
        title: 'Investing is long-term',
        content:
            'Investing gives your money a chance to grow faster than cash savings, but it works best over longer time horizons.',
      ),
      _LessonSection(
        title: 'Risk and return move together',
        content:
            'Higher return potential usually comes with more uncertainty. Diversification helps reduce the risk of any single investment going badly.',
      ),
    ],
  ),
  'lesson_8': _LessonContent(
    icon: Icons.account_balance_rounded,
    objectives: [
      'Tell the difference between a checking and a savings account',
      'Compare accounts on fees, access and tooling instead of branding',
      'Set up the alerts that prevent overdraft charges',
    ],
    keyTerms: {
      'Checking account': 'the account you spend from day to day',
      'Savings account':
          'a separate account for money you are deliberately not spending',
      'Overdraft fee':
          'a charge for spending past your balance — one of the most avoidable costs there is',
      'Direct deposit':
          'pay sent straight into your account, which is what makes payday automation possible',
    },
    takeaway:
        'The right account setup is the one that makes good habits automatic and bad surprises loud.',
    sections: [
      _LessonSection(
        title: 'Choose the right tools',
        content:
            'Checking accounts, savings accounts, alerts, and autopay features all support different money habits. The right setup reduces friction.',
      ),
      _LessonSection(
        title: 'Bank with intention',
        content:
            'Look at fees, digital tools, transfer speed, and customer support instead of picking an account only because it is nearby.',
      ),
    ],
  ),
  'lesson_9': _LessonContent(
    icon: Icons.warning_amber_rounded,
    objectives: [
      'Explain what an emergency fund is for and what it is not for',
      'Choose a starting target you can actually reach',
      'Decide where emergency money should live',
    ],
    keyTerms: {
      'Emergency fund':
          'money set aside so an unexpected cost does not become new debt',
      'Liquidity':
          'how quickly money can be turned into spendable cash without a penalty',
      'Starter fund':
          r'a first milestone — often $500 or one month of essentials — before building further',
    },
    takeaway:
        'An emergency fund is insurance for your budget, so reachability matters far more than the interest rate it earns.',
    sections: [
      _LessonSection(
        title: 'Emergencies will happen',
        content:
            'An emergency fund protects your budget from turning into new debt when life throws you a surprise.',
      ),
      _LessonSection(
        title: 'Accessible beats fancy',
        content:
            'Emergency money should stay easy to reach and separate from everyday spending so it is there when you need it.',
      ),
    ],
  ),
  'lesson_10': _LessonContent(
    icon: Icons.flag_rounded,
    objectives: [
      'Turn a vague intention into a goal you can check progress against',
      'Break a large target into a monthly amount',
      'Use milestones to keep long goals from feeling invisible',
    ],
    keyTerms: {
      'SMART goal':
          'specific, measurable, achievable, relevant and time-bound — the test a goal has to pass',
      'Milestone': 'a checkpoint along the way that proves the plan is working',
      'Target date': 'the deadline that turns a wish into a monthly number',
    },
    takeaway:
        r'"Save more" cannot be checked; "$600 by December, $50 a month" tells you every single month whether you are on track.',
    sections: [
      _LessonSection(
        title: 'Give money a destination',
        content:
            'Long-term goals turn abstract saving into something concrete. Good goals are specific, measurable, and tied to a timeline.',
      ),
      _LessonSection(
        title: 'Progress builds motivation',
        content:
            'Tracking milestones makes large goals feel real and keeps consistent habits from feeling invisible.',
      ),
    ],
  ),
  'lesson_11': _LessonContent(
    icon: Icons.workspace_premium_rounded,
    objectives: [
      'Explain why saving from leftovers rarely works',
      'Set a savings percentage and schedule it on payday',
      'Budget from what remains after saving, not before',
    ],
    keyTerms: {
      'Pay yourself first':
          'moving money to savings before any other spending happens',
      'Savings rate':
          'the share of take-home pay you save, expressed as a percentage',
      'Leftover saving':
          'the habit of saving whatever survives the month — unreliable because everything else competes with it first',
    },
    takeaway:
        'Saving survives a busy month only when it happens before the month starts spending.',
    sections: [
      _LessonSection(
        title: 'Save before spending',
        content:
            'Paying yourself first means moving money to savings before the rest of your spending choices happen. It reduces the temptation to save only whatever is left.',
      ),
      _LessonSection(
        title: 'Build it into your system',
        content:
            'When savings happen automatically on payday, discipline matters less because the decision is already made.',
      ),
    ],
  ),
  'lesson_12': _LessonContent(
    icon: Icons.inventory_2_rounded,
    workedExample: WorkedExample(_sinkingFundExample),
    objectives: [
      'Tell a sinking fund apart from an emergency fund',
      'Convert a known future cost into a monthly contribution',
      'Spot the recurring costs that keep ambushing your budget',
    ],
    keyTerms: {
      'Sinking fund': 'money saved gradually for a known, dated future cost',
      'Irregular expense':
          'a real cost that does not arrive monthly, like insurance or gifts',
      'Smoothing': 'spreading a lumpy cost across the months leading up to it',
    },
    takeaway:
        'A bill you knew about is not an emergency — sinking funds are what keep predictable costs out of your emergency fund.',
    sections: [
      _LessonSection(
        title: 'What is a sinking fund?',
        content:
            'A sinking fund is money set aside little by little for a known future cost like car repairs, school supplies, or holidays.',
      ),
      _LessonSection(
        title: 'Why it helps',
        content:
            'Instead of being surprised by expected expenses, you spread them out over time so they do not wreck your monthly budget.',
      ),
    ],
  ),
  'lesson_13': _LessonContent(
    icon: Icons.account_balance_wallet_outlined,
    objectives: [
      'Match an account type to how soon you need the money',
      'Read past a headline interest rate to the conditions attached',
      'Explain why access beats yield for short-horizon money',
    ],
    keyTerms: {
      'Interest rate': 'what the bank pays you for keeping money there',
      'APY':
          'the yearly rate including compounding, which makes two accounts genuinely comparable',
      'Minimum balance':
          'the amount you must keep in the account to avoid fees or keep the advertised rate',
      'Withdrawal penalty': 'the cost of taking money out earlier than agreed',
    },
    takeaway:
        'A great rate you cannot reach when you need it is worth nothing — pick the account by the job the money is doing.',
    sections: [
      _LessonSection(
        title: 'Savings accounts are tools',
        content:
            'Different accounts help with different goals. Emergency savings should be safe and easy to access, while longer-term money can focus more on earning interest.',
      ),
      _LessonSection(
        title: 'Compare the details',
        content:
            'Interest rate, fees, minimum balance rules, and transfer speed all matter when choosing where your savings should live.',
      ),
    ],
  ),
  'lesson_14': _LessonContent(
    icon: Icons.sync_alt_rounded,
    objectives: [
      'Identify which money decisions are worth automating',
      'Explain why automation beats willpower for recurring habits',
      'Schedule a review so automation does not drift out of date',
    ],
    keyTerms: {
      'Automatic transfer': 'a recurring move of money you set up once',
      'Autopay': 'scheduled bill payment, which protects your payment history',
      'Subscription creep':
          'recurring charges that outlive their usefulness because nobody is watching',
    },
    takeaway:
        'Automation removes friction in both directions — it protects good habits and hides dead subscriptions, so a periodic review is part of the system.',
    sections: [
      _LessonSection(
        title: 'Automation removes friction',
        content:
            'Automatic transfers, bill pay, and alerts reduce the number of money decisions you need to make manually every week.',
      ),
      _LessonSection(
        title: 'Good habits need visibility',
        content:
            'Automation works best when you still review it regularly, so your system keeps matching your goals and your income.',
      ),
    ],
  ),
  'lesson_15': _LessonContent(
    icon: Icons.calendar_month_rounded,
    objectives: [
      'List the irregular costs that a monthly budget usually misses',
      'Divide an annual total into a monthly line item',
      'Keep predictable costs from draining the emergency fund',
    ],
    keyTerms: {
      'Annualising':
          'adding up a cost across a year so you can divide it by twelve',
      'Buffer category':
          'a budget line for costs you know are coming but cannot date precisely',
    },
    takeaway:
        r'Costs like gifts, servicing and renewals are predictable in total even when they are unpredictable in timing — $720 a year is just $60 a month.',
    sections: [
      _LessonSection(
        title: 'Irregular costs are still real',
        content:
            'Expenses like annual subscriptions, gifts, medical visits, or school fees may not happen every month, but they still belong in your plan.',
      ),
      _LessonSection(
        title: 'Smooth the bumps',
        content:
            'Divide larger expected costs by the number of months until they arrive. That turns a sudden hit into a manageable monthly amount.',
      ),
    ],
  ),
  'lesson_16': _LessonContent(
    icon: Icons.trending_up_rounded,
    objectives: [
      'Explain how inflation erodes money that is not growing',
      'Say when investing is appropriate and when saving is',
      'Describe what you are being paid to accept when you invest',
    ],
    keyTerms: {
      'Inflation':
          'the general rise in prices, which shrinks what a fixed amount buys',
      'Purchasing power':
          'what your money can actually buy, rather than its face value',
      'Real return':
          'return after inflation — the only one that changes your life',
    },
    takeaway:
        'A balance that never falls still loses ground if prices rise faster than it grows, which is why long-horizon money is invested rather than parked.',
    sections: [
      _LessonSection(
        title: 'Investing grows future options',
        content:
            'People invest because cash savings alone often do not grow fast enough to outpace long-term goals or inflation.',
      ),
      _LessonSection(
        title: 'Time matters more than hype',
        content:
            'Starting earlier usually matters more than finding the perfect investment because growth has longer to compound.',
      ),
    ],
  ),
  'lesson_17': _LessonContent(
    icon: Icons.scatter_plot_rounded,
    objectives: [
      'Explain what diversification protects against and what it does not',
      'Recognise concentrated risk in a portfolio',
      'Match the amount of risk you take to your time horizon',
    ],
    keyTerms: {
      'Concentration risk':
          'having so much in one place that a single outcome decides everything',
      'Volatility': 'how sharply a value swings up and down along the way',
      'Asset allocation':
          'how money is split between different kinds of investment',
    },
    takeaway:
        'Diversification does not stop you losing money — it stops any one failure being the whole story.',
    sections: [
      _LessonSection(
        title: 'Risk is normal',
        content:
            'Investments move up and down. Risk is not something to erase completely, but something to understand and manage.',
      ),
      _LessonSection(
        title: 'Diversification spreads exposure',
        content:
            'Owning different assets lowers the damage one bad performer can do to your whole portfolio.',
      ),
    ],
  ),
  'lesson_18': _LessonContent(
    icon: Icons.stacked_line_chart_rounded,
    objectives: [
      'Tell the difference between owning and lending',
      'Describe what a fund holds and why beginners often start there',
      'Explain why low fees matter over long horizons',
    ],
    keyTerms: {
      'Stock': 'part-ownership of a company, with no guaranteed payment',
      'Bond': 'a loan to a company or government, repaid with interest',
      'Index fund':
          'a fund that buys a wide slice of the market at low cost rather than picking winners',
      'Expense ratio':
          'the yearly fee a fund charges, quietly subtracted from your return',
    },
    takeaway:
        'Stocks own, bonds lend, funds bundle — and the fee you pay for the bundle compounds against you just as surely as returns compound for you.',
    sections: [
      _LessonSection(
        title: 'Know the categories',
        content:
            'Stocks represent ownership, bonds are loans, and funds combine many investments together into one basket.',
      ),
      _LessonSection(
        title: 'Use the right tool for the goal',
        content:
            'The best choice depends on your time horizon, comfort with risk, and how hands-on you want to be.',
      ),
    ],
  ),
  'lesson_19': _LessonContent(
    icon: Icons.auto_graph_rounded,
    workedExample: WorkedExample(_compoundingExample),
    objectives: [
      'Explain how compounding differs from simple growth',
      'Show why starting earlier beats contributing more later',
      'Estimate growth over several years without a calculator',
    ],
    keyTerms: {
      'Compound growth':
          'growth that earns returns on previous returns, not just the original amount',
      'Principal': 'the original amount you put in',
      'Rule of 72':
          'divide 72 by the yearly return to estimate the years it takes money to double',
    },
    takeaway:
        'Compounding is unremarkable in year two and overwhelming in year thirty — which is why the most valuable thing a young investor has is time, not money.',
    sections: [
      _LessonSection(
        title: 'Growth can build on growth',
        content:
            'Compound growth happens when your money earns returns and those returns begin earning returns too.',
      ),
      _LessonSection(
        title: 'Consistency multiplies the effect',
        content:
            'Regular contributions plus time create much stronger results than trying to time the market perfectly.',
      ),
    ],
  ),
  'lesson_20': _LessonContent(
    icon: Icons.psychology_alt_rounded,
    objectives: [
      'Explain why selling during a downturn usually locks in the loss',
      'Recognise hype, FOMO and tips as signals to slow down',
      'Write a plan you can follow when the market is falling',
    ],
    keyTerms: {
      'Market downturn':
          'a period when prices broadly fall — a normal feature, not a malfunction',
      'Paper loss':
          'a drop in value you have not realised because you have not sold',
      'FOMO':
          'fear of missing out, which reliably pushes people to buy high and sell low',
      'Dollar-cost averaging':
          'investing a fixed amount on a schedule, so you buy more units when prices are low',
    },
    takeaway:
        'The downturn is not the risk — reacting to it is. Deciding your response in advance is what turns volatility into something you can sit through.',
    sections: [
      _LessonSection(
        title: 'Stay focused on the plan',
        content:
            'A long-term investor mindset means not panicking every time prices move. Strategy should matter more than mood.',
      ),
      _LessonSection(
        title: 'Zoom out',
        content:
            'Short-term noise can feel dramatic, but long-term goals are usually served by patience, diversification, and steady contributions.',
      ),
    ],
  ),
  'lesson_21': _LessonContent(
    icon: Icons.receipt_long_rounded,
    objectives: [
      'Find gross pay, deductions and net pay on a real stub',
      'Explain what each common deduction is for',
      'Use year-to-date figures to check your pay is correct',
    ],
    keyTerms: {
      'Gross pay': 'total earnings before anything is taken out',
      'Net pay': 'take-home pay, the amount that actually reaches your account',
      'Deduction':
          'anything subtracted from gross pay, such as tax or retirement contributions',
      'Year to date (YTD)':
          'the running total since January across all pay periods',
    },
    takeaway:
        'Your pay stub is a receipt for your own labour — reading it is how you catch errors that would otherwise go unnoticed for months.',
    sections: [
      _LessonSection(
        title: 'A pay stub tells the real story',
        content:
            'Your pay stub shows gross pay, deductions, taxes, benefits, and the net amount you actually take home.',
      ),
      _LessonSection(
        title: 'Use take-home pay for planning',
        content:
            'Your budget should be based on the number that lands in your account, not the larger headline salary number.',
      ),
    ],
  ),
  'lesson_22': _LessonContent(
    icon: Icons.work_outline_rounded,
    objectives: [
      'Convert benefits into an hourly value you can compare',
      'Account for commute time and cost in the real wage',
      'Compare two offers on total value rather than headline rate',
    ],
    keyTerms: {
      'Total compensation':
          'pay plus the cash value of every benefit attached to it',
      'Benefits': 'non-cash pay such as health cover, transport or paid leave',
      'Effective hourly rate':
          'what you really earn per hour once benefits, commute time and costs are counted',
    },
    takeaway:
        r'The advertised rate is the least interesting number on an offer — $17 with cover and a transport pass can comfortably beat $19 without.',
    sections: [
      _LessonSection(
        title: 'Salary is only one part',
        content:
            'Job offers can differ in healthcare, retirement match, commute costs, hours, flexibility, and growth opportunities.',
      ),
      _LessonSection(
        title: 'Compare the full package',
        content:
            'A smaller salary with better benefits or lower living costs can sometimes leave you better off overall.',
      ),
    ],
  ),
  'lesson_23': _LessonContent(
    icon: Icons.home_work_rounded,
    objectives: [
      'List the costs that advertised rent leaves out',
      'Apply a housing guideline to your own take-home pay',
      'Budget for the up-front cost of moving in',
    ],
    keyTerms: {
      'Utilities':
          'electricity, water, heating and internet — usually billed separately from rent',
      'Security deposit':
          'money held up front and returned if the place is left in good order',
      '30% guideline':
          'a common rule of thumb capping housing at about 30% of take-home pay',
      'Cost of living':
          'the total of everything it takes to run your life in a given place',
    },
    takeaway:
        'Rent is the headline, not the total — utilities, deposit and getting to work are what decide whether a place is actually affordable.',
    sections: [
      _LessonSection(
        title: 'Housing has layers',
        content:
            'Rent is only one part of monthly living costs. Utilities, internet, deposits, parking, and commuting all affect affordability.',
      ),
      _LessonSection(
        title: 'Plan for the full monthly load',
        content:
            'Looking at only the rent number can make a place seem affordable when the real total is much higher.',
      ),
    ],
  ),
  'lesson_24': _LessonContent(
    icon: Icons.request_quote_rounded,
    objectives: [
      'Use W-4, W-2 and Form 1040 correctly in a first-job tax story',
      'Tell marginal and average tax rates apart',
      'Compare income, payroll, sales and property taxes',
      'Explain why credits and deductions lower taxes in different ways',
    ],
    keyTerms: {
      'Withholding':
          'tax your employer sends to the government on your behalf as you earn',
      'W-4':
          'the form employees use to tell an employer how much federal income tax to withhold',
      'W-2':
          'the year-end wage and tax statement an employer sends to the worker and the IRS',
      'Form 1040': 'the main federal income tax return form for individuals',
      'Payroll tax':
          'tax taken from wages for Social Security and Medicare programs',
      'Marginal tax rate':
          'the rate that applies to your next dollar of income',
      'Average tax rate': 'total tax paid divided by total taxable income',
      'Tax deduction': 'an amount that lowers taxable income',
      'Tax credit': 'an amount that lowers the tax bill itself',
      'Tax refund':
          'money returned because you overpaid during the year — your own money coming back',
      'Filing':
          'the yearly reconciliation between what you paid and what you owed',
      'W-4 / tax code':
          'the form or setting that tells your employer how much to withhold',
    },
    takeaway:
        'Taxes are not just money disappearing — they fund public services, change take-home pay, and reward careful paperwork.',
    workedExample: WorkedExample(_taxWithholdingExample),
    sections: [
      _LessonSection(
        title: 'Taxes pay for shared services',
        content:
            'Roads, schools, courts, emergency services and public programs are paid for partly by taxes. Paying tax is one way workers contribute to the community they use every day.',
      ),
      _LessonSection(
        title: 'Your first job starts with forms',
        content:
            'A W-4 tells your employer how much federal income tax to withhold from each paycheck. Later, a W-2 summarizes your wages and withheld taxes for the year. When you file a Form 1040, those numbers are reconciled with what you actually owe.',
      ),
      _LessonSection(
        title: 'Refunds and bills are corrections',
        content:
            'Withholding is an estimate. If too much was withheld, you may get a refund. If too little was withheld, you may owe money at filing time. A refund can feel good, but it is usually your own overpaid money coming back.',
      ),
      _LessonSection(
        title: 'Not every tax works the same way',
        content:
            'Income tax is based on earnings. Payroll tax funds Social Security and Medicare. Sales tax is added when you buy many goods and services. Property tax is based on the value of property such as a home or car, and often funds local services.',
      ),
      _LessonSection(
        title: 'Marginal is not average',
        content:
            'A marginal tax rate applies to the next dollar you earn. An average tax rate is total tax divided by taxable income. In a progressive system, higher chunks of income can be taxed at higher rates without making every dollar taxed at the top rate.',
      ),
      _LessonSection(
        title: 'Credits beat deductions dollar-for-dollar',
        content:
            'A deduction lowers taxable income before tax is calculated. A credit lowers the tax bill after it is calculated. Both matter, but a 100 dollar credit cuts the bill by 100 dollars, while a 100 dollar deduction only removes 100 dollars from the income being taxed.',
      ),
    ],
  ),
  'lesson_25': _LessonContent(
    icon: Icons.route_rounded,
    objectives: [
      'Assemble budgeting, saving, credit and investing into one order of operations',
      'Decide what to do with a monthly surplus',
      'Recognise lifestyle creep before it absorbs a raise',
    ],
    keyTerms: {
      'Order of operations':
          'the usual sequence: cover essentials, build a starter emergency fund, clear high-interest debt, then invest',
      'Surplus': 'money left after everything planned has been funded',
      'Lifestyle creep':
          'spending quietly rising to match income, so a raise leaves you no better off',
      'Net worth': 'what you own minus what you owe — the long-run scoreboard',
    },
    takeaway:
        'Every unit so far is one step in a single sequence — the plan is knowing which step you are on, and what earns your next spare dollar.',
    sections: [
      _LessonSection(
        title: 'Bring the pieces together',
        content:
            'A personal money plan connects your income, bills, savings, debt strategy, and long-term goals into one system.',
      ),
      _LessonSection(
        title: 'Keep refining it',
        content:
            'Your plan should change when your life changes. Review it regularly so it stays realistic and useful.',
      ),
    ],
  ),

  // ---------------- Unit 6 · Stocks and Trading ----------------
  'lesson_26': _LessonContent(
    icon: Icons.pie_chart_outline_rounded,
    objectives: [
      'Explain what owning a share actually entitles you to',
      'Tell the difference between a share price and a company\'s value',
      'Describe why companies sell shares in the first place',
    ],
    keyTerms: {
      'Share': 'one unit of ownership in a company',
      'Market cap':
          'share price multiplied by the number of shares — the market\'s price tag on the whole company',
      'Dividend': 'a slice of profit some companies pay out to shareholders',
    },
    takeaway:
        'A share is a piece of a real business, not a lottery ticket with a ticker on it.',
    sections: [
      _LessonSection(
        title: 'You are buying a business',
        content:
            'When you buy a share you own a genuine fraction of a company — its buildings, its brand, its future profits. If the business does well over time, your slice is worth more.',
      ),
      _LessonSection(
        title: 'Price is not the same as value',
        content:
            'A 500-coin share is not "expensive" and a 5-coin share is not "cheap". What matters is what you get for that price — a company worth ten times more can still have a lower share price if it simply split its ownership into more pieces.',
      ),
      _LessonSection(
        title: 'Why companies sell shares',
        content:
            'Selling shares raises money without borrowing it. The company gets cash to grow; you get a claim on what that growth produces.',
      ),
    ],
  ),
  'lesson_27': _LessonContent(
    icon: Icons.show_chart_rounded,
    objectives: [
      'Explain price as the meeting point of buyers and sellers',
      'Separate news-driven moves from long-term value',
      'Recognise why daily swings are mostly noise',
    ],
    keyTerms: {
      'Volatility': 'how sharply a price swings up and down',
      'Sentiment': 'how buyers and sellers currently feel, regardless of facts',
    },
    takeaway:
        'Day to day, price mostly tracks what people expect. Over years, it tracks what the business actually does.',
    sections: [
      _LessonSection(
        title: 'Price is an agreement',
        content:
            'A stock is worth exactly what someone will pay right now. More eager buyers than sellers pushes it up; the reverse pushes it down. That is the whole mechanism.',
      ),
      _LessonSection(
        title: 'Expectations move faster than reality',
        content:
            'A company can report record profits and still drop, because the market expected even more. You are trading against expectations, not just results.',
      ),
      _LessonSection(
        title: 'Most days are noise',
        content:
            'A 1-2% daily move usually means nothing changed about the business. Checking a long-term holding every hour mostly teaches you to feel anxious.',
      ),
    ],
  ),
  'lesson_28': _LessonContent(
    icon: Icons.donut_large_rounded,
    objectives: [
      'Explain diversification in one sentence',
      'Describe what an index fund holds and why that matters',
      'Judge concentration risk in a portfolio',
    ],
    keyTerms: {
      'Diversification':
          'spreading money across many holdings so no single one can sink you',
      'Index fund':
          'one fund that holds hundreds of companies at once, tracking a whole market',
      'Concentration risk':
          'the danger of having too much riding on one company',
    },
    takeaway:
        'Owning one stock is a bet on one company. Owning an index is a bet that the economy keeps producing — historically the safer bet.',
    sections: [
      _LessonSection(
        title: 'Do not put it all in one place',
        content:
            'If everything you own is in one company and that company stumbles, so do you. Spreading across many means one bad result is a dent, not a disaster.',
      ),
      _LessonSection(
        title: 'Index funds do it for you',
        content:
            'An index fund like SPY holds hundreds of companies in one share. Buying it once gives you a spread that would take a lot of separate purchases to build by hand.',
      ),
      _LessonSection(
        title: 'Check your own mix',
        content:
            'Open the Market Board and look at the allocation ring. If one slice dominates the circle, that is concentration risk — visible at a glance.',
      ),
    ],
  ),
  'lesson_29': _LessonContent(
    icon: Icons.receipt_long_rounded,
    objectives: [
      'Explain the bid-ask spread as a real cost',
      'Choose between a market order and a limit order',
      'Estimate what frequent trading costs over time',
    ],
    keyTerms: {
      'Bid / Ask':
          'the highest price a buyer will pay and the lowest a seller will accept',
      'Spread': 'the gap between them — a cost you pay on every round trip',
      'Limit order':
          'an order that only fills at your price or better, instead of whatever is available',
    },
    takeaway:
        'Every trade costs something even with no visible fee. Trading less is a strategy, not laziness.',
    sections: [
      _LessonSection(
        title: 'The spread is a real cost',
        content:
            'You buy at the ask and sell at the bid, and the ask is always higher. Buy and immediately sell and you lose that gap — which is exactly why the Market Board charges one.',
      ),
      _LessonSection(
        title: 'Market vs limit orders',
        content:
            'A market order fills instantly at whatever price is there. A limit order waits for your price. Instant certainty or price control — you pick which one matters more.',
      ),
      _LessonSection(
        title: 'Costs compound too',
        content:
            'A small cost paid on every trade, many times a year, quietly becomes a large number. Frequent trading has to beat that drag before it beats simply holding.',
      ),
    ],
  ),
  'lesson_30': _LessonContent(
    icon: Icons.hourglass_bottom_rounded,
    workedExample: WorkedExample(_compoundingExample),
    objectives: [
      'Explain why time in the market beats timing the market',
      'Describe what missing the best days costs',
      'Build a rule for what to do when prices fall',
    ],
    keyTerms: {
      'Timing the market': 'trying to buy the bottom and sell the top',
      'Time in the market': 'staying invested and letting compounding work',
    },
    takeaway:
        'The best recovery days cluster right after the worst crash days — sell to escape one and you usually miss the other.',
    sections: [
      _LessonSection(
        title: 'Nobody reliably calls the top',
        content:
            'Timing requires being right twice: when to get out and when to get back in. Professionals with full-time teams mostly fail at this.',
      ),
      _LessonSection(
        title: 'Missing a handful of days matters enormously',
        content:
            'Historically, a small number of days account for a huge share of long-run returns — and they usually land right after sharp drops, when selling feels most sensible.',
      ),
      _LessonSection(
        title: 'Decide before it drops',
        content:
            'Write your rule while things are calm: "if my holdings fall 30%, I hold" or "I buy more". A rule made in advance beats a decision made in a panic.',
      ),
    ],
  ),

  // ---------------- Unit 7 · Spending Traps (ages 11-13) ----------------
  'lesson_31': _LessonContent(
    icon: Icons.theater_comedy_rounded,
    objectives: [
      'Separate a need from a want using consequences, not price',
      'Notice when a want is being dressed up as a need',
      'Rank spending when there is not enough for everything',
    ],
    keyTerms: {
      'Need': 'something your day genuinely breaks without',
      'Want': 'something you would enjoy but can live without',
      'Justification':
          'the story you tell yourself to make a want sound necessary',
    },
    takeaway:
        'Ask what actually breaks if you skip it. If the honest answer is '
        '"nothing", it is a want — and wants are fine, as long as you know.',
    sections: [
      _LessonSection(
        title: 'The test is consequence, not price',
        content:
            'A 2-coin snack you do not need is a want. A 40-coin bus pass you '
            'cannot get to school without is a need. Cost tells you how much '
            'it hurts, not which category it belongs to.',
      ),
      _LessonSection(
        title: 'Wants in disguise',
        content:
            '"I need it for school." "Everyone has one." "It is on sale." '
            'These are justifications, and they are the sound your brain makes '
            'when it has already decided. Notice them and you get a second '
            'chance to choose.',
      ),
      _LessonSection(
        title: 'Order matters more than willpower',
        content:
            'When money is tight, fund the needs first and let the wants '
            'compete for what is left. Deciding the order in advance means you '
            'are not relying on self-control in the shop.',
      ),
    ],
  ),
  'lesson_32': _LessonContent(
    icon: Icons.campaign_rounded,
    objectives: [
      'Explain what an advert is actually selling',
      'Recognise sponsored content and influencer marketing',
      'Name three pressure tactics used on young buyers',
    ],
    keyTerms: {
      'Sponsored content': 'a paid advert made to look like a recommendation',
      'Scarcity': 'making something feel limited so you decide faster',
      'Social proof': 'suggesting everyone else already has it',
    },
    takeaway:
        'Adverts sell a feeling and attach a product to it. Once you can name '
        'the feeling being sold, it loses most of its grip.',
    sections: [
      _LessonSection(
        title: 'You are the product being aimed at',
        content:
            'Companies pay a lot to reach people your age, because habits '
            'formed now can last decades. That is not a conspiracy — it is '
            'written down in their marketing plans.',
      ),
      _LessonSection(
        title: 'Three tactics to watch for',
        content:
            'Scarcity ("only today") rushes you. Social proof ("everyone has '
            'it") makes missing out feel like a loss. And a friendly face '
            'reading a script borrows trust it did not earn.',
      ),
      _LessonSection(
        title: 'The defence is naming it',
        content:
            'Say out loud what the advert wants you to feel — cool, included, '
            'ahead of your friends. Naming it moves the decision from your gut '
            'to your head, which is where it belongs.',
      ),
    ],
  ),
  'lesson_33': _LessonContent(
    icon: Icons.videogame_asset_rounded,
    objectives: [
      'Trace in-game currency back to real money',
      'Explain why bundles and battle passes are priced the way they are',
      'Set a personal rule for in-game spending',
    ],
    keyTerms: {
      'Premium currency': 'coins or gems you buy with real money',
      'Bundle': 'a larger pack sold at a lower price per unit',
      'Sunk cost': 'money already spent, which should not drive new spending',
    },
    takeaway:
        'Game currency is a layer of paint over real money. The spending '
        'happened when you bought the coins, not when you spent them.',
    sections: [
      _LessonSection(
        title: 'Two currencies, one wallet',
        content:
            'Games rarely price items in real money. They price them in gems, '
            'and sell gems in amounts that never quite match what you want. '
            'The leftover balance is deliberate: it pulls you back.',
      ),
      _LessonSection(
        title: 'Why the big bundle is cheaper',
        content:
            'A better price per coin is real, but the reason it is offered is '
            'the bigger single payment. A discount only saves you money on '
            'what you were already going to buy.',
      ),
      _LessonSection(
        title: 'A rule beats a decision',
        content:
            'Decide once — a monthly cap, or only spending money you earned '
            'yourself — instead of deciding again every time a limited offer '
            'appears. Rules do not get tired; willpower does.',
      ),
    ],
  ),
  'lesson_34': _LessonContent(
    icon: Icons.hourglass_bottom_rounded,
    objectives: [
      'Apply a waiting rule to non-urgent purchases',
      'Explain why waiting costs almost nothing',
      'Use a savings goal as a comparison point',
    ],
    keyTerms: {
      'Impulse buy': 'a purchase decided in seconds, on feeling alone',
      'Cooling-off period': 'deliberate time between wanting and buying',
      'Opportunity cost': 'what you gave up by choosing this instead',
    },
    takeaway:
        'If you still want it tomorrow, buy it tomorrow. Almost nothing real '
        'is lost by waiting a day, and a lot of regret is avoided.',
    sections: [
      _LessonSection(
        title: 'Excitement has a short half-life',
        content:
            'The feeling that makes something feel essential usually fades '
            'within hours. A 24-hour gap lets you decide with the version of '
            'yourself who has to live with the purchase.',
      ),
      _LessonSection(
        title: 'What waiting actually costs',
        content:
            'Almost always: nothing. "Limited time" offers repeat. And if you '
            'could not afford it today anyway, waiting was already the plan — '
            'you just get to keep the choice.',
      ),
      _LessonSection(
        title: 'Compare it to your goal',
        content:
            'Every purchase competes with something you are saving for. Write '
            'the goal down, and the comparison happens on its own instead of '
            'needing willpower.',
      ),
    ],
  ),
  'lesson_35': _LessonContent(
    icon: Icons.gpp_maybe_rounded,
    objectives: [
      'Recognise the standard shape of a money scam',
      'Explain why real prizes never ask you to pay',
      'Know what to do when something feels off',
    ],
    keyTerms: {
      'Advance-fee scam':
          'paying a small amount to unlock a prize that is not real',
      'Phishing': 'a fake message that copies a service you trust',
      'Urgency': 'artificial time pressure used to stop you thinking',
    },
    takeaway:
        'Urgency plus secrecy plus a payment from you is the signature of a '
        'scam. Slowing down and telling an adult breaks all three.',
    sections: [
      _LessonSection(
        title: 'The shape is always similar',
        content:
            'Something great is offered, there is a reason you must act now, '
            'and there is a reason not to mention it to anyone. Those three '
            'together are the pattern, whatever the story on top.',
      ),
      _LessonSection(
        title: 'Real prizes do not charge you',
        content:
            'If you have to send money, pay postage, or buy a gift card to '
            'collect something you "won", the fee was the whole point. Nothing '
            'is waiting on the other side.',
      ),
      _LessonSection(
        title: 'What to do instead',
        content:
            'Do not reply, do not click, and tell an adult you trust. Scammers '
            'rely on embarrassment to keep people quiet — being scammed is not '
            'a failure of intelligence, it is a crime committed against you.',
      ),
    ],
  ),

  // ---------------- Unit 8 · Money by the Numbers (ages 14-17) ----------------
  'lesson_36': _LessonContent(
    icon: Icons.percent_rounded,
    objectives: [
      'Calculate a discount, a tip, and an interest amount',
      'Explain why percentages apply to the current value',
      'Spot when a percentage hides a small real amount',
    ],
    keyTerms: {
      'Base': 'the number a percentage is taken from',
      'Percentage point': 'a difference between two percentages, not a ratio',
      'Compounding': 'a percentage applied repeatedly to a growing number',
    },
    takeaway:
        'A percentage means nothing without its base. "20% off" and "20% '
        'return" can be tiny or huge depending on what they are 20% of.',
    sections: [
      _LessonSection(
        title: 'The base is half the answer',
        content:
            '50% of 150 is less money than 5% of 2000. Whenever a percentage '
            'is quoted at you, find the base before you react to the number.',
      ),
      _LessonSection(
        title: 'Up then down does not cancel',
        content:
            'Fall 50% and rise 50% and you are down 25%, because the rise is '
            'calculated on the smaller number. This is why a 50% loss needs a '
            '100% gain to recover.',
      ),
      _LessonSection(
        title: 'Percentages of your own money',
        content:
            'Saving 10% of what you earn is a rule that scales with you: it '
            'stays sensible whether you earn 20 a week or 2000 a month. Fixed '
            'amounts do not adapt; percentages do.',
      ),
    ],
  ),
  'lesson_37': _LessonContent(
    icon: Icons.equalizer_rounded,
    objectives: [
      'Calculate a mean and a median',
      'Explain how one outlier distorts an average',
      'Choose the right summary for a given dataset',
    ],
    keyTerms: {
      'Mean': 'the total divided by how many values there are',
      'Median': 'the middle value when the data is sorted',
      'Outlier': 'a value far away from the rest',
    },
    takeaway:
        'When a headline quotes an average income, ask for the median. The gap '
        'between them tells you how skewed the picture is.',
    sections: [
      _LessonSection(
        title: 'Two different questions',
        content:
            'The mean answers "if we shared it out equally, how much each?" '
            'The median answers "what does a typical one look like?" Those are '
            'not the same question, and money data pulls them apart.',
      ),
      _LessonSection(
        title: 'One value can move the mean',
        content:
            'Nine people earning 30 and one earning 1000 gives a mean of 127 — '
            'a number nobody in the room earns. The median, 30, describes '
            'almost everyone.',
      ),
      _LessonSection(
        title: 'Which one is being quoted?',
        content:
            'Averages get quoted when they flatter the argument. Neither is '
            'dishonest by itself; choosing without saying which is.',
      ),
    ],
  ),
  'lesson_38': _LessonContent(
    icon: Icons.ssid_chart_rounded,
    objectives: [
      'Read the axes and time range on a price chart',
      'Tell a trend apart from ordinary noise',
      'Explain how zoom level changes the story',
    ],
    keyTerms: {
      'Axis': 'the labelled scale along an edge of the chart',
      'Time range': 'the window of history a chart covers',
      'Noise': 'small movement that carries no information',
    },
    takeaway:
        'A chart shape means nothing until you have read both axes and the '
        'time range. The same data can look calm or catastrophic.',
    sections: [
      _LessonSection(
        title: 'Read the labels first',
        content:
            'Price on the vertical, time on the horizontal — usually. Check '
            'where the vertical axis starts and how long the window is before '
            'you form any opinion about the line.',
      ),
      _LessonSection(
        title: 'Zoom is a storyteller',
        content:
            'A 1% wobble is invisible across a year and looks like a cliff '
            'across an hour. Nothing about the business changed; only the '
            'window did.',
      ),
      _LessonSection(
        title: 'Try it on the Market Board',
        content:
            'Open a stock in the Market Board and switch between the short and '
            'long views. Watching the same holding change character is the '
            'fastest way to internalise this.',
      ),
    ],
  ),
  'lesson_39': _LessonContent(
    icon: Icons.warning_amber_rounded,
    objectives: [
      'Spot a truncated vertical axis',
      'Recognise a cherry-picked time window',
      'Ask the right question of any financial chart',
    ],
    keyTerms: {
      'Truncated axis': 'a vertical scale that does not start at zero',
      'Cherry-picking': 'choosing the window that flatters the result',
      'Survivorship bias': 'only showing the ones that worked out',
    },
    takeaway:
        'Most misleading charts are not fake data. They are honest data framed '
        'to make one conclusion look obvious.',
    sections: [
      _LessonSection(
        title: 'The axis that starts at 98',
        content:
            'Cutting the bottom off the vertical scale turns a 2% move into a '
            'mountain. It is the single most common trick, and it appears in '
            'news graphics as often as adverts.',
      ),
      _LessonSection(
        title: 'The window that starts at the bottom',
        content:
            'Any investment has a three-month stretch that looks brilliant. '
            'Choosing that stretch after the fact proves nothing. Ask what the '
            'full period looks like.',
      ),
      _LessonSection(
        title: 'The funds you never see',
        content:
            'Adverts show the funds that survived. The ones that closed are '
            'not in the chart, which quietly lifts every average you are '
            'shown.',
      ),
    ],
  ),
  'lesson_40': _LessonContent(
    icon: Icons.query_stats_rounded,
    objectives: [
      'Record spending in categories for a full month',
      'Turn small recurring amounts into annual figures',
      'Change one specific behaviour based on the data',
    ],
    keyTerms: {
      'Category': 'a spending group like food, transport, or games',
      'Recurring cost': 'an amount that repeats on a schedule',
      'Annualising': 'multiplying a repeating cost out over a year',
    },
    takeaway:
        'Tracking does not reduce spending. It replaces a guess with a number, '
        'and numbers are what you can actually argue with.',
    sections: [
      _LessonSection(
        title: 'Categories, not a list',
        content:
            'A list of purchases is noise. The same purchases grouped into '
            'five or six categories tell you immediately where the money '
            'concentrates — usually somewhere surprising.',
      ),
      _LessonSection(
        title: 'Annualise the small stuff',
        content:
            '12 a week is 624 a year. Nobody flinches at 12; almost everybody '
            'flinches at 624. Multiplying out is the cheapest way to make a '
            'recurring cost visible.',
      ),
      _LessonSection(
        title: 'One change, measured',
        content:
            'Pick the largest category, set one specific limit, and track it '
            'for a month. A single measured change beats a broad promise to '
            'spend less, which nobody has ever kept.',
      ),
    ],
  ),

  // ---------------- Unit 9 · Retirement and the 401(k) (ages 21+) ----------------
  'lesson_41': _LessonContent(
    icon: Icons.account_balance_rounded,
    objectives: [
      'Explain what a retirement account is and who owns it',
      'Describe the tax advantage in plain language',
      'Understand why the money is hard to withdraw early',
    ],
    keyTerms: {
      '401(k)': 'a tax-advantaged retirement account offered through a job',
      'IRA': 'a retirement account you open yourself',
      'Tax-advantaged': 'taxed less, or later, than an ordinary account',
    },
    takeaway:
        'A retirement account is a wrapper around investments, with a tax '
        'break attached and a lock on the door until you are much older.',
    sections: [
      _LessonSection(
        title: 'It is yours, not the employer\'s',
        content:
            'Your contributions belong to you from the first day, even if you '
            'leave the job. The employer administers the plan; it does not own '
            'the balance.',
      ),
      _LessonSection(
        title: 'The tax break is the point',
        content:
            'Ordinary investing is taxed as it grows. Retirement accounts '
            'defer or eliminate that, which over forty years is worth far more '
            'than it sounds in any single year.',
      ),
      _LessonSection(
        title: 'The lock is a feature',
        content:
            'Penalties on early withdrawal exist to stop you raiding it. That '
            'friction is doing real work — the accounts people never touch are '
            'the ones that end up large.',
      ),
    ],
  ),
  'lesson_42': _LessonContent(
    icon: Icons.handshake_rounded,
    objectives: [
      'Read a match formula correctly',
      'Calculate the money a match is worth',
      'Explain why the match comes before fund selection',
    ],
    keyTerms: {
      'Employer match': 'money your employer adds when you contribute',
      'Match formula':
          'the rule setting how much they add and up to what limit',
      'Contribution rate': 'the percentage of your pay you put in',
    },
    takeaway:
        'The match is pay you have already earned but have not claimed. '
        'Nothing else in investing offers a guaranteed instant return.',
    sections: [
      _LessonSection(
        title: 'Read the formula slowly',
        content:
            '"50% of the first 6%" means you must contribute 6% to get 3% '
            'added. It is not the same as "6%", and misreading it is the most '
            'common way people leave money behind.',
      ),
      _LessonSection(
        title: 'What it is actually worth',
        content:
            'On a 40,000 salary, contributing 6% is 2,400 of yours and 1,200 '
            'of theirs. Skipping it is turning down a 3% raise every single '
            'year you work there.',
      ),
      _LessonSection(
        title: 'Priority order',
        content:
            'Get the full match first. Only after that does it make sense to '
            'argue about which fund, how much extra, or anything else. No fund '
            'reliably beats free money.',
      ),
    ],
  ),
  'lesson_43': _LessonContent(
    icon: Icons.compare_arrows_rounded,
    objectives: [
      'State when tax is paid under each option',
      'Match the choice to your expected future tax rate',
      'Recognise that both can be used over a career',
    ],
    keyTerms: {
      'Roth': 'tax paid now, qualified withdrawals later are untaxed',
      'Traditional': 'tax deferred now, withdrawals taxed later',
      'Marginal rate': 'the rate applied to your next unit of income',
    },
    takeaway:
        'Pay the tax in the year your rate is lowest. Early in a career that '
        'is usually now, which is why Roth suits people starting out.',
    sections: [
      _LessonSection(
        title: 'Same money, different timing',
        content:
            'Both wrappers shelter the growth. The only real question is '
            'whether you hand the tax over on the way in or on the way out.',
      ),
      _LessonSection(
        title: 'Guess your future bracket',
        content:
            'If you expect to earn much more later, prepaying tax now at a low '
            'rate wins. If you are at your peak earnings already, deferring is '
            'usually better.',
      ),
      _LessonSection(
        title: 'You do not have to pick forever',
        content:
            'Many people use Roth early and traditional later. The decision is '
            'made fresh each year, not once for life.',
      ),
    ],
  ),
  'lesson_44': _LessonContent(
    icon: Icons.trending_up_rounded,
    objectives: [
      'Explain why early contributions outweigh later, larger ones',
      'Describe compounding over a multi-decade horizon',
      'Identify the real cost of waiting to start',
    ],
    keyTerms: {
      'Compounding': 'growth earning growth of its own',
      'Time horizon': 'how many years the money has to grow',
      'Contribution': 'money you put in, before any growth',
    },
    takeaway:
        'Ten years of early contributions often beats thirty years of later '
        'ones. Time is the input you cannot buy back.',
    sections: [
      _LessonSection(
        title: 'The classic comparison',
        content:
            'One person saves from 25 to 35 and stops. Another saves the same '
            'monthly amount from 35 to 65. At 65 the first is frequently ahead '
            'despite contributing a third as much.',
      ),
      _LessonSection(
        title: 'Why it works that way',
        content:
            'The earliest coins spend the longest compounding, and compounding '
            'accelerates. The last decade before retirement does more for the '
            'money already there than for anything newly added.',
      ),
      _LessonSection(
        title: 'What waiting costs',
        content:
            'Delaying five years is not five years of contributions — it is '
            'five years off the end of every future coin\'s growth. That is '
            'the expensive part.',
      ),
    ],
  ),
  'lesson_45': _LessonContent(
    icon: Icons.receipt_long_rounded,
    objectives: [
      'Find the expense ratio on a fund',
      'Explain how vesting affects employer money',
      'Know the options for an old account when changing jobs',
    ],
    keyTerms: {
      'Expense ratio': 'the annual percentage a fund charges you',
      'Vesting': 'the schedule on which employer contributions become yours',
      'Rollover': 'moving an old account into a new one without penalty',
    },
    takeaway:
        'Fees are charged every year, including the good ones. A 1% fund '
        'versus a 0.05% fund is a large share of your balance over a career.',
    sections: [
      _LessonSection(
        title: 'Fees compound too',
        content:
            'A percentage taken annually applies to a growing balance, so the '
            'cost grows with your savings. Over forty years the gap between '
            'cheap and expensive funds is measured in years of retirement.',
      ),
      _LessonSection(
        title: 'Vesting only affects their money',
        content:
            'Your own contributions are yours immediately. The employer match '
            'may need two to four years of service before you keep all of it '
            'if you leave.',
      ),
      _LessonSection(
        title: 'Do not lose the old account',
        content:
            'When you change jobs the account stays yours. Roll it into the '
            'new plan or an IRA so it does not sit forgotten in cash for a '
            'decade — a surprisingly common way to lose growth.',
      ),
    ],
  ),

  // ------------------------- Unit 12 · Big Purchases -------------------------
  'lesson_53': _LessonContent(
    icon: Icons.directions_car_rounded,
    objectives: [
      'List the costs a sticker price leaves out',
      'Explain why a cheap car can be the expensive one',
      'Estimate a yearly cost of ownership before buying',
    ],
    keyTerms: {
      'Depreciation': 'the value a car loses just by getting older',
      'Total cost of ownership':
          'purchase price plus fuel, insurance, maintenance, tax and repairs',
      'Running costs': 'what the car takes from you every month you keep it',
    },
    takeaway:
        'The sticker is the entry fee. Insurance, fuel, tax and repairs are '
        'the subscription, and the subscription is usually the bigger number.',
    sections: [
      _LessonSection(
        title: 'The price is the smallest question',
        content:
            'Two cars at the same price are not the same purchase. One may '
            'cost twice as much to insure, drink twice the fuel and need '
            'parts that are hard to get. Ask what a year of owning it costs '
            'before you ask what it costs to drive away.',
      ),
      _LessonSection(
        title: 'Depreciation is a real cost even if no bill arrives',
        content:
            'A new car loses value fastest in its first years. You do not feel '
            'it monthly, but you pay it the day you sell. Buying something a '
            'few years old lets the first owner absorb that drop for you.',
      ),
      _LessonSection(
        title: 'Insurance before you commit',
        content:
            'Get an insurance quote for the exact car before you buy it, not '
            'after. Two similar cars can differ enormously, and a quote takes '
            'minutes — this is the single easiest way to avoid a nasty '
            'surprise in month one.',
      ),
    ],
  ),
  'lesson_54': _LessonContent(
    icon: Icons.request_quote_rounded,
    objectives: [
      'Separate the monthly payment from the total price',
      'Explain what APR includes that an interest rate does not',
      'Say why a longer loan term costs more overall',
    ],
    keyTerms: {
      'APR': 'the yearly cost of borrowing including fees, not just interest',
      'Term': 'how many months you will be making payments',
      'Principal': 'the amount you actually borrowed',
      'Negative equity': 'owing more on the car than the car is worth',
    },
    takeaway:
        'A dealer sells you a monthly payment; a lender sells you a total. '
        'Multiply the payment by the term before you agree to anything.',
    sections: [
      _LessonSection(
        title: 'The monthly payment is the sales pitch',
        content:
            '"Only 240 a month" is not a price. Ask for the term, multiply, '
            'and compare that to the car. A payment can always be made '
            'smaller by stretching the loan — which makes the total bigger.',
      ),
      _LessonSection(
        title: 'Why a longer term costs more',
        content:
            'A longer loan means more months of interest on a balance that '
            'falls more slowly. The payment drops and the total rises. Those '
            'two facts feel contradictory, which is exactly why the tactic '
            'works.',
      ),
      _LessonSection(
        title: 'APR is the number that compares',
        content:
            'APR folds fees into the rate, so it is the figure that lets you '
            'compare two offers honestly. A lower interest rate with higher '
            'fees can be the worse deal, and APR is what exposes that.',
      ),
      _LessonSection(
        title: 'Get the loan before the showroom',
        content:
            'Arranging finance with your own bank or credit union first gives '
            'you a rate to beat. Walking in pre-approved changes the '
            'conversation from "what payment can you afford" to "can you beat '
            'this number".',
      ),
    ],
  ),
  'lesson_55': _LessonContent(
    icon: Icons.apartment_rounded,
    objectives: [
      'Describe what a landlord checks before approving you',
      'Explain what a lease commits you to',
      'Judge whether a rent is affordable on your income',
    ],
    keyTerms: {
      'Lease': 'a contract fixing your rent and your obligations for a term',
      'Security deposit':
          'money held against damage, returnable if you leave the place as you found it',
      'Joint and several liability':
          'each person on the lease is responsible for all of the rent, not just their share',
    },
    takeaway:
        'A lease is the largest contract most people sign before a mortgage. '
        'Read the exit terms before you read the kitchen.',
    sections: [
      _LessonSection(
        title: 'What they check',
        content:
            'Landlords generally look at income, rental history and a credit '
            'report. This is one of the first places a thin or damaged credit '
            'file costs you something concrete — sometimes a bigger deposit, '
            'sometimes a guarantor, sometimes the flat.',
      ),
      _LessonSection(
        title: 'The 30% guide, and what it is for',
        content:
            'A long-standing housing guideline treats spending more than 30% '
            'of income on housing as cost-burdened. It is a rule of thumb, not '
            'a law — but if rent takes far more than that, the rest of the '
            'budget has to give somewhere, and usually it is savings.',
      ),
      _LessonSection(
        title: 'Splitting rent does not split the liability',
        content:
            'On a joint lease, if your flatmate does not pay, the landlord '
            'can pursue you for the whole amount. "We each pay half" is an '
            'agreement between you two; the lease is the agreement that '
            'counts.',
      ),
    ],
  ),
  'lesson_56': _LessonContent(
    icon: Icons.local_shipping_rounded,
    objectives: [
      'Total the real cost of moving in',
      'Plan for the gap between deposit out and deposit back',
      'Avoid the first-month cash crunch',
    ],
    keyTerms: {
      'Move-in cost': 'everything due before you get keys',
      'Utilities':
          'power, water, heating, internet — usually separate from rent',
      'Proration': 'paying part of a month when you move in mid-month',
    },
    takeaway:
        'Moving in costs far more than one month of rent, and your old deposit '
        'usually arrives after the new one is due.',
    sections: [
      _LessonSection(
        title: 'Add it up before you sign',
        content:
            'First month, a security deposit, sometimes a last month, utility '
            'connection charges, and everything a flat does not come with — '
            'from a shower curtain to a bed. It is normal for this to be two '
            'to three times the monthly rent.',
      ),
      _LessonSection(
        title: 'The deposit gap',
        content:
            'You pay the new deposit before you get the old one back. If both '
            'are a month of rent, you need both at once. This is the single '
            'most common reason a first move goes onto a credit card.',
      ),
      _LessonSection(
        title: 'Photograph everything on day one',
        content:
            'Date-stamped photos of every existing mark, taken before you '
            'move anything in, is what turns "you damaged this" into a '
            'settled question. It takes ten minutes and is worth a deposit.',
      ),
    ],
  ),
  'lesson_57': _LessonContent(
    icon: Icons.compare_arrows_rounded,
    objectives: [
      'Compare buying, financing and waiting as three real options',
      'Identify when not buying is the strongest move',
      'Apply opportunity cost to a large purchase',
    ],
    keyTerms: {
      'Opportunity cost': 'what the same money could have done instead',
      'Sunk cost':
          'money already spent, which should not drive the next choice',
      'Cash purchase': 'buying outright, owing nothing afterwards',
    },
    takeaway:
        'Waiting is a real option with a real return, and it is the one that '
        'never appears on the forecourt.',
    sections: [
      _LessonSection(
        title: 'Three options, not two',
        content:
            'Buy outright, finance, or do not buy yet. The third is usually '
            'missing from the conversation because nobody in the room earns '
            'anything from it.',
      ),
      _LessonSection(
        title: 'What the money would have done',
        content:
            'Money spent on a depreciating thing is money not in an emergency '
            'fund or an index fund. That is not an argument against ever '
            'buying — it is the price tag the sticker leaves off.',
      ),
      _LessonSection(
        title: 'Needing it is a real answer',
        content:
            'If a car is how you get to work, the analysis changes: no car '
            'may cost you the job. Necessity is a legitimate reason to buy '
            'the cheap reliable option now. It is not a reason to buy the '
            'expensive one.',
      ),
    ],
  ),

  // -------------------- Unit 13 · Protecting Your Money --------------------
  'lesson_58': _LessonContent(
    icon: Icons.person_off_rounded,
    objectives: [
      'Describe how stolen details become opened accounts',
      'Recognise the early signs before the damage compounds',
      'Know the one site to go to first',
    ],
    keyTerms: {
      'Identity theft': 'someone using your details to borrow or buy as you',
      'Data breach': 'a leak of customer details from a company you used',
      'Recovery plan': 'the step-by-step FTC process for undoing the damage',
    },
    takeaway:
        'Identity theft is usually noticed on a statement or a credit report, '
        'not at the moment it happens — which is why checking matters.',
    sections: [
      _LessonSection(
        title: 'It rarely starts with you',
        content:
            'Most stolen details come from a breach at a company that held '
            'them, not from something you did wrong. That is worth saying '
            'plainly: being a victim here is usually not carelessness.',
      ),
      _LessonSection(
        title: 'The early signs',
        content:
            'A bill for something you did not buy, a letter about an account '
            'you did not open, a card declined for no reason, or a credit '
            'report entry you do not recognise. Any one of these is worth '
            'ten minutes of checking.',
      ),
      _LessonSection(
        title: 'Where to go',
        content:
            'The FTC runs IdentityTheft.gov specifically for this. It builds '
            'a recovery plan for your situation and produces the official '
            'affidavit that banks and credit bureaus ask for — which is the '
            'part that is hard to do on your own.',
      ),
    ],
  ),
  'lesson_59': _LessonContent(
    icon: Icons.lock_rounded,
    objectives: [
      'Explain what a credit freeze does and does not do',
      'Name the three bureaus a freeze must be placed with',
      'Decide between a freeze and a fraud alert',
    ],
    keyTerms: {
      'Credit freeze': 'a lock stopping new lenders from seeing your file',
      'Fraud alert': 'a flag asking lenders to verify identity before lending',
      'Credit bureau':
          'a company that keeps your credit file — Equifax, Experian, TransUnion',
    },
    takeaway:
        'A freeze is free, reversible, and the strongest single thing you can '
        'do — but it only counts at the bureaus you actually freeze.',
    sections: [
      _LessonSection(
        title: 'What it actually blocks',
        content:
            'Most lenders will not open an account without checking your '
            'file. Freeze the file and that check fails, so the account does '
            'not open. It does not touch your existing accounts, and it does '
            'not affect your score.',
      ),
      _LessonSection(
        title: 'All three, or it does not count',
        content:
            'There are three major bureaus and a freeze at one does nothing '
            'at the other two. A lender only needs to reach one unfrozen file '
            'to approve a fraudulent account, so this is a three-part job.',
      ),
      _LessonSection(
        title: 'Freezing is free, and reversible',
        content:
            'Federal law makes placing and lifting a freeze free. You lift it '
            'temporarily when you genuinely apply for credit. The friction is '
            'the point — it is a few minutes against someone opening a loan '
            'in your name.',
      ),
    ],
  ),
  'lesson_60': _LessonContent(
    icon: Icons.fact_check_rounded,
    objectives: [
      'Get your report from the official free source',
      'Know what to look for line by line',
      'Dispute an entry that is not yours',
    ],
    keyTerms: {
      'Credit report': 'the record of your accounts and payment history',
      'Hard inquiry': 'a lender checking your file because you applied',
      'Dispute': 'a formal challenge to an entry you believe is wrong',
    },
    takeaway:
        'AnnualCreditReport.com is the federally authorised free source. '
        'Anything charging you for the same report is selling you something '
        'you are entitled to.',
    sections: [
      _LessonSection(
        title: 'One official site',
        content:
            'AnnualCreditReport.com is the site set up under federal law for '
            'free reports from all three bureaus. Search results are full of '
            'lookalikes that want a subscription — this is the one that does '
            'not.',
      ),
      _LessonSection(
        title: 'What to scan for',
        content:
            'Accounts you do not recognise, addresses you never lived at, and '
            'hard inquiries from lenders you never applied to. Those three '
            'are how fraud shows up on paper.',
      ),
      _LessonSection(
        title: 'Disputing works',
        content:
            'You have a right to dispute an entry, and the bureau has to '
            'investigate. Wrong entries do get removed — but only for people '
            'who look, which is most of the value of ever opening the report.',
      ),
    ],
  ),
  'lesson_61': _LessonContent(
    icon: Icons.money_off_rounded,
    objectives: [
      'Identify fees that are opt-in rather than automatic',
      'Explain what overdraft coverage actually buys',
      'Choose account features that avoid fees entirely',
    ],
    keyTerms: {
      'Overdraft': 'spending past your balance, if the bank allows it',
      'Opt in': 'a choice you have to actively make — the default is off',
      'Declined transaction': 'the free alternative to an overdraft fee',
    },
    takeaway:
        'Some of the most expensive fees on a bank account are optional, and '
        'the option was presented as a convenience.',
    sections: [
      _LessonSection(
        title: 'Overdraft coverage is a choice',
        content:
            'For ATM and everyday debit card transactions, a bank generally '
            'needs your opt-in before it can charge overdraft fees. Without '
            'it the transaction is simply declined — which is free, and '
            'briefly embarrassing rather than expensive.',
      ),
      _LessonSection(
        title: 'Do the arithmetic on the convenience',
        content:
            'A flat fee on a small purchase is an enormous effective rate. '
            'Paying a fixed charge so a coffee goes through is the most '
            'expensive borrowing most people ever do, measured properly.',
      ),
      _LessonSection(
        title: 'Pick the account, not the apology',
        content:
            'Accounts differ on monthly charges, minimum balances and ATM '
            'fees. Choosing one that fits how you actually bank removes those '
            'costs permanently, rather than fighting them one refund at a '
            'time.',
      ),
    ],
  ),
  'lesson_62': _LessonContent(
    icon: Icons.gavel_rounded,
    objectives: [
      'Escalate a problem in the right order',
      'Use the federal complaint process',
      'Know what debt collectors may and may not do',
    ],
    keyTerms: {
      'Complaint': 'a formal, recorded report to a regulator',
      'Debt collector':
          'a company pursuing a debt, often bought from someone else',
      'Validation':
          'a collector\'s obligation to prove the debt is really yours',
    },
    takeaway:
        'Complaining to the company first and the regulator second is not '
        'politeness — it is the order that actually gets things fixed.',
    sections: [
      _LessonSection(
        title: 'Company first, in writing',
        content:
            'Start with the company and keep a record: dates, names, and what '
            'was said. Most problems end here, and the record is what makes '
            'the next step work if they do not.',
      ),
      _LessonSection(
        title: 'Then the CFPB',
        content:
            'The CFPB takes complaints about financial products and forwards '
            'them to the company, which is expected to respond. A complaint '
            'is on the record — a phone call is not.',
      ),
      _LessonSection(
        title: 'Collectors have rules',
        content:
            'A collector has to tell you who they are and what the debt is, '
            'and you can ask them to prove it is yours before paying '
            'anything. Debts get sold with bad data attached; asking for '
            'validation is normal, not obstructive.',
      ),
    ],
  ),
};
