import 'package:flutter/material.dart';
import '../models/lesson.dart';

/// A single node in the skill tree representing a lesson
class SkillTreeNode extends StatelessWidget {
  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback? onTap;
  final Offset position; // Position in the skill tree layout

  const SkillTreeNode({
    super.key,
    required this.lesson,
    required this.status,
    this.onTap,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status using the app's color palette
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (status) {
      case LessonStatus.completed:
        backgroundColor = const Color.fromARGB(255, 161, 236, 64).withOpacity(0.3);
        borderColor = const Color.fromARGB(255, 96, 170, 36);
        iconColor = const Color.fromARGB(255, 96, 170, 36);
        icon = Icons.check_circle;
        break;
      case LessonStatus.available:
        backgroundColor = const Color.fromARGB(255, 25, 210, 155).withOpacity(0.2);
        borderColor = const Color.fromARGB(255, 25, 210, 155);
        iconColor = Colors.white;
        icon = Icons.play_arrow;
        break;
      case LessonStatus.locked:
        backgroundColor = Colors.grey.withOpacity(0.2);
        borderColor = Colors.grey.shade400;
        iconColor = Colors.grey.shade600;
        icon = Icons.lock;
        break;
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: status == LessonStatus.available ? onTap : null,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: status == LessonStatus.available ? 3 : 2,
            ),
            boxShadow: status == LessonStatus.available
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 40,
          ),
        ),
      ),
    );
  }
}
