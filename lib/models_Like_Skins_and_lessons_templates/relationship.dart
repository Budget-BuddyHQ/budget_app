import 'package:flutter/material.dart';

/// Who somebody is to you.
///
/// Kinds differ in one way that matters: how fast they drift when you stop
/// turning up. Family forgives a lot of neglect and a friend forgives less,
/// which is both true and the reason the People menu is now a decision rather
/// than a list.
enum RelationshipKind {
  family('Family', Icons.home_rounded, Color(0xFFFF8FB1), 0.6),
  friend('Friend', Icons.people_alt_rounded, Color(0xFF69C6FF), 1.0),
  partner('Partner', Icons.favorite_rounded, Color(0xFFFF6B9D), 1.3),
  mentor('Mentor', Icons.school_rounded, Color(0xFFB388FF), 1.5);

  const RelationshipKind(this.label, this.icon, this.accent, this.driftRate);

  final String label;
  final IconData icon;
  final Color accent;

  /// How quickly this kind of relationship fades without contact, as a
  /// multiplier on the base drift.
  ///
  /// A mentor drifts fastest — that connection is the one nobody maintains by
  /// accident. Family drifts slowest, because they turn up anyway.
  final double driftRate;
}

/// One person in a life, and how close you actually are.
///
/// **What this replaced.** Relationships were a `List<String>` — bare names,
/// every one identical, nothing about any of them ever changing. You could
/// press "Spend time with Priya" forty times for +8 Happiness each and it
/// meant precisely as much the fortieth time as the first.
///
/// That left the game unable to say the one thing it most needed to. There is
/// an ending called **Rich but Lonely** and nothing in the simulation could
/// make you lonely: it fired on a happiness threshold, so it was reachable by
/// working too hard and had no more to do with people than any other ending.
///
/// Closeness fixes that. It falls a little every year on its own, faster for
/// the kinds of relationship that really do need maintaining, and time spent
/// is the only thing that reliably raises it. Gifts help less than time does,
/// which is the lesson this app would want to teach even if it were not also
/// true.
@immutable
class Relationship {
  const Relationship({
    required this.name,
    required this.kind,
    required this.closeness,
    required this.metAtAge,
    this.lastSeenAge,
  });

  final String name;
  final RelationshipKind kind;

  /// 0 to 100. Starts around 60 for somebody who has just arrived.
  final int closeness;

  final int metAtAge;

  /// The age at which you last did something with them, or null if never.
  final int? lastSeenAge;

  Relationship copyWith({int? closeness, int? lastSeenAge}) => Relationship(
    name: name,
    kind: kind,
    closeness: closeness ?? this.closeness,
    metAtAge: metAtAge,
    lastSeenAge: lastSeenAge ?? this.lastSeenAge,
  );

  /// A word for where this stands, for the menu row.
  ///
  /// Plain language on purpose — "Drifting" tells a nine-year-old what is
  /// happening to a friendship in a way that "Closeness: 34" does not.
  String get status {
    if (closeness >= 80) return 'Close';
    if (closeness >= 55) return 'Good';
    if (closeness >= 30) return 'Drifting';
    if (closeness > 0) return 'Barely speak';
    return 'Lost touch';
  }

  Color get statusColour {
    if (closeness >= 80) return const Color(0xFF85EFAC);
    if (closeness >= 55) return const Color(0xFF9CCC65);
    if (closeness >= 30) return const Color(0xFFF2C66D);
    return const Color(0xFFFF8474);
  }

  /// Whether this person still counts as somebody you have in your life.
  ///
  /// Below 15 they are a name you used to know. They stay in the list rather
  /// than being deleted — losing touch with somebody is a thing that happened
  /// to you, and quietly removing the row would hide it.
  bool get isPresent => closeness >= 15;
}

/// How much closeness is lost per year with no contact at all.
///
/// Three points a year is slow enough that a run has to actually neglect
/// somebody for a decade to lose them, and fast enough that a sixty-year life
/// spent working can end alone. Tuned against the sweep in
/// `relationships_test`.
const double kBaseYearlyDrift = 3.0;

/// The closeness a new person arrives with.
const int kStartingCloseness = 60;
