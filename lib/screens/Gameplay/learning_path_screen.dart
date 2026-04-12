import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../models/progression_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import 'lesson_screen.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({
    super.key,
    this.activeTabIndex = 3,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late final ProgressionService _progressionService;

  @override
  void initState() {
    super.initState();
    _progressionService = ProgressionService()..addListener(_refresh);
  }

  @override
  void dispose() {
    _progressionService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openLesson(Lesson lesson) async {
    final status = _progressionService.getLessonStatus(lesson.id);
    if (status == LessonStatus.locked) {
      GameToast.show(
        context,
        title: 'Locked lesson',
        message: 'Finish the previous lesson to unlock ${lesson.title}.',
        icon: Icons.lock_outline_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
          progressionService: _progressionService,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _progressionService.lessons;
    final nextLesson = lessons.cast<Lesson?>().firstWhere(
      (lesson) =>
          lesson != null &&
          _progressionService.getLessonStatus(lesson.id) ==
              LessonStatus.available,
      orElse: () => null,
    );
    final completed = _progressionService.completedCount;
    final total = _progressionService.totalCount;
    final progress = _progressionService.getProgress();

    return Scaffold(
      backgroundColor: const Color(0xFF081A14),
      bottomNavigationBar: widget.onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: widget.activeTabIndex,
              onSelected: widget.onNavSelected,
            ),
      body: Stack(
        children: [
          const _LessonsBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
              children: [
                _LessonsHero(
                  completed: completed,
                  total: total,
                  progress: progress,
                  onDashboard: () => widget.onNavSelected?.call(0),
                ),
                const SizedBox(height: 18),
                if (nextLesson != null)
                  _NextLessonCard(
                    lesson: nextLesson,
                    onOpen: () => _openLesson(nextLesson),
                  ),
                if (nextLesson != null) const SizedBox(height: 18),
                _LessonsMap(
                  lessons: lessons,
                  progressionService: _progressionService,
                  onLessonTap: _openLesson,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsBackdrop extends StatelessWidget {
  const _LessonsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF06150F), Color(0xFF0B231A), Color(0xFF103127)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _Aura(
            size: 220,
            color: const Color(0xFF4ADE80).withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          top: 220,
          left: -70,
          child: _Aura(
            size: 170,
            color: const Color(0xFF58C7FF).withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.42,
              spreadRadius: size * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonsHero extends StatelessWidget {
  const _LessonsHero({
    required this.completed,
    required this.total,
    required this.progress,
    required this.onDashboard,
  });

  final int completed;
  final int total;
  final double progress;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF102C21).withValues(alpha: 0.98),
            const Color(0xFF174333).withValues(alpha: 0.94),
            const Color(0xFF1E4F3D).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lessons Academy',
                      style: TextStyle(
                        color: const Color(0xFFB7F7D0).withValues(alpha: 0.96),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Node-based learning path',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build real money instincts one lesson at a time, then return to the dashboard stronger.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58C7FF), Color(0xFF85EFAC)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF062C21),
                  size: 42,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: 'Completed',
                  value: '$completed/$total',
                  accent: const Color(0xFF85EFAC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroPill(
                  label: 'Completion',
                  value: '${(progress * 100).round()}%',
                  accent: const Color(0xFFFFD45C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF85EFAC),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onDashboard,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD45C),
                foregroundColor: const Color(0xFF062C21),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Back to Dashboard',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.lesson, required this.onOpen});

  final Lesson lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF58C7FF).withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF58C7FF).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF58C7FF).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF58C7FF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF58C7FF),
              foregroundColor: const Color(0xFF062C21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Start',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsMap extends StatelessWidget {
  const _LessonsMap({
    required this.lessons,
    required this.progressionService,
    required this.onLessonTap,
  });

  final List<Lesson> lessons;
  final ProgressionService progressionService;
  final ValueChanged<Lesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final positions = _buildPositions(width, lessons.length);
        final canvasHeight = 180 + math.max(0, lessons.length - 1) * 148.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Academy Path',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap any available lesson node to open it. Completed nodes stay lit so progress is always visible.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(width, 360),
                  height: canvasHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LessonPathPainter(
                            positions: positions,
                            statuses: lessons
                                .map(
                                  (lesson) => progressionService
                                      .getLessonStatus(lesson.id),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ),
                      for (var index = 0; index < lessons.length; index++)
                        Positioned(
                          left: positions[index].dx - 44,
                          top: positions[index].dy - 44,
                          child: _LessonNode(
                            lesson: lessons[index],
                            status: progressionService.getLessonStatus(
                              lessons[index].id,
                            ),
                            onTap: () => onLessonTap(lessons[index]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Offset> _buildPositions(double width, int count) {
    final positions = <Offset>[];
    const horizontalPadding = 30.0;
    final safeWidth = width - (horizontalPadding * 2);
    const verticalSpacing = 148.0;
    const startY = 62.0;

    for (var index = 0; index < count; index++) {
      final pattern = index % 4;
      final xFactor = switch (pattern) {
        0 => 0.20,
        1 => 0.76,
        2 => 0.32,
        _ => 0.68,
      };
      positions.add(
        Offset(safeWidth * xFactor, startY + index * verticalSpacing),
      );
    }

    return positions;
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.lesson,
    required this.status,
    required this.onTap,
  });

  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = status == LessonStatus.locked;
    final accent = switch (status) {
      LessonStatus.completed => const Color(0xFF85EFAC),
      LessonStatus.available => const Color(0xFFFFD45C),
      LessonStatus.locked => const Color(0xFF8A9D96),
    };
    final icon = switch (status) {
      LessonStatus.completed => Icons.check_rounded,
      LessonStatus.available => Icons.play_arrow_rounded,
      LessonStatus.locked => Icons.lock_rounded,
    };

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isLocked
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.98),
                        accent.withValues(alpha: 0.72),
                      ],
                    ),
              color: isLocked ? const Color(0xFF20352C) : null,
              border: Border.all(
                color: accent.withValues(alpha: isLocked ? 0.42 : 0.82),
                width: status == LessonStatus.available ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isLocked ? 0.10 : 0.26),
                  blurRadius: 18,
                  spreadRadius: status == LessonStatus.available ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isLocked ? accent : const Color(0xFF062C21),
                  size: 30,
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.order.toString(),
                  style: TextStyle(
                    color: isLocked ? accent : const Color(0xFF062C21),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 132,
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLocked ? Colors.white54 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPathPainter extends CustomPainter {
  _LessonPathPainter({required this.positions, required this.statuses});

  final List<Offset> positions;
  final List<LessonStatus> statuses;

  @override
  void paint(Canvas canvas, Size size) {
    final inactivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF85EFAC).withValues(alpha: 0.82);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x224ADE80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (var index = 0; index < positions.length - 1; index++) {
      final start = positions[index];
      final end = positions[index + 1];
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, start.dy + 48, end.dx, end.dy - 48, end.dx, end.dy);

      canvas.drawPath(path, inactivePaint);

      final isActive = statuses[index] == LessonStatus.completed;
      if (isActive) {
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LessonPathPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.statuses != statuses;
  }
}
