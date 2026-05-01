import 'package:flutter/material.dart';

import '../../../components/unit_row_item.dart';
import '../../../models/lesson.dart';
import '../../../models/progression_service.dart';
import '../../../navigation/app_tab_index.dart';
import '../../../widgets/ambient_lottie_card.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../widgets/game_toast.dart';
import 'lesson_detail_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.academy,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final ProgressionService _progressionService;
  int _selectedUnitIndex = 0;

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
        message: 'Finish the earlier content in this unit to unlock ${lesson.title}.',
        icon: Icons.lock_outline_rounded,
        accent: const Color(0xFFFFB084),
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
    final nextUnit = nextLesson == null
        ? null
        : _progressionService.getUnit(nextLesson.unitId);
    final overallProgress = _progressionService.getProgress();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: widget.onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: widget.activeTabIndex,
              onSelected: widget.onNavSelected,
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactLayout =
                constraints.maxWidth < 920 || constraints.maxHeight < 760;

            if (compactLayout) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _HubHeader(
                    compact: true,
                    completed: _progressionService.completedCount,
                    total: _progressionService.totalCount,
                    progress: overallProgress,
                    nextLesson: nextLesson,
                    onBrowseUnits: () => _showUnitPickerSheet(units),
                    onOpenNext:
                        nextLesson == null ? null : () => _openLesson(nextLesson),
                  ),
                  const SizedBox(height: 12),
                  _NextLessonFocusCard(
                    nextLesson: nextLesson,
                    nextUnit: nextUnit,
                    progress: overallProgress,
                    onOpenNext:
                        nextLesson == null ? null : () => _openLesson(nextLesson),
                  ),
                  const SizedBox(height: 12),
                  const _MasteryLegend(compact: true),
                  const SizedBox(height: 16),
                  _MobileUnitSelector(
                    units: units,
                    selectedIndex: _selectedUnitIndex,
                    onSelected: (index) {
                      setState(() => _selectedUnitIndex = index);
                    },
                  ),
                  const SizedBox(height: 16),
                  _UnitCard(
                    compact: true,
                    unit: selectedUnit,
                    progress: _progressionService.getUnitProgress(selectedUnit.id),
                    mastery: _progressionService.getUnitMastery(selectedUnit.id),
                    onLessonTap: _openLesson,
                    statusFor: _progressionService.getLessonStatus,
                  ),
                ],
              );
            }

            final railExtended = constraints.maxWidth >= 1120;

            return Column(
              children: [
                _HubHeader(
                  completed: _progressionService.completedCount,
                  total: _progressionService.totalCount,
                  progress: overallProgress,
                  nextLesson: nextLesson,
                  onBrowseUnits:
                      constraints.maxWidth < 1040
                          ? () => _showUnitPickerSheet(units)
                          : null,
                  onOpenNext:
                      nextLesson == null ? null : () => _openLesson(nextLesson),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _NextLessonFocusCard(
                    nextLesson: nextLesson,
                    nextUnit: nextUnit,
                    progress: overallProgress,
                    onOpenNext:
                        nextLesson == null ? null : () => _openLesson(nextLesson),
                  ),
                ),
                const _MasteryLegend(),
                Expanded(
                  child: Row(
                    children: [
                      if (constraints.maxWidth >= 1040)
                        _UnitSidebar(
                          width: railExtended ? 232 : 116,
                          extended: railExtended,
                          units: units,
                          selectedIndex: _selectedUnitIndex,
                          onSelected: (index) {
                            setState(() => _selectedUnitIndex = index);
                          },
                        ),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth >= 1040 ? 8 : 20,
                              16,
                              20,
                              24,
                            ),
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
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
    final content = Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIllustration = !compact && constraints.maxWidth >= 760;
          final copy = Column(
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
                'Move unit by unit, resume faster, and keep the whole learning path readable on every screen.',
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
                  _MetricPill(
                    label: 'Completed',
                    value: '$completed/$total',
                    compact: compact,
                  ),
                  _MetricPill(
                    label: 'Progress',
                    value: '${(progress * 100).round()}%',
                    compact: compact,
                  ),
                  _MetricPill(
                    label: 'Next up',
                    value: nextLesson?.title ?? 'All units complete',
                    compact: compact,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackedActions = constraints.maxWidth < 520;

                  final progressBar = ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF85EFAC),
                      ),
                    ),
                  );

                  final buttons = [
                    if (onBrowseUnits != null)
                      OutlinedButton.icon(
                        onPressed: onBrowseUnits,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        icon: const Icon(Icons.menu_open_rounded),
                        label: const Text(
                          'Browse Units',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    if (onOpenNext != null)
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
                  ];

                  if (buttons.isEmpty) {
                    return progressBar;
                  }

                  if (stackedActions) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        progressBar,
                        const SizedBox(height: 18),
                        ...buttons.expand(
                          (button) => <Widget>[
                            SizedBox(width: double.infinity, child: button),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ]..removeLast(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      progressBar,
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: buttons,
                      ),
                    ],
                  );
                },
              ),
            ],
          );

          if (!showIllustration) {
            return copy;
          }

          return Row(
            children: [
              Expanded(flex: 3, child: copy),
              const SizedBox(width: 18),
              const Expanded(
                flex: 2,
                child: AmbientLottieCard(
                  assetPath: 'assets/animations/academy_loop.json',
                  semanticLabel: 'Animated academy illustration',
                  height: 220,
                ),
              ),
            ],
          );
        },
      ),
    );

    return content;
  }
}

class _NextLessonFocusCard extends StatelessWidget {
  const _NextLessonFocusCard({
    required this.nextLesson,
    required this.nextUnit,
    required this.progress,
    required this.onOpenNext,
  });

  final Lesson? nextLesson;
  final LessonUnit? nextUnit;
  final double progress;
  final VoidCallback? onOpenNext;

  @override
  Widget build(BuildContext context) {
    final isComplete = nextLesson == null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 560;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isComplete ? 'Path complete' : 'Continue where you left off',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isComplete
                    ? 'You finished the current academy path. Revisit any unit or add the next chapter when you are ready.'
                    : '${nextLesson!.title} • ${nextUnit?.title ?? 'Academy'} • ${nextLesson!.estimatedMinutes} min',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FocusPill(
                    label: 'Mastery',
                    value: '${(progress * 100).round()}%',
                    accent: const Color(0xFF2F9E68),
                  ),
                  _FocusPill(
                    label: 'Mode',
                    value: isComplete ? 'Review' : 'Guided lesson',
                    accent: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ],
          );

          final action = FilledButton.icon(
            onPressed: onOpenNext,
            style: FilledButton.styleFrom(
              backgroundColor: isComplete
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF2F9E68),
              foregroundColor: isComplete
                  ? const Color(0xFF64748B)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: Icon(isComplete ? Icons.check_circle_rounded : Icons.play_arrow_rounded),
            label: Text(
              isComplete ? 'All caught up' : 'Resume lesson',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: action),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 18),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _FocusPill extends StatelessWidget {
  const _FocusPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      color: Color(0xFF334155),
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
          separatorBuilder: (_, _) => const SizedBox(width: 10),
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
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                separatorBuilder: (_, _) => const SizedBox(height: 10),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F9E68)),
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
