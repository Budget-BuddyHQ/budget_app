import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/progression_service.dart';
import '../components/skill_tree_node.dart';
import 'lesson_screen.dart';
import 'dart:math' as math;

/// Main learning path screen with skill tree visualization
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late ProgressionService _progressionService;

  @override
  void initState() {
    super.initState();
    _progressionService = ProgressionService();
    _progressionService.addListener(_onProgressionChanged);
  }

  @override
  void dispose() {
    _progressionService.removeListener(_onProgressionChanged);
    super.dispose();
  }

  void _onProgressionChanged() {
    setState(() {});
  }

  /// Calculate positions for lessons in a skill tree layout
  List<Offset> _calculateNodePositions(int count) {
    final positions = <Offset>[];
    final spacing = 120.0;
    final startX = 100.0;
    final startY = 150.0;

    // Create a path that goes: top-right, down, then left
    for (int i = 0; i < count; i++) {
      double x, y;

      if (i == 0) {
        // First node: top-right
        x = startX + spacing * 2;
        y = startY;
      } else if (i == 1) {
        // Second node: below first
        x = startX + spacing * 2;
        y = startY + spacing;
      } else if (i == 2) {
        // Third node: current active (below second)
        x = startX + spacing * 2;
        y = startY + spacing * 2;
      } else {
        // Remaining nodes: continue down or create a branch
        x = startX + spacing * (2 - (i - 3) % 2);
        y = startY + spacing * (2 + (i - 2));
      }

      positions.add(Offset(x, y));
    }

    return positions;
  }

  /// Draw connection lines between lessons
  Widget _buildConnectionLine(Offset start, Offset end, bool isCompleted) {
    final path = Path();
    path.moveTo(start.dx + 40, start.dy + 40); // Center of start node
    path.lineTo(end.dx + 40, end.dy + 40); // Center of end node

    return CustomPaint(
      painter: _ConnectionLinePainter(
        path: path,
        color: isCompleted
            ? const Color.fromARGB(255, 96, 170, 36)
            : Colors.grey.shade300,
        strokeWidth: isCompleted ? 3 : 2,
      ),
    );
  }

  void _handleLessonTap(Lesson lesson) {
    if (_progressionService.getLessonStatus(lesson.id) ==
        LessonStatus.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonScreen(
            lesson: lesson,
            progressionService: _progressionService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _progressionService.lessons;
    final positions = _calculateNodePositions(lessons.length);
    final progress = _progressionService.getProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Literacy'),
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 96, 170, 36),
              const Color.fromARGB(255, 230, 245, 220),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProgressIndicator(
                      icon: Icons.school,
                      label: 'Lessons',
                      value: '${_progressionService.completedCount}/${_progressionService.totalCount}',
                    ),
                    _buildProgressIndicator(
                      icon: Icons.trending_up,
                      label: 'Progress',
                      value: '${(progress * 100).toInt()}%',
                    ),
                  ],
                ),
              ),

              // Skill tree visualization
              Expanded(
                child: Stack(
                  children: [
                    // Background grid pattern
                    _buildGridBackground(),

                    // Connection lines
                    ...List.generate(
                      lessons.length - 1,
                      (index) {
                        final isCompleted = _progressionService
                                .getLessonStatus(lessons[index].id) ==
                            LessonStatus.completed;
                        return _buildConnectionLine(
                          positions[index],
                          positions[index + 1],
                          isCompleted,
                        );
                      },
                    ),

                    // Lesson nodes
                    ...lessons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lesson = entry.value;
                      final status =
                          _progressionService.getLessonStatus(lesson.id);

                      return SkillTreeNode(
                        lesson: lesson,
                        status: status,
                        position: positions[index],
                        onTap: () => _handleLessonTap(lesson),
                      );
                    }),
                  ],
                ),
              ),

              // Lesson list at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Lessons',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...lessons.map((lesson) {
                      final status =
                          _progressionService.getLessonStatus(lesson.id);
                      return _buildLessonListItem(lesson, status);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildLessonListItem(Lesson lesson, LessonStatus status) {
    IconData icon;
    Color iconColor;
    String statusText;

    switch (status) {
      case LessonStatus.completed:
        icon = Icons.check_circle;
        iconColor = const Color.fromARGB(255, 96, 170, 36);
        statusText = 'Completed';
        break;
      case LessonStatus.available:
        icon = Icons.play_arrow;
        iconColor = const Color.fromARGB(255, 25, 210, 155);
        statusText = 'Available';
        break;
      case LessonStatus.locked:
        icon = Icons.lock;
        iconColor = Colors.grey;
        statusText = 'Locked';
        break;
    }

    return InkWell(
      onTap: status == LessonStatus.available
          ? () => _handleLessonTap(lesson)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: status == LessonStatus.available
              ? const Color.fromARGB(255, 25, 210, 155).withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: status == LessonStatus.available
                ? const Color.fromARGB(255, 25, 210, 155).withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: status == LessonStatus.locked
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
            if (status == LessonStatus.available)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for connection lines between nodes
class _ConnectionLinePainter extends CustomPainter {
  final Path path;
  final Color color;
  final double strokeWidth;

  _ConnectionLinePainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConnectionLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Custom painter for grid background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
