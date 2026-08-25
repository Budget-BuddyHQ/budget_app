import 'package:flutter/material.dart';

import '../widgets_custom_lotties/ambient_lottie_card.dart' show AmbientMotif;
import 'lesson.dart';
import 'lesson_data.dart';
import 'money_habit_models.dart';
import 'quiz_bank.dart';

/// The single surface a quest sends the player to.
///
/// This is the whole point of the daily plan: instead of five co-equal menus
/// (Academy / Arcade / Adventure / Money Habits / a stray Daily button)
/// competing for attention, each day hands the player an ordered list of
/// concrete actions, each pointing at exactly one place. The modes become
/// steps in one funnel rather than separate destinations — Money Habits in
/// particular used to be its own big standalone promo card on Home; it lives
/// here now instead, so Home doesn't grow a new card per feature.
enum QuestSurface {
  academyLesson,
  academyPractice,
  arcade,
  adventure,
  moneyHabit,
}

@immutable
class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.title,
    required this.detail,
    required this.surface,
    required this.icon,
    required this.accent,
    required this.xpReward,
    this.unitId,
    this.arcadeGameId,
    this.habitId,
    this.skillLabel,
    this.spriteMotif,
  });

  final String id;
  final String title;
  final String detail;
  final QuestSurface surface;
  final IconData icon;
  final Color accent;
  final int xpReward;

  /// When set, the quest row renders this animated pixel sprite instead of
  /// [icon] — used for arcade games that have their own mascot art rather
  /// than a generic Material icon.
  final AmbientMotif? spriteMotif;

  /// For academy quests: which unit to open.
  final String? unitId;

  /// For arcade quests: which game to launch.
  final String? arcadeGameId;

  /// For money-habit quests: which saved habit to log, if any is picked yet.
  final String? habitId;

  /// Human-readable skill this quest targets, if any (for the "why this" line).
  final String? skillLabel;
}

/// A day's plan: an ordered, completable checklist.
@immutable
class DailyPlan {
  const DailyPlan({
    required this.dateKey,
    required this.quests,
    required this.completedIds,
    required this.streakDays,
  });

  final String dateKey;
  final List<DailyQuest> quests;
  final Set<String> completedIds;
  final int streakDays;

  bool isDone(String questId) => completedIds.contains(questId);

  int get completedCount =>
      quests.where((q) => completedIds.contains(q.id)).length;

  bool get allDone => quests.isNotEmpty && completedCount == quests.length;

  /// The next quest to nudge the player toward — first incomplete one.
  DailyQuest? get nextQuest {
    for (final quest in quests) {
      if (!completedIds.contains(quest.id)) {
        return quest;
      }
    }
    return null;
  }

  double get progress => quests.isEmpty ? 0 : completedCount / quests.length;
}

/// Builds a deterministic daily plan from the player's state.
///
/// Deterministic per (day, player state) so it does not reshuffle every time
/// the home screen rebuilds. The choices are needs-based: it leads with the
/// player's weakest skill, fills in the next lesson, and rounds out with the
/// least-played arcade game so the plan always routes toward something that
/// actually helps rather than a random menu.
class DailyPlanBuilder {
  const DailyPlanBuilder();

  /// Arcade games a quest may point at, with the skill each best reinforces.
  static const Map<String, String> _arcadeSkillFocus = <String, String>{
    'finance_brawl': 'Recall under pressure',
    'market_board': 'Risk and volatility',
    'react_challenge': 'Quick judgement',
  };

  static const Map<String, IconData> _arcadeIcons = <String, IconData>{
    'finance_brawl': Icons.gavel_rounded,
    'market_board': Icons.show_chart_rounded,
    'react_challenge': Icons.bolt_rounded,
  };

  // Arcade games with their own mascot art use that instead of the generic
  // icon above — Finance Brawl gets the celebrating turtle sprite rather
  // than a courtroom gavel, which never actually matched the game.
  static const Map<String, AmbientMotif> _arcadeSpriteMotifs =
      <String, AmbientMotif>{'finance_brawl': AmbientMotif.turtle};

  DailyPlan build({
    required String dateKey,
    required Set<String> completedIds,
    required int streakDays,
    required List<String> weakSkills,
    required Set<String> completedLessons,
    required int Function(String gameId) arcadePlays,
    required List<String> activeArcadeGameIds,
    List<String> savedHabitIds = const <String>[],
    Set<String> habitsDoneToday = const <String>{},
    // The player's own self-declared age band, so the learning slot can
    // skip units pitched below them — see [_nextLesson].
    AgeStage? readerStage,
  }) {
    final quests = <DailyQuest>[];

    // 1. Learning slot — the next uncompleted lesson keeps the curriculum
    //    moving, which is the backbone of the whole app.
    final nextLesson = _nextLesson(completedLessons, readerStage);
    if (nextLesson != null) {
      quests.add(
        DailyQuest(
          id: 'lesson_${nextLesson.lesson.id}',
          title: 'Learn: ${nextLesson.lesson.title}',
          detail: 'Continue ${nextLesson.unit.title}',
          surface: QuestSurface.academyLesson,
          icon: Icons.school_rounded,
          accent: const Color(0xFF85EFAC),
          xpReward: 15,
          unitId: nextLesson.unit.id,
        ),
      );
    }

    // 2. Practice slot — drill the weakest skill, so play is remedial rather
    //    than random. Falls back to reviewing a finished unit if there are no
    //    recorded weak skills yet.
    final weakUnit = _unitForWeakestSkill(weakSkills);
    if (weakUnit != null) {
      quests.add(
        DailyQuest(
          id: 'practice_${weakUnit.unitId}',
          title: 'Practise: ${weakUnit.skillLabel}',
          detail: 'A quick set on something you missed',
          surface: QuestSurface.academyPractice,
          icon: Icons.fitness_center_rounded,
          accent: const Color(0xFF69C6FF),
          xpReward: 12,
          unitId: weakUnit.unitId,
          skillLabel: weakUnit.skillLabel,
        ),
      );
    }

    // 3. Arcade slot — the least-played active game, tagged with what it
    //    teaches so it reads as practice, not filler.
    final game = _leastPlayedGame(activeArcadeGameIds, arcadePlays);
    if (game != null) {
      quests.add(
        DailyQuest(
          id: 'arcade_${game}_$dateKey',
          title: 'Play: ${_arcadeTitle(game)}',
          detail: 'Drills ${_arcadeSkillFocus[game] ?? 'money skills'}',
          surface: QuestSurface.arcade,
          icon: _arcadeIcons[game] ?? Icons.sports_esports_rounded,
          accent: const Color(0xFFE1BB72),
          xpReward: 10,
          arcadeGameId: game,
          skillLabel: _arcadeSkillFocus[game],
          spriteMotif: _arcadeSpriteMotifs[game],
        ),
      );
    }

    // 4. Money habit slot — Money Habits' entire Home presence lives here
    //    now rather than in its own promo card. Nudges toward logging a
    //    saved-but-not-yet-done-today habit, or toward picking a first one
    //    if none is saved yet — either way this is the only Home-level
    //    surface the feature gets.
    final habitQuest = _moneyHabitQuest(savedHabitIds, habitsDoneToday);
    if (habitQuest != null) {
      quests.add(habitQuest);
    }

    // Guarantee a non-empty plan even for a brand-new account with nothing
    // recorded: send them into the adventure to earn their first coins.
    if (quests.isEmpty) {
      quests.add(
        const DailyQuest(
          id: 'adventure_intro',
          title: 'Explore the world',
          detail: 'Collect coins in the adventure map',
          surface: QuestSurface.adventure,
          icon: Icons.explore_rounded,
          accent: Color(0xFFFFD45C),
          xpReward: 10,
        ),
      );
    }

    return DailyPlan(
      dateKey: dateKey,
      quests: quests,
      completedIds: completedIds,
      streakDays: streakDays,
    );
  }

  /// The lesson to quest today.
  ///
  /// **Why this takes an age stage.** This used to walk `lessonUnits` in raw
  /// list order and quest the first uncompleted node it found, which made
  /// list position secretly mean "difficulty order". That forced the
  /// youngest units (ages 4-6, 7-10) to be pinned at the *end* of the
  /// curriculum list purely so they wouldn't be recommended to adults —
  /// while the Academy's own unit strip displayed them first, because it
  /// sorts by age. List order and reading order disagreed, and the list
  /// could never be put in the order a human would expect.
  ///
  /// Filtering by the reader's own age band decouples those two things: the
  /// curriculum list is now in chronological (age) order like the Academy
  /// shows it, and an adult still never gets "What Is Money?" as their
  /// daily quest, because units below their stage are skipped on the first
  /// pass.
  ///
  /// The fallback matters: a reader who has finished everything at or above
  /// their own stage still gets *something* rather than no learning quest,
  /// so the slot never silently disappears.
  ({Lesson lesson, LessonUnit unit})? _nextLesson(
    Set<String> completed,
    AgeStage? readerStage,
  ) {
    ({Lesson lesson, LessonUnit unit})? firstUncompleted(
      bool Function(LessonUnit unit) where,
    ) {
      for (final unit in lessonUnits) {
        if (!where(unit)) continue;
        for (final lesson in unit.lessons) {
          if (lesson.type != LessonNodeType.lesson) continue;
          if (!completed.contains(lesson.id)) {
            return (lesson: lesson, unit: unit);
          }
        }
      }
      return null;
    }

    if (readerStage != null) {
      final atOrAboveReader = firstUncompleted(
        (unit) => unit.ageStage.minAge >= readerStage.minAge,
      );
      if (atOrAboveReader != null) return atOrAboveReader;
    }
    return firstUncompleted((_) => true);
  }

  ({String unitId, String skillLabel})? _unitForWeakestSkill(
    List<String> weakSkills,
  ) {
    if (weakSkills.isEmpty) {
      return null;
    }
    final skillId = weakSkills.first;
    final unitId = _unitForSkill(skillId);
    if (unitId == null) {
      return null;
    }
    return (unitId: unitId, skillLabel: QuizSkills.label(skillId));
  }

  /// Maps a skill back to the unit whose practice set covers it.
  String? _unitForSkill(String skillId) {
    for (final unit in lessonUnits) {
      final questions = practiceFor(unit.id);
      if (questions.any((q) => q.skillId == skillId)) {
        return unit.id;
      }
    }
    // Not in a practice set — fall back to any unit that quizzes it.
    for (final entry in quizBank.entries) {
      if (entry.value.any((q) => q.skillId == skillId)) {
        final node = lessonUnits
            .expand((u) => u.lessons.map((l) => (u, l)))
            .where((pair) => pair.$2.id == entry.key)
            .firstOrNull;
        if (node != null) {
          return node.$1.id;
        }
      }
    }
    return null;
  }

  DailyQuest? _moneyHabitQuest(
    List<String> savedHabitIds,
    Set<String> doneToday,
  ) {
    if (savedHabitIds.isEmpty) {
      return const DailyQuest(
        id: 'money_habit_pick',
        title: 'Pick a money habit',
        detail: 'Save one from Money Habits to start your streak',
        surface: QuestSurface.moneyHabit,
        icon: Icons.savings_rounded,
        accent: Color(0xFF4BD2A3),
        xpReward: 8,
      );
    }
    final pending = savedHabitIds.where((id) => !doneToday.contains(id));
    if (pending.isEmpty) {
      // Every saved habit is already logged today — no slot needed.
      return null;
    }
    final habitId = pending.first;
    final title = habitById(habitId)?.title ?? 'your saved habit';
    return DailyQuest(
      id: 'money_habit_$habitId',
      title: 'Save today: $title',
      detail: 'Log it in Money Habits',
      surface: QuestSurface.moneyHabit,
      icon: Icons.savings_rounded,
      accent: const Color(0xFF4BD2A3),
      xpReward: 8,
      habitId: habitId,
    );
  }

  String? _leastPlayedGame(List<String> gameIds, int Function(String) plays) {
    if (gameIds.isEmpty) {
      return null;
    }
    final sorted = [...gameIds]..sort((a, b) => plays(a).compareTo(plays(b)));
    return sorted.first;
  }

  String _arcadeTitle(String gameId) => switch (gameId) {
    'finance_brawl' => 'Finance Brawl',
    'market_board' => 'Market Board',
    'react_challenge' => 'React Challenge',
    _ => gameId,
  };
}
