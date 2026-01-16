import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/progression_service.dart';
import '../components/skill_tree_node.dart';
import 'lesson_screen.dart';

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
    final spacing = 100.0;
    final startX = 80.0;
    final startY = 120.0;

    // Create a zigzag path for better visual flow
    for (int i = 0; i < count; i++) {
      double x, y;
      
      // Create a pattern: right, down, left, down, right, etc.
      final row = i ~/ 2; // Which row (0, 1, 2, ...)
      final col = i % 2; // Which column in the row (0 or 1)
      
      x = startX + (col * spacing * 2.5);
      y = startY + (row * spacing * 1.2);
      
      // Center the first node
      if (i == 0) {
        x = startX + spacing * 1.25;
      }

      positions.add(Offset(x, y));
    }

    return positions;
  }

  /// Draw connection lines between lessons
  Widget _buildConnectionLine(Offset start, Offset end, bool isCompleted) {
    final path = Path();
    final startCenter = Offset(start.dx + 40, start.dy + 40);
    final endCenter = Offset(end.dx + 40, end.dy + 40);
    
    // Create a curved path for better visual appeal
    path.moveTo(startCenter.dx, startCenter.dy);
    
    // Add a slight curve for diagonal connections
    final midX = (startCenter.dx + endCenter.dx) / 2;
    final midY = (startCenter.dy + endCenter.dy) / 2;
    
    if ((startCenter.dx - endCenter.dx).abs() > 50) {
      // Diagonal connection - use curve
      path.quadraticBezierTo(
        midX + (endCenter.dx > startCenter.dx ? 20 : -20),
        midY,
        endCenter.dx,
        endCenter.dy,
      );
    } else {
      // Vertical connection - straight line
      path.lineTo(endCenter.dx, endCenter.dy);
    }

    return CustomPaint(
      painter: _ConnectionLinePainter(
        path: path,
        color: isCompleted
            ? const Color.fromARGB(255, 96, 170, 36)
            : Colors.grey.shade300,
        strokeWidth: isCompleted ? 4 : 2.5,
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
      body: Stack(
        children: [
          _buildMainContent(
            lessons: lessons,
            positions: positions,
            progress: progress,
          ),
          _buildResizableLessonSheet(),
        ],
      ),
    );
  }

  Widget _buildMainContent({
    required List<Lesson> lessons,
    required List<Offset> positions,
    required double progress,
  }) {
    return Container(
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
            // Enhanced Progress Header
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Progress',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressIndicator(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value:
                            '${_progressionService.completedCount}',
                        color: Colors.green.shade300,
                      ),
                      _buildProgressIndicator(
                        icon: Icons.play_circle,
                        label: 'Available',
                        value:
                            '${_progressionService.lessons.where((l) => _progressionService.getLessonStatus(l.id) == LessonStatus.available).length}',
                        color: Colors.blue.shade300,
                      ),
                      _buildProgressIndicator(
                        icon: Icons.lock,
                        label: 'Locked',
                        value:
                            '${_progressionService.lessons.where((l) => _progressionService.getLessonStatus(l.id) == LessonStatus.locked).length}',
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Skill tree visualization
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                        width: constraints.maxWidth * 1.3,
                        height: positions.isEmpty
                            ? constraints.maxHeight
                            : (positions.map((p) => p.dy).reduce((a, b) => a > b ? a : b) + 150),
                        child: Stack(
                          children: [
                            _buildGridBackground(),

                            ...List.generate(lessons.length - 1, (index) {
                              final isCompleted =
                                  _progressionService.getLessonStatus(
                                    lessons[index].id,
                                  ) ==
                                  LessonStatus.completed;

                              return _buildConnectionLine(
                                positions[index],
                                positions[index + 1],
                                isCompleted,
                              );
                            }),

                            ...lessons.asMap().entries.map((entry) {
                              final index = entry.key;
                              final lesson = entry.value;
                              final status = _progressionService.getLessonStatus(
                                lesson.id,
                              );

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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final iconColor = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }

  Widget _buildResizableLessonSheet() {
    final lessons = _progressionService.lessons;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.20,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.25, 0.50, 0.75],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle area - MUST be outside ListView to work properly
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 96, 170, 36).withOpacity(0.1),
                        const Color.fromARGB(255, 25, 210, 155).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle - visual indicator
                      Container(
                        width: 60,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Title with progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Learning Path',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_progressionService.completedCount} of ${_progressionService.totalCount} lessons completed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Progress circle
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 96, 170, 36),
                                  const Color.fromARGB(255, 25, 210, 155),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${(_progressionService.getProgress() * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Scrollable lesson list - scrollController is used here
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final status = _progressionService.getLessonStatus(
                      lesson.id,
                    );
                    return _buildLessonListItem(lesson, status, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildLessonListItem(Lesson lesson, LessonStatus status, int index) {
    IconData icon;
    Color iconColor;
    String statusText;
    String? description;

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

    // Add descriptions for each lesson
    switch (lesson.id) {
      case 'lesson_1':
        description = 'Learn the basics of budgeting and money management';
        break;
      case 'lesson_2':
        description = 'Understand different types of income and how to manage it';
        break;
      case 'lesson_3':
        description = 'Track expenses and distinguish between needs and wants';
        break;
      case 'lesson_4':
        description = 'Discover strategies to save money and build wealth';
        break;
      case 'lesson_5':
        description = 'Create and maintain your personal budget';
        break;
      case 'lesson_6':
        description = 'Learn about credit, debt, and how to use them wisely';
        break;
      case 'lesson_7':
        description = 'Explore investment basics and growing your money';
        break;
      case 'lesson_8':
        description = 'Understand banking, accounts, and financial tools';
        break;
      case 'lesson_9':
        description = 'Plan for emergencies and unexpected expenses';
        break;
      case 'lesson_10':
        description = 'Set and achieve your long-term financial goals';
        break;
      default:
        description = null;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: status == LessonStatus.available
            ? () => _handleLessonTap(lesson)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: status == LessonStatus.completed
                ? LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 96, 170, 36).withOpacity(0.15),
                      const Color.fromARGB(255, 161, 236, 64).withOpacity(0.1),
                    ],
                  )
                : status == LessonStatus.available
                    ? LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 25, 210, 155)
                              .withOpacity(0.15),
                          const Color.fromARGB(255, 96, 170, 36)
                              .withOpacity(0.1),
                        ],
                      )
                    : null,
            color: status == LessonStatus.locked
                ? Colors.grey.withOpacity(0.05)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: status == LessonStatus.completed
                  ? const Color.fromARGB(255, 96, 170, 36).withOpacity(0.5)
                  : status == LessonStatus.available
                      ? const Color.fromARGB(255, 25, 210, 155).withOpacity(0.5)
                      : Colors.grey.withOpacity(0.2),
              width: 2.5,
            ),
            boxShadow: status == LessonStatus.available
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(255, 25, 210, 155)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : status == LessonStatus.completed
                    ? [
                        BoxShadow(
                          color: const Color.fromARGB(255, 96, 170, 36)
                              .withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: Row(
            children: [
              // Lesson number badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: status == LessonStatus.completed
                      ? LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 96, 170, 36),
                            const Color.fromARGB(255, 161, 236, 64),
                          ],
                        )
                      : status == LessonStatus.available
                          ? LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 25, 210, 155),
                                const Color.fromARGB(255, 96, 170, 36),
                              ],
                            )
                          : null,
                  color: status == LessonStatus.locked
                      ? Colors.grey.shade300
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: status != LessonStatus.locked
                      ? [
                          BoxShadow(
                            color: iconColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: status == LessonStatus.locked
                      ? Icon(icon, color: iconColor, size: 24)
                      : Text(
                          '${lesson.order}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: status == LessonStatus.locked
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (status == LessonStatus.completed)
                          Icon(Icons.check_circle,
                              color: iconColor, size: 20),
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: status == LessonStatus.locked
                              ? Colors.grey.shade600
                              : Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: status != LessonStatus.locked
                            ? LinearGradient(
                                colors: [
                                  iconColor.withOpacity(0.2),
                                  iconColor.withOpacity(0.1),
                                ],
                              )
                            : null,
                        color: status == LessonStatus.locked
                            ? Colors.grey.shade200
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (status == LessonStatus.available)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios,
                      color: iconColor, size: 18),
                ),
            ],
          ),
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
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
