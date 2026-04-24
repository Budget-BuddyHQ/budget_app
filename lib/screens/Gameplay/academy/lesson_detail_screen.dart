import 'package:flutter/material.dart';

import '../../../models/lesson.dart';
import '../../../models/progression_service.dart';
import '../../../widgets/game_toast.dart';

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

  void _completeLesson() {
    if (_isCompleted) {
      Navigator.of(context).pop();
      return;
    }

    widget.progressionService.completeLesson(widget.lesson.id);
    setState(() => _isCompleted = true);
    GameToast.show(
      context,
      title: 'Lesson complete',
      message: '${widget.lesson.title} marked complete.',
      icon: Icons.school_rounded,
      accent: const Color(0xFF2F9E68),
    );
  }

  Map<String, dynamic> _getLessonContent() {
    switch (widget.lesson.id) {
      case 'lesson_1':
        return {
          'icon': Icons.account_balance_wallet_rounded,
          'sections': [
            {
              'title': 'What is budgeting?',
              'content':
                  'Budgeting is a plan for how your money will be used before you spend it. It helps you choose what matters most instead of reacting to every expense.',
            },
            {
              'title': 'Why it matters',
              'content':
                  'A budget gives you control, protects your goals, and makes tradeoffs easier because you can see what every dollar is doing.',
            },
            {
              'title': 'A simple starting rule',
              'content':
                  'Try the 50/30/20 rule: 50% for needs, 30% for wants, and 20% for savings or debt payoff. It is not perfect for everyone, but it is a strong first framework.',
            },
          ],
        };
      case 'lesson_2':
        return {
          'icon': Icons.payments_rounded,
          'sections': [
            {
              'title': 'Income comes first',
              'content':
                  'Your budget starts with money coming in. Fixed income is predictable, while variable income changes from paycheck to paycheck.',
            },
            {
              'title': 'Gross vs net',
              'content':
                  'Use net income for planning. Gross income looks bigger, but net income reflects what actually reaches your account.',
            },
          ],
        };
      case 'lesson_3':
        return {
          'icon': Icons.shopping_bag_rounded,
          'sections': [
            {
              'title': 'Track spending patterns',
              'content':
                  'Expenses usually reveal habits faster than intentions do. Looking at recent spending helps you find recurring leaks and spot your essentials.',
            },
            {
              'title': 'Needs and wants',
              'content':
                  'Needs keep life running. Wants can still matter, but they should fit after the essentials and savings plan are covered.',
            },
          ],
        };
      case 'lesson_4':
        return {
          'icon': Icons.savings_rounded,
          'sections': [
            {
              'title': 'Pay yourself first',
              'content':
                  'Saving works best when it is treated like a required bill instead of whatever is left over at the end of the month.',
            },
            {
              'title': 'Start smaller than feels impressive',
              'content':
                  'Consistency beats intensity. A small automatic transfer repeated every week usually wins over occasional big efforts.',
            },
          ],
        };
      case 'lesson_5':
        return {
          'icon': Icons.pie_chart_rounded,
          'sections': [
            {
              'title': 'Build the plan',
              'content':
                  'List income, fixed costs, flexible spending, savings goals, and debt payments in one place. Then compare the total against your take-home pay.',
            },
            {
              'title': 'Review regularly',
              'content':
                  'Budgets are living tools. Review them often and adjust after changes in income, bills, or priorities.',
            },
          ],
        };
      case 'lesson_6':
        return {
          'icon': Icons.credit_card_rounded,
          'sections': [
            {
              'title': 'Credit is borrowed trust',
              'content':
                  'Credit lets you use money now and repay it later. Used well, it builds options. Used carelessly, it becomes expensive debt.',
            },
            {
              'title': 'Healthy credit habits',
              'content':
                  'Pay on time, keep balances low, and avoid treating credit limits like spending targets.',
            },
          ],
        };
      case 'lesson_7':
        return {
          'icon': Icons.show_chart_rounded,
          'sections': [
            {
              'title': 'Investing is long-term',
              'content':
                  'Investing gives your money a chance to grow faster than cash savings, but it works best over longer time horizons.',
            },
            {
              'title': 'Risk and return move together',
              'content':
                  'Higher return potential usually comes with more uncertainty. Diversification helps reduce the risk of any single investment going badly.',
            },
          ],
        };
      case 'lesson_8':
        return {
          'icon': Icons.account_balance_rounded,
          'sections': [
            {
              'title': 'Choose the right tools',
              'content':
                  'Checking accounts, savings accounts, alerts, and autopay features all support different money habits. The right setup reduces friction.',
            },
            {
              'title': 'Bank with intention',
              'content':
                  'Look at fees, digital tools, transfer speed, and customer support instead of picking an account only because it is nearby.',
            },
          ],
        };
      case 'lesson_9':
        return {
          'icon': Icons.warning_amber_rounded,
          'sections': [
            {
              'title': 'Emergencies will happen',
              'content':
                  'An emergency fund protects your budget from turning into new debt when life throws you a surprise.',
            },
            {
              'title': 'Accessible beats fancy',
              'content':
                  'Emergency money should stay easy to reach and separate from everyday spending so it is there when you need it.',
            },
          ],
        };
      case 'lesson_10':
        return {
          'icon': Icons.flag_rounded,
          'sections': [
            {
              'title': 'Give money a destination',
              'content':
                  'Long-term goals turn abstract saving into something concrete. Good goals are specific, measurable, and tied to a timeline.',
            },
            {
              'title': 'Progress builds motivation',
              'content':
                  'Tracking milestones makes large goals feel real and keeps consistent habits from feeling invisible.',
            },
          ],
        };
      default:
        return {
          'icon': switch (widget.lesson.type) {
            LessonNodeType.lesson => Icons.crop_square_rounded,
            LessonNodeType.quiz => Icons.bolt_rounded,
            LessonNodeType.unitTest => Icons.star_rounded,
          },
          'sections': [
            {
              'title': widget.lesson.title,
              'content':
                  widget.lesson.type == LessonNodeType.quiz
                      ? 'This quick quiz checks how well the ideas from the unit are sticking before you move on.'
                      : 'This unit test brings the key ideas together so you can confirm your understanding before the next unit.',
            },
          ],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _getLessonContent();
    final sections = content['sections'] as List<Map<String, String>>;
    final icon = content['icon'] as IconData;

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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F8EF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, color: const Color(0xFF2F9E68)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lesson.title,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.lesson.estimatedMinutes} min lesson',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...sections.map(
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
                          section['title']!,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          section['content']!,
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
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
                child: Text(
                  _isCompleted ? 'Return to Units' : 'Complete Lesson',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
