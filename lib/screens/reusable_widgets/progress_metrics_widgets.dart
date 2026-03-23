import 'package:flutter/material.dart';

class FinanceMetricCard extends StatelessWidget {
  const FinanceMetricCard({
    super.key,
    required this.background,
    required this.border,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.progressValue,
    this.sparklinePoints,
  });

  final Color background;
  final Color border;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final double? progressValue;
  final List<double>? sparklinePoints;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progressValue == null
        ? null
        : progressValue!.clamp(0.0, 1.0) as double;

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
          if (safeProgress != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: safeProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
          if (sparklinePoints != null && sparklinePoints!.length >= 2) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 20,
              child: CustomPaint(
                painter: _SparklinePainter(
                  color: accent,
                  points: sparklinePoints!,
                ),
                size: const Size(double.infinity, 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.spacing = 10,
    this.minTileWidth = 180,
  });

  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = (constraints.maxWidth / minTileWidth).floor();
        columns = columns.clamp(1, maxColumns).toInt();
        if (columns > children.length) {
          columns = children.length;
        }

        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: tileWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class ProgressBarInfoRow extends StatelessWidget {
  const ProgressBarInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.percentText,
    required this.accent,
  });

  final String label;
  final double value;
  final String percentText;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0) as double;

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
            widthFactor: safeValue,
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

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.color,
    required this.points,
  });

  final Color color;
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = points
        .map((p) => p.clamp(0.0, 1.0))
        .cast<double>()
        .toList(growable: false);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (var i = 0; i < normalized.length; i++) {
      final x = i == 0 ? 0.0 : (size.width / (normalized.length - 1)) * i;
      final y = size.height - (normalized[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}
