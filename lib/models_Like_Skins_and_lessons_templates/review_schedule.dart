import 'dart:math' as math;

import 'finance_concepts.dart';

/// Spaced repetition for the sixteen money ideas.
///
/// **The problem this solves.** The Academy records that you scored 90% on
/// compound growth in March and then never mentions it again. That is a
/// *record* of learning, not a system for it: the best-established finding in
/// memory research is that recall decays on a curve, and that the way to beat
/// the curve is to be tested again right before you would have forgotten.
/// Without that, a quiz score is a photograph of one afternoon.
///
/// **The algorithm.** A simplified SM-2 — the scheduler behind Anki and, in
/// modified form, most serious learning software. Each concept carries an
/// *ease factor* (how well it sticks for this particular person) and an
/// *interval* (how many days until it should be seen again). Answer well and
/// both go up, so the concept gets out of your way. Answer badly and the
/// interval collapses to a day, because a thing you just got wrong is not
/// something to leave alone for a fortnight.
///
/// **What is deliberately different from textbook SM-2.**
///
/// * **A floor on the ease factor at 1.3.** Without it, a run of bad answers
///   drives ease toward zero and the concept is scheduled every single day
///   forever — a punishment loop, which for a nine-year-old is how an app
///   gets deleted. 1.3 is SM-2's own floor and it exists for the same reason.
/// * **A ceiling on the interval at 180 days.** Real SM-2 lets intervals run
///   to years, which is right for a language learner and wrong here: nobody
///   uses one app for three years, and a concept that never comes back is
///   indistinguishable from one that was dropped.
/// * **The first two intervals are fixed** (1 day, then 6). SM-2 does this
///   too, and it matters more here because our grades are coarse — a quiz
///   score, not a five-point self-report.
///
/// **Why it runs on-device with no service.** Every input is already stored:
/// accuracy per concept, and when it was last assessed. There is no model to
/// download, no API to call, nothing leaves the phone, and it works offline
/// on a school bus. That is not a compromise — for this problem it is simply
/// the correct engineering.
class ReviewState {
  const ReviewState({
    required this.concept,
    this.repetitions = 0,
    this.easeFactor = defaultEase,
    this.intervalDays = 0,
    this.lastReviewed,
  });

  /// SM-2's starting ease. Everything is calibrated against this.
  static const double defaultEase = 2.5;

  /// The floor. See the class comment — below this the schedule becomes a
  /// punishment loop rather than a study plan.
  static const double minimumEase = 1.3;

  /// Roughly six months. Long enough to be out of the way, short enough that
  /// a concept always comes back.
  static const int maximumIntervalDays = 180;

  /// The score at or above which an answer counts as "you knew that".
  ///
  /// 0.6 rather than a pass mark. This decides whether to *stop asking*, and
  /// being asked again about something you half-know is the entire point of
  /// the system — so the bar for getting left alone is deliberately higher
  /// than the bar for being told you passed.
  static const double passingGrade = 0.6;

  final FinanceConcept concept;

  /// Consecutive successful reviews. Reset to zero by any failure.
  final int repetitions;

  final double easeFactor;
  final int intervalDays;
  final DateTime? lastReviewed;

  /// When this concept should next be shown, or null if never studied.
  DateTime? get dueDate => lastReviewed == null
      ? null
      : DateTime(
          lastReviewed!.year,
          lastReviewed!.month,
          lastReviewed!.day + intervalDays,
        );

  /// True when it is time to see this again.
  ///
  /// A concept that has never been studied is **not** due. It is *new*, which
  /// is a different queue — mixing them would bury the three things a player
  /// is forgetting under thirteen they have never met.
  bool isDueOn(DateTime today) {
    final due = dueDate;
    if (due == null) return false;
    final day = DateTime(today.year, today.month, today.day);
    return !day.isBefore(due);
  }

  bool get isNew => lastReviewed == null;

  /// Applies a graded review and returns the new state.
  ///
  /// [grade] is 0..1 — a quiz accuracy, not a self-report.
  ReviewState review(double grade, {required DateTime on}) {
    final passed = grade >= passingGrade;

    // A failure resets the streak and brings it back tomorrow. It does not
    // reset the ease factor, on purpose: how easily *this person* holds
    // *this idea* is a slower-moving fact than one bad answer, and throwing
    // it away would make the schedule thrash.
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

    // SM-2's ease update, driven by how well rather than merely whether.
    // Rescaled from its 0..5 self-rating to our 0..1 accuracy.
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

  /// Reads a number out of stored JSON without trusting its type.
  ///
  /// `as num?` throws on a String, and this map comes back from a `jsonb`
  /// column — so its contents are whatever any version of this app, or a hand
  /// edit in the Supabase table editor, has ever put there. A schedule that
  /// throws while parsing takes the whole Coach screen down with it, and the
  /// correct reading of an unparseable value is "we do not know when this was
  /// last reviewed", which is exactly the same as never having reviewed it.
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

/// The whole schedule: one [ReviewState] per concept.
class ReviewSchedule {
  const ReviewSchedule(this.states);

  final Map<FinanceConcept, ReviewState> states;

  /// A schedule with nothing studied yet.
  factory ReviewSchedule.empty() => ReviewSchedule(<FinanceConcept, ReviewState>{
    for (final c in FinanceConcept.values) c: ReviewState(concept: c),
  });

  ReviewState stateFor(FinanceConcept concept) =>
      states[concept] ?? ReviewState(concept: concept);

  /// Concepts that need seeing again, worst first.
  ///
  /// Ordered by how *overdue* they are rather than by due date, so a concept
  /// three weeks past its slot outranks one due this morning even if the
  /// second was scheduled first. Being late is the signal, not the calendar.
  List<ReviewState> dueOn(DateTime today) {
    final due = states.values.where((s) => s.isDueOn(today)).toList();
    due.sort((a, b) {
      final aDays = today.difference(a.dueDate!).inDays;
      final bDays = today.difference(b.dueDate!).inDays;
      if (aDays != bDays) return bDays.compareTo(aDays);
      // Tie-break on ease: the one this person finds harder comes first.
      return a.easeFactor.compareTo(b.easeFactor);
    });
    return due;
  }

  /// Concepts never studied at all.
  List<ReviewState> get unseen =>
      states.values.where((s) => s.isNew).toList();

  /// The single concept to put in front of somebody right now.
  ///
  /// Overdue work first, then something new. Reviewing beats discovering when
  /// both are available — an idea half-remembered is worth more than a
  /// sixteenth idea met once.
  ReviewState? nextUp(DateTime today) {
    final due = dueOn(today);
    if (due.isNotEmpty) return due.first;
    final fresh = unseen;
    return fresh.isEmpty ? null : fresh.first;
  }

  /// How many days until the next thing falls due, or null if nothing is
  /// scheduled. Zero means something is due today.
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
