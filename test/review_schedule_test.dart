import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/review_schedule.dart';

/// The spaced-repetition scheduler.
///
/// This is the one piece of the app where being *slightly* wrong is invisible
/// and expensive: a scheduler that drifts does not crash, it just quietly
/// stops asking about the thing you were forgetting, or asks about it every
/// day until the app gets deleted. Neither shows up on any screen. So the
/// properties are pinned rather than the outputs — an interval of 6 versus 7
/// does not matter, and "hard things come back sooner than easy ones" does.
void main() {
  final monday = DateTime(2026, 3, 2);

  ReviewState fresh([FinanceConcept c = FinanceConcept.compoundGrowth]) =>
      ReviewState(concept: c);

  group('a single concept', () {
    test('something never studied is new, not overdue', () {
      // These are different queues on purpose. Treating unstudied concepts as
      // due would bury the three a player is actually forgetting under
      // thirteen they have never met.
      final state = fresh();
      expect(state.isNew, isTrue);
      expect(state.isDueOn(monday), isFalse);
      expect(state.dueDate, isNull);
    });

    test('the first two intervals are fixed at 1 then 6 days', () {
      var state = fresh().review(0.9, on: monday);
      expect(state.intervalDays, 1);

      state = state.review(0.9, on: monday.add(const Duration(days: 1)));
      expect(state.intervalDays, 6);
    });

    test('intervals grow after that, and the ease factor drives how fast', () {
      var strong = fresh();
      var weak = fresh();
      var day = monday;

      // Same number of reviews, different accuracy each time.
      for (var i = 0; i < 5; i++) {
        strong = strong.review(1.0, on: day);
        weak = weak.review(0.65, on: day);
        day = day.add(const Duration(days: 1));
      }

      expect(
        strong.intervalDays,
        greaterThan(weak.intervalDays),
        reason:
            'a concept somebody answers perfectly should get out of their '
            'way faster than one they scrape through',
      );
      expect(strong.easeFactor, greaterThan(weak.easeFactor));
    });

    test('a failure resets the streak and asks again tomorrow', () {
      var state = fresh();
      var day = monday;
      for (var i = 0; i < 4; i++) {
        state = state.review(0.95, on: day);
        day = day.add(Duration(days: state.intervalDays));
      }
      expect(state.intervalDays, greaterThan(6));

      final failed = state.review(0.2, on: day);
      expect(failed.repetitions, 0);
      expect(failed.intervalDays, 1);
    });

    test('failing does not throw away what it knows about the person', () {
      // How easily *this person* holds *this idea* is a slower-moving fact
      // than one bad answer. Resetting ease on every miss makes the schedule
      // thrash between "every day" and "in a month".
      var state = fresh();
      var day = monday;
      for (var i = 0; i < 4; i++) {
        state = state.review(1.0, on: day);
        day = day.add(Duration(days: state.intervalDays));
      }
      final before = state.easeFactor;
      final after = state.review(0.1, on: day).easeFactor;

      expect(after, lessThan(before));
      expect(
        after,
        greaterThan(before - 0.5),
        reason: 'one miss should nudge the ease factor, not reset it',
      );
    });

    test('repeated failure cannot drive the schedule into a punishment loop', () {
      var state = fresh();
      var day = monday;
      for (var i = 0; i < 30; i++) {
        state = state.review(0.0, on: day);
        day = day.add(const Duration(days: 1));
      }
      // The floor is the whole point. Without it the ease factor heads for
      // zero and the concept is scheduled every day forever, which for a
      // nine-year-old is how an app gets deleted.
      expect(state.easeFactor, ReviewState.minimumEase);
      expect(state.intervalDays, 1);
    });

    test('intervals are capped so nothing disappears for years', () {
      var state = fresh();
      var day = monday;
      for (var i = 0; i < 25; i++) {
        state = state.review(1.0, on: day);
        day = day.add(Duration(days: state.intervalDays));
      }
      expect(state.intervalDays, lessThanOrEqualTo(
        ReviewState.maximumIntervalDays,
      ));
    });

    test('due lands exactly on the interval, not before', () {
      final state = fresh().review(0.9, on: monday);
      expect(state.isDueOn(monday), isFalse);
      expect(state.isDueOn(monday.add(const Duration(days: 1))), isTrue);
      expect(state.isDueOn(monday.add(const Duration(days: 9))), isTrue);
    });
  });

  group('the schedule', () {
    test('an empty schedule has everything new and nothing due', () {
      final schedule = ReviewSchedule.empty();
      expect(schedule.unseen, hasLength(FinanceConcept.values.length));
      expect(schedule.dueOn(monday), isEmpty);
      expect(schedule.daysUntilNextDue(monday), isNull);
    });

    test('the most overdue concept comes first, not the earliest scheduled', () {
      var schedule = ReviewSchedule.empty()
          .withReview(FinanceConcept.taxes, 0.9, on: monday)
          .withReview(
            FinanceConcept.inflation,
            0.9,
            on: monday.subtract(const Duration(days: 20)),
          );

      final due = schedule.dueOn(monday.add(const Duration(days: 2)));
      expect(due.first.concept, FinanceConcept.inflation,
          reason: 'being late is the signal, not the calendar order');
    });

    test('review beats discovery when both are waiting', () {
      final schedule = ReviewSchedule.empty()
          .withReview(FinanceConcept.taxes, 0.9, on: monday);

      final next = schedule.nextUp(monday.add(const Duration(days: 3)));
      expect(next!.concept, FinanceConcept.taxes);
      expect(next.isNew, isFalse);
    });

    test('with nothing due it offers something unseen', () {
      final schedule = ReviewSchedule.empty()
          .withReview(FinanceConcept.taxes, 0.9, on: monday);

      // Same day: taxes is not due until tomorrow.
      final next = schedule.nextUp(monday);
      expect(next, isNotNull);
      expect(next!.isNew, isTrue);
      expect(next.concept, isNot(FinanceConcept.taxes));
    });

    test('a fully studied, fully current schedule offers nothing', () {
      var schedule = ReviewSchedule.empty();
      for (final concept in FinanceConcept.values) {
        schedule = schedule.withReview(concept, 1.0, on: monday);
      }
      // Nothing new left, nothing due yet. Offering filler here would be the
      // app inventing work to look busy.
      expect(schedule.nextUp(monday), isNull);
      expect(schedule.daysUntilNextDue(monday), 1);
    });
  });

  group('it survives a round trip through storage', () {
    test('a studied schedule reads back identically', () {
      final schedule = ReviewSchedule.empty()
          .withReview(FinanceConcept.compoundGrowth, 0.95, on: monday)
          .withReview(FinanceConcept.creditScore, 0.4, on: monday);

      final restored = ReviewSchedule.fromMap(schedule.toMap());

      for (final concept in FinanceConcept.values) {
        final a = schedule.stateFor(concept);
        final b = restored.stateFor(concept);
        expect(b.repetitions, a.repetitions);
        expect(b.intervalDays, a.intervalDays);
        expect(b.easeFactor, closeTo(a.easeFactor, 0.0001));
        expect(b.lastReviewed, a.lastReviewed);
      }
    });

    test('only studied concepts are written', () {
      // Sixteen concepts of default state is pure noise in a jsonb column,
      // and it would grow every time a concept is added.
      final schedule = ReviewSchedule.empty()
          .withReview(FinanceConcept.taxes, 0.9, on: monday);
      expect(schedule.toMap().keys, ['taxes']);
    });

    test('rubbish in storage reads as unstudied rather than throwing', () {
      final restored = ReviewSchedule.fromMap(<String, dynamic>{
        'taxes': 'not a map',
        'notAConcept': {'r': 3},
        'inflation': {'r': 'three', 'l': 'never'},
      });

      expect(restored.stateFor(FinanceConcept.taxes).isNew, isTrue);
      expect(restored.stateFor(FinanceConcept.inflation).repetitions, 0);
      expect(restored.stateFor(FinanceConcept.inflation).lastReviewed, isNull);
    });
  });
}
