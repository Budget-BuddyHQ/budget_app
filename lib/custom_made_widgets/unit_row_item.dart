import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/lesson.dart';

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
    return Column(
      children: [
        for (var index = 0; index < lessons.length; index++) ...[
          _UnitLessonBlock(
            lesson: lessons[index],
            status: statusFor(lessons[index].id),
            index: index,
            onTap: () => onLessonTap(lessons[index]),
          ),
          if (index != lessons.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _UnitLessonBlock extends StatelessWidget {
  const _UnitLessonBlock({
    required this.lesson,
    required this.status,
    required this.index,
    required this.onTap,
  });

  final Lesson lesson;
  final LessonStatus status;
  final int index;
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
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Semantics(
      button: true,
      label: 'Lesson ${index + 1}: ${lesson.title}. $statusLabel.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF173B2E), Color(0xFF10291F)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border.withValues(alpha: 0.32)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 48 : 56,
                height: compact ? 48 : 56,
                decoration: BoxDecoration(
                  color: palette.fill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border, width: 2),
                ),
                child: Icon(
                  icon,
                  color: palette.foreground,
                  size: compact ? 26 : 30,
                ),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFF7FFFB),
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.border.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: palette.border,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
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
