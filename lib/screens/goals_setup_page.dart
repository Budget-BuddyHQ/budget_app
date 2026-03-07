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

    Navigator.pushReplacementNamed(context, '/home');
  }

  String get _selectionLabel {
    final count = _selectedGoalIds.length;
    if (count == 0) return 'Select at least one goal';
    if (count == 1) return '1 goal selected';
    return '$count goals selected';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 700;

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
            colors: [deepForest, forestGreen, darkGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildAnimatedItem(
                      0,
                      Column(
                        children: [
                          Text(
                            'What are you working toward?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isWide ? 34 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: const Text(
                              'Choose one or more goals so we can personalize your financial learning experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectionLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedGoalIds.isEmpty
                                  ? Colors.white60
                                  : limeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildAnimatedItem(
                      1,
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Select your priorities',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You can choose more than one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: _goals.map((goal) {
                                final bool selected =
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildAnimatedItem(
                      2,
                      ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeAccent,
                          foregroundColor: deepForest,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 10,
                          shadowColor: limeAccent.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedItem(
                      3,
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

  Widget _buildAnimatedItem(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.8);
    final end = (start + 0.45).clamp(0.0, 1.0);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
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
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? limeAccent.withValues(alpha: 0.17)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? limeAccent.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.15,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: limeAccent.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? limeAccent : Colors.white70,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}