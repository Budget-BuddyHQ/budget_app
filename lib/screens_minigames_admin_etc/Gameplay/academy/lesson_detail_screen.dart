import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> _completeLesson() async {
    if (_isSaving) {
      return;
    }

    if (_isCompleted) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    widget.progressionService.completeLesson(widget.lesson.id);

    final result = await context
        .read<UserStatsController>()
        .completeLessonProgress(
          lessonId: widget.lesson.id,
          lessonTitle: widget.lesson.title,
          xpEarned: 12,
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
      message: '${widget.lesson.title} saved. ${result.message}',
      icon: Icons.school_rounded,
      accent: const Color(0xFF2F9E68),
      soundEffect: AppSoundEffect.celebration,
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          widget.lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  '${widget.unit.title} > ${widget.lesson.title}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
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
                ...content.sections.map(
                  (section) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          section.content,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 16,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: FilledButton(
                onPressed: _completeLesson,
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 420;

          final leading = Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8EF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF2F9E68)),
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessonTitle,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$estimatedMinutes min lesson',
                style: const TextStyle(
                  color: Color(0xFF475569),
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

class _LessonContent {
  const _LessonContent({required this.icon, required this.sections});

  final IconData icon;
  final List<_LessonSection> sections;
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
};

