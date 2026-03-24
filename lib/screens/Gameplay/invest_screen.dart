import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../../services/database_service.dart';
import '../reusable_widgets/custom_bottom_nav.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({
    super.key,
    this.activeTabIndex = 2,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  final List<double> _portfolioSeries = <double>[
    0.28,
    0.32,
    0.38,
    0.35,
    0.46,
    0.52,
    0.58,
  ];

  int _indexFundLots = 3;
  int _stockLots = 2;
  bool _isSaving = false;

  double get _portfolioValue =>
      (_indexFundLots * 210 + _stockLots * 165).toDouble();

  Future<void> _applyTrade({
    required BuildContext context,
    required String label,
    required int goldDelta,
    required double growthShift,
    required VoidCallback onApplied,
  }) async {
    final user = UserProgressState.instance;
    final success = user.applyEconomyAction(
      goldDelta: goldDelta,
      label: label,
      meta: 'Invest tab',
      xpDelta: goldDelta < 0 ? 18 : 10,
      literacyDelta: 8,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough gold for that move yet.'),
        ),
      );
      return;
    }

    setState(() {
      onApplied();
      final nextPoint =
          ((_portfolioSeries.last + growthShift).clamp(0.18, 0.95) as num)
              .toDouble();
      _portfolioSeries
        ..removeAt(0)
        ..add(nextPoint);
      _isSaving = true;
    });

    final result = await DatabaseService.instance.syncGameplayResults(
      <String, dynamic>{
        'id': user.userId,
        'username': user.username,
        'gold': user.gold,
        'xp': user.xp,
        'literacy_score': user.literacyPoints,
        'personality_type': user.personalityType,
        'spending_habits': user.spendingHabits,
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Investment synced.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF1A4D3D);
    const cardBg = Color(0xFF254E3F);
    const cardBorder = Color(0xFF3B6B59);
    const accent = Color(0xFF85EFAC);

    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final user = UserProgressState.instance;
        return Scaffold(
          backgroundColor: background,
          bottomNavigationBar: widget.onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: widget.activeTabIndex,
                  onSelected: widget.onNavSelected,
                ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invest Lab',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Grow your gold with small, learnable investment moves.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.stacked_line_chart,
                              color: accent,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Simulated Portfolio Growth',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_isSaving)
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _PortfolioChartPainter(
                              points: _portfolioSeries,
                              accent: accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _InvestmentStat(
                                label: 'Portfolio Value',
                                value: '\$${_portfolioValue.toStringAsFixed(0)}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InvestmentStat(
                                label: 'Available Gold',
                                value: '\$${user.gold}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InvestmentStat(
                                label: 'Literacy Score',
                                value: '${user.literacyPoints}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          title: 'Buy Index Fund',
                          subtitle: 'Spend 200 gold to add a steady long-term asset.',
                          buttonLabel: 'Invest 200',
                          onPressed: () => _applyTrade(
                            context: context,
                            label: 'Bought Index Fund',
                            goldDelta: -200,
                            growthShift: 0.08,
                            onApplied: () {
                              _indexFundLots += 1;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          title: 'Sell Stocks',
                          subtitle: 'Convert one stock lot back into 140 gold.',
                          buttonLabel: 'Sell 140',
                          onPressed: _stockLots == 0
                              ? null
                              : () => _applyTrade(
                                    context: context,
                                    label: 'Sold Stocks',
                                    goldDelta: 140,
                                    growthShift: -0.05,
                                    onApplied: () {
                                      _stockLots =
                                          math.max(0, _stockLots - 1).toInt();
                                    },
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Holdings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HoldingRow(
                          label: 'Index Fund Lots',
                          value: '$_indexFundLots',
                        ),
                        const SizedBox(height: 8),
                        _HoldingRow(
                          label: 'Stock Lots',
                          value: '$_stockLots',
                        ),
                        const SizedBox(height: 8),
                        _HoldingRow(
                          label: 'Wizard Advice',
                          value: user.wizardAdvice,
                          multiLine: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InvestmentStat extends StatelessWidget {
  const _InvestmentStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF85EFAC),
                foregroundColor: const Color(0xFF1A4D3D),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PortfolioChartPainter extends CustomPainter {
  const _PortfolioChartPainter({
    required this.points,
    required this.accent,
  });

  final List<double> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var row = 1; row <= 3; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fillPath = Path();
    final strokePath = Path();
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? 0.0
          : (size.width / (points.length - 1)) * index;
      final normalizedPoint = (points[index].clamp(0.0, 1.0) as num).toDouble();
      final y = size.height - (normalizedPoint * size.height);

      if (index == 0) {
        fillPath.moveTo(x, y);
        strokePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        strokePath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      strokePath,
      Paint()
        ..color = accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? 0.0
          : (size.width / (points.length - 1)) * index;
      final normalizedPoint = (points[index].clamp(0.0, 1.0) as num).toDouble();
      final y = size.height - (normalizedPoint * size.height);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.accent != accent;
  }
}
