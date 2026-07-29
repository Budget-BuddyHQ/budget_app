import 'package:flutter/material.dart';

import 'lesson.dart';
import 'lesson_data.dart';
import 'quiz_bank.dart';

/// The single surface a quest sends the player to.
///
/// This is the whole point of the daily plan: instead of four co-equal menus
/// (Academy / Arcade / Adventure / a stray Daily button) competing for
/// attention, each day hands the player an ordered list of 3 concrete actions,
/// each pointing at exactly one place. The modes become steps in one funnel
/// rather than four separate destinations.
enum QuestSurface { academyLesson, academyPractice, arcade, adventure }

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
    this.skillLabel,
  });

  final String id;
  final String title;
  final String detail;
  final QuestSurface surface;
  final IconData icon;
  final Color accent;
  final int xpReward;

  /// For academy quests: which unit to open.
  final String? unitId;

  /// For arcade quests: which game to launch.
  final String? arcadeGameId;

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

  DailyPlan build({
    required String dateKey,
    required Set<String> completedIds,
    required int streakDays,
    required List<String> weakSkills,
    required Set<String> completedLessons,
    required int Function(String gameId) arcadePlays,
    required List<String> activeArcadeGameIds,
  }) {
    final quests = <DailyQuest>[];

    // 1. Learning slot — the next uncompleted lesson keeps the curriculum
    //    moving, which is the backbone of the whole app.
    final nextLesson = _nextLesson(completedLessons);
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
        ),
      );
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

  ({Lesson lesson, LessonUnit unit})? _nextLesson(Set<String> completed) {
    for (final unit in lessonUnits) {
      for (final lesson in unit.lessons) {
        if (lesson.type != LessonNodeType.lesson) {
          continue;
        }
        if (!completed.contains(lesson.id)) {
          return (lesson: lesson, unit: unit);
        }
      }
    }
    return null;
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
