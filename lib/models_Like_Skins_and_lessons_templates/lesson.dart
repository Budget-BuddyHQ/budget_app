import 'package:flutter/material.dart' show Color;

enum LessonStatus { completed, available, locked }

enum LessonNodeType { lesson, quiz, unitTest }

enum MasteryLevel { novice, familiar, proficient, mastered }

/// One accent per unit, in curriculum order.
///
/// The Academy used to draw every unit in the same emerald, which made the
/// whole tab read as one dense wall of green and made units visually
/// indistinguishable from each other. Giving each its own hue lets the path
/// show progression at a glance and balances the green with blue/gold/violet.
const List<Color> kUnitAccents = <Color>[
  Color(0xFF4BD2A3), // Unit 1 · Budgeting — emerald (the app's home colour)
  Color(0xFF58C7FF), // Unit 2 · Credit — blue
  Color(0xFF5EE7D6), // Unit 3 · Saving Systems — cyan
  Color(0xFFFFD45C), // Unit 4 · Investing Basics — gold
  Color(0xFFB388FF), // Unit 5 · Real-World Money — violet
];

/// Accent for a unit by its 0-based position, wrapping if the curriculum
/// ever grows past the palette.
Color unitAccentFor(int unitIndex) =>
    kUnitAccents[unitIndex % kUnitAccents.length];

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

/// The stage a given age falls into, by [AgeStageInfo.minAge]. [AgeStage]'s
/// declaration order is already ascending by minAge, so this is a simple
/// "last stage whose floor we've reached" scan rather than a sorted lookup.
AgeStage stageForAge(int age) {
  var result = AgeStage.values.first;
  for (final stage in AgeStage.values) {
    if (age >= stage.minAge) {
      result = stage;
    } else {
      break;
    }
  }
  return result;
}

/// True when [unit] is written for an older band than the reader's own.
///
/// Nothing is locked by this — the unit still opens, because the curriculum
/// gates on finishing the previous unit's test, not on age. It only decides
/// whether the Academy shows an "older than you" warning first, so a 12-year-old
/// who reaches the 401(k) unit knows the examples assume a salary they don't
/// have yet. Returns false when the reader didn't share an age band, since
/// there is nothing to compare against.
bool isAboveReaderStage(AgeStage unit, AgeStage? reader) =>
    reader != null && unit.minAge > reader.minAge;

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
