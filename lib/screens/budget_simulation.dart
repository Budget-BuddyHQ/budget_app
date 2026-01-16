import 'package:flutter/material.dart';

class BudgetSimulationScreen extends StatefulWidget {
  const BudgetSimulationScreen({super.key});

  @override
  State<BudgetSimulationScreen> createState() => _BudgetSimulationScreenState();
}

class _BudgetSimulationScreenState extends State<BudgetSimulationScreen>
    with TickerProviderStateMixin {
  // Budget variables
  double monthlyIncome = 3000.0;
  double housing = 1000.0;
  double food = 400.0;
  double transportation = 300.0;
  double entertainment = 200.0;
  double savings = 500.0;
  double other = 200.0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _chartController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for balance indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Chart animation
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    _chartController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  double get totalExpenses =>
      housing + food + transportation + entertainment + savings + other;

  double get remainingBalance => monthlyIncome - totalExpenses;

  Color get balanceColor {
    if (remainingBalance > 0) return Colors.green;
    if (remainingBalance == 0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Simulator'),
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 96, 170, 36),
              Color.fromARGB(255, 230, 245, 220),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  '💰 Monthly Budget Simulator',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Adjust your expenses and see how they affect your budget!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),

                // Balance Card with Animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildBalanceCard(),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Income Slider
                _buildSectionTitle('Monthly Income'),
                _buildSliderCard(
                  'Income',
                  monthlyIncome,
                  1000,
                  10000,
                  Icons.account_balance_wallet,
                  Colors.blue,
                  (value) => setState(() => monthlyIncome = value),
                ),
                const SizedBox(height: 20),

                // Expenses Section
                _buildSectionTitle('Monthly Expenses'),
                
                _buildSliderCard(
                  'Housing',
                  housing,
                  0,
                  5000,
                  Icons.home,
                  Colors.purple,
                  (value) => setState(() => housing = value),
                ),
                const SizedBox(height: 12),
                
                _buildSliderCard(
                  'Food',
                  food,
                  0,
                  2000,
                  Icons.restaurant,
                  Colors.orange,
                  (value) => setState(() => food = value),
                ),
                const SizedBox(height: 12),
                
                _buildSliderCard(
                  'Transportation',
                  transportation,
                  0,
                  1500,
                  Icons.directions_car,
                  Colors.blue,
                  (value) => setState(() => transportation = value),
                ),
                const SizedBox(height: 12),
                
                _buildSliderCard(
                  'Entertainment',
                  entertainment,
                  0,
                  1000,
                  Icons.movie,
                  Colors.pink,
                  (value) => setState(() => entertainment = value),
                ),
                const SizedBox(height: 12),
                
                _buildSliderCard(
                  'Savings',
                  savings,
                  0,
                  3000,
                  Icons.savings,
                  Colors.green,
                  (value) => setState(() => savings = value),
                ),
                const SizedBox(height: 12),
                
                _buildSliderCard(
                  'Other',
                  other,
                  0,
                  1000,
                  Icons.more_horiz,
                  Colors.grey,
                  (value) => setState(() => other = value),
                ),
                const SizedBox(height: 30),

                // Visual Chart
                _buildSectionTitle('Expense Breakdown'),
                _buildExpenseChart(),
                const SizedBox(height: 20),

                // Tips Section
                _buildTipsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: balanceColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(
                remainingBalance >= 0 ? Icons.check_circle : Icons.warning,
                color: balanceColor,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${remainingBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: balanceColor,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (totalExpenses / monthlyIncome).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(balanceColor),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            'Spent: \$${totalExpenses.toStringAsFixed(2)} / \$${monthlyIncome.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSliderCard(
    String label,
    double value,
    double min,
    double max,
    IconData icon,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 50).round(),
            activeColor: color,
            inactiveColor: Colors.grey[300],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    final expenses = [
      {'name': 'Housing', 'amount': housing, 'color': Colors.purple},
      {'name': 'Food', 'amount': food, 'color': Colors.orange},
      {'name': 'Transport', 'amount': transportation, 'color': Colors.blue},
      {'name': 'Entertainment', 'amount': entertainment, 'color': Colors.pink},
      {'name': 'Savings', 'amount': savings, 'color': Colors.green},
      {'name': 'Other', 'amount': other, 'color': Colors.grey},
    ];

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: expenses.map((expense) {
              final percentage = totalExpenses > 0
                  ? (expense['amount'] as double) / totalExpenses
                  : 0.0;
              final animatedWidth = percentage * _chartAnimation.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          expense['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${(expense['amount'] as double).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: expense['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: animatedWidth,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: expense['color'] as Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTipsCard() {
    String tip;
    IconData tipIcon;
    Color tipColor;

    if (remainingBalance < 0) {
      tip = '⚠️ You\'re overspending! Try reducing some expenses.';
      tipIcon = Icons.warning;
      tipColor = Colors.red;
    } else if (remainingBalance == 0) {
      tip = '⚖️ Perfect balance! Consider adding a small buffer.';
      tipIcon = Icons.balance;
      tipColor = Colors.orange;
    } else if (savings / monthlyIncome < 0.1) {
      tip = '💡 Great! Try to save at least 10% of your income.';
      tipIcon = Icons.lightbulb;
      tipColor = Colors.blue;
    } else {
      tip = '🎉 Excellent budgeting! You\'re on the right track!';
      tipIcon = Icons.celebration;
      tipColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: tipColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(tipIcon, color: tipColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tipColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
