import 'leak_patrol_models.dart';
import 'player_profile.dart';
import 'quiz_bank.dart';
import 'reading_grade.dart';

/// What the app actually changes for a player's age, stated as facts.
///
/// # Why this exists
///
/// Reported twice, in the same words: *"I'm still not seeing the age
/// separated for the app."* And that was fair. By then the age band was
/// deciding:
///
///  * which of the 187 quiz questions a player is served, by measured reading
///    grade (`ageAppropriateQuestions`),
///  * whether questions naming mortgages, IRAs or APR are held back at all
///    (`kAdultOnlyTopics` — the gap a reading score cannot close, because
///    "What is a CD Ladder?" is four words and grade 2.9),
///  * whether the life sim will offer them a wager,
///  * whether the life sim and Market Board speak in plain words,
///  * how fast Leak Patrol runs.
///
/// Five systems, and the player was told about it in one sentence at sign-up
/// that they saw once. **Age scaling nobody can see is indistinguishable from
/// age scaling that does not exist** — and it is one of the strongest things
/// in this app.
///
/// # Why facts rather than a paragraph
///
/// A paragraph saying "content is tailored to your age" is a marketing claim.
/// A line saying *"142 of 187 questions fit your reading level"* is checkable,
/// and the number is computed from the bank at runtime rather than typed in,
/// so it cannot quietly become a lie when questions are added.
///
/// # Why the model is separate from the card
///
/// So the claims can be tested. Every line here asserts something about the
/// app's real behaviour; a test that the under-9 band reports fewer questions
/// than the adult band is a test of the routing, not of the copy.
class AgeScalingFact {
  const AgeScalingFact({
    required this.icon,
    required this.title,
    required this.detail,
  });

  /// Which icon the card should use. An enum rather than an `IconData` so
  /// this file stays free of Flutter and can be tested as plain Dart.
  final AgeScalingIcon icon;

  final String title;

  /// One line, in the player's own terms. Never says "content is filtered".
  final String detail;
}

// There used to be a `rewards` fact here, telling under-13s the skin case
// was closed to them. The team removed that gate (the case is open to every
// age, with its odds shown before any gold is spent), and a card that
// promises a restriction the app does not apply is worse than no card.
enum AgeScalingIcon { reading, topics, wager, wording, speed }

/// The facts for [band], in the order they matter to the player.
List<AgeScalingFact> ageScalingFacts(AgeBand band) {
  final total = allQuizQuestions.length;
  final mine = questionsPerBand[band] ?? total;
  final round = LeakRound.forBand(band);
  final leakSeconds = (round.visibleMillis / 1000).toStringAsFixed(1);

  return <AgeScalingFact>[
    AgeScalingFact(
      icon: AgeScalingIcon.reading,
      title: 'Questions you get',
      detail: band == AgeBand.undisclosed
          // Says what to do about it, since this is the one band where the
          // app is guessing rather than knowing.
          ? '$mine of $total questions, a general mix. Set your age below to '
                'sharpen it.'
          : '$mine of $total questions fit your reading level. '
                '${band.readingBlurb}',
    ),
    AgeScalingFact(
      icon: AgeScalingIcon.topics,
      title: 'Grown-up money words',
      detail: band.blocksAdultTopics
          ? '${kAdultOnlyTopics.length} topics like mortgages, IRAs and APR '
                'are held back until you are older — even when the question '
                'is short.'
          : 'Nothing is held back. Tax, credit and investing questions are '
                'all in the mix.',
    ),
    AgeScalingFact(
      icon: AgeScalingIcon.wager,
      title: 'Betting in the life game',
      detail: band.allowsWagering
          ? 'Wagers can appear, and the lessons about them are honest about '
                'the odds.'
          : 'You are never offered a bet. The events that explain how betting '
                'works still show up — reading about it costs nothing.',
    ),
    AgeScalingFact(
      icon: AgeScalingIcon.wording,
      title: 'How things are worded',
      detail: band.prefersSimpleWording
          ? 'The life game and the Market Board use everyday words — "What '
                'you own" instead of "Assets".'
          : 'Full wording, including the terms you will meet on a real pay '
                'slip or brokerage.',
    ),
    AgeScalingFact(
      icon: AgeScalingIcon.speed,
      title: 'Leak Patrol speed',
      detail:
          'Leaks stay up for $leakSeconds seconds across ${round.holes} '
          'holes, for ${round.seconds} seconds a round.',
    ),
  ];
}
