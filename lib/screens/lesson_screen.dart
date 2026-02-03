import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/progression_service.dart';

/// Screen for displaying and completing a lesson with detailed content
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final ProgressionService progressionService;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.progressionService,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(_bgController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
    ]).animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _completeLesson(BuildContext context) {
    widget.progressionService.completeLesson(widget.lesson.id);
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.lesson.title} completed! 🎉'),
<<<<<<< Updated upstream
        backgroundColor: const Color(0xFF2E4A3D),
=======
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
>>>>>>> Stashed changes
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _getLessonContent() {
    switch (widget.lesson.id) {
      case 'lesson_1':
        return {
          'icon': Icons.account_balance_wallet,
          'sections': [
            {
              'title': 'What is Budgeting? 💰',
              'content':
                  'Budgeting is a plan for how you will spend your money. Think of it as a roadmap that helps you decide where your money should go before you spend it.',
            },
            {
              'title': 'Why Budget?',
              'content':
                  'Budgeting helps you:\n• Control your spending\n• Save money for goals\n• Avoid debt\n• Plan for emergencies\n• Make informed financial decisions',
            },
            {
              'title': 'The 50/30/20 Rule',
              'content':
                  'A simple budgeting method:\n\n• 50% for Needs (housing, food, bills)\n• 30% for Wants (entertainment, hobbies)\n• 20% for Savings and debt repayment',
            },
            {
              'title': 'Getting Started',
              'content':
                  '1. Track your income (money coming in)\n2. List your expenses (money going out)\n3. Compare income vs expenses\n4. Adjust spending to meet your goals',
            },
          ],
        };
      case 'lesson_2':
        return {
          'icon': Icons.trending_up,
          'sections': [
            {
              'title': 'Understanding Income 💵',
              'content':
                  'Income is the money you receive regularly. It can come from a job, allowance, gifts, or other sources.',
            },
            {
              'title': 'Types of Income',
              'content':
                  '• Fixed Income: Same amount regularly (salary, allowance)\n• Variable Income: Changes each time (tips, freelance work)\n• Passive Income: Money earned with little effort (investments)',
            },
            {
              'title': 'Gross vs Net Income',
              'content':
                  '• Gross Income: Total money before deductions\n• Net Income: Money you actually receive after taxes and deductions\n\nAlways budget with your net income!',
            },
            {
              'title': 'Increasing Your Income',
              'content':
                  'Ways to earn more:\n• Develop new skills\n• Take on part-time work\n• Start a small business\n• Invest in education\n• Save and invest wisely',
            },
          ],
        };
      case 'lesson_3':
        return {
          'icon': Icons.shopping_cart,
          'sections': [
            {
              'title': 'Expenses and Spending 💸',
              'content':
                  'Expenses are the money you spend. Understanding your expenses is key to successful budgeting.',
            },
            {
              'title': 'Fixed vs Variable Expenses',
              'content':
                  '• Fixed Expenses: Same amount each month (rent, phone bill)\n• Variable Expenses: Change each month (groceries, entertainment)\n\nFixed expenses are easier to plan for!',
            },
            {
              'title': 'Needs vs Wants',
              'content':
                  '• Needs: Essential items (food, shelter, clothing)\n• Wants: Things you desire but don\'t need (latest phone, designer clothes)\n\nAlways prioritize needs over wants!',
            },
            {
              'title': 'Smart Spending Tips',
              'content':
                  '• Compare prices before buying\n• Wait 24 hours before big purchases\n• Use coupons and discounts\n• Buy generic brands when possible\n• Track every expense',
            },
          ],
        };
      case 'lesson_4':
        return {
          'icon': Icons.savings,
          'sections': [
            {
              'title': 'Saving Strategies 🏦',
              'content':
                  'Saving money is setting aside part of your income for future use. It\'s one of the most important financial habits!',
            },
            {
              'title': 'Why Save?',
              'content':
                  '• Emergency fund for unexpected expenses\n• Achieve financial goals (car, college, vacation)\n• Build wealth over time\n• Gain financial security and peace of mind',
            },
            {
              'title': 'The Pay Yourself First Rule',
              'content':
                  'Before spending on anything else, set aside money for savings. Even 10% of your income can make a big difference over time!',
            },
            {
              'title': 'Saving Tips',
              'content':
                  '• Start small - even \$5 a week adds up\n• Set specific savings goals\n• Use automatic transfers\n• Save windfalls (gifts, tax refunds)\n• Track your progress',
            },
            {
              'title': 'Compound Interest',
              'content':
                  'When you save money in an account that earns interest, you earn interest on your interest! This helps your money grow faster over time.',
            },
          ],
        };
      case 'lesson_5':
        return {
          'icon': Icons.pie_chart,
          'sections': [
            {
              'title': 'Building Your Budget 📊',
              'content':
                  'Now that you understand income, expenses, and savings, let\'s put it all together into a working budget!',
            },
            {
              'title': 'Step 1: Calculate Income',
              'content':
                  'Add up all sources of income for the month. Use your net income (after taxes and deductions).',
            },
            {
              'title': 'Step 2: List All Expenses',
              'content':
                  'Write down every expense:\n• Fixed expenses (rent, bills)\n• Variable expenses (food, gas)\n• Savings goals\n• Emergency fund',
            },
            {
              'title': 'Step 3: Compare and Adjust',
              'content':
                  '• If expenses > income: Reduce spending\n• If income > expenses: Increase savings\n• Aim for a balanced budget',
            },
            {
              'title': 'Step 4: Track and Review',
              'content':
                  '• Track spending throughout the month\n• Review your budget weekly\n• Adjust as needed\n• Celebrate when you meet goals!',
            },
            {
              'title': 'Budget Tools',
              'content':
                  'You can use:\n• Pen and paper\n• Spreadsheets (Excel, Google Sheets)\n• Budget apps\n• The Budget Simulator in this app!',
            },
          ],
        };
      case 'lesson_6':
        return {
          'icon': Icons.credit_card,
          'sections': [
            {
              'title': 'Credit and Debt Management 💳',
              'content':
                  'Credit can be a powerful tool when used wisely, but debt can become a burden. Learn how to manage both effectively.',
            },
            {
              'title': 'What is Credit?',
              'content':
                  'Credit is the ability to borrow money or access goods/services with the understanding you\'ll pay later. Your credit score reflects how trustworthy you are as a borrower.',
            },
            {
              'title': 'Types of Debt',
              'content':
                  '• Good Debt: Investments that increase in value (student loans, mortgages)\n• Bad Debt: Things that lose value quickly (credit card debt for non-essentials)\n\nAlways minimize bad debt!',
            },
            {
              'title': 'Credit Card Basics',
              'content':
                  '• Pay your balance in full each month to avoid interest\n• Never spend more than you can afford\n• Use credit cards for convenience, not as extra income\n• Keep your credit utilization below 30%',
            },
            {
              'title': 'Managing Debt',
              'content':
                  '• Pay more than the minimum payment\n• Focus on high-interest debt first (debt avalanche)\n• Consider debt consolidation if you have multiple debts\n• Create a debt payoff plan',
            },
            {
              'title': 'Building Good Credit',
              'content':
                  '• Pay bills on time, every time\n• Keep old accounts open (longer credit history)\n• Don\'t apply for too many credit cards at once\n• Monitor your credit report regularly',
            },
          ],
        };
      case 'lesson_7':
        return {
          'icon': Icons.trending_up,
          'sections': [
            {
              'title': 'Introduction to Investing 📈',
              'content':
                  'Investing is putting your money to work so it can grow over time. Start early, and time becomes your best friend!',
            },
            {
              'title': 'Why Invest?',
              'content':
                  '• Beat inflation (prices go up over time)\n• Build wealth faster than saving alone\n• Achieve long-term financial goals\n• Create passive income streams',
            },
            {
              'title': 'Investment Basics',
              'content':
                  '• Stocks: Ownership in companies (higher risk, higher potential return)\n• Bonds: Loans to companies/governments (lower risk, steady income)\n• Mutual Funds: Diversified portfolios managed by professionals\n• ETFs: Like mutual funds but trade like stocks',
            },
            {
              'title': 'Risk vs Return',
              'content':
                  'Generally:\n• Higher risk = Higher potential return\n• Lower risk = Lower potential return\n\nDiversification (spreading investments) reduces risk!',
            },
            {
              'title': 'Getting Started',
              'content':
                  '• Start with index funds (diversified, low fees)\n• Invest regularly (dollar-cost averaging)\n• Think long-term (5+ years)\n• Don\'t try to time the market\n• Invest only money you won\'t need soon',
            },
            {
              'title': 'The Power of Compound Interest',
              'content':
                  'When you invest, you earn returns on your returns! Starting early means your money has more time to compound, leading to significantly larger wealth over decades.',
            },
          ],
        };
      case 'lesson_8':
        return {
          'icon': Icons.account_balance,
          'sections': [
            {
              'title': 'Banking and Financial Tools 🏦',
              'content':
                  'Understanding banking products and tools helps you manage money efficiently and make informed financial decisions.',
            },
            {
              'title': 'Types of Bank Accounts',
              'content':
                  '• Checking Account: For daily transactions (debit card, checks)\n• Savings Account: For storing money and earning interest\n• Money Market Account: Higher interest, limited transactions\n• Certificate of Deposit (CD): Lock money for a set period, earn higher interest',
            },
            {
              'title': 'Choosing a Bank',
              'content':
                  'Consider:\n• Fees (monthly, ATM, overdraft)\n• Interest rates on savings\n• Branch and ATM locations\n• Online/mobile banking features\n• Customer service quality',
            },
            {
              'title': 'Online Banking Benefits',
              'content':
                  '• 24/7 access to your accounts\n• Mobile check deposit\n• Automatic bill pay\n• Real-time transaction alerts\n• Budget tracking tools',
            },
            {
              'title': 'Financial Apps and Tools',
              'content':
                  'Use technology to your advantage:\n• Budget tracking apps\n• Investment platforms\n• Credit score monitors\n• Bill reminder apps\n• Expense categorization tools',
            },
            {
              'title': 'Safety and Security',
              'content':
                  '• Use strong, unique passwords\n• Enable two-factor authentication\n• Monitor accounts regularly\n• Never share banking information\n• Use secure Wi-Fi for transactions',
            },
          ],
        };
      case 'lesson_9':
        return {
          'icon': Icons.warning,
          'sections': [
            {
              'title': 'Emergency Planning 🚨',
              'content':
                  'Life is unpredictable. An emergency fund protects you from financial disasters and gives you peace of mind.',
            },
            {
              'title': 'What is an Emergency Fund?',
              'content':
                  'An emergency fund is money set aside to cover unexpected expenses like:\n• Medical emergencies\n• Car repairs\n• Job loss\n• Home repairs\n• Unexpected travel',
            },
            {
              'title': 'How Much to Save',
              'content':
                  '• Starter goal: \$1,000 (covers small emergencies)\n• Full goal: 3-6 months of expenses\n• Calculate: Add up all monthly expenses × 3-6\n\nStart small, build gradually!',
            },
            {
              'title': 'Where to Keep It',
              'content':
                  'Emergency funds should be:\n• Easily accessible (savings account)\n• Separate from regular spending\n• Not invested (too risky)\n• In a high-yield savings account if possible',
            },
            {
              'title': 'Building Your Fund',
              'content':
                  '• Set up automatic transfers\n• Save windfalls (tax refunds, gifts)\n• Cut one expense and save the difference\n• Save a percentage of every paycheck\n• Make it a priority, not an afterthought',
            },
            {
              'title': 'When to Use It',
              'content':
                  'Only use for TRUE emergencies:\n✓ Unexpected medical bills\n✓ Essential car repairs\n✓ Job loss\n✗ Planned vacations\n✗ Shopping sprees\n✗ Non-essential purchases',
            },
          ],
        };
      case 'lesson_10':
        return {
          'icon': Icons.flag,
          'sections': [
            {
              'title': 'Long-Term Financial Goals 🎯',
              'content':
                  'Setting and achieving long-term financial goals gives your money purpose and direction. Dream big, plan smart!',
            },
            {
              'title': 'Types of Financial Goals',
              'content':
                  '• Short-term (1-2 years): Vacation, emergency fund, small purchases\n• Mid-term (3-5 years): Car, down payment, major purchases\n• Long-term (5+ years): Retirement, house, children\'s education, financial independence',
            },
            {
              'title': 'SMART Goals Framework',
              'content':
                  'Make goals:\n• Specific: "Save \$50,000 for a house down payment"\n• Measurable: Track progress monthly\n• Achievable: Realistic based on your income\n• Relevant: Aligned with your values\n• Time-bound: "In 5 years"',
            },
            {
              'title': 'Prioritizing Goals',
              'content':
                  'Order of priority:\n1. Emergency fund (financial safety net)\n2. High-interest debt payoff\n3. Retirement savings (start early!)\n4. Other long-term goals\n5. Short-term wants',
            },
            {
              'title': 'Creating a Plan',
              'content':
                  'For each goal:\n• Calculate total amount needed\n• Set a deadline\n• Determine monthly savings required\n• Automate savings if possible\n• Review and adjust quarterly',
            },
            {
              'title': 'Staying Motivated',
              'content':
                  '• Visualize your goals (vision board, photos)\n• Celebrate milestones\n• Track progress visually\n• Share goals with someone for accountability\n• Review goals regularly\n• Adjust as life changes',
            },
            {
              'title': 'The Journey Ahead',
              'content':
                  'Financial literacy is a lifelong journey. Keep learning, stay disciplined, and remember: small consistent actions lead to big results over time. You\'ve got this! 🎉',
            },
          ],
        };
      default:
        return {
          'icon': Icons.school,
          'sections': [
            {
              'title': widget.lesson.title,
              'content': 'Lesson content coming soon!',
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: [
<<<<<<< Updated upstream
                  const Color(0xFF2E4A3D), // Deep Forest
                  const Color(0xFF1B3329), // Darker Forest
                  const Color(0xFF2E4A3D),
=======
                  const Color.fromARGB(255, 25, 210, 155),
                  const Color.fromARGB(255, 96, 170, 36),
                  const Color.fromARGB(255, 25, 210, 155),
>>>>>>> Stashed changes
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Placeholder (White Screen)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 80,
<<<<<<< Updated upstream
                            color: const Color(0xFF2E4A3D),
=======
                            color: const Color.fromARGB(
                              255,
                              96,
                              170,
                              36,
                            ).withOpacity(0.8),
>>>>>>> Stashed changes
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Lesson sections with entrance animations
                      ...sections.asMap().entries.map((entry) {
                        final index = entry.key;
                        final section = entry.value;
                        return _buildAnimatedSection(
                          section['title']!,
                          section['content']!,
                          index,
                        );
                      }),

                      // Spacer to allow content to scroll above fixed button
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),

              // Complete button with glassmorphism
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.8), Colors.white],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeLesson(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF76FF03), // Lime
                      foregroundColor: const Color(0xFF1B3329), // Dark Text
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 12,
<<<<<<< Updated upstream
                      shadowColor: const Color(0xFF76FF03).withOpacity(0.5),
=======
                      shadowColor: const Color.fromARGB(
                        255,
                        96,
                        170,
                        36,
                      ).withOpacity(0.5),
>>>>>>> Stashed changes
                    ),
                    child: const Text(
                      'Complete Lesson',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(String title, String content, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          ),
        );
      },
      child: _buildSection(title, content),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 40, 40, 40),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}
