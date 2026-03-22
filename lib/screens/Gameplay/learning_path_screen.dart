import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../models/progression_service.dart';
import 'lesson_screen.dart';
import '../../components/skill_tree_node.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late ProgressionService _progressionService;
  bool _isTopBarVisible = true;
  bool _isBottomSheetVisible = true;
  late AnimationController _backgroundController;

  // Controller for the interactive map view
  final TransformationController _transformationController =
      TransformationController();
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _progressionService = ProgressionService();
    _progressionService.addListener(_onProgressionChanged);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Center the view initially (optional, slight delay to ensure build is done)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(0.0, -100.0, 0.0, 1.0);// Start slightly scrolled down
    });
  }

  @override
  void dispose() {
    _progressionService.removeListener(_onProgressionChanged);
    _transformationController.dispose();
    _bottomSheetController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _onProgressionChanged() {
    setState(() {});
  }

  void _toggleTopBar() {
    setState(() {
      _isTopBarVisible = !_isTopBarVisible;
    });
  }

  void _toggleBottomSheet() {
    setState(() {
      _isBottomSheetVisible = !_isBottomSheetVisible;
    });
  }

  /// Calculate positions based on a fixed width so math doesn't break
  List<Offset> _calculateNodePositions(int count, double width) {
    final positions = <Offset>[];
    final verticalSpacing = 160.0;
    final topPadding = 100.0;

    // Ensure we have a valid width to work with, even if screen is weird
    final usableWidth = width > 0 ? width : 400.0;
    final safeWidth = usableWidth - 80;

    for (int i = 0; i < count; i++) {
      final y = topPadding + (i * verticalSpacing);

      double horizontalPercent;
      int patternStep = i % 4;

      if (patternStep == 0) {
        horizontalPercent = 0.5;
      } else if (patternStep == 1)
        {horizontalPercent = 0.75;}
      else if (patternStep == 2)
        {horizontalPercent = 0.5;}
      else
        {horizontalPercent = 0.25;}

      final x = 40 + (horizontalPercent * safeWidth) - 45; // -45 to center node

      positions.add(Offset(x, y));
    }
    return positions;
  }

  Widget _buildConnectionLine(Offset start, Offset end, bool isCompleted) {
    final path = Path();
    final startCenter = Offset(start.dx + 45, start.dy + 45);
    final endCenter = Offset(end.dx + 45, end.dy + 45);

    // Bezier Curve Logic for fluid path
    path.moveTo(startCenter.dx, startCenter.dy);

    final controlPoint1 = Offset(
      startCenter.dx,
      startCenter.dy + (endCenter.dy - startCenter.dy) * 0.5,
    );
    final controlPoint2 = Offset(
      endCenter.dx,
      endCenter.dy - (endCenter.dy - startCenter.dy) * 0.5,
    );

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endCenter.dx,
      endCenter.dy,
    );

    return CustomPaint(
      painter: _ConnectionLinePainter(
        path: path,
        color: isCompleted
            ? const Color.fromARGB(255, 96, 170, 36)
            : Colors.grey.withValues(alpha: 0.5),
        strokeWidth: isCompleted ? 6.0 : 4.0,
        isCompleted: isCompleted,
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
    final progress = _progressionService.getProgress();
    final screenSize = MediaQuery.of(context).size;

    // Total height of the skill tree canvas
    final double totalCanvasHeight = (lessons.length * 160.0) + 400.0;

    // Pre-calculate positions using SCREEN width, not LayoutBuilder constraints
    // This fixes the issue where nodes disappeared because constraints were infinite
    final nodePositions = _calculateNodePositions(
      lessons.length,
      screenSize.width,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Light grey backing
      appBar: AppBar(
        title: const Text('Financial Literacy'),
        backgroundColor: const Color(0xFF2E4A3D), // Deep Forest Green
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Interactive Map View (Pannable/Zoomable)
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(
              500.0,
            ), // Allow panning way out
            minScale: 0.5,
            maxScale: 2.0,
            constrained: false, // Allows the child to be bigger than the screen
            child: SizedBox(
              width: screenSize.width,
              height: totalCanvasHeight,
              child: Stack(
                children: [
                  // A. Grid Background (Restored)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _backgroundController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _GridPatternPainter(
                            progress: _backgroundController.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // B. Connection Lines (Draw first so they are behind nodes)
                  ...List.generate(lessons.length - 1, (index) {
                    final isCompleted =
                        _progressionService.getLessonStatus(
                          lessons[index].id,
                        ) ==
                        LessonStatus.completed;
                    return _buildConnectionLine(
                      nodePositions[index],
                      nodePositions[index + 1],
                      isCompleted,
                    );
                  }),

                  // C. Nodes
                  ...lessons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lesson = entry.value;
                    final status = _progressionService.getLessonStatus(
                      lesson.id,
                    );

                    return SkillTreeNode(
                      lesson: lesson,
                      status: status,
                      position: nodePositions[index],
                      onTap: () => _handleLessonTap(lesson),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 2. UI Overlays
          if (_isTopBarVisible)
            Positioned(
              top: 16.0,
              left: 16.0,
              right: 80.0, // Make room for buttons
              child: IgnorePointer(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildGlassmorphicProgressBar(progress),
                ),
              ),
            ),

          if (_isBottomSheetVisible) _buildResizableLessonSheet(),
          _buildFloatingControls(),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildResizableLessonSheet() {
    final lessons = _progressionService.lessons;
    final bool allLessonsCompleted =
        _progressionService.completedCount == _progressionService.totalCount;

    Lesson? availableLesson;
    if (!allLessonsCompleted) {
      try {
        availableLesson = lessons.firstWhere(
          (l) =>
              _progressionService.getLessonStatus(l.id) ==
              LessonStatus.available,
        );
      } catch (e) {
        availableLesson = null;
      }
    }

    return DraggableScrollableSheet(
      controller: _bottomSheetController,
      initialChildSize: 0.2,
      minChildSize: 0.1,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header / Drag Handle Area
              GestureDetector(
                onTap: () {
                  // Optional: tap header to snap up
                  if (_bottomSheetController.size < 0.25) {
                    _bottomSheetController.animateTo(
                      0.35,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Path',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '${_progressionService.completedCount}/${_progressionService.totalCount}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 96, 170, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    if (!allLessonsCompleted && availableLesson != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          "NEXT UP",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildLessonListItem(
                          availableLesson,
                          LessonStatus.available,
                          0,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        "ALL LESSONS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...lessons.asMap().entries.map((e) {
                      final status = _progressionService.getLessonStatus(
                        e.value.id,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildLessonListItem(e.value, status, e.key),
                      );
                    }),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonListItem(Lesson lesson, LessonStatus status, int index) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (status) {
      case LessonStatus.completed:
        icon = Icons.check_circle;
        color = const Color.fromARGB(255, 96, 170, 36);
        bgColor = Colors.white;
        break;
      case LessonStatus.available:
        icon = Icons.play_circle_fill;
        color = const Color.fromARGB(255, 33, 150, 243);
        bgColor = Colors.white;
        break;
      case LessonStatus.locked:
        icon = Icons.lock;
        color = Colors.grey[400]!;
        bgColor = Colors.white;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: status == LessonStatus.locked
                ? Colors.grey[100]
                : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status == LessonStatus.locked ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          status == LessonStatus.locked
              ? 'Complete previous lesson'
              : 'Tap to start',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        onTap: () => _handleLessonTap(lesson),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "btn1",
            onPressed: _toggleTopBar,
            backgroundColor: Colors.white,
            child: Icon(
              _isTopBarVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "btn2",
            onPressed: _toggleBottomSheet,
            backgroundColor: Colors.white,
            child: Icon(
              _isBottomSheetVisible
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicProgressBar(double progress) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 96, 170, 36).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 96, 170, 36).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF76FF03),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "${(progress * 100).toInt()}%",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER CLASSES ---

// 1. GRID PAINTER (Restored)
class _GridPatternPainter extends CustomPainter {
  final double progress;

  _GridPatternPainter({this.progress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const double spacing = 40.0;
    final double offset = progress * spacing;

    for (double x = -spacing + offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = -spacing + offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// 2. LINE PAINTER
class _ConnectionLinePainter extends CustomPainter {
  final Path path;
  final Color color;
  final double strokeWidth;
  final bool isCompleted;

  _ConnectionLinePainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
    this.isCompleted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isCompleted) {
      canvas.drawPath(path, paint);
    } else {
      // Dashed line effect for incomplete paths
      final dashWidth = 12.0;
      final dashSpace = 8.0;
      final pathMetrics = path.computeMetrics();

      for (final metric in pathMetrics) {
        double distance = 0;
        while (distance < metric.length) {
          canvas.drawPath(
            metric.extractPath(distance, distance + dashWidth),
            paint,
          );
          distance += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.path != path ||
        oldDelegate.isCompleted != isCompleted;
  }
}
