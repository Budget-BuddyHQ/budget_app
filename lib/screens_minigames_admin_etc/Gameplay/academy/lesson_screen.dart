import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../custom_made_widgets/unit_row_item.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/progression_service.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../loading/temporary_loading_screen.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
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
  late final UserStatsController _statsController;
  late final ProgressionService _progressionService;
  final ScrollController _unitQuickScrollController = ScrollController();
  int _selectedUnitIndex = 0;
  bool _hasManualUnitSelection = false;

  @override
  void initState() {
    super.initState();
    _statsController = context.read<UserStatsController>();
    _progressionService = ProgressionService(
      initialCompletedLessons: _statsController.stats.completedLessons,
    )..addListener(_refresh);
    _statsController.addListener(_syncProgressFromStats);
  }

  @override
  void dispose() {
    _unitQuickScrollController.dispose();
    _statsController.removeListener(_syncProgressFromStats);
    _progressionService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncProgressFromStats() {
    _progressionService.replaceCompletedLessons(
      _statsController.stats.completedLessons,
    );
  }

  void _selectUnit(int index) {
    setState(() {
      _selectedUnitIndex = index;
      _hasManualUnitSelection = true;
    });

    if (!_unitQuickScrollController.hasClients) {
      return;
    }

    final targetOffset = (index * 156.0).clamp(
      0.0,
      _unitQuickScrollController.position.maxScrollExtent,
    );
    _unitQuickScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
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

  List<Widget> _unitCards(List<LessonUnit> units, {required bool compact}) {
    return <Widget>[
      for (var index = 0; index < units.length; index++) ...[
        _UnitCard(
          compact: compact,
          unit: units[index],
          progress: _progressionService.getUnitProgress(units[index].id),
          mastery: _progressionService.getUnitMastery(units[index].id),
          onLessonTap: _openLesson,
          statusFor: _progressionService.getLessonStatus,
        ),
        if (index != units.length - 1) const SizedBox(height: 16),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final units = _progressionService.units;
    final nextLesson = _progressionService.nextLesson;
    final nextUnit = nextLesson == null
        ? null
        : _progressionService.getUnit(nextLesson.unitId);
    final activeUnitIndex = nextUnit == null
        ? units.length - 1
        : units.indexWhere((unit) => unit.id == nextUnit.id);
    final selectedUnitIndex = _hasManualUnitSelection
        ? _selectedUnitIndex.clamp(0, units.length - 1)
        : (activeUnitIndex < 0 ? 0 : activeUnitIndex);
    final selectedUnit = units[selectedUnitIndex];
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.villageMapBackground,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0D2B20).withValues(alpha: 0.86),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Treat landscape or short heights as compact to avoid vertical overflow.
                final orientation = MediaQuery.of(context).orientation;
                final compactLayout =
                    constraints.maxWidth < 980 ||
                    constraints.maxHeight < 720 ||
                    (orientation == Orientation.landscape &&
                        constraints.maxHeight < 720);

                if (compactLayout) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _UnitQuickChangerBar(
                        controller: _unitQuickScrollController,
                        units: units,
                        activeIndex: selectedUnitIndex,
                        progressFor: _progressionService.getUnitProgress,
                        masteryFor: _progressionService.getUnitMastery,
                        onSelected: _selectUnit,
                      ),
                      const SizedBox(height: 12),
                      _HubHeader(
                        compact: true,
                        completed: _progressionService.completedCount,
                        total: _progressionService.totalCount,
                        progress: overallProgress,
                        nextLesson: nextLesson,
                        onOpenNext: nextLesson == null
                            ? null
                            : () => _openLesson(nextLesson),
                      ),
                      const SizedBox(height: 12),
                      _NextLessonFocusCard(
                        nextLesson: nextLesson,
                        nextUnit: nextUnit,
                        progress: overallProgress,
                        onOpenNext: nextLesson == null
                            ? null
                            : () => _openLesson(nextLesson),
                      ),
                      const SizedBox(height: 12),
                      const _MasteryLegend(compact: true),
                      const SizedBox(height: 16),
                      ..._unitCards([selectedUnit], compact: true),
                    ],
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: _UnitQuickChangerBar(
                        controller: _unitQuickScrollController,
                        units: units,
                        activeIndex: selectedUnitIndex,
                        progressFor: _progressionService.getUnitProgress,
                        masteryFor: _progressionService.getUnitMastery,
                        onSelected: _selectUnit,
                      ),
                    ),
                    _HubHeader(
                      completed: _progressionService.completedCount,
                      total: _progressionService.totalCount,
                      progress: overallProgress,
                      nextLesson: nextLesson,
                      onOpenNext: nextLesson == null
                          ? null
                          : () => _openLesson(nextLesson),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _NextLessonFocusCard(
                        nextLesson: nextLesson,
                        nextUnit: nextUnit,
                        progress: overallProgress,
                        onOpenNext: nextLesson == null
                            ? null
                            : () => _openLesson(nextLesson),
                      ),
                    ),
                    const _MasteryLegend(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: _unitCards([
                          selectedUnit,
                        ], compact: compactLayout),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_statsController.isLoading)
              const Positioned(
                top: 10,
                right: 10,
                child: TemporaryLoadingScreen(
                  message: 'Syncing',
                  compact: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnitQuickChangerBar extends StatelessWidget {
  const _UnitQuickChangerBar({
    required this.controller,
    required this.units,
    required this.activeIndex,
    required this.progressFor,
    required this.masteryFor,
    required this.onSelected,
  });

  final ScrollController controller;
  final List<LessonUnit> units;
  final int activeIndex;
  final double Function(String unitId) progressFor;
  final MasteryLevel Function(String unitId) masteryFor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.22),
        ),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 5,
        radius: const Radius.circular(999),
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              for (var index = 0; index < units.length; index++) ...[
                _UnitJumpChip(
                  unit: units[index],
                  index: index,
                  selected: index == activeIndex,
                  progress: progressFor(units[index].id),
                  mastery: masteryFor(units[index].id),
                  onTap: () => onSelected(index),
                ),
                if (index != units.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitJumpChip extends StatelessWidget {
  const _UnitJumpChip({
    required this.unit,
    required this.index,
    required this.selected,
    required this.progress,
    required this.mastery,
    required this.onTap,
  });

  final LessonUnit unit;
  final int index;
  final bool selected;
  final double progress;
  final MasteryLevel mastery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final masteryColor = switch (mastery) {
      MasteryLevel.novice => const Color(0xFFCBD5E1),
      MasteryLevel.familiar => const Color(0xFFA7D8FF),
      MasteryLevel.proficient => const Color(0xFFFFD45C),
      MasteryLevel.mastered => const Color(0xFF85EFAC),
    };

    return Semantics(
      button: true,
      label:
          'Jump to ${unit.title}, ${(progress * 100).round()} percent complete',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 60, minWidth: 146),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF85EFAC) : const Color(0xFF14382C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB8FFD6)
                  : masteryColor.withValues(alpha: 0.42),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: selected ? const Color(0xFF062C21) : masteryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit ${index + 1}',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF062C21)
                          : const Color(0xFFB9D1C6),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 118),
                    child: Text(
                      unit.title.replaceFirst('Unit ${index + 1}: ', ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF062C21)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    this.compact = false,
  });

  final int completed;
  final int total;
  final double progress;
  final Lesson? nextLesson;
  final VoidCallback? onOpenNext;
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF10382D), Color(0xFF1C5C48)],
        ),
        borderRadius: BorderRadius.circular(compact ? 26 : 30),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
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
                'Pick up the next lesson, clear quizzes, and keep mastery moving.',
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
                      Wrap(spacing: 12, runSpacing: 12, children: buttons),
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
                  assetPath: AppAssets.academyLoopAnimation,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15392D), Color(0xFF0F2A21)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Color(0x554BD2A3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
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
                  color: Color(0xFFF7FFFB),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isComplete
                    ? 'You finished the current academy path. Revisit any unit or add the next chapter when you are ready.'
                    : '${nextLesson!.title} • ${nextUnit?.title ?? 'Academy'} • ${nextLesson!.estimatedMinutes} min',
                style: const TextStyle(color: Color(0xFFB9D1C6), height: 1.45),
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
                  ? const Color(0xFF274337)
                  : const Color(0xFF2F9E68),
              foregroundColor: isComplete
                  ? const Color(0xFFB9D1C6)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.play_arrow_rounded,
            ),
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
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9D1C6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
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
        color: const Color(0xFF143428),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4BD2A3)),
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
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15392D), Color(0xFF10281F)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Color(0x554BD2A3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cottage_rounded,
                        color: const Color(0xFFB8F5D1),
                        size: compact ? 22 : 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unit.title,
                          style: TextStyle(
                            color: const Color(0xFFF7FFFB),
                            fontSize: compact ? 24 : 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 14), badge],
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
              color: Color(0xFFF7FFFB),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2F9E68),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
