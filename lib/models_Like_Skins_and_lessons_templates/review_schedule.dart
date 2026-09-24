import 'dart:math' as math;

import 'finance_concepts.dart';

// spaced repetition for the 16 money concepts. basically anki's algo (sm-2)
// so stuff you got right doesnt just get forgotten a month later.
// tweaked the floors/ceilings a bit so it never spirals into asking the
// same thing every single day forever, and caps out around 6 months
class ReviewState {
  const ReviewState({
    required this.concept,
    this.repetitions = 0,
    this.easeFactor = defaultEase,
    this.intervalDays = 0,
    this.lastReviewed,
  });

  // starting ease, everything else is relative to this
  static const double defaultEase = 2.5;

  // floor so it cant spiral into asking every day forever
  static const double minimumEase = 1.3;

  // ~6 months, long enough to be out the way, short enough it comes back
  static const int maximumIntervalDays = 180;

  // 60% counts as "knew it". set higher than a normal pass mark on purpose
  static const double passingGrade = 0.6;

  final FinanceConcept concept;

  // correct answers in a row. one miss resets this to 0
  final int repetitions;

  final double easeFactor;
  final int intervalDays;
  final DateTime? lastReviewed;

  // when this should show up again, null if never studied
  DateTime? get dueDate => lastReviewed == null
      ? null
      : DateTime(
          lastReviewed!.year,
          lastReviewed!.month,
          lastReviewed!.day + intervalDays,
        );

  // never-studied concepts arent "due", theyre new. different queue
  bool isDueOn(DateTime today) {
    final due = dueDate;
    if (due == null) return false;
    final day = DateTime(today.year, today.month, today.day);
    return !day.isBefore(due);
  }

  bool get isNew => lastReviewed == null;

  // grade is 0..1, a quiz accuracy not a self rating
  ReviewState review(double grade, {required DateTime on}) {
    final passed = grade >= passingGrade;

    // fail = resets streak, comes back tomorrow. doesnt touch ease factor,
    // one bad answer shouldnt undo how easily this person usually gets it
    if (!passed) {
      return ReviewState(
        concept: concept,
        repetitions: 0,
        easeFactor: math.max(minimumEase, easeFactor - 0.2),
        intervalDays: 1,
        lastReviewed: on,
      );
    }

    final nextReps = repetitions + 1;

    // sm-2 ease update, rescaled from its 0-5 rating to our 0-1 accuracy
    final q = grade * 5;
    final nextEase = math.max(
      minimumEase,
      easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)),
    );

    final nextInterval = switch (nextReps) {
      1 => 1,
      2 => 6,
      _ => math.min(
        maximumIntervalDays,
        (intervalDays * nextEase).round(),
      ),
    };

    return ReviewState(
      concept: concept,
      repetitions: nextReps,
      easeFactor: nextEase,
      intervalDays: nextInterval,
      lastReviewed: on,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'r': repetitions,
    'e': easeFactor,
    'i': intervalDays,
    if (lastReviewed != null) 'l': lastReviewed!.toIso8601String(),
  };

  // pulls a number out of stored json without trusting the type. this comes
  // from a jsonb column so who knows whats actually in there, dont crash
  static num? _num(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static ReviewState fromMap(FinanceConcept concept, Map<String, dynamic> map) {
    DateTime? last;
    final raw = map['l'];
    if (raw is String) last = DateTime.tryParse(raw);

    return ReviewState(
      concept: concept,
      repetitions: _num(map['r'])?.toInt() ?? 0,
      easeFactor: _num(map['e'])?.toDouble() ?? defaultEase,
      intervalDays: _num(map['i'])?.toInt() ?? 0,
      lastReviewed: last,
    );
  }
}

// the whole schedule, one ReviewState per concept
class ReviewSchedule {
  const ReviewSchedule(this.states);

  final Map<FinanceConcept, ReviewState> states;

  // nothing studied yet
  factory ReviewSchedule.empty() => ReviewSchedule(<FinanceConcept, ReviewState>{
    for (final c in FinanceConcept.values) c: ReviewState(concept: c),
  });

  ReviewState stateFor(FinanceConcept concept) =>
      states[concept] ?? ReviewState(concept: concept);

  // needs-review concepts, most overdue first (not by due date, by how late)
  List<ReviewState> dueOn(DateTime today) {
    final due = states.values.where((s) => s.isDueOn(today)).toList();
    due.sort((a, b) {
      final aDays = today.difference(a.dueDate!).inDays;
      final bDays = today.difference(b.dueDate!).inDays;
      if (aDays != bDays) return bDays.compareTo(aDays);
      // tie goes to whichever one this person finds harder
      return a.easeFactor.compareTo(b.easeFactor);
    });
    return due;
  }

  // never studied at all
  List<ReviewState> get unseen =>
      states.values.where((s) => s.isNew).toList();

  // whats next, overdue beats new every time
  ReviewState? nextUp(DateTime today) {
    final due = dueOn(today);
    if (due.isNotEmpty) return due.first;
    final fresh = unseen;
    return fresh.isEmpty ? null : fresh.first;
  }

  // days til next thing is due. 0 = due today, null = nothing scheduled
  int? daysUntilNextDue(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    int? best;
    for (final state in states.values) {
      final due = state.dueDate;
      if (due == null) continue;
      final days = math.max(0, due.difference(day).inDays);
      if (best == null || days < best) best = days;
    }
    return best;
  }

  ReviewSchedule withReview(
    FinanceConcept concept,
    double grade, {
    required DateTime on,
  }) {
    final next = Map<FinanceConcept, ReviewState>.from(states);
    next[concept] = stateFor(concept).review(grade, on: on);
    return ReviewSchedule(next);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    for (final entry in states.entries)
      if (!entry.value.isNew) entry.key.name: entry.value.toMap(),
  };

  static ReviewSchedule fromMap(Map<String, dynamic> map) {
    final states = <FinanceConcept, ReviewState>{};
    for (final concept in FinanceConcept.values) {
      final raw = map[concept.name];
      states[concept] = raw is Map
          ? ReviewState.fromMap(concept, Map<String, dynamic>.from(raw))
          : ReviewState(concept: concept);
    }
    return ReviewSchedule(states);
  }
}
