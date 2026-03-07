// lib/screens/goals_setup_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';

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

  static const deepForest = Color(0xFF1B3329);
  static const limeAccent = Color(0xFF76FF03);

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
      duration: const Duration(milliseconds: 900),
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
        const SnackBar(content: Text('Please select at least one goal.')),
      );
      return;
    }

    if (widget.onContinue != null) {
      await widget.onContinue!(_selectedGoalIds.toList());
    }

    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Your Goals'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, Color(0xFF2E4A3D), Color(0xFF0F2018)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedItem(
                      0,
                      const Text(
                        'What are you working toward?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedItem(
                      1,
                      _buildGlassCard(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _goals.map((goal) {
                            final selected =
                                _selectedGoalIds.contains(goal.id);
                            return _GoalChip(
                              title: goal.title,
                              icon: goal.icon,
                              selected: selected,
                              onTap: () => _toggleGoal(goal.id),
                              limeAccent: limeAccent,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedItem(
                      2,
                      ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeAccent,
                          foregroundColor: deepForest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? limeAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: selected
                ? limeAccent.withValues(alpha: 0.75)
                :  Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? limeAccent : Colors.white70),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}