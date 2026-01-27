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
    Color? backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    Gradient? gradient;

    switch (status) {
      case LessonStatus.completed:
        gradient = LinearGradient(
          colors: [
            const Color.fromARGB(255, 96, 170, 36),
            const Color.fromARGB(255, 161, 236, 64),
          ],
        );
        borderColor = const Color.fromARGB(255, 96, 170, 36);
        iconColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case LessonStatus.available:
        gradient = LinearGradient(
          colors: [
            const Color.fromARGB(255, 25, 210, 155),
            const Color.fromARGB(255, 96, 170, 36),
          ],
        );
        borderColor = const Color.fromARGB(255, 25, 210, 155);
        iconColor = Colors.white;
        icon = Icons.play_arrow;
        break;
      case LessonStatus.locked:
        backgroundColor = const Color.fromRGBO(158, 158, 158, 0.2);
        borderColor = Colors.grey.shade400;
        iconColor = Colors.grey.shade600;
        icon = Icons.lock;
        break;
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: (status == LessonStatus.available || status == LessonStatus.completed) ? onTap : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: gradient,
              color: status == LessonStatus.locked ?  backgroundColor : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: status == LessonStatus.available ? 4 : 3,
              ),
              boxShadow: status == LessonStatus.available
                  ? [
                      BoxShadow(
                        color: borderColor.withAlpha((255 * 0.5).round()),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ]
                  : status == LessonStatus.completed
                      ? [
                          BoxShadow(
                            color: borderColor.withAlpha((255 * 0.3).round()),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 35,
                ),
                if (status != LessonStatus.locked) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.order}',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
