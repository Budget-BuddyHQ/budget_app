import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GridWorldComponent extends PositionComponent {
  GridWorldComponent({
    required Vector2 mapSize,
    this.tileSize = 64,
  }) {
    size = mapSize;
    anchor = Anchor.topLeft;
  }

  final double tileSize;

  @override
  void render(Canvas canvas) {
    final basePaint = Paint()..color = const Color(0xFF0B251C);
    final gridPaint = Paint()
      ..color = const Color(0xFF85EFAC).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final lanePaint = Paint()
      ..color = const Color(0xFF7C5C33)
      ..strokeWidth = 42
      ..strokeCap = StrokeCap.round;
    final laneEdgePaint = Paint()
      ..color = const Color(0xFFD2B279).withValues(alpha: 0.36)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final waterPaint = Paint()..color = const Color(0xFF163F31).withValues(alpha: 0.92);
    final grovePaint = Paint()..color = const Color(0xFF174434).withValues(alpha: 0.90);
    final markerPaint = Paint()..color = const Color(0xFFE1BB72);
    final rockPaint = Paint()..color = const Color(0xFF27463A);

    canvas.drawRect(size.toRect(), basePaint);

    for (double x = 0; x <= size.x; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y <= size.y; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    final districts = <_DistrictMarker>[
      _DistrictMarker(
        center: Offset(tileSize * 4.3, tileSize * 4.4),
        label: 'Starter Village',
      ),
      _DistrictMarker(
        center: Offset(tileSize * 11.8, tileSize * 6.6),
        label: 'Market Square',
      ),
      _DistrictMarker(
        center: Offset(tileSize * 17.2, tileSize * 13.5),
        label: 'Savings Grove',
      ),
      _DistrictMarker(
        center: Offset(tileSize * 8.4, tileSize * 15.8),
        label: 'Credit Cliffs',
      ),
      _DistrictMarker(
        center: Offset(tileSize * 20.2, tileSize * 20.2),
        label: 'Investor Ridge',
      ),
    ];

    final route = Path()
      ..moveTo(districts[0].center.dx, districts[0].center.dy)
      ..quadraticBezierTo(
        tileSize * 7.5,
        tileSize * 4.2,
        districts[1].center.dx,
        districts[1].center.dy,
      )
      ..quadraticBezierTo(
        tileSize * 16.0,
        tileSize * 9.8,
        districts[2].center.dx,
        districts[2].center.dy,
      )
      ..quadraticBezierTo(
        tileSize * 11.5,
        tileSize * 17.8,
        districts[3].center.dx,
        districts[3].center.dy,
      )
      ..quadraticBezierTo(
        tileSize * 15.2,
        tileSize * 18.6,
        districts[4].center.dx,
        districts[4].center.dy,
      );
    canvas.drawPath(route, lanePaint);
    canvas.drawPath(route, laneEdgePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(tileSize * 14.4, tileSize * 12.3),
          width: tileSize * 5.5,
          height: tileSize * 3.1,
        ),
        const Radius.circular(34),
      ),
      grovePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(tileSize * 6.1, tileSize * 14.9),
          width: tileSize * 3.3,
          height: tileSize * 2.1,
        ),
        const Radius.circular(26),
      ),
      rockPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tileSize * 18.3, tileSize * 6.8),
        width: tileSize * 2.7,
        height: tileSize * 2.2,
      ),
      waterPaint,
    );

    for (final patch in _treeClusters) {
      _drawTreeCluster(canvas, patch);
    }

    for (final district in districts) {
      canvas.drawCircle(district.center, 16, markerPaint);
      canvas.drawCircle(
        district.center,
        26,
        Paint()..color = markerPaint.color.withValues(alpha: 0.16),
      );
      _paintLabel(canvas, district.label, district.center + const Offset(0, -34));
    }

    _paintLabel(
      canvas,
      'Use WASD or the stick to roam the route.',
      Offset(tileSize * 2.4, tileSize * 2.5),
      color: const Color(0xFFB8F5D1),
      maxWidth: 250,
    );
  }

  void _drawTreeCluster(Canvas canvas, Rect area) {
    final trunkPaint = Paint()..color = const Color(0xFF4A3222);
    final leafPaint = Paint()..color = const Color(0xFF1E5A43);
    final highlightPaint = Paint()
      ..color = const Color(0xFF85EFAC).withValues(alpha: 0.12);

    final centers = <Offset>[
      Offset(area.left + 18, area.top + 18),
      Offset(area.center.dx, area.top + 12),
      Offset(area.right - 18, area.center.dy),
      Offset(area.left + 20, area.bottom - 20),
      Offset(area.center.dx + 12, area.bottom - 18),
    ];

    for (final center in centers) {
      canvas.drawCircle(center + const Offset(0, 8), 12, highlightPaint);
      canvas.drawRect(
        Rect.fromCenter(center: center + const Offset(0, 10), width: 6, height: 14),
        trunkPaint,
      );
      canvas.drawCircle(center, 12, leafPaint);
    }
  }

  void _paintLabel(
    Canvas canvas,
    String label,
    Offset offset, {
    Color color = Colors.white,
    double maxWidth = 180,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(
              color: Color(0xCC071711),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);

    painter.paint(
      canvas,
      Offset(offset.dx - (painter.width / 2), offset.dy - painter.height),
    );
  }
}

class _DistrictMarker {
  const _DistrictMarker({
    required this.center,
    required this.label,
  });

  final Offset center;
  final String label;
}

final List<Rect> _treeClusters = <Rect>[
  const Rect.fromLTWH(120, 120, 120, 120),
  const Rect.fromLTWH(820, 180, 140, 120),
  const Rect.fromLTWH(1020, 820, 160, 120),
  const Rect.fromLTWH(300, 980, 160, 120),
  const Rect.fromLTWH(1180, 1180, 120, 120),
];
