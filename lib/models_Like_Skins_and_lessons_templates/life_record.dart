import 'package:flutter/foundation.dart';

import 'life_debrief.dart';
import 'life_ending.dart';

/// One finished life, kept after the epilogue closes.
///
/// **Why this exists.** Finishing a life used to record exactly one thing:
/// the ending's id, added to a set of "endings discovered". Everything else
/// — who you were, how long you lived, what you were worth at the end, how
/// many money ideas you'd met — was shown once on the epilogue and then
/// thrown away. So the main game had no memory: your tenth life looked
/// identical to your first from the outside, and there was nothing to beat.
///
/// A record is deliberately small. It is stored inside the `spendingHabits`
/// JSON blob alongside everything else, which is a column not a table, so
/// this holds the handful of fields a history list and a personal best
/// actually need rather than a full replay of the run.
@immutable
class LifeRecord {
  const LifeRecord({
    required this.endingId,
    required this.name,
    required this.age,
    required this.netWorth,
    required this.happiness,
    required this.died,
    required this.conceptsMet,
    required this.goldEarned,
    required this.finishedAt,
    this.graded = true,
    this.detail,
    this.facts,
  });

  /// What this life was made of: school, work, what was owned and who was there.
  ///
  /// **Why it is separate from the fields above.** Those five were enough for a
  /// history list. They said how a life ended and nothing about how it was lived,
  /// so the Coach could see that net worth went up and not that it went up
  /// because of a degree, or down because of a loan. Null for a record from
  /// before this existed, and the Coach reads only records that have it, so an
  /// old life is not counted as "had no degree".
  final LifeDetail? detail;

  /// What the debrief was graded on, kept so tapping this life in Past Lives can
  /// grade it again and show the same diagnostic the epilogue showed.
  ///
  /// Only the newest few records keep it (see [LifeRecordBook.keepFactsFor]),
  /// because it is a few kilobytes each and this lives in a blob that is
  /// rewritten on nearly every action. An older record keeps [detail], which is
  /// tiny, and loses the full story.
  final LifeRunFacts? facts;

  LifeRecord withoutFacts() => LifeRecord(
    endingId: endingId,
    name: name,
    age: age,
    netWorth: netWorth,
    happiness: happiness,
    died: died,
    conceptsMet: conceptsMet,
    goldEarned: goldEarned,
    finishedAt: finishedAt,
    graded: graded,
    detail: detail,
  );

  /// Whether this run counts toward the coach's reading of the player.
  ///
  /// **Why a run can opt out.** Players deliberately wreck a life to reach an
  /// unusual ending, or blitz one for quick gold. The coach reads
  /// `pastLifeNetWorths` and concluded from those that somebody was getting
  /// *worse* with money — which is a false reading of a deliberate choice,
  /// and exactly the sort of thing that makes a player stop trusting it.
  ///
  /// Ungraded runs still pay out, still unlock endings, and still appear in
  /// Past Lives. They are simply excluded from the history the analyzer
  /// reasons over. See `money_snapshot_source.dart`.
  ///
  /// **Defaults to true, and old records parse as true.** Every life recorded
  /// before this existed was played normally, so treating a missing key as
  /// "graded" preserves them exactly.
  final bool graded;

  factory LifeRecord.fromSummary(
    LifeSummary summary, {
    DateTime? finishedAt,
    bool graded = true,
  }) {
    return LifeRecord(
      endingId: summary.archetype.name,
      name: summary.name,
      age: summary.age,
      netWorth: summary.netWorth,
      happiness: summary.happiness,
      died: summary.died,
      conceptsMet: summary.conceptsMet,
      goldEarned: summary.goldReward,
      finishedAt: finishedAt ?? DateTime.now().toUtc(),
      graded: graded,
      detail: summary.facts == null
          ? null
          : LifeDetail.fromFacts(summary.facts!),
      facts: summary.facts,
    );
  }

  /// Rebuilds a record from persisted JSON.
  ///
  /// Every field is coerced rather than cast: this round-trips through a
  /// remote JSON column, so a number can come back as an int, a double or a
  /// string depending on what touched it in between, and one bad row must
  /// not take out the whole history list.
  factory LifeRecord.fromJson(Map<dynamic, dynamic> json) {
    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse('$value') ?? 0;
    }

    return LifeRecord(
      endingId: '${json['ending'] ?? ''}'.trim(),
      name: '${json['name'] ?? ''}'.trim(),
      age: asInt(json['age']),
      netWorth: asInt(json['net_worth']),
      happiness: asInt(json['happiness']),
      died: json['died'] == true,
      conceptsMet: asInt(json['concepts']),
      goldEarned: asInt(json['gold']),
      finishedAt:
          DateTime.tryParse('${json['at']}')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      // A missing key reads as graded. Every life recorded before this
      // existed was played normally, so the absent case has to mean "counts"
      // or the split would silently erase the coach's entire history.
      graded: json['graded'] != false,
      detail: json['detail'] is Map
          ? LifeDetail.fromJson(json['detail'] as Map)
          : null,
      facts: json['facts'] is Map
          ? LifeRunFacts.fromJson(json['facts'] as Map)
          : null,
    );
  }

  final String endingId;
  final String name;
  final int age;
  final int netWorth;
  final int happiness;

  /// Whether the life ended by death rather than by retiring on purpose.
  final bool died;

  /// How many distinct [FinanceConcept]s this life ran into — the one
  /// number here that measures learning rather than performance.
  final int conceptsMet;

  final int goldEarned;
  final DateTime finishedAt;

  /// The archetype this ending id resolves to, or null if the id came from
  /// a build where that ending no longer exists. Callers render a fallback
  /// rather than crashing on an old save.
  LifeEndingArchetype? get archetype {
    for (final value in LifeEndingArchetype.values) {
      if (value.name == endingId) return value;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ending': endingId,
    'name': name,
    'age': age,
    'net_worth': netWorth,
    'happiness': happiness,
    'died': died,
    'concepts': conceptsMet,
    'gold': goldEarned,
    'at': finishedAt.toUtc().toIso8601String(),
    'graded': graded,
    if (detail != null) 'detail': detail!.toJson(),
    if (facts != null) 'facts': facts!.toJson(),
  };
}

/// The handful of numbers that say how a life was lived.
///
/// Small on purpose: a dozen ints, kept for every record up to the cap. The full
/// story lives in [LifeRecord.facts] and is kept for fewer.
@immutable
class LifeDetail {
  const LifeDetail({
    this.degrees = 0,
    this.borrowedForSchool = 0,
    this.promotions = 0,
    this.workYears = 0,
    this.assetsValue = 0,
    this.loansOwed = 0,
    this.ownedHome = false,
    this.hadPartner = false,
    this.children = 0,
    this.connection,
    this.educationRank = 0,
  });

  factory LifeDetail.fromFacts(LifeRunFacts facts) => LifeDetail(
    degrees: facts.tally.degreesEarned,
    borrowedForSchool: facts.tally.studentBorrowed,
    promotions: facts.tally.promotions,
    workYears: facts.tally.workYears,
    assetsValue: facts.assetsValue,
    loansOwed: facts.loanBalance + facts.debt,
    ownedHome: facts.ownsHome,
    hadPartner: facts.hasPartner,
    children: facts.children,
    connection: facts.connection,
    educationRank: facts.educationRank,
  );

  factory LifeDetail.fromJson(Map<dynamic, dynamic> json) {
    int at(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse('$value') ?? 0;
    }

    return LifeDetail(
      degrees: at('dg'),
      borrowedForSchool: at('sb'),
      promotions: at('pr'),
      workYears: at('wy'),
      assetsValue: at('av'),
      loansOwed: at('lo'),
      ownedHome: json['home'] == true,
      hadPartner: json['pt'] == true,
      children: at('kids'),
      connection: json['conn'] == null ? null : at('conn'),
      educationRank: at('edu'),
    );
  }

  /// Qualifications finished over the life.
  final int degrees;

  /// What was borrowed to pay for school, over the whole life.
  final int borrowedForSchool;

  /// Promotions won, and years worked.
  final int promotions;
  final int workYears;

  /// What was owned when the life ended, and what was still owed, on loans and
  /// on borrowed cash together.
  final int assetsValue;
  final int loansOwed;

  final bool ownedHome;
  final bool hadPartner;
  final int children;

  /// How close the people around the player were at the end, 0 to 100, or null
  /// when it was not measured.
  final int? connection;

  /// The highest qualification, as an index into `EducationLevel`.
  final int educationRank;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (degrees != 0) 'dg': degrees,
    if (borrowedForSchool != 0) 'sb': borrowedForSchool,
    if (promotions != 0) 'pr': promotions,
    if (workYears != 0) 'wy': workYears,
    if (assetsValue != 0) 'av': assetsValue,
    if (loansOwed != 0) 'lo': loansOwed,
    if (ownedHome) 'home': true,
    if (hadPartner) 'pt': true,
    if (children != 0) 'kids': children,
    if (connection != null) 'conn': connection,
    if (educationRank != 0) 'edu': educationRank,
  };
}

/// The full history plus the bests derived from it.
///
/// Bests are computed, never stored. Storing them would mean two sources of
/// truth that can disagree — and they *would* disagree the moment the cap
/// below trims an old record, or a save is edited by hand.
@immutable
class LifeRecordBook {
  const LifeRecordBook(this.records);

  /// How many finished lives to keep, newest first.
  ///
  /// These live in the same JSON blob as the rest of the player's stats,
  /// which is written on nearly every action — so this is capped to keep
  /// that payload small. Twenty is far more than the history list shows and
  /// still nothing next to the rest of the blob.
  static const int maxRecords = 20;

  /// How many of the newest lives keep the full story for Past Lives to reopen.
  ///
  /// A stored story is a curve, up to two dozen moments and a tally: a few
  /// kilobytes. Twenty of them would be more than the rest of the player's stats
  /// put together, in a blob that is rewritten on nearly every action. Five is
  /// enough to look back on the lives that are still fresh, and every older one
  /// still has its summary and its [LifeRecord.detail].
  static const int keepFactsFor = 5;

  final List<LifeRecord> records;

  bool get isEmpty => records.isEmpty;
  int get totalLives => records.length;

  /// Newest first, which is the order the history list wants and the order
  /// the cap trims from the wrong end of.
  List<LifeRecord> get newestFirst {
    final sorted = [...records]
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return List.unmodifiable(sorted);
  }

  LifeRecord? _bestBy(int Function(LifeRecord) score) {
    if (records.isEmpty) return null;
    return records.reduce((a, b) => score(b) > score(a) ? b : a);
  }

  LifeRecord? get richest => _bestBy((r) => r.netWorth);
  LifeRecord? get longest => _bestBy((r) => r.age);
  LifeRecord? get wisest => _bestBy((r) => r.conceptsMet);

  /// Distinct endings reached across every kept record.
  Set<String> get endingsSeen =>
      records.map((r) => r.endingId).where((id) => id.isNotEmpty).toSet();

  /// Adds a run and trims to [maxRecords], dropping the oldest.
  LifeRecordBook add(LifeRecord record) {
    final next = [record, ...newestFirst].take(maxRecords).toList();
    return LifeRecordBook(
      List.unmodifiable([
        for (var i = 0; i < next.length; i++)
          i < keepFactsFor ? next[i] : next[i].withoutFacts(),
      ]),
    );
  }

  /// Which categories [record] would top, judged against the records held
  /// here — so call this *before* adding it.
  ///
  /// Strictly greater than, so replaying an identical result doesn't
  /// re-announce a best that was already set. The first life ever is a
  /// special case: it beats nothing, and calling that three personal bests
  /// would make the label meaningless, so an empty book returns none.
  Set<LifeBest> bestsBeaten(LifeRecord record) {
    if (records.isEmpty) return const <LifeBest>{};
    return <LifeBest>{
      if (record.netWorth > (richest?.netWorth ?? 0)) LifeBest.netWorth,
      if (record.age > (longest?.age ?? 0)) LifeBest.age,
      if (record.conceptsMet > (wisest?.conceptsMet ?? 0)) LifeBest.concepts,
    };
  }

  List<Map<String, dynamic>> toJson() =>
      newestFirst.map((r) => r.toJson()).toList(growable: false);

  /// Parses a persisted list, skipping anything unreadable.
  factory LifeRecordBook.fromJson(Object? raw) {
    if (raw is! List) return const LifeRecordBook(<LifeRecord>[]);
    final parsed = <LifeRecord>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      try {
        parsed.add(LifeRecord.fromJson(entry));
      } catch (_) {
        // One malformed row must not cost the player their whole history.
        continue;
      }
    }
    return LifeRecordBook(List.unmodifiable(parsed));
  }
}

/// The three things a life can be your best at.
enum LifeBest {
  netWorth('Richest life'),
  age('Longest life'),
  concepts('Most ideas met');

  const LifeBest(this.label);

  final String label;
}
