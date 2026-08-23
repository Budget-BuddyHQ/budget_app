import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../themes_colors/app_theme.dart';

const List<String> _weekdayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The Track tab's 7-day habit grid: one row per saved habit, one column
/// per of the trailing 7 days, a check when that habit was completed that
/// day. Only today's column is tappable — the grid is a record of what
/// happened, not an editable history.
class HabitWeeklyTrackerGrid extends StatelessWidget {
  const HabitWeeklyTrackerGrid({
    super.key,
    required this.habits,
    required this.weeklyLog,
    required this.onCompleteToday,
  });

  final List<HabitTemplate> habits;
  final Map<String, List<String>> weeklyLog;
  final ValueChanged<HabitTemplate> onCompleteToday;

  @override
  Widget build(BuildContext context) {
    final days = HabitDateKeys.lastDayKeys(7);
    final today = HabitDateKeys.todayKey();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox.shrink()),
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabels[DateTime.parse(days[i]).weekday - 1],
                      style: GoogleFonts.baloo2(
                        color: days[i] == today
                            ? AppTheme.greenPrimary
                            : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final habit in habits) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final day in days)
                  Expanded(
                    child: Center(
                      child: _DayCell(
                        done: (weeklyLog[day] ?? const <String>[]).contains(habit.id),
                        isToday: day == today,
                        accent: habit.category.accent,
                        onTap: day == today ? () => onCompleteToday(habit) : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Save a habit from Activity to start tracking it here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(color: AppTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.done,
    required this.isToday,
    required this.accent,
    this.onTap,
  });

  final bool done;
  final bool isToday;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = onTap != null && !done;
    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? accent.withValues(alpha: 0.9) : Colors.transparent,
          border: Border.all(
            color: done
                ? accent
                : (isToday ? accent.withValues(alpha: 0.6) : Colors.white24),
            width: isToday && !done ? 2 : 1.5,
          ),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0B2419))
            : (isToday ? Icon(Icons.add_rounded, size: 14, color: accent.withValues(alpha: 0.8)) : null),
      ),
    );
  }
}

/// The profile's activity calendar heatmap — a GitHub-contributions-style
/// grid over the trailing ~12 weeks, hand-rolled (no calendar/heatmap
/// package exists in this project; the house convention is hand-rolled
/// charts, e.g. the Market Board's `MiniSparkline`).
class HabitActivityHeatmap extends StatelessWidget {
  const HabitActivityHeatmap({
    super.key,
    required this.activityCalendar,
    this.weeks = 12,
  });

  final Map<String, int> activityCalendar;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final totalDays = weeks * 7;
    final days = HabitDateKeys.lastDayKeys(totalDays);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final day in days) _HeatCell(count: activityCalendar[day] ?? 0),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.count});

  final int count;

  Color get _color {
    if (count <= 0) return Colors.white.withValues(alpha: 0.06);
    if (count == 1) return AppTheme.greenPrimary.withValues(alpha: 0.35);
    if (count <= 3) return AppTheme.greenPrimary.withValues(alpha: 0.65);
    return AppTheme.greenPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
