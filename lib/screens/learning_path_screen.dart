import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/progression_service.dart';
import '../components/skill_tree_node.dart';
import 'lesson_screen.dart';

class LearningPathScreen extends StatefulWidget { // This is the class for the main learning page like the mimo
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> with SingleTickerProviderStateMixin {
  late ProgressionService _progressionService;
  bool _isTopBarVisible = true;
  bool _isBottomSheetVisible = true;
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();
  late TransformationController _transformationController;
  late AnimationController _animationController;
  bool _isFirstBuild = true; // Reintroduced
  bool _shouldRecenterOnNextBuild = false; // New flag

  @override
  void initState() {
    super.initState();
    _progressionService = ProgressionService();
    _progressionService.addListener(_onProgressionChanged);
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _progressionService.removeListener(_onProgressionChanged);
    _bottomSheetController.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onProgressionChanged() {
    setState(() {
      _shouldRecenterOnNextBuild = true; // Set flag to recenter on next build
    });
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

  /// Calculate positions for lessons in a more organic skill tree layout
  List<Offset> _calculateNodePositions(int count, double totalWidth) {
    final positions = <Offset>[];
    final verticalSpacing = 200.0; // Increased
    final nodeWidth = 90.0;
    final horizontalPadding = 40.0;

    // The area where node centers can be placed
    final usableWidth = totalWidth - (2 * horizontalPadding) - nodeWidth;

    for (int i = 0; i < count; i++) {
      final y = 100.0 + (i * verticalSpacing);
      double centerX;

      // Determine the horizontal position (as a percentage of usableWidth)
      double horizontalPercent;
      switch (i % 4) {
        case 0:
          horizontalPercent = 0.2;
          break;
        case 1:
          horizontalPercent = 0.8;
          break;
        case 2:
          horizontalPercent = 0.7;
          break;
        case 3:
          horizontalPercent = 0.3;
          break;
        default:
          horizontalPercent = 0.5;
      }

      if (i == 0) {
        horizontalPercent = 0.5;
      }

      // Calculate center X and then top-left X
      centerX = horizontalPadding +
          (nodeWidth / 2) +
          (horizontalPercent * usableWidth);
      final x = centerX - (nodeWidth / 2);

      positions.add(Offset(x, y));
    }
    return positions;
  }

  /// Draw connection lines between lessons with a smoother curve
  Widget _buildConnectionLine(Offset start, Offset end, bool isCompleted) {
    final path = Path();
    // Center of the 90x90 node is at 45x45 offset
    final startCenter = Offset(start.dx + 45, start.dy + 45);
    final endCenter = Offset(end.dx + 45, end.dy + 45);

    path.moveTo(startCenter.dx, startCenter.dy);

    // Use a cubic curve for a more elegant 'S' shape
    final controlPoint1 = Offset(
      startCenter.dx,
      startCenter.dy + (endCenter.dy - startCenter.dy) / 2,
    );
    final controlPoint2 = Offset(
      endCenter.dx,
      endCenter.dy - (endCenter.dy - startCenter.dy) / 2,
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
            : Colors.grey.shade300,
        strokeWidth: isCompleted ? 4.5 : 3.0,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Literacy'),
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // This ensures the skill tree occupies the full available space below the AppBar
          _buildMainContent(
            lessons: lessons,
            // progress is no longer needed here
          ),

          // Positioned progress bar (header)
          if (_isTopBarVisible)
            Positioned(
              top: 16.0, // Position it 16 pixels from the top of the Stack (below AppBar)
              left: 16.0,
              right: 16.0 + 50.0 + 16.0, // Increased padding for floating buttons (FAB width + additional spacing)
              child: IgnorePointer( // Added to prevent blocking touch events
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildGlassmorphicProgressBar(progress),
                ),
              ),
            ),

          // Bottom sheet (already positioned by DraggableScrollableSheet)
          if (_isBottomSheetVisible) _buildResizableLessonSheet(),

          // Floating toggle buttons (already positioned)
          _buildFloatingControls(),
        ],
      ),
    );
  }

  Widget _buildMainContent({
    required List<Lesson> lessons,
  }) {
    return Container(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapWidth = constraints.maxWidth * 1.8;
            final positions =
                _calculateNodePositions(lessons.length, mapWidth);
            final mapHeight = positions.isEmpty
                ? constraints.maxHeight
                : (positions
                          .map((p) => p.dy)
                          .reduce((a, b) => a > b ? a : b) +
                      200);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_isFirstBuild && lessons.isNotEmpty) {
                _centerViewOnActiveNode(
                  lessons,
                  positions,
                  Size(constraints.maxWidth, constraints.maxHeight),
                  Size(mapWidth, mapHeight),
                  animate: false, // No animation for initial load
                );
                _isFirstBuild = false; // Set to false after first successful centering
              } else if (_shouldRecenterOnNextBuild && lessons.isNotEmpty) {
                _centerViewOnActiveNode(
                  lessons,
                  positions,
                  Size(constraints.maxWidth, constraints.maxHeight),
                  Size(mapWidth, mapHeight),
                  animate: true, // Animate for progression change
                );
                _shouldRecenterOnNextBuild = false; // Reset flag
              }
            });

            return InteractiveViewer(
              transformationController: _transformationController, // Added
              minScale: 0.4,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(2000), // Updated boundaryMargin
              child: SizedBox(
                width: mapWidth,
                height: mapHeight,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }

  Widget _buildResizableLessonSheet() {
    final lessons = _progressionService.lessons;
    final bool allLessonsCompleted =
        _progressionService.completedCount == _progressionService.totalCount;

    Lesson? availableLesson;
    if (!allLessonsCompleted) {
      try {
        availableLesson = lessons.firstWhere(
          (l) => _progressionService.getLessonStatus(l.id) == LessonStatus.available,
        );
      } catch (e) {
        availableLesson = null; // No available lesson found
      }
    }

    return DraggableScrollableSheet(
      controller: _bottomSheetController,
      initialChildSize: 0.2, // Updated
      minChildSize: 0.1,     // Updated
      maxChildSize: 0.9,     // Updated
      snap: true,
      snapSizes: const [
        0.1, // Updated
        0.35,
        0.9, // Updated
      ], // Collapsed, Half-expanded, Fully expanded
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            return true;
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withAlpha((255 * 0.2).round()),
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle area
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Optional: Expand on tap
                        },
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
                                const Color.fromRGBO(96, 170, 36, 0.1),
                                const Color.fromRGBO(25, 210, 155, 0.1),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Drag handle
                              _buildDragHandle(),
                              const SizedBox(height: 12),
                              // Title with progress
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 96, 170, 36),
                                          Color.fromARGB(255, 25, 210, 155),
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

                      // Content area - shows different content based on sheet size
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final sheetHeight = constraints.maxHeight;
                            final isCollapsed = sheetHeight < 100;
                            final isHalfExpanded = sheetHeight < 300;

                            if (isCollapsed) {
                              return const SizedBox.shrink();
                            } else if (isHalfExpanded) {
                              if (allLessonsCompleted) {
                                return _buildCompletionMessage(scrollController);
                              } else if (availableLesson != null) {
                                return _buildCurrentLessonView(availableLesson, scrollController);
                              } else {
                                return const SizedBox.shrink(); // No available lessons, and not all completed.
                              }
                            } else {
                              return Column(
                                children: [
                                  const Divider(height: 1, thickness: 1),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.all(16),
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: lessons.length,
                                      itemBuilder: (context, index) {
                                        final lesson = lessons[index];
                                        final status = _progressionService
                                            .getLessonStatus(lesson.id);
                                        return _buildLessonListItem(
                                          lesson,
                                          status,
                                          index,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentLessonView(Lesson lesson, ScrollController scrollController) {
    final status = _progressionService.getLessonStatus(lesson.id);
    return SingleChildScrollView(
      controller: scrollController,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
            Text(
              'Current Lesson',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            _buildLessonListItem(lesson, status, 0),
          ],
        ),
      ),
    );
  }

  // --- MISSING METHOD ADDED HERE ---
  Widget _buildLessonListItem(Lesson lesson, LessonStatus status, int index) {
    IconData icon;
    Color color;

    switch (status) {
      case LessonStatus.completed:
        icon = Icons.check_circle;
        color = const Color.fromARGB(255, 96, 170, 36);
        break;
      case LessonStatus.available:
        icon = Icons.play_circle_fill;
        color = Colors.blue;
        break;
      case LessonStatus.locked:
        icon = Icons.lock;
        color = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          lesson.title, // Assuming Lesson model has a title
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status == LessonStatus.locked ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          status == LessonStatus.locked ? 'Locked' : 'Tap to start',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
            heroTag: "btn1", // Unique tag
            onPressed: _toggleTopBar,
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
            child: Icon(
              _isTopBarVisible ? Icons.visibility_off : Icons.visibility,
              color: const Color.fromARGB(255, 96, 170, 36),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "btn2", // Unique tag
            onPressed: _toggleBottomSheet,
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
            child: Icon(
              _isBottomSheetVisible
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: const Color.fromARGB(255, 96, 170, 36),
            ),
          ),
        ],
      ),
    );
  }

  // --- FIXED METHOD HERE ---
  Widget _buildGlassmorphicProgressBar(double progress) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3), width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              "${(progress * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionMessage(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 60,
              color: const Color.fromARGB(255, 96, 170, 36),
            ),
            SizedBox(height: 16),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have completed all lessons!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _centerViewOnActiveNode(
      List<Lesson> lessons,
      List<Offset> positions,
      Size viewportSize,
      Size mapSize,
      {bool animate = true}) { // Added animate parameter
    if (lessons.isEmpty) {
      return;
    }

    // Find the first available lesson, or the first lesson if none are available
    Lesson? targetLesson;
    Offset? targetNodePosition;

    try {
      targetLesson = lessons.firstWhere(
        (l) => _progressionService.getLessonStatus(l.id) == LessonStatus.available,
      );
    } catch (e) {
      // No available lessons, fallback to the first lesson if it exists
      if (lessons.isNotEmpty) {
        targetLesson = lessons.first;
      }
    }

    if (targetLesson != null) {
      final targetLessonIndex = lessons.indexOf(targetLesson);
      targetNodePosition = positions[targetLessonIndex];

      // Center of the node
      final nodeCenter = Offset(
        targetNodePosition.dx + 45, // Node width/2 (90/2)
        targetNodePosition.dy + 45, // Node height/2 (90/2)
      );

      // Set a fixed scale that shows the node clearly with some context
      final double effectiveScale = 1.0; // A good balance for visibility and context

      // Ensure scale is within min/max bounds of InteractiveViewer
      // The clamp is already handled by InteractiveViewer's minScale/maxScale,
      // but keeping it explicit for clarity.
      // effectiveScale = effectiveScale.clamp(0.4, 2.5);

      // Calculate the translation to center the node
      final double translateX = (viewportSize.width / 2) - nodeCenter.dx * effectiveScale;
      final double translateY = (viewportSize.height / 2) - nodeCenter.dy * effectiveScale;

      final Matrix4 matrix = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(effectiveScale);

      if (animate) {
        // Stop any ongoing animation
        _animationController.stop();
        _animationController.value = 0.0; // Reset animation progress

        final Matrix4Tween tween = Matrix4Tween(
          begin: _transformationController.value,
          end: matrix,
        );

        void listener() {
          _transformationController.value = tween.evaluate(_animationController);
        }

        _animationController.addListener(listener);
        _animationController.forward(from: 0.0).then((_) {
          _animationController.removeListener(listener); // Clean up listener
        });
      } else {
        _transformationController.value = matrix;
      }
    }
  } // This closes _centerViewOnActiveNode

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
}


// --- MISSING PAINTER CLASSES ADDED HERE ---

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
      ..strokeCap = StrokeCap.round;

    if (isCompleted) {
      canvas.drawPath(path, paint);
    } else {
      // Draw a dashed line for locked paths
      final dashWidth = 5;
      final dashSpace = 4;
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const double spacing = 40;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

