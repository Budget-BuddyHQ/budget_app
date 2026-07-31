enum LessonStatus { completed, available, locked }

enum LessonNodeType { lesson, quiz, unitTest }

enum MasteryLevel { novice, familiar, proficient, mastered }

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.unitId,
    required this.order,
    this.type = LessonNodeType.lesson,
    this.prerequisites = const <String>[],
    this.estimatedMinutes = 8,
  });

  final String id;
  final String title;
  final String unitId;
  final int order;
  final LessonNodeType type;
  final List<String> prerequisites;
  final int estimatedMinutes;
}

/// Roughly who a unit is written for. Units are ordered by this so the Academy
/// reads as a path that grows with the learner rather than a flat list — a
/// 13-year-old starts at pocket money, an 18-year-old at credit and taxes.
enum AgeStage { middleSchool, highSchool, graduating, adult }

extension AgeStageInfo on AgeStage {
  /// Short label shown on the unit header.
  String get label => switch (this) {
    AgeStage.middleSchool => 'Ages 11–13',
    AgeStage.highSchool => 'Ages 14–17',
    AgeStage.graduating => 'Ages 18–20',
    AgeStage.adult => 'Ages 21+',
  };

  String get blurb => switch (this) {
    AgeStage.middleSchool => 'Pocket money and first choices',
    AgeStage.highSchool => 'Earning, saving and first accounts',
    AgeStage.graduating => 'Credit, rent and independence',
    AgeStage.adult => 'Investing and long-term wealth',
  };

  /// Lowest age this stage is aimed at — used to sort and to pick the stage
  /// that matches the player's own age band.
  int get minAge => switch (this) {
    AgeStage.middleSchool => 11,
    AgeStage.highSchool => 14,
    AgeStage.graduating => 18,
    AgeStage.adult => 21,
  };
}

class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.order,
    required this.lessons,
    this.ageStage = AgeStage.highSchool,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int order;
  final List<Lesson> lessons;

  /// Who this unit is pitched at.
  final AgeStage ageStage;
}
