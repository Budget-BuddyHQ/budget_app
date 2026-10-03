import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../themes_colors/app_theme.dart';

enum HabitRowStatus { completed, available, locked }

/// A row of challenge task nodes — same visual shape as Academy's
/// `UnitRowItem` (icon tile, title, status pill, puffy shadow), rebuilt as
/// its own lightweight widget rather than reusing `UnitRowItem` directly,
/// since that widget is typed against Academy's `Lesson`/`LessonStatus` and
/// carries curriculum-specific baggage (age stages, quiz node types) that
/// doesn't apply to a habit list.
class HabitChallengeRowItem extends StatelessWidget {
  const HabitChallengeRowItem({
    super.key,
    required this.tasks,
    required this.statusFor,
    required this.onTaskTap,
  });

  final List<ChallengeTask> tasks;
  final HabitRowStatus Function(ChallengeTask task) statusFor;
  final ValueChanged<ChallengeTask> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          _HabitTaskBlock(
            task: tasks[i],
            status: statusFor(tasks[i]),
            onTap: () => onTaskTap(tasks[i]),
          ),
          if (i != tasks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HabitTaskBlock extends StatelessWidget {
  const _HabitTaskBlock({
    required this.task,
    required this.status,
    required this.onTap,
  });

  final ChallengeTask task;
  final HabitRowStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final template = task.template;
    final palette = switch (status) {
      HabitRowStatus.completed => const _StatusPalette(
        fill: Color(0xFF9BE870),
        border: Color(0xFF2A7D52),
        foreground: Color(0xFF172328),
        label: 'Done',
        icon: Icons.check_circle_rounded,
      ),
      HabitRowStatus.available => const _StatusPalette(
        fill: Color(0xFFFFD45C),
        border: Color(0xFFB38C10),
        foreground: Color(0xFF3C2B00),
        label: 'Ready',
        icon: Icons.play_circle_fill_rounded,
      ),
      HabitRowStatus.locked => const _StatusPalette(
        fill: Color(0xFFE7ECF2),
        border: Color(0xFFB8C1CC),
        foreground: Color(0xFF6B7280),
        label: 'Locked',
        icon: Icons.lock_rounded,
      ),
    };
    final locked = status == HabitRowStatus.locked;

    return Semantics(
      button: true,
      label: '${template?.title ?? task.id}. ${palette.label}.',
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Opacity(
          opacity: locked ? 0.66 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.panelStrong,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: palette.border.withValues(alpha: 0.32)),
              boxShadow: AppTheme.ledgeShadow(palette.border, restAlpha: 0.16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.fill.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: palette.border, width: 2),
                  ),
                  child: Icon(
                    template?.icon ?? Icons.savings_rounded,
                    color: palette.border,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template?.title ?? task.id,
                        style: GoogleFonts.pixelifySans(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (task.resource != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.resource!,
                          style: GoogleFonts.quicksand(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.border.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(palette.icon, color: palette.border, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        palette.label,
                        style: GoogleFonts.pixelifySans(
                          color: palette.border,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.fill,
    required this.border,
    required this.foreground,
    required this.label,
    required this.icon,
  });

  final Color fill;
  final Color border;
  final Color foreground;
  final String label;
  final IconData icon;
}
