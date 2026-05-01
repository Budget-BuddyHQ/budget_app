import 'package:flutter/material.dart';

import '../../../components/unit_row_item.dart';
import '../../../models/lesson.dart';
import '../../../models/progression_service.dart';
import '../../../services/app_sound_service.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../widgets/game_toast.dart';
import 'lesson_detail_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, this.activeTabIndex = 3, this.onNavSelected});

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final ProgressionService _progressionService;
  int _selectedUnitIndex = 0;

  bool get railExtended => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _progressionService = ProgressionService()..addListener(_refresh);
  }

  @override
  void dispose() {
    _progressionService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showUnitPickerSheet(List<LessonUnit> units) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: _UnitPickerSheet(
              units: units,
              selectedIndex: _selectedUnitIndex,
              onSelected: (index) {
                setState(() => _selectedUnitIndex = index);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLesson(Lesson lesson) async {
    final status = _progressionService.getLessonStatus(lesson.id);
    if (status == LessonStatus.locked) {
      GameToast.show(
        context,
        title: 'Lesson locked',
        message:
            'Finish the earlier content in this unit to unlock ${lesson.title}.',
        icon: Icons.lock_outline_rounded,
        accent: const Color(0xFFFFB084),
        soundEffect: AppSoundEffect.error,
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(
          lesson: lesson,
          unit: _progressionService.getUnit(lesson.unitId)!,
          progressionService: _progressionService,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _progressionService.units;
    final selectedUnit = units[_selectedUnitIndex.clamp(0, units.length - 1)];
    final nextLesson = _progressionService.nextLesson;
    final overallProgress = _progressionService.getProgress();

    return Scaffold(
      backgroundColor: const Color(0xFF0D2B20),
      bottomNavigationBar: widget.onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: widget.activeTabIndex,
              onSelected: widget.onNavSelected,
            ),
      body: SafeArea(
        child: Column(
          children: [
            _HubHeader(
              completed: _progressionService.completedCount,
              total: _progressionService.totalCount,
              progress: overallProgress,
              nextLesson: nextLesson,
              onOpenNext: nextLesson == null ? null : () => _openLesson(nextLesson),
            ),
            const _MasteryLegend(),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: railExtended ? 220 : 88,
                    margin: const EdgeInsets.fromLTRB(20, 16, 12, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: NavigationRail(
                      extended: railExtended,
                      minExtendedWidth: 220,
                      backgroundColor: Colors.transparent,
                      destinations: units
                          .map(
                            (unit) => NavigationRailDestination(
                              icon: const Icon(Icons.menu_book_outlined),
                              selectedIcon: const Icon(Icons.menu_book_rounded),
                              label: Text(unit.title),
                            ),
                          )
                          .toList(growable: false),
                      selectedIndex: _selectedUnitIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedUnitIndex = index);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 16, 20, 24),
                      children: [
                        _UnitCard(
                          unit: selectedUnit,
                          progress: _progressionService.getUnitProgress(
                            selectedUnit.id,
                          ),
                          mastery: _progressionService.getUnitMastery(
                            selectedUnit.id,
                          ),
                          onLessonTap: _openLesson,
                          statusFor: _progressionService.getLessonStatus,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
    required this.completed,
    required this.total,
    required this.progress,
    required this.nextLesson,
    required this.onOpenNext,
    this.onBrowseUnits,
    this.compact = false,
  });

  final int completed;
  final int total;
  final double progress;
  final Lesson? nextLesson;
  final VoidCallback? onOpenNext;
  final VoidCallback? onBrowseUnits;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        compact ? 0 : 20,
        compact ? 0 : 20,
        compact ? 0 : 20,
        compact ? 0 : 12,
      ),
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF114B3A), Color(0xFF1D7056)],
        ),
        borderRadius: BorderRadius.circular(compact ? 26 : 30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academy',
            style: TextStyle(
              color: Color(0xFFB8F5D1),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Units and mastery',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 24 : 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Move unit by unit, revisit lessons quickly, and keep the full learning journey visible in one place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(label: 'Completed', value: '$completed/$total'),
              _MetricPill(label: 'Progress', value: '${(progress * 100).round()}%'),
              _MetricPill(
                label: 'Next up',
                value: nextLesson?.title ?? 'All units complete',
                compact: compact,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
            ),
          ),
          if (onOpenNext != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD45C),
                foregroundColor: const Color(0xFF133626),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Resume Learning',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 132 : 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryLegend extends StatelessWidget {
  const _MasteryLegend({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const items = <(String, Color)>[
      ('Novice', Color(0xFFE7ECF2)),
      ('Familiar', Color(0xFFA5D8FF)),
      ('Proficient', Color(0xFFFFD45C)),
      ('Mastered', Color(0xFF85EFAC)),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 0 : 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4D3D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF85EFAC)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: items
            .map(
              (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.$2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MobileUnitSelector extends StatelessWidget {
  const _MobileUnitSelector({
    required this.units,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<LessonUnit> units;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Scrollbar(
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 0,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: units.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final selected = index == selectedIndex;
            final unit = units[index];
            return ChoiceChip(
              selected: selected,
              label: Text(unit.title),
              onSelected: (_) => onSelected(index),
              labelStyle: TextStyle(
                color: selected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF334155),
                fontWeight: FontWeight.w800,
              ),
              selectedColor: const Color(0xFF85EFAC),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? const Color(0xFF2F9E68)
                    : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnitSidebar extends StatelessWidget {
  const _UnitSidebar({
    required this.width,
    required this.extended,
    required this.units,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double width;
  final bool extended;
  final List<LessonUnit> units;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          itemCount: units.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final unit = units[index];
            final selected = index == selectedIndex;
            final accent = selected
                ? const Color(0xFF2F9E68)
                : const Color(0xFF94A3B8);

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: extended ? 14 : 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE9F8EF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2F9E68)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: extended
                    ? Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.menu_book_rounded
                                : Icons.menu_book_outlined,
                            color: accent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              unit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF334155),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            selected
                                ? Icons.menu_book_rounded
                                : Icons.menu_book_outlined,
                            color: accent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet({
    required this.units,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<LessonUnit> units;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse Units',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open any unit without losing your place on smaller screens.',
            style: TextStyle(
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final selected = index == selectedIndex;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF2F9E68)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    tileColor: selected
                        ? const Color(0xFFE9F8EF)
                        : Colors.white,
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? const Color(0xFF2F9E68)
                          : const Color(0xFFE2E8F0),
                      foregroundColor: selected
                          ? Colors.white
                          : const Color(0xFF334155),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      unit.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      unit.subtitle,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2F9E68),
                          )
                        : null,
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.progress,
    required this.mastery,
    required this.onLessonTap,
    required this.statusFor,
    this.compact = false,
  });

  final LessonUnit unit;
  final double progress;
  final MasteryLevel mastery;
  final ValueChanged<Lesson> onLessonTap;
  final LessonStatus Function(String lessonId) statusFor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = compact || constraints.maxWidth < 560;
              final badge = _MasteryBadge(mastery: mastery);
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.title,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: compact ? 24 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unit.description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    const SizedBox(height: 14),
                    badge,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 16),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '${(progress * 100).round()}% complete',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2F9E68),
              ),
            ),
          ),
          const SizedBox(height: 24),
          UnitRowItem(
            lessons: unit.lessons,
            statusFor: statusFor,
            onLessonTap: onLessonTap,
          ),
        ],
      ),
    );
  }
}

class _MasteryBadge extends StatelessWidget {
  const _MasteryBadge({required this.mastery});

  final MasteryLevel mastery;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mastery) {
      MasteryLevel.novice => ('Novice', const Color(0xFF94A3B8)),
      MasteryLevel.familiar => ('Familiar', const Color(0xFF3B82F6)),
      MasteryLevel.proficient => ('Proficient', const Color(0xFFFFD45C)),
      MasteryLevel.mastered => ('Mastered', const Color(0xFF2F9E68)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}