import 'package:flutter/material.dart';

import '../models/lesson.dart';

class UnitRowItem extends StatelessWidget {
  const UnitRowItem({
    super.key,
    required this.lessons,
    required this.statusFor,
    required this.onLessonTap,
  });

  final List<Lesson> lessons;
  final LessonStatus Function(String lessonId) statusFor;
  final ValueChanged<Lesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final cardWidth = availableWidth < 360
            ? ((availableWidth - 14) / 2).clamp(92.0, 132.0)
            : 112.0;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: lessons
              .map(
                (lesson) => _UnitLessonIcon(
                  width: cardWidth,
                  lesson: lesson,
                  status: statusFor(lesson.id),
                  onTap: () => onLessonTap(lesson),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _UnitLessonIcon extends StatelessWidget {
  const _UnitLessonIcon({
    required this.width,
    required this.lesson,
    required this.status,
    required this.onTap,
  });

  final double width;
  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      LessonStatus.completed => const _LessonPalette(
        fill: Color(0xFF85EFAC),
        border: Color(0xFF2A7D52),
        foreground: Color(0xFF0B2D1A),
      ),
      LessonStatus.available => const _LessonPalette(
        fill: Color(0xFFFFD45C),
        border: Color(0xFFB38C10),
        foreground: Color(0xFF3C2B00),
      ),
      LessonStatus.locked => const _LessonPalette(
        fill: Color(0xFFE7ECF2),
        border: Color(0xFFB8C1CC),
        foreground: Color(0xFF6B7280),
      ),
    };

    final icon = switch (lesson.type) {
      LessonNodeType.lesson => Icons.crop_square_rounded,
      LessonNodeType.quiz => Icons.bolt_rounded,
      LessonNodeType.unitTest => Icons.star_rounded,
    };
    final statusLabel = _statusLabel(status);
    final lessonTypeLabel = switch (lesson.type) {
      LessonNodeType.lesson => 'Lesson',
      LessonNodeType.quiz => 'Quiz',
      LessonNodeType.unitTest => 'Unit test',
    };

    return Semantics(
      button: true,
      label:
          '$lessonTypeLabel: ${lesson.title}. $statusLabel. ${lesson.estimatedMinutes} minute lesson.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.fill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border, width: 1.5),
                ),
                child: Icon(icon, color: palette.foreground),
              ),
              const SizedBox(height: 10),
              Text(
                lesson.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: palette.border,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lesson.estimatedMinutes} min',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(LessonStatus status) {
    return switch (status) {
      LessonStatus.completed => 'Mastered',
      LessonStatus.available => 'Ready',
      LessonStatus.locked => 'Locked',
    };
  }
}

class _LessonPalette {
  const _LessonPalette({
    required this.fill,
    required this.border,
    required this.foreground,
  });

  final Color fill;
  final Color border;
  final Color foreground;
}
