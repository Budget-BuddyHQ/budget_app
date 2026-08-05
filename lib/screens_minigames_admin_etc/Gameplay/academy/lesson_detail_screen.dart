import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../../models_Like_Skins_and_lessons_templates/progression_service.dart';
import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'quiz_widgets.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.unit,
    required this.progressionService,
  });

  final Lesson lesson;
  final LessonUnit unit;
  final ProgressionService progressionService;

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
  late final List<QuizQuestion> _quiz = quizFor(widget.lesson.id);

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

      final result = await context
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

      setState(() {
        _isCompleted = true;
        _isSaving = false;
      });

      // 3. Define rewards string
      final String rewardsText = '+$xpEarned XP, +$goldEarned Gold';

      GameToast.show(
        context,
        title: 'Lesson complete',
        message: hasQuiz
            ? 'Scored $_correctCount/${quiz.length}. Earned $rewardsText! ${result.message}'
            : '${widget.lesson.title} saved. Earned $rewardsText!',
        icon: Icons.school_rounded,
        accent: const Color(0xFF2F9E68),
        soundEffect: AppSoundEffect.celebration,
      );
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
    setState(() {
      _questionIndex++;
      _selectedOption = null;
    });
  }

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
      backgroundColor: const Color(0xFF0D2B20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.lesson.title,
          style: GoogleFonts.baloo2(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.villageMapBackground,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0D2B20).withValues(alpha: 0.74),
            ),
          ),
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
                      const SizedBox(height: 24),
                      if (quiz.isEmpty && content.objectives.isNotEmpty) ...[
                        _ObjectivesCard(objectives: content.objectives),
                        const SizedBox(height: 8),
                      ],
                      if (quiz.isEmpty)
                        ...content.sections.map(
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
                                  style: GoogleFonts.baloo2(
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
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                style: GoogleFonts.baloo2(
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
            style: GoogleFonts.baloo2(
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
                style: GoogleFonts.baloo2(
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
            style: GoogleFonts.baloo2(
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

class _LessonSection {
  const _LessonSection({required this.title, required this.content});

  final String title;
  final String content;
}

const Map<String, _LessonContent> _lessonLibrary = <String, _LessonContent>{
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
      'Explain what withholding is and why it happens during the year',
      'Describe what a refund or a bill at filing time actually means',
      'Know which documents you need before filing',
    ],
    keyTerms: {
      'Withholding':
          'tax your employer sends to the government on your behalf as you earn',
      'Tax refund':
          'money returned because you overpaid during the year — your own money coming back',
      'Filing':
          'the yearly reconciliation between what you paid and what you owed',
      'W-4 / tax code':
          'the form or setting that tells your employer how much to withhold',
    },
    takeaway:
        'A big refund is not a prize — it means the government held your money interest-free all year, and your withholding may be set too high.',
    sections: [
      _LessonSection(
        title: 'Taxes reduce take-home pay',
        content:
            'Withholding is money set aside from each paycheck for taxes. It changes how much cash reaches you right now.',
      ),
      _LessonSection(
        title: 'Understand the tradeoff',
        content:
            'Too little withholding can create a bill later, while too much means you are giving up cash flow during the year.',
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
};
