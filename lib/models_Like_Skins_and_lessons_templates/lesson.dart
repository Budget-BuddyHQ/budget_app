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

class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.order,
    required this.lessons,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int order;
  final List<Lesson> lessons;
}
