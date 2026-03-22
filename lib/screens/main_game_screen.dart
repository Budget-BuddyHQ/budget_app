import 'package:flutter/material.dart';
import 'user_profile_screen.dart';
import '../screens/Gameplay/game_hub_screen.dart';
import 'NavBarClass/custom_bottom_nav.dart';

class MainGameScreen extends StatelessWidget {
  const MainGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF1A4D3D);
    const cardBg = Color(0xFF254E3F);
    const cardBorder = Color(0xFF3B6B59);
    const accent = Color(0xFF85EFAC);


    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: const CustomBottomNav(activeIndex: 0, ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TopBar(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DailyInsightCard(background: cardBg, border: cardBorder),
                    const SizedBox(height: 16),
                    const Text(
                      "Week's Progress Metrics",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            background: cardBg,
                            border: cardBorder,
                            title: 'Savings Rate',
                            value: '72%',
                            subtitle: 'of goal',
                            icon: Icons.savings,
                            accent: accent,
                            showProgress: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            background: cardBg,
                            border: cardBorder,
                            title: 'Literacy Points',
                            value: '850',
                            subtitle: 'Knowledge Score',
                            icon: Icons.psychology,
                            accent: accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            background: cardBg,
                            border: cardBorder,
                            title: 'Investment ROI',
                            value: '+12.5%',
                            subtitle: 'This Month',
                            icon: Icons.trending_up,
                            accent: accent,
                            showSparkline: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Daily Challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BudgetBattleCard(
                      background: cardBg,
                      border: cardBorder,
                      accent: accent,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Progress Bar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ProgressBarRow(
                      label: 'Current Weekly Goals',
                      value: 0.65,
                      percentText: '65%',
                      accent: accent,
                    ),
                    const SizedBox(height: 10),
                    _ProgressBarRow(
                      label: 'Overall Completion',
                      value: 0.42,
                      percentText: '42%',
                      accent: accent,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LeaderboardTable(
                      background: cardBg,
                      border: cardBorder,
                      accent: accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4E3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF85EFAC),
            child: Icon(Icons.person, size: 18, color: Color(0xFF1A4D3D)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Current Balance: \$2450',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Level 7 Finance Wizard',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(width: 10),
          Icon(Icons.notifications_none, color: Colors.white70),
        ],
      ),
    );
  }
}

class _DailyInsightCard extends StatelessWidget {
  final Color background;
  final Color border;

  const _DailyInsightCard({required this.background, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF85EFAC),
                child: Icon(
                  Icons.lightbulb,
                  size: 18,
                  color: Color(0xFF1A4D3D),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Daily Budget Insight',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?auto=format&fit=crop&w=900&q=80',
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A penny saved is a penny earned—Invest \$10 today for a 5% gain!',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Color background;
  final Color border;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool showProgress;
  final bool showSparkline;

  const _MetricCard({
    required this.background,
    required this.border,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.showProgress = false,
    this.showSparkline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.72,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
          if (showSparkline) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 20,
              child: CustomPaint(
                painter: _SparklinePainter(accent),
                size: const Size(double.infinity, 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.6)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.25);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BudgetBattleCard extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;

  const _BudgetBattleCard({
    required this.background,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: Color(0xFF85EFAC), size: 18),
              SizedBox(width: 8),
              Text(
                'THE BUDGET BATTLE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyze this \$50 Grocery Receipt and find 3 savings.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF1A4D3D),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Start Challenge'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final double value;
  final String percentText;
  final Color accent;

  const _ProgressBarRow({
    required this.label,
    required this.value,
    required this.percentText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              percentText,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;

  const _LeaderboardTable({
    required this.background,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _LeaderRow(rank: '🥇', name: 'MoneyMaster99', points: '2,450'),
      _LeaderRow(rank: '🥈', name: 'BudgetPro', points: '2,280'),
      _LeaderRow(
        rank: '🥉',
        name: 'Username3189 (You)',
        points: '2,150',
        highlight: true,
      ),
      _LeaderRow(rank: '4', name: 'SaverSally', points: '2,020'),
      _LeaderRow(rank: '5', name: 'InvestorMax', points: '1,890'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 30,
                  child: Text(
                    '#',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    'User',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Points',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final String rank;
  final String name;
  final String points;
  final bool highlight;

  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.points,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF2B5A4A) : Colors.transparent,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(rank, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: highlight ? const Color(0xFF85EFAC) : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              points,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
