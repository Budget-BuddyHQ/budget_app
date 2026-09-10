/// Which age a question was written for, taken from the unit it belongs to.
///
/// # The report
///
/// Two of them, and they turned out to be the same bug:
///
/// > *"make sure that no 4 year old or someone will get the wrong questions"*
///
/// > *"the questions are a bit shift because my little brother of 10 year of
/// > age is struggling with questions that are 8 and below"*
///
/// The second is the precise one. He was being served the **under-9 set** and
/// finding it too hard — which means the set was mislabelled, not that he was
/// behind. Dumping what that band actually got showed why:
///
/// > *"A 401(k) is best described as:"* — reading grade 2.3
/// > *"Which best describes a bond?"* — 2.9
/// > *"Which form tells your employer how much tax to withhold?"* — 2.5
/// > *"Gross pay and net pay differ because of:"* — 2.3
///
/// Fifty questions in the four-to-eight window, and those were in it.
///
/// # Why reading grade could never have caught this
///
/// Flesch-Kincaid counts syllables per word and words per sentence. That is
/// all it counts. *"Which best describes a bond?"* is five short words, so it
/// scores as easier than *"You want to buy a big toy. How do you save up?"*
///
/// The measurement is not wrong; it is answering a different question. It
/// tells you whether a child can **decode** the sentence, not whether they
/// have ever met the thing it is about.
///
/// # Why the unit is the right answer
///
/// The Academy's units already carry an `ageStage`, hand-assigned by whoever
/// wrote them: unit 10 is "Money Is Real" at `earlyChildhood`, unit 9 is
/// "Retirement and the 401(k)" at `adult`. That is a human judgement about
/// who a question is *for*, which is exactly what was missing — and it was
/// sitting in the repo the whole time, used to order the Academy screen and
/// nothing else.
///
/// `ageAppropriateQuestions` even said so in its own doc comment: *"the unit
/// a question belongs to is the other input, and the Academy already gates
/// units by age"*. It was a description of intent, not of code.
///
/// # The rule
///
/// **You may read above your age. You are not tested above it.**
///
/// The Academy already warns when somebody opens a unit written for older
/// readers (`isAboveReadingAge`) and lets them read it anyway, which is
/// right — curiosity should not be blocked. Being *quizzed* on it is
/// different: a quiz says "you should know this", and telling a six-year-old
/// they got vesting wrong teaches them they are bad at money.
///
/// So a young reader on an old unit gets the lesson and no quiz.
/// `lesson_detail_screen.dart` already renders that state.
library;

import 'lesson.dart';
import 'lesson_data.dart';
import 'player_profile.dart';
import 'quiz_bank.dart';

/// Question id to the stage of the unit that owns it.
///
/// Built by walking the units rather than by parsing ids. The ids *look*
/// parseable — `u10p1` is unit 10, `u1q3` is unit 1 — but `u1`, `u10`, `u11`,
/// `u12` and `u13` all share a prefix, and a prefix match would file every
/// unit-1 question under unit 13 or the reverse depending on iteration order.
/// Walking the real structure cannot get that wrong.
final Map<String, AgeStage> kQuestionStage = _buildQuestionStages();

Map<String, AgeStage> _buildQuestionStages() {
  final out = <String, AgeStage>{};
  for (final unit in lessonUnits) {
    for (final lesson in unit.lessons) {
      for (final question in quizFor(lesson.id)) {
        out[question.id] = unit.ageStage;
      }
    }
    for (final question in practiceFor(unit.id)) {
      out[question.id] = unit.ageStage;
    }
  }
  return out;
}

extension AgeBandStage on AgeBand {
  /// The oldest unit this band may be **quizzed** on.
  ///
  /// Note the bands and the stages do not line up one to one, because they
  /// were written for different jobs — the bands are a sign-up question, the
  /// stages are a curriculum. Where they straddle, this takes the stage whose
  /// range the band's *oldest* member sits in, so nobody is held back from
  /// material they are ready for.
  AgeStage get maxQuizStage => switch (this) {
    // 4-8. earlyChildhood is 4-6, youngKids is 7-10.
    AgeBand.under9 => AgeStage.youngKids,
    // 9-12. middleSchool is 11-13.
    AgeBand.age9to12 => AgeStage.middleSchool,
    AgeBand.teen13to15 => AgeStage.highSchool,
    AgeBand.teen16to17 => AgeStage.graduating,
    AgeBand.adult18plus => AgeStage.adult,
    // Same reasoning as `maxReadingGrade`: the middle of the range rather
    // than the easiest or the hardest. Guessing young is patronising;
    // guessing old is the bug this file exists to fix.
    AgeBand.undisclosed => AgeStage.highSchool,
  };

  /// The youngest unit this band is quizzed on.
  ///
  /// # What this replaced, and why it had to
  ///
  /// There used to be an [AgeBandReading.minReadingGrade] floor doing this
  /// job — "so nobody is fed years-below material". The intent was right and
  /// the instrument was wrong, and measuring it showed how wrong:
  ///
  ///  * The adult floor of grade 6.0 withheld **109 of 186 questions**. An
  ///    adult was served 77. Fifty-nine per cent of the bank was unreachable
  ///    by the band that should see all of it.
  ///  * The 9-to-12 floor of grade 1.0 withheld the **sixteen easiest
  ///    questions in the app** from exactly the child in the report — a
  ///    ten-year-old who was struggling. He could not be given the easy ones
  ///    because a syllable count had decided they were beneath him.
  ///
  /// A reading grade is a property of the sentence, not of the reader. Using
  /// it as a floor punishes plain writing: *"What is money used for?"* scores
  /// 0.5 and is a perfectly good question for anybody who has not thought
  /// about it.
  ///
  /// A stage floor says the same thing in the units' own terms, and it fails
  /// in the kind direction — a struggling reader can always reach easier
  /// material, because the floor sits a stage or two below the band rather
  /// than at its feet.
  AgeStage get minQuizStage => switch (this) {
    // No floor at all for the youngest two. A child who is finding it hard
    // must always be able to get something easier; that is the whole report.
    AgeBand.under9 => AgeStage.earlyChildhood,
    AgeBand.age9to12 => AgeStage.earlyChildhood,
    AgeBand.teen13to15 => AgeStage.youngKids,
    AgeBand.teen16to17 => AgeStage.middleSchool,
    AgeBand.adult18plus => AgeStage.middleSchool,
    AgeBand.undisclosed => AgeStage.youngKids,
  };
}

/// Whether [questionId] was written for a reader in [band] or younger.
///
/// A question with no stage — one that belongs to no unit — is **kept**. The
/// map is derived from the units, so a missing entry means content was added
/// outside the curriculum, and silently withholding it from everybody is a
/// worse failure than showing it. The topic floor in
/// `ageAppropriateQuestions` still applies to it.
bool questionFitsStage(String questionId, AgeBand band) {
  final stage = kQuestionStage[questionId];
  if (stage == null) return true;
  return stage.index <= band.maxQuizStage.index &&
      stage.index >= band.minQuizStage.index;
}
