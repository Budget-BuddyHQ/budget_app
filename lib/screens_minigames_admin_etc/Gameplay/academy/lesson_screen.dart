import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../custom_made_widgets/unit_row_item.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/progression_service.dart';
import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../services_backend_and_other_services/supabase_service.dart'
    show UserStats;
import '../../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../loading/temporary_loading_screen.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'lesson_detail_screen.dart';
import 'practice_screen.dart';

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
      initialAccuracy: _accuracyFromStats(),
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

  /// Best accuracy per assessment node, pulled out of the saved quiz scores.
  Map<String, double> _accuracyFromStats() {
    final stats = _statsController.stats;
    final result = <String, double>{};
    for (final nodeId in stats.quizScores.keys) {
      final accuracy = stats.accuracyFor(nodeId);
      if (accuracy != null) {
        result[nodeId] = accuracy;
      }
    }
    return result;
  }

  void _syncProgressFromStats() {
    _progressionService
      ..replaceCompletedLessons(_statsController.stats.completedLessons)
      ..replaceAccuracy(_accuracyFromStats());
  }

  void _selectUnit(int index) {
    setState(() {
      _selectedUnitIndex = index;
      _hasManualUnitSelection = true;
    });

    if (!_unitQuickScrollController.hasClients) {
      return;
    }

    // The strip is grouped by age band, so a unit's position in it is no
    // longer its curriculum index — and each band adds a header of its own
    // width ahead of the units under it.
    final targetOffset =
        _UnitQuickChangerBar.estimatedOffsetFor(
          _progressionService.units,
          index,
        ).clamp(0.0, _unitQuickScrollController.position.maxScrollExtent);
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

    final unit = _progressionService.getUnit(lesson.unitId)!;

    // Age warning, not an age lock. The prerequisite chain is what gates the
    // curriculum; this only makes sure nobody wanders into the 401(k) unit at
    // twelve and assumes the salary-shaped examples are describing them.
    if (isAboveReaderStage(
      unit.ageStage,
      _statsController.stats.ageBand.maxPlausibleStage,
    )) {
      final proceed = await _confirmAboveAge(unit);
      if (!proceed || !mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(
          lesson: lesson,
          unit: unit,
          progressionService: _progressionService,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  /// Asks before opening a unit written for an older band. Returns false if
  /// the player backs out or dismisses the sheet.
  Future<bool> _confirmAboveAge(LessonUnit unit) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F2C22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x55FFB84D)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFB84D),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Written for ${unit.ageStage.label.toLowerCase()}',
                style: GoogleFonts.baloo2(
                  color: const Color(0xFFFFB84D),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${unit.title.split(':').last.trim()} assumes money and choices from '
          'an older age group — things like a salary, taxes, or a workplace '
          'plan. Nothing is stopping you reading it, but the numbers are a '
          'preview of later, not a description of now.',
          style: GoogleFonts.quicksand(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.7),
            ),
            child: const Text(
              'Go back',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB84D),
              foregroundColor: const Color(0xFF3A2400),
            ),
            child: const Text(
              'Read it anyway',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _openPractice(LessonUnit unit) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PracticeScreen(unit: unit)));
    if (mounted) {
      setState(() {});
    }
  }

  List<Widget> _unitCards(
    List<LessonUnit> units, {
    required bool compact,
    required int unitIndexOffset,
    AgeStage? recommendedStage,
    AgeStage? warnAboveStage,
  }) {
    return <Widget>[
      for (var index = 0; index < units.length; index++) ...[
        _UnitCard(
          compact: compact,
          unit: units[index],
          unitIndex: unitIndexOffset + index,
          progress: _progressionService.getUnitProgress(units[index].id),
          mastery: _progressionService.getUnitMastery(units[index].id),
          accuracy: _progressionService.getUnitAccuracy(units[index].id),
          onLessonTap: _openLesson,
          onPractice: () => _openPractice(units[index]),
          statusFor: _progressionService.getLessonStatus,
          accuracyFor: _progressionService.accuracyFor,
          isRecommended: units[index].ageStage == recommendedStage,
          isAboveReader: isAboveReaderStage(
            units[index].ageStage,
            warnAboveStage,
          ),
        ),
        if (index != units.length - 1) const SizedBox(height: 16),
      ],
    ];
  }

  /// Existing tile backgrounds, reused so each unit tab reads as its own
  /// place without drawing new art.
  static const List<String> _unitBackgrounds = [
    AppAssets.homeTileBackground,
    AppAssets.arcadeTileBackground,
    AppAssets.meadowTileBackground,
    AppAssets.adventureMapBackground,
    AppAssets.profileTileBackground,
  ];

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
    final recommendedStage = _statsController.stats.ageBand.recommendedStage;
    // Warnings use the *top* of the player's age band, not its middle — see
    // `AgeBand.maxPlausibleStage`.
    final warnAboveStage = _statsController.stats.ageBand.maxPlausibleStage;

    return Scaffold(
      backgroundColor: const Color(0xFF10352A),
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
                _unitBackgrounds[selectedUnitIndex % _unitBackgrounds.length],
                key: ValueKey(selectedUnitIndex),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
              ),
            ),
            // A vignette instead of a flat dim: darker top/bottom so header
            // text and the bottom nav stay readable, lighter through the
            // middle so the hand-composited unit art actually reads instead
            // of looking like a flat muted wash.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // Matches the welcome screen's light 0.55-0.62 range
                      // rather than the 0.82-0.86 wash that was burying the
                      // unit art completely. Slightly stronger at the very
                      // top and bottom so the header text and bottom nav
                      // still have something to sit against.
                      const Color(0xFF0C2418).withValues(alpha: 0.66),
                      const Color(0xFF0C2418).withValues(alpha: 0.48),
                      const Color(0xFF0C2418).withValues(alpha: 0.70),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -50,
              child: IgnorePointer(
                child: _AcademyGlowOrb(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.20),
                  size: 210,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -60,
              child: IgnorePointer(
                child: _AcademyGlowOrb(
                  color: const Color(0xFF58C7FF).withValues(alpha: 0.14),
                  size: 190,
                ),
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
                        readerStage: recommendedStage,
                        warnAboveStage: warnAboveStage,
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
                      _AcademyAnalyticsCard(
                        compact: true,
                        units: units,
                        progression: _progressionService,
                        stats: _statsController.stats,
                      ),
                      const SizedBox(height: 12),
                      const _MasteryLegend(compact: true),
                      const SizedBox(height: 16),
                      ..._unitCards(
                        [selectedUnit],
                        compact: true,
                        unitIndexOffset: selectedUnitIndex,
                        recommendedStage: recommendedStage,
                        warnAboveStage: warnAboveStage,
                      ),
                    ],
                  );
                }

                // Everything scrolls as one list. Pinning the header above an
                // Expanded list overflowed once the combined fixed height
                // passed the viewport — which happens on a tablet in
                // landscape at 1024x768.
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _UnitQuickChangerBar(
                      controller: _unitQuickScrollController,
                      units: units,
                      activeIndex: selectedUnitIndex,
                      progressFor: _progressionService.getUnitProgress,
                      masteryFor: _progressionService.getUnitMastery,
                      onSelected: _selectUnit,
                      readerStage: recommendedStage,
                      warnAboveStage: warnAboveStage,
                    ),
                    const SizedBox(height: 12),
                    _HubHeader(
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
                    _AcademyAnalyticsCard(
                      compact: false,
                      units: units,
                      progression: _progressionService,
                      stats: _statsController.stats,
                    ),
                    const SizedBox(height: 12),
                    const _MasteryLegend(),
                    const SizedBox(height: 16),
                    ..._unitCards(
                      [selectedUnit],
                      compact: compactLayout,
                      unitIndexOffset: selectedUnitIndex,
                      recommendedStage: recommendedStage,
                      warnAboveStage: warnAboveStage,
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
    this.readerStage,
    this.warnAboveStage,
  });

  final ScrollController controller;
  final List<LessonUnit> units;
  final int activeIndex;
  final double Function(String unitId) progressFor;
  final MasteryLevel Function(String unitId) masteryFor;
  final ValueChanged<int> onSelected;

  /// The player's own [AgeStage], or null if they didn't share an age band.
  final AgeStage? readerStage;

  /// The top of the player's age band — anything above it gets a warning mark.
  final AgeStage? warnAboveStage;

  /// Chips grouped under age headers rather than left in curriculum order.
  ///
  /// The curriculum order is a prerequisite chain and isn't age-monotonic —
  /// Unit 2 (credit) is written for 18-20s while Unit 3 (saving systems) is
  /// for 14-17s — so reading the strip left to right told you nothing about
  /// who a unit was for. Sorting the *strip* by age band (and only the strip;
  /// `onSelected` still carries each unit's real index) makes the division by
  /// age the first thing you see.
  List<({int index, LessonUnit unit})> get _byAge => _sortByAge(units);

  static List<({int index, LessonUnit unit})> _sortByAge(
    List<LessonUnit> units,
  ) {
    final entries = <({int index, LessonUnit unit})>[
      for (var i = 0; i < units.length; i++) (index: i, unit: units[i]),
    ];
    entries.sort((a, b) {
      final byStage = a.unit.ageStage.minAge.compareTo(b.unit.ageStage.minAge);
      return byStage != 0 ? byStage : a.unit.order.compareTo(b.unit.order);
    });
    return entries;
  }

  /// Roughly how far along the strip the unit at curriculum [index] sits, so
  /// tapping a chip scrolls it into view. Approximate on purpose — chip widths
  /// depend on their labels, and this only has to land near the right place.
  static double estimatedOffsetFor(List<LessonUnit> units, int index) {
    const chipWidth = 156.0;
    const headerWidth = 174.0;
    var offset = 0.0;
    AgeStage? previousStage;
    for (final entry in _sortByAge(units)) {
      if (entry.unit.ageStage != previousStage) {
        offset += headerWidth;
        previousStage = entry.unit.ageStage;
      }
      if (entry.index == index) return offset;
      offset += chipWidth;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _byAge;
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
              for (var slot = 0; slot < entries.length; slot++) ...[
                if (slot == 0 ||
                    entries[slot].unit.ageStage !=
                        entries[slot - 1].unit.ageStage) ...[
                  if (slot != 0) const SizedBox(width: 10),
                  _AgeGroupHeader(
                    stage: entries[slot].unit.ageStage,
                    isReaderStage: entries[slot].unit.ageStage == readerStage,
                    isAboveReader: isAboveReaderStage(
                      entries[slot].unit.ageStage,
                      warnAboveStage,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                _UnitJumpChip(
                  unit: entries[slot].unit,
                  index: entries[slot].index,
                  selected: entries[slot].index == activeIndex,
                  progress: progressFor(entries[slot].unit.id),
                  mastery: masteryFor(entries[slot].unit.id),
                  isAboveReader: isAboveReaderStage(
                    entries[slot].unit.ageStage,
                    warnAboveStage,
                  ),
                  onTap: () => onSelected(entries[slot].index),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Age-band label that opens each group in the unit strip.
///
/// Not tappable — it's a heading, and the units under it are the controls.
class _AgeGroupHeader extends StatelessWidget {
  const _AgeGroupHeader({
    required this.stage,
    required this.isReaderStage,
    required this.isAboveReader,
  });

  final AgeStage stage;
  final bool isReaderStage;
  final bool isAboveReader;

  @override
  Widget build(BuildContext context) {
    final accent = isReaderStage
        ? const Color(0xFF85EFAC)
        : isAboveReader
        ? const Color(0xFFFFB84D)
        : const Color(0xFF9FB8AC);

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReaderStage
                    ? Icons.star_rounded
                    : isAboveReader
                    ? Icons.warning_amber_rounded
                    : Icons.cake_rounded,
                size: 13,
                color: accent,
              ),
              const SizedBox(width: 5),
              Text(
                stage.label,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              isReaderStage
                  ? 'Your age group'
                  : isAboveReader
                  ? 'Older than you'
                  : stage.blurb,
              maxLines: 2,
              style: TextStyle(
                color: accent.withValues(alpha: 0.8),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
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
    this.isAboveReader = false,
  });

  final LessonUnit unit;
  final int index;
  final bool selected;
  final double progress;
  final MasteryLevel mastery;
  final VoidCallback onTap;

  /// Pitched at an older band than the player's own — draws a warning mark.
  final bool isAboveReader;

  @override
  Widget build(BuildContext context) {
    final masteryColor = switch (mastery) {
      MasteryLevel.novice => const Color(0xFFCBD5E1),
      MasteryLevel.familiar => const Color(0xFFA7D8FF),
      MasteryLevel.proficient => const Color(0xFFFFD45C),
      MasteryLevel.mastered => const Color(0xFF85EFAC),
    };
    // The selected chip fills with its unit's own colour, so the tab strip
    // reads as five distinct places rather than five identical green pills.
    final accent = unitAccentFor(index);

    return Semantics(
      button: true,
      label:
          'Jump to ${unit.title}, ${(progress * 100).round()} percent complete'
          '${isAboveReader ? ', written for an older age group' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 60, minWidth: 146),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent
                : Color.lerp(const Color(0xFF13332A), accent, 0.12)!,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.85)
                  : accent.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: selected ? const Color(0xFF062C21) : accent,
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
                  // Mastery used to be carried by this chip's icon/border
                  // colour, which the per-unit accent now owns — so it moves
                  // to its own progress bar rather than being dropped.
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 118,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: progress,
                        backgroundColor: selected
                            ? const Color(0x33062C21)
                            : Colors.white.withValues(alpha: 0.14),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          selected ? const Color(0xFF062C21) : masteryColor,
                        ),
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
                  motif: AmbientMotif.academy,
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
    required this.unitIndex,
    required this.progress,
    required this.mastery,
    required this.accuracy,
    required this.onLessonTap,
    required this.onPractice,
    required this.statusFor,
    required this.accuracyFor,
    this.compact = false,
    this.isRecommended = false,
    this.isAboveReader = false,
  });

  final LessonUnit unit;
  final int unitIndex;
  final double progress;
  final MasteryLevel mastery;
  final bool isRecommended;

  /// This unit is written for an older age band than the player's own.
  final bool isAboveReader;

  /// Mean best accuracy across attempted assessments, null if none taken yet.
  final double? accuracy;

  final ValueChanged<Lesson> onLessonTap;
  final VoidCallback onPractice;
  final LessonStatus Function(String lessonId) statusFor;

  /// Best accuracy on one specific quiz/unit-test node, null if not
  /// attempted yet — shown as a score on that node's row.
  final double? Function(String lessonId) accuracyFor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Each unit carries its own hue so the Academy isn't one flat green.
    final accent = unitAccentFor(unitIndex);
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // Lifted off the near-black end of the palette so the card sits
            // *above* the backdrop tonally instead of merging into it — the
            // main reason the tab read as one dense block of green.
            Color.lerp(const Color(0xFF1B4536), accent, 0.16)!,
            const Color(0xFF122F26),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.4),
        boxShadow: [
          const BoxShadow(
            color: Color(0x44000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.13),
            blurRadius: 26,
            spreadRadius: -6,
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
                  // Who this unit is written for, so the path visibly grows
                  // with the learner instead of reading as a flat list.
                  _AgeStageChip(
                    stage: unit.ageStage,
                    isRecommended: isRecommended,
                    isAboveReader: isAboveReader,
                  ),
                  const SizedBox(height: 10),
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
          if (isAboveReader) ...[
            const SizedBox(height: 14),
            _TooYoungBanner(stage: unit.ageStage, compact: compact),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(progress * 100).round()}% complete',
                  style: const TextStyle(
                    color: Color(0xFFF7FFFB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (accuracy != null)
                Text(
                  '${(accuracy! * 100).round()}% accuracy',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 16),
          UnitRowItem(
            lessons: unit.lessons,
            statusFor: statusFor,
            accuracyFor: accuracyFor,
            onLessonTap: onLessonTap,
            unitIndex: unitIndex,
          ),
          if (practiceFor(unit.id).isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.fitness_center_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF69C6FF),
                  side: BorderSide(
                    color: const Color(0xFF69C6FF).withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  'Practice this unit',
                  style: GoogleFonts.baloo2(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
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

/// Small badge naming the age range a unit is pitched at.
class _AgeStageChip extends StatelessWidget {
  const _AgeStageChip({
    required this.stage,
    this.isRecommended = false,
    this.isAboveReader = false,
  });

  final AgeStage stage;

  /// True when this unit is pitched above the player's own band. Takes
  /// precedence over [isRecommended] in the styling — the two can never both
  /// be true, but a warning outranks a suggestion if they somehow are.
  final bool isAboveReader;

  /// True when this unit's [AgeStage] matches the player's own age band.
  /// Purely informational — it never unlocks or reorders anything, since
  /// every unit still requires the previous unit's test to be completed
  /// first regardless of age. See `player_profile.dart`'s
  /// `AgeBand.recommendedStage`.
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final accent = isAboveReader
        ? const Color(0xFFFFB84D)
        : isRecommended
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFFD45C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAboveReader
                ? Icons.warning_amber_rounded
                : isRecommended
                ? Icons.star_rounded
                : Icons.cake_rounded,
            size: 12,
            color: accent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isAboveReader
                  ? '${stage.label} · Older than you'
                  : isRecommended
                  ? '${stage.label} · For you'
                  : '${stage.label} · ${stage.blurb}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "this is written for older readers" notice on a unit card.
///
/// Deliberately a warning and not a lock: the Academy's gating is the
/// prerequisite chain, and a curious 12-year-old reading the 401(k) unit is a
/// good outcome. What they need is a heads-up that the examples assume a
/// salary and a tax bracket they don't have yet, so they don't read their own
/// situation as the failure.
class _TooYoungBanner extends StatelessWidget {
  const _TooYoungBanner({required this.stage, this.compact = false});

  final AgeStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFB84D);
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Written for ${stage.label.toLowerCase()}',
                  style: const TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This unit is above your age group, so the examples assume '
                  'money and choices you may not have yet. You can still read '
                  'it — just take the numbers as a preview.',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Learning analytics: how much of the Academy is done, how accurate the
/// player's answers are, which age stages they have reached, and which skills
/// still need work. Uses only data the app already records.
class _AcademyAnalyticsCard extends StatelessWidget {
  const _AcademyAnalyticsCard({
    required this.compact,
    required this.units,
    required this.progression,
    required this.stats,
  });

  final bool compact;
  final List<LessonUnit> units;
  final ProgressionService progression;
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final completed = progression.completedCount;
    final total = progression.totalCount;

    // Average accuracy across units that have actually been attempted.
    final accuracies = <double>[
      for (final unit in units)
        if (progression.getUnitAccuracy(unit.id) case final a?) a,
    ];
    final avgAccuracy = accuracies.isEmpty
        ? null
        : accuracies.reduce((a, b) => a + b) / accuracies.length;

    final mastered = units
        .where((u) => progression.getUnitMastery(u.id) == MasteryLevel.mastered)
        .length;

    // The furthest age stage with any progress — how far along the path they are.
    AgeStage? reached;
    for (final unit in units) {
      if (progression.getUnitProgress(unit.id) > 0) {
        if (reached == null || unit.ageStage.minAge > reached.minAge) {
          reached = unit.ageStage;
        }
      }
    }

    final weakSkills = stats.weakSkills;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x554BD2A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: Color(0xFF85EFAC),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your learning stats',
                style: TextStyle(
                  color: Color(0xFFF7FFFB),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AnalyticStat(
                label: 'Lessons done',
                value: '$completed/$total',
                color: const Color(0xFF85EFAC),
              ),
              _AnalyticStat(
                label: 'Avg accuracy',
                value: avgAccuracy == null
                    ? '—'
                    : '${(avgAccuracy * 100).round()}%',
                color: avgAccuracy == null
                    ? Colors.white54
                    : (avgAccuracy >= 0.8
                          ? const Color(0xFF85EFAC)
                          : const Color(0xFFFFD45C)),
              ),
              _AnalyticStat(
                label: 'Units mastered',
                value: '$mastered/${units.length}',
                color: const Color(0xFFFFD45C),
              ),
              _AnalyticStat(
                label: 'Reached',
                value: reached?.label ?? 'Not started',
                color: const Color(0xFF58C7FF),
              ),
            ],
          ),
          if (weakSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Worth reviewing',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in weakSkills.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB084).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: Color(0xFFFFB084),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticStat extends StatelessWidget {
  const _AnalyticStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft ambient glow, same treatment as the one on the Home dashboard —
/// gives the backdrop some depth instead of reading as a flat tint.
class _AcademyGlowOrb extends StatelessWidget {
  const _AcademyGlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.40,
            spreadRadius: size * 0.06,
          ),
        ],
      ),
    );
  }
}
