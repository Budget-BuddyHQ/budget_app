/// Self-described player details collected at onboarding and editable later
/// from the profile screen.
///
/// These live inside `UserStats.spendingHabits` (a JSON column) rather than in
/// dedicated Supabase columns, so adding them needs no schema migration.
library;

import 'lesson.dart' show AgeStage, stageForAge;

/// Age bracket rather than an exact birthday: it is enough to tailor lesson
/// examples and it keeps the app from storing a date of birth for minors.
enum AgeBand {
  /// Roughly 4 to 8. Reading, not just protecting.
  ///
  /// **Why this had to be split off.** There was one `under13` bucket, and
  /// the comment on `prefersSimpleWording` said the quiet part out loud: *"the
  /// bucket spans roughly 4-12, so there is no single honest age for it"*. A
  /// four-year-old and a twelve-year-old were served identical questions, and
  /// measured with `tool/measure_question_reading_level.py` the bank actually
  /// ranges from grade -2.4 to 18.4 — the content to tell them apart was
  /// already written and nothing was routing it.
  ///
  /// Everything protective still applies to both halves. What changes is what
  /// gets *taught*.
  under9('under_9', '8 or under'),

  /// Roughly 9 to 12.
  ///
  /// Keeps the original `under_13` id on purpose. Every account created
  /// before the split is stored with that string, and this is the half of the
  /// old bucket most of them are in — so existing players land here with no
  /// migration, no lost data, and no one silently re-aged to four.
  age9to12('under_13', '9 to 12'),
  teen13to15('13_15', '13 to 15'),
  teen16to17('16_17', '16 to 17'),
  adult18plus('18_plus', '18 or older'),
  undisclosed('undisclosed', 'Rather not say');

  const AgeBand(this.id, this.label);

  final String id;
  final String label;

  static AgeBand fromId(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return AgeBand.undisclosed;
    }
    return AgeBand.values.firstWhere(
      (band) => band.id == value,
      orElse: () => AgeBand.undisclosed,
    );
  }

  /// Money situation the lessons should use for worked examples.
  ///
  /// A 13-year-old budgeting an allowance and a 19-year-old budgeting rent need
  /// the same concepts but very different numbers to take them seriously.
  LifeStage get lifeStage => switch (this) {
    AgeBand.under9 ||
    AgeBand.age9to12 ||
    AgeBand.teen13to15 => LifeStage.allowance,
    AgeBand.teen16to17 => LifeStage.firstJob,
    AgeBand.adult18plus => LifeStage.independent,
    AgeBand.undisclosed => LifeStage.firstJob,
  };

  /// Under-13 accounts get the conservative default: no leaderboard presence.
  bool get isMinorUnder13 => this == AgeBand.under9 || this == AgeBand.age9to12;

  /// Whether money explainers should use the simplest wording (see
  /// `FinanceConcept.explainerFor`).
  ///
  /// Deliberately **not** derived from [representativeAge]: that returns 12
  /// for this bucket, which would route every under-13 to the older copy
  /// and defeat the point. The bucket spans roughly 4-12, so there is no
  /// single honest age for it — the question worth answering is not "how
  /// old exactly" but "does this reader need plain wording", and for the
  /// whole under-13 bucket the answer is yes. A 12-year-old reading the
  /// simpler version loses very little; an 6-year-old reading the adult
  /// version loses everything.
  bool get prefersSimpleWording =>
      this == AgeBand.under9 || this == AgeBand.age9to12;

  /// Whether this player may be shown staked wagers.
  ///
  /// **The character's age is not the player's age.** Every gambling gate in
  /// the simulation runs off `LifeSimController.age` — the age of the person
  /// being played — which is correct for the fiction and useless as a
  /// safeguard: a four-year-old reaches an eighteen-year-old character in
  /// about ninety seconds of tapping Age, and was then offered "Gamble 100
  /// coins. A 42% chance to double it." on the same screen as the library.
  ///
  /// This gates on the account instead. `undisclosed` is treated as an adult
  /// deliberately: the sign-up question is optional and skippable, and the
  /// alternative — locking content behind answering a personal question — is
  /// how you teach children to over-share to get features.
  ///
  /// **What this does and does not cover.** It hides *wagers*: staking money
  /// on an uncertain outcome, which is the thing Play's Families policy calls
  /// simulated gambling. It deliberately does **not** hide the cautionary
  /// content — `t_loot_box` states the real odds of a 0.6% drop and
  /// `t_skin_gamble` explains a 5% house cut. Those teach a child what the
  /// mechanic looks like from the inside before somebody sells them one, and
  /// they are the most valuable events in the pack for exactly the age group
  /// this flag protects. Their outcomes are scripted, so nothing is being
  /// wagered to read them.
  bool get allowsWagering => this != AgeBand.under9 && this != AgeBand.age9to12;

  /// Whether paid games of chance are kept off this player's screen entirely.
  ///
  /// Only the youngest band. A loot box explained with its real odds is one
  /// of the most useful things a twelve-year-old can be shown, because it is
  /// the thing actually taking their money. An eight-year-old does not need
  /// to see the mechanic at all, and the events that carry it gate on the
  /// *character's* age, which a child can run up in ten taps.
  bool get hidesGamblingMechanics => this == AgeBand.under9;

  /// A single representative number for this bucket, used only where a plain
  /// integer is needed (e.g. mirroring into a numeric database column) — the
  /// app's own logic should keep using the bucket, not this.
  int get representativeAge => switch (this) {
    AgeBand.under9 => 7,
    AgeBand.age9to12 => 11,
    AgeBand.teen13to15 => 14,
    AgeBand.teen16to17 => 16,
    AgeBand.adult18plus => 19,
    AgeBand.undisclosed => 13,
  };

  /// Which Academy [AgeStage] to lead with for this band — null when the
  /// player didn't say, since there's nothing to recommend from. This never
  /// hides any other unit; see [AgeStageInfo] — it only affects default
  /// ordering and a "Recommended for you" badge.
  AgeStage? get recommendedStage =>
      this == AgeBand.undisclosed ? null : stageForAge(representativeAge);

  /// The oldest stage this band could plausibly be in — the yardstick for the
  /// Academy's "this unit is written for older readers" warning.
  ///
  /// Deliberately *not* [recommendedStage]. That one uses
  /// [representativeAge], the bottom-ish end of the bucket, which is right for
  /// deciding what to lead with but wrong for deciding whom to warn: it would
  /// tell a 25-year-old who picked "18 or older" that the 401(k) unit is above
  /// their age. Bands are ranges, and a warning should only fire when the
  /// whole range sits below the unit.
  AgeStage? get maxPlausibleStage => switch (this) {
    AgeBand.under9 => AgeStage.middleSchool,
    AgeBand.age9to12 => AgeStage.middleSchool,
    AgeBand.teen13to15 => AgeStage.highSchool,
    AgeBand.teen16to17 => AgeStage.highSchool,
    // Open-ended: this player could be any age at all, so nothing is above them.
    AgeBand.adult18plus => AgeStage.adult,
    AgeBand.undisclosed => null,
  };
}

/// Framing used for lesson examples and money amounts.
enum LifeStage {
  /// Allowance, gifts, small chores. Amounts in the tens.
  allowance('allowance'),

  /// Part-time work, first paycheck, saving for something big. Hundreds.
  firstJob('first_job'),

  /// Rent, bills, full paychecks, longer horizons. Thousands.
  independent('independent');

  const LifeStage(this.id);

  final String id;

  /// Multiplier applied to the baseline (first-job) figures in lesson examples,
  /// so the same lesson text can quote numbers that feel real to the reader.
  double get exampleScale => switch (this) {
    LifeStage.allowance => 0.2,
    LifeStage.firstJob => 1.0,
    LifeStage.independent => 4.0,
  };

  String get incomeNoun => switch (this) {
    LifeStage.allowance => 'allowance',
    LifeStage.firstJob => 'paycheck',
    LifeStage.independent => 'paycheck',
  };
}

/// Self-described gender. Used to pick which avatars are *featured* first and
/// to let players see themselves in the app — it never gates content, skins, or
/// rewards, and every skin stays available to every player.
enum GenderIdentity {
  female('female', 'Female'),
  male('male', 'Male'),
  nonBinary('non_binary', 'Non-binary'),
  undisclosed('undisclosed', 'Rather not say');

  const GenderIdentity(this.id, this.label);

  final String id;
  final String label;

  static GenderIdentity fromId(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return GenderIdentity.undisclosed;
    }
    return GenderIdentity.values.firstWhere(
      (gender) => gender.id == value,
      orElse: () => GenderIdentity.undisclosed,
    );
  }
}

/// Keys used inside the `spending_habits` JSON blob.
class ProfileKeys {
  ProfileKeys._();

  static const String ageBand = 'age_band';
  static const String gender = 'gender';

  /// Explicit avatar body choice. Absent means "follow [gender]".
  static const String villagerBody = 'villager_body';
  static const String displayPronoun = 'display_pronoun';
  static const String onboardingComplete = 'personal_details_complete';
}

/// Which questions a band should actually be asked.
///
/// **The feature this whole split exists for.** One bank of 177 questions
/// measured at Flesch-Kincaid grades -2.4 to 18.4 was being served
/// identically to every player, so a six-year-old met "Diversification
/// reduces risk by:" (grade 18.4) and an adult met "You do the dishes every
/// day and get \$1 each time" (grade 1.2). Both are good questions. Neither
/// was reaching the person it was written for.
///
/// The window is generous at the top on purpose. A reader is stretched by
/// material a little above them and stopped by material far above, so each
/// band gets everything it can comfortably read plus roughly two grades of
/// reach. The floor matters more than the ceiling: nothing is more
/// discouraging than being handed something years below you, and nothing is
/// less useful than being handed something years above.
extension AgeBandReading on AgeBand {
  /// Highest reading grade to serve this band.
  ///
  /// A **trim, not the main filter.** Since `AgeBandStage.maxQuizStage`
  /// started deciding what a band is asked *about*, this only has to catch
  /// sentences that are long for the reader — and it was doing far more than
  /// that. At 3.5 it cut the under-9 pool from its own 28 questions to 17,
  /// throwing away material written for four-to-eight-year-olds because the
  /// sentence ran long. Raised to 5.0, which keeps 26 and still trims the two
  /// genuinely wordy ones.
  double get maxReadingGrade => switch (this) {
    AgeBand.under9 => 5.0,
    AgeBand.age9to12 => 6.5,
    AgeBand.teen13to15 => 9.5,
    AgeBand.teen16to17 => 12.0,
    AgeBand.adult18plus => 99.0,
    // Somebody who declined to say gets the middle of the range rather than
    // the easiest or the hardest. Guessing young is patronising; guessing
    // old locks them out.
    AgeBand.undisclosed => 9.5,
  };

  /// Lowest reading grade to serve.
  ///
  /// **Retired, and deliberately left at no floor.** This used to keep older
  /// readers away from years-below material, and measuring it showed the
  /// instrument was wrong for the job:
  ///
  ///  * The adult floor of 6.0 withheld **109 of 186 questions**. Adults were
  ///    served 77 — fifty-nine per cent of the bank unreachable by the one
  ///    band that should see all of it.
  ///  * The 9-to-12 floor of 1.0 withheld the **sixteen easiest questions in
  ///    the app** from exactly the child in the report: a ten-year-old who
  ///    was struggling and could not be handed anything easier, because a
  ///    syllable count had decided it was beneath him.
  ///
  /// A reading grade is a property of the sentence, not of the reader, so
  /// using it as a floor punishes plain writing. *"What is money used for?"*
  /// scores 0.5 and is a fine question for anybody who has not thought about
  /// it.
  ///
  /// The job moved to `AgeBandStage.minQuizStage`, which says the same thing
  /// in the curriculum's own terms — a unit's hand-assigned audience — and
  /// fails in the kind direction. The getter stays so the ceiling and the
  /// floor read as a pair and so nothing that reads it breaks.
  double get minReadingGrade => -99.0;

  /// Whether to withhold questions naming adult financial instruments.
  ///
  /// A separate switch from [maxReadingGrade] because the two catch different
  /// things. Reading grade measures sentence and word length, so a short
  /// question about a complicated instrument scores as easy — "What is a CD
  /// Ladder?" is four words and grade 2.9. It was served to an eight-year-old
  /// for exactly that reason.
  ///
  /// On for everyone below 13. A thirteen-year-old meeting the word "mortgage"
  /// is fine and probably overdue; an eight-year-old meeting "liquidity" is
  /// being asked a question from someone else's life.
  bool get blocksAdultTopics =>
      this == AgeBand.under9 || this == AgeBand.age9to12;

  /// What to tell the player about why the questions changed.
  String get readingBlurb => switch (this) {
    AgeBand.under9 => 'Short questions with small numbers.',
    AgeBand.age9to12 => 'Everyday money, in plain words.',
    AgeBand.teen13to15 => 'First jobs, saving and what things really cost.',
    AgeBand.teen16to17 => 'Pay slips, credit and longer-term choices.',
    AgeBand.adult18plus => 'The full set, including tax and investing.',
    AgeBand.undisclosed => 'A general mix. Set your age to sharpen it.',
  };
}
