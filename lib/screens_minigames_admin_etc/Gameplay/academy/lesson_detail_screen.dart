import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/progression_service.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

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

    final result = await context
        .read<UserStatsController>()
        .completeLessonProgress(
          lessonId: widget.lesson.id,
          lessonTitle: widget.lesson.title,
          xpEarned: 12 + bonusXp,
          literacyPointsEarned: 20,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCompleted = true;
      _isSaving = false;
    });

    GameToast.show(
      context,
      title: 'Lesson complete',
      message: hasQuiz
          ? 'Scored $_correctCount/${quiz.length}. ${result.message}'
          : '${widget.lesson.title} saved. ${result.message}',
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
    final quiz = content.quiz;
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
              color: const Color(0xFF0D2B20).withValues(alpha: 0.62),
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
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (inQuizResults)
                        _QuizResultsCard(
                          correct: _correctCount,
                          total: quiz.length,
                        )
                      else
                        _QuizQuestionCard(
                          questionNumber: _questionIndex + 1,
                          totalQuestions: quiz.length,
                          question: quiz[_questionIndex],
                          selectedOption: _selectedOption,
                          onSelect: (optionIndex) =>
                              _selectOption(quiz[_questionIndex], optionIndex),
                        ),
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

// ---------------------------------------------------------------------
// Quiz UI
// ---------------------------------------------------------------------

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.selectedOption,
    required this.onSelect,
  });

  final int questionNumber;
  final int totalQuestions;
  final QuizQuestion question;
  final int? selectedOption;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final answered = selectedOption != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question $questionNumber of $totalQuestions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (questionNumber - 1) / totalQuestions,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          question.question,
          style: GoogleFonts.baloo2(
            color: const Color(0xFFF7FFFB),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++) ...[
          _OptionCard(
            label: question.options[i],
            state: _resolveState(i),
            onTap: answered ? null : () => onSelect(i),
          ),
          if (i != question.options.length - 1) const SizedBox(height: 10),
        ],
        if (answered && question.explanation != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFFFD45C),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.explanation!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  _OptionCardState _resolveState(int index) {
    if (selectedOption == null) {
      return _OptionCardState.neutral;
    }
    if (index == question.correctIndex) {
      return _OptionCardState.correct;
    }
    if (index == selectedOption) {
      return _OptionCardState.incorrect;
    }
    return _OptionCardState.disabled;
  }
}

enum _OptionCardState { neutral, correct, incorrect, disabled }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionCardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Color text;
    final Widget? trailing;

    switch (state) {
      case _OptionCardState.neutral:
        fill = Colors.white.withValues(alpha: 0.06);
        border = Colors.white.withValues(alpha: 0.16);
        text = Colors.white;
        trailing = null;
      case _OptionCardState.correct:
        fill = const Color(0xFF2F9E68).withValues(alpha: 0.24);
        border = const Color(0xFF85EFAC);
        text = const Color(0xFFF7FFFB);
        trailing = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF85EFAC),
        );
      case _OptionCardState.incorrect:
        fill = const Color(0xFFE24B4A).withValues(alpha: 0.22);
        border = const Color(0xFFFF8474);
        text = const Color(0xFFF7FFFB);
        trailing = const Icon(Icons.cancel_rounded, color: Color(0xFFFF8474));
      case _OptionCardState.disabled:
        fill = Colors.white.withValues(alpha: 0.03);
        border = Colors.transparent;
        text = Colors.white.withValues(alpha: 0.38);
        trailing = null;
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                color: text,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing],
        ],
      ),
    );

    final wrapped = state == _OptionCardState.incorrect
        ? _ShakeX(child: card)
        : state == _OptionCardState.correct
        ? _PulseScale(child: card)
        : card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: wrapped,
      ),
    );
  }
}

class _QuizResultsCard extends StatelessWidget {
  const _QuizResultsCard({required this.correct, required this.total});

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final passed = total == 0 || correct / total >= 0.7;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(
            passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
            color: const Color(0xFFFFD45C),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '$correct / $total correct',
            style: GoogleFonts.baloo2(
              color: const Color(0xFFF7FFFB),
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? 'Nice work — those ideas are sticking.'
                : 'Worth a re-read before the next unit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShakeX extends StatefulWidget {
  const _ShakeX({required this.child});

  final Widget child;

  @override
  State<_ShakeX> createState() => _ShakeXState();
}

class _ShakeXState extends State<_ShakeX> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final decay = 1 - t;
        final dx = math.sin(t * math.pi * 6) * 8 * decay;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class _PulseScale extends StatefulWidget {
  const _PulseScale({required this.child});

  final Widget child;

  @override
  State<_PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<_PulseScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

// ---------------------------------------------------------------------
// Content model + library
// ---------------------------------------------------------------------

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
}

class _LessonContent {
  const _LessonContent({
    required this.icon,
    this.sections = const [],
    this.quiz = const [],
  });

  final IconData icon;
  final List<_LessonSection> sections;
  final List<QuizQuestion> quiz;
}

class _LessonSection {
  const _LessonSection({required this.title, required this.content});

  final String title;
  final String content;
}

const Map<String, _LessonContent> _lessonLibrary = <String, _LessonContent>{
  'lesson_1': _LessonContent(
    icon: Icons.account_balance_wallet_rounded,
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
  'quiz_1': _LessonContent(
    icon: Icons.bolt_rounded,
    quiz: [
      QuizQuestion(
        question: 'In the 50/30/20 rule, what is the 20% for?',
        options: ['Wants', 'Savings or debt payoff', 'Rent', 'Taxes'],
        correctIndex: 1,
        explanation:
            '50% needs, 30% wants, 20% savings or debt payoff — the 20% is your future-focused slice.',
      ),
      QuizQuestion(
        question:
            'When building a budget, which number should you plan around?',
        options: [
          'Gross income',
          'Net (take-home) income',
          'Last year’s income',
          'Expected bonus income',
        ],
        correctIndex: 1,
        explanation:
            'Net income is what actually reaches your account, so it is the honest number to plan against.',
      ),
    ],
  ),
  'lesson_3': _LessonContent(
    icon: Icons.shopping_bag_rounded,
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
  'lesson_5': _LessonContent(
    icon: Icons.pie_chart_rounded,
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
  'test_1': _LessonContent(
    icon: Icons.star_rounded,
    quiz: [
      QuizQuestion(
        question: 'What is the best description of budgeting?',
        options: [
          'Spending whatever is left at the end of the month',
          'A plan for how money will be used before you spend it',
          'A way to avoid ever checking your account',
          'A once-a-year financial review',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'In the 50/30/20 rule, what does the 50% cover?',
        options: ['Wants', 'Needs', 'Savings', 'Entertainment'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Which income figure should you budget against?',
        options: [
          'Gross income',
          'Net income',
          'Projected raise',
          'Side income only',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: '“Pay yourself first” means treating savings like:',
        options: [
          'An optional leftover',
          'A required bill',
          'A once-a-year bonus',
          'Something to skip when busy',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question:
            'A complete budget plan should list all of the following EXCEPT:',
        options: [
          'Income and fixed costs',
          'Savings goals and debt payments',
          'Flexible spending',
          'Your friends’ spending habits',
        ],
        correctIndex: 3,
      ),
    ],
  ),
  'lesson_6': _LessonContent(
    icon: Icons.credit_card_rounded,
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
  'quiz_2': _LessonContent(
    icon: Icons.bolt_rounded,
    quiz: [
      QuizQuestion(
        question: 'Which is a healthy credit habit?',
        options: [
          'Maxing out your limit every month',
          'Paying on time and keeping balances low',
          'Only checking your balance once a year',
          'Treating your credit limit as spending money',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Investing tends to work best over:',
        options: [
          'A single weekend',
          'Long time horizons',
          'One paycheck cycle',
          'The next 24 hours',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_8': _LessonContent(
    icon: Icons.account_balance_rounded,
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
  'test_2': _LessonContent(
    icon: Icons.star_rounded,
    quiz: [
      QuizQuestion(
        question: 'Credit is best described as:',
        options: [
          'Free money',
          'Borrowed money you use now and repay later',
          'A savings bonus',
          'Something that never affects your budget',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Higher potential investment return usually comes with:',
        options: [
          'Guaranteed profit',
          'More uncertainty',
          'Zero risk',
          'A fixed schedule',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'When choosing a bank account, you should compare:',
        options: [
          'Only the branch location',
          'Fees, digital tools, transfer speed, and support',
          'Just the color of the card',
          'Whichever account a friend has',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'The main purpose of an emergency fund is to:',
        options: [
          'Fund vacations',
          'Protect your budget from turning into new debt',
          'Replace your regular savings',
          'Earn the highest possible interest rate',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Good long-term financial goals should be:',
        options: [
          'Vague and flexible',
          'Specific, measurable, and tied to a timeline',
          'Kept secret from yourself',
          'Set once and never reviewed',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_11': _LessonContent(
    icon: Icons.workspace_premium_rounded,
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
  'quiz_3': _LessonContent(
    icon: Icons.bolt_rounded,
    quiz: [
      QuizQuestion(
        question: '“Pay yourself first” means:',
        options: [
          'Spend first, save whatever is left',
          'Move money to savings before other spending',
          'Only save on holidays',
          'Save only after a raise',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'A sinking fund is money set aside for:',
        options: [
          'Impulse purchases',
          'A known future cost, saved gradually',
          'Emergencies only',
          'Paying off credit cards',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_13': _LessonContent(
    icon: Icons.account_balance_wallet_outlined,
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
  'test_3': _LessonContent(
    icon: Icons.star_rounded,
    quiz: [
      QuizQuestion(
        question: 'Automatic transfers on payday help mainly because:',
        options: [
          'They earn extra interest',
          'The saving decision is already made for you',
          'They are required by banks',
          'They remove the need for a budget',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'When choosing a savings account, you should compare:',
        options: [
          'Only the app icon',
          'Interest rate, fees, minimum balance, and transfer speed',
          'Whichever bank is newest',
          'Nothing — all accounts are the same',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Irregular costs like annual subscriptions should be:',
        options: [
          'Ignored until they happen',
          'Divided across months and saved for gradually',
          'Paid only with credit',
          'Someone else’s problem',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'A sinking fund helps you avoid being surprised by:',
        options: [
          'Daily coffee costs',
          'Known future expenses',
          'Interest rates',
          'Tax season',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Automation still works best when paired with:',
        options: [
          'Never checking your accounts',
          'Regular review to match your goals',
          'Turning off all alerts',
          'Ignoring irregular costs',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_16': _LessonContent(
    icon: Icons.trending_up_rounded,
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
  'quiz_4': _LessonContent(
    icon: Icons.bolt_rounded,
    quiz: [
      QuizQuestion(
        question: 'People invest mainly because:',
        options: [
          'Cash savings alone often can’t outpace long-term goals or inflation',
          'It guarantees a profit',
          'It is required by law',
          'It removes all financial risk',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'Diversification helps because it:',
        options: [
          'Guarantees higher returns',
          'Spreads exposure so one bad performer does less damage',
          'Eliminates all risk',
          'Only applies to bonds',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_18': _LessonContent(
    icon: Icons.stacked_line_chart_rounded,
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
  'test_4': _LessonContent(
    icon: Icons.star_rounded,
    quiz: [
      QuizQuestion(
        question: 'A stock represents:',
        options: [
          'A loan to a company',
          'Ownership in a company',
          'A savings account',
          'A tax form',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'A bond is best described as:',
        options: [
          'Ownership in a company',
          'A loan that earns interest',
          'A basket of assets',
          'A type of bank fee',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Compound growth happens when:',
        options: [
          'Returns start earning returns too',
          'You withdraw money early',
          'Prices never change',
          'You only invest once',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question:
            'For long-term growth, what usually matters more than picking the perfect investment?',
        options: [
          'Starting earlier',
          'Checking prices daily',
          'Avoiding all risk',
          'Following trends',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'A long-term investor mindset means:',
        options: [
          'Reacting to every price swing',
          'Staying focused on strategy instead of short-term noise',
          'Selling as soon as prices dip',
          'Avoiding diversification',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_21': _LessonContent(
    icon: Icons.receipt_long_rounded,
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
  'quiz_5': _LessonContent(
    icon: Icons.bolt_rounded,
    quiz: [
      QuizQuestion(
        question: 'Your budget should be based on:',
        options: [
          'Gross salary',
          'Take-home (net) pay',
          'Expected bonuses',
          'Last year’s income',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'When comparing job offers, you should also weigh:',
        options: [
          'Only the salary number',
          'Benefits, commute, flexibility, and growth opportunities',
          'The company logo',
          'Nothing besides salary',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  'lesson_23': _LessonContent(
    icon: Icons.home_work_rounded,
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
  'test_5': _LessonContent(
    icon: Icons.star_rounded,
    quiz: [
      QuizQuestion(
        question: 'A pay stub shows all of the following EXCEPT:',
        options: [
          'Gross pay and deductions',
          'Taxes and benefits',
          'Net take-home pay',
          'Your neighbor’s salary',
        ],
        correctIndex: 3,
      ),
      QuizQuestion(
        question: 'Beyond rent, monthly housing costs can include:',
        options: [
          'Nothing else',
          'Utilities, internet, parking, and commuting',
          'Only groceries',
          'Only entertainment',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Withholding is:',
        options: [
          'A bonus added to your paycheck',
          'Money set aside from each paycheck for taxes',
          'An optional savings account',
          'A type of investment',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Too little tax withholding during the year can lead to:',
        options: [
          'A larger refund automatically',
          'A tax bill later',
          'Lower rent',
          'No effect at all',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'A personal money plan connects:',
        options: [
          'Only your savings account',
          'Income, bills, savings, debt strategy, and goals',
          'Just your credit score',
          'Only your job title',
        ],
        correctIndex: 1,
      ),
    ],
  ),
};
