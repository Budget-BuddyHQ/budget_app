// lib/screens/goals_setup_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../Gameplay/main_game_screen.dart';

class GoalsSetupPage extends StatefulWidget {
  const GoalsSetupPage({
    super.key,
    this.onContinue,
  });

  final Future<void> Function(List<String> selectedGoalIds)? onContinue;

  @override
  State<GoalsSetupPage> createState() => _GoalsSetupPageState();
}

class _GoalsSetupPageState extends State<GoalsSetupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const Color deepForest = Color(0xFF1B3329);
  static const Color forestGreen = Color(0xFF2E4A3D);
  static const Color darkGreen = Color(0xFF0F2018);
  static const Color limeAccent = Color(0xFF76FF03);

  final List<_GoalOption> _goals = const [
    _GoalOption(
      id: 'track_spending',
      title: 'Track Spending',
      icon: Icons.receipt_long,
    ),
    _GoalOption(
      id: 'build_budget',
      title: 'Build a Budget',
      icon: Icons.pie_chart_outline,
    ),
    _GoalOption(
      id: 'save_more',
      title: 'Save More',
      icon: Icons.savings_outlined,
    ),
    _GoalOption(
      id: 'pay_off_debt',
      title: 'Pay Off Debt',
      icon: Icons.trending_down,
    ),
    _GoalOption(
      id: 'emergency_fund',
      title: 'Emergency Fund',
      icon: Icons.health_and_safety_outlined,
    ),
    _GoalOption(
      id: 'invest_basics',
      title: 'Learn Investing',
      icon: Icons.show_chart,
    ),
    _GoalOption(
      id: 'avoid_impulse',
      title: 'Avoid Impulse Buys',
      icon: Icons.shopping_cart_outlined,
    ),
    _GoalOption(
      id: 'credit_score',
      title: 'Improve Credit',
      icon: Icons.verified_outlined,
    ),
  ];

  final Set<String> _selectedGoalIds = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleGoal(String id) {
    setState(() {
      if (_selectedGoalIds.contains(id)) {
        _selectedGoalIds.remove(id);
      } else {
        _selectedGoalIds.add(id);
      }
    });
  }

  Future<void> _handleContinue() async {
    if (_selectedGoalIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one goal.'),
        ),
      );
      return;
    }

    if (widget.onContinue != null) {
      await widget.onContinue!(_selectedGoalIds.toList());
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainGameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curve, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, forestGreen, darkGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedItem(
                      0,
                      Center(
                        child: Container(
                          height: 92,
                          width: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: limeAccent.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: limeAccent.withValues(alpha: 0.18),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flag_outlined,
                            color: limeAccent,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      1,
                      const Text(
                        'Choose Your Goals',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildAnimatedItem(
                      2,
                      Text(
                        'Select what you want to work toward so we can personalize your experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      3,
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('What are your priorities?'),
                              const SizedBox(height: 14),
                              GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 2.6,
                                children: _goals.map((goal) {
                                  final selected = _selectedGoalIds.contains(goal.id);

                                  return _GoalChip(
                                    title: goal.title,
                                    icon: goal.icon,
                                    selected: selected,
                                    onTap: () => _toggleGoal(goal.id),
                                    limeAccent: limeAccent,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    _buildAnimatedItem(
                      4,
                      FractionallySizedBox(
                        widthFactor: 0.96,
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: limeAccent,
                            foregroundColor: deepForest,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: limeAccent.withValues(alpha: 0.45),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildAnimatedItem(
                      5,
                      const Text(
                        'We’ll use your selections to tailor lessons, tools, and recommendations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(index * 0.08, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GoalOption {
  final String id;
  final String title;
  final IconData icon;

  const _GoalOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.limeAccent,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color limeAccent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? limeAccent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? limeAccent.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? limeAccent : Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}