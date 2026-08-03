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
  under13('under_13', '12 or under'),
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
    AgeBand.under13 || AgeBand.teen13to15 => LifeStage.allowance,
    AgeBand.teen16to17 => LifeStage.firstJob,
    AgeBand.adult18plus => LifeStage.independent,
    AgeBand.undisclosed => LifeStage.firstJob,
  };

  /// Under-13 accounts get the conservative default: no leaderboard presence.
  bool get isMinorUnder13 => this == AgeBand.under13;

  /// A single representative number for this bucket, used only where a plain
  /// integer is needed (e.g. mirroring into a numeric database column) — the
  /// app's own logic should keep using the bucket, not this.
  int get representativeAge => switch (this) {
    AgeBand.under13 => 12,
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
