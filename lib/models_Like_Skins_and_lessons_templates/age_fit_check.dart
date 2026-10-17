import 'player_profile.dart';

/// Whether the questions look too easy for the age group the player picked.
///
/// **Asked for as:** *"guide them how they can check and then change their
/// age if the questions are too easy, and tell them they might be on the
/// wrong age group."* The Academy picks every question by age group, and a
/// teenager who tapped "9 to 12" at sign-up, or skipped the question, gets
/// questions written for somebody younger without ever being told why they
/// feel easy.
///
/// The sign is a run of near-perfect quizzes: [kAgeFitStreak] in a row at
/// [kAgeFitScore] or better, each with at least [kAgeFitMinQuestions]
/// questions so a two-question quiz cannot set it off. Never for adults,
/// whose questions are already the hardest there are. Once answered "my age
/// is right" it stays quiet for that age group, and otherwise waits
/// [kAgeFitCooldown] before asking again.
const int kAgeFitStreak = 3;
const double kAgeFitScore = 0.9;
const int kAgeFitMinQuestions = 3;
const Duration kAgeFitCooldown = Duration(days: 14);

class AgeFitState {
  const AgeFitState({this.streak = 0, this.lastAsked, this.confirmedBand});

  /// Near-perfect quizzes in a row.
  final int streak;

  /// When the pop-up last showed.
  final DateTime? lastAsked;

  /// The age group the player said was right, by id. The pop-up stays quiet
  /// while they are still in it.
  final String? confirmedBand;

  AgeFitState copyWith({
    int? streak,
    DateTime? lastAsked,
    String? confirmedBand,
  }) => AgeFitState(
    streak: streak ?? this.streak,
    lastAsked: lastAsked ?? this.lastAsked,
    confirmedBand: confirmedBand ?? this.confirmedBand,
  );
}

/// The state after one quiz, and whether to ask now.
({AgeFitState state, bool ask}) recordQuizForAgeFit(
  AgeFitState state, {
  required int correct,
  required int total,
  required AgeBand band,
  required DateTime now,
}) {
  if (total < kAgeFitMinQuestions) return (state: state, ask: false);
  final nearPerfect = correct / total >= kAgeFitScore;
  final streak = nearPerfect ? state.streak + 1 : 0;
  var next = state.copyWith(streak: streak);
  if (!nearPerfect) {
    // copyWith cannot clear to zero through `??`; build it directly.
    next = AgeFitState(
      lastAsked: state.lastAsked,
      confirmedBand: state.confirmedBand,
    );
  }
  final ask =
      streak >= kAgeFitStreak &&
      band != AgeBand.adult18plus &&
      state.confirmedBand != band.id &&
      (state.lastAsked == null ||
          now.difference(state.lastAsked!) >= kAgeFitCooldown);
  if (ask) {
    next = AgeFitState(lastAsked: now, confirmedBand: state.confirmedBand);
  }
  return (state: next, ask: ask);
}
