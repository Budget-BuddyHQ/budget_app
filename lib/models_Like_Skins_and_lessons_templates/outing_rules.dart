import 'dart:math';

import 'package:flutter/material.dart';

/// Whether the character is allowed out of the house right now, and why not.
///
/// **Why this exists.** "Explore the town" used to be an always-on button:
/// a newborn could walk to the bank. That is the single biggest thing
/// separating this from a life sim — in BitLife what you are *allowed* to
/// do is a function of who you are and where you are in life, and being
/// told "no, and here is why" is itself part of the game.
///
/// Three factors, deliberately: one you grow out of (age), one rolled at
/// birth that makes two runs differ (how strict the household is), and one
/// that changes year to year (weather). Age alone would be a gate; three
/// factors make it a *situation*.
enum OutingBlockReason { tooYoung, strictParents, badWeather, unwell }

extension OutingBlockReasonInfo on OutingBlockReason {
  IconData get icon => switch (this) {
    OutingBlockReason.tooYoung => Icons.child_care_rounded,
    OutingBlockReason.strictParents => Icons.family_restroom_rounded,
    OutingBlockReason.badWeather => Icons.thunderstorm_rounded,
    OutingBlockReason.unwell => Icons.sick_rounded,
  };
}

/// How closely the character is supervised as a child. Rolled at birth, so
/// two runs from the same origin still play differently.
enum HouseholdStrictness { relaxed, normal, strict }

extension HouseholdStrictnessInfo on HouseholdStrictness {
  String get label => switch (this) {
    HouseholdStrictness.relaxed => 'Relaxed',
    HouseholdStrictness.normal => 'Normal',
    HouseholdStrictness.strict => 'Strict',
  };

  /// Age from which the character may leave the house alone.
  ///
  /// A relaxed household lets a 10-year-old roam; a strict one holds out
  /// until 14. Everyone is free at 16 regardless (see [Weather] use in
  /// [OutingPermission.evaluate]) — the point is a few in-between years
  /// where the answer depends on the family you happened to be born into,
  /// not a permanent handicap.
  int get freeRoamAge => switch (this) {
    HouseholdStrictness.relaxed => 10,
    HouseholdStrictness.normal => 12,
    HouseholdStrictness.strict => 14,
  };

  String get blurb => switch (this) {
    HouseholdStrictness.relaxed =>
      'Your family is relaxed — you got to roam early.',
    HouseholdStrictness.normal => 'Your family is about average about rules.',
    HouseholdStrictness.strict =>
      'Your family is strict. You will be waiting a while for freedom.',
  };
}

/// This year's weather. Re-rolled every time the character ages up.
enum Weather { clear, rain, storm, snow, heatwave }

extension WeatherInfo on Weather {
  String get label => switch (this) {
    Weather.clear => 'Clear',
    Weather.rain => 'Rainy',
    Weather.storm => 'Stormy',
    Weather.snow => 'Snowy',
    Weather.heatwave => 'Heatwave',
  };

  IconData get icon => switch (this) {
    Weather.clear => Icons.wb_sunny_rounded,
    Weather.rain => Icons.umbrella_rounded,
    Weather.storm => Icons.thunderstorm_rounded,
    Weather.snow => Icons.ac_unit_rounded,
    Weather.heatwave => Icons.local_fire_department_rounded,
  };

  Color get accent => switch (this) {
    Weather.clear => const Color(0xFFFFD45C),
    Weather.rain => const Color(0xFF69C6FF),
    Weather.storm => const Color(0xFFB388FF),
    Weather.snow => const Color(0xFFCFE9FF),
    Weather.heatwave => const Color(0xFFFF8A65),
  };

  /// Only a genuine storm stops an adult going out. Rain is atmosphere, not
  /// an obstacle — gating on it would make the town unreachable a third of
  /// the time, which is tedious rather than realistic.
  bool get blocksOuting => this == Weather.storm;

  /// Weighted so most years are unremarkable. A storm that shows up one
  /// year in twelve is an event; one that shows up constantly is a chore.
  static Weather roll(Random random) {
    const weights = <Weather, int>{
      Weather.clear: 50,
      Weather.rain: 24,
      Weather.storm: 8,
      Weather.snow: 10,
      Weather.heatwave: 8,
    };
    var roll = random.nextInt(weights.values.reduce((a, b) => a + b));
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return Weather.clear;
  }
}

/// The answer to "can I go out right now", with the reason attached.
@immutable
class OutingPermission {
  const OutingPermission._({
    required this.allowed,
    this.reason,
    this.message = '',
  });

  final bool allowed;
  final OutingBlockReason? reason;
  final String message;

  static const OutingPermission _yes = OutingPermission._(allowed: true);

  /// Age is checked first, then health, then the household rule, then the
  /// sky — roughly the order a real "can I go out?" conversation resolves,
  /// and it means the message always names the thing that would have to
  /// change first.
  static OutingPermission evaluate({
    required int age,
    required int health,
    required HouseholdStrictness strictness,
    required Weather weather,
  }) {
    if (age < 6) {
      return const OutingPermission._(
        allowed: false,
        reason: OutingBlockReason.tooYoung,
        message: 'You are far too little to go out on your own.',
      );
    }
    if (health <= 15) {
      return const OutingPermission._(
        allowed: false,
        reason: OutingBlockReason.unwell,
        message: 'You are too unwell to leave the house today.',
      );
    }
    // 16+, nobodys rules apply any more
    if (age < 16 && age < strictness.freeRoamAge) {
      return OutingPermission._(
        allowed: false,
        reason: OutingBlockReason.strictParents,
        message: strictness == HouseholdStrictness.strict
            ? 'Your family says no — not until you are '
                  '${strictness.freeRoamAge}.'
            : 'You are not allowed out alone until '
                  '${strictness.freeRoamAge}.',
      );
    }
    if (weather.blocksOuting) {
      return const OutingPermission._(
        allowed: false,
        reason: OutingBlockReason.badWeather,
        message: 'There is a storm outside. Today is an indoors day.',
      );
    }
    return _yes;
  }
}
