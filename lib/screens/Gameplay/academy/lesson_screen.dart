import 'package:flutter/material.dart';

import '../../../components/unit_row_item.dart';
import '../../../models/lesson.dart';
import '../../../models/progression_service.dart';
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
    final railExtended = MediaQuery.of(context).size.width >= 980;

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
              onOpenNext: nextLesson == null
                  ? null
                  : () => _openLesson(nextLesson),
            ),
            const _MasteryLegend(),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: railExtended ? 220 : 88,
                    margin: const EdgeInsets.fromLTRB(20, 16, 12, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A4D3D),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF85EFAC)),
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
  });

  final int completed;
  final int total;
  final double progress;
  final Lesson? nextLesson;
  final VoidCallback? onOpenNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF114B3A), Color(0xFF1D7056)],
        ),
        borderRadius: BorderRadius.circular(30),
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
          const Text(
            'Units and mastery',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
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
              _MetricPill(
                label: 'Progress',
                value: '${(progress * 100).round()}%',
              ),
              _MetricPill(
                label: 'Next up',
                value: nextLesson?.title ?? 'All units complete',
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF85EFAC),
              ),
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
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryLegend extends StatelessWidget {
  const _MasteryLegend();

  @override
  Widget build(BuildContext context) {
    const items = <(String, Color)>[
      ('Novice', Color(0xFFE7ECF2)),
      ('Familiar', Color(0xFFA5D8FF)),
      ('Proficient', Color(0xFFFFD45C)),
      ('Mastered', Color(0xFF85EFAC)),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.progress,
    required this.mastery,
    required this.onLessonTap,
    required this.statusFor,
  });

  final LessonUnit unit;
  final double progress;
  final MasteryLevel mastery;
  final ValueChanged<Lesson> onLessonTap;
  final LessonStatus Function(String lessonId) statusFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 28,
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
                ),
              ),
              const SizedBox(width: 16),
              _MasteryBadge(mastery: mastery),
            ],
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
