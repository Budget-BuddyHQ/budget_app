import 'package:flutter/material.dart';

import 'finance_concepts.dart';

/// Somewhere to give your time, and what it costs you.
///
/// **Why this replaced a button.** Volunteering used to be one menu row that
/// paid a flat +9 Happiness and +2 Smarts for nothing, every time, forever.
/// It was the single most efficient action in the game and it involved no
/// decision at all — which is the opposite of what this app is for, and it
/// quietly taught that good things are free.
///
/// They are not. Every one of these costs a real amount of time, and time is
/// the resource the game has been treating as infinite. So each place asks
/// the same question in a different shape: **what are you giving up, and what
/// do you get that money could not buy?**
///
/// The economics are honest and they are not all the same:
///
/// * The food bank is hard work and the most rewarding. Effort and meaning
///   correlate, usually.
/// * Tutoring pays you back in Smarts — teaching something is how you find
///   out whether you know it.
/// * The animal shelter is pure happiness and teaches you nothing, and that
///   is a completely acceptable reason to do something.
/// * The charity shop is the one that pays a *skill*: retail, stock, pricing.
///   Unpaid work that is really training is a real thing and worth naming.
/// * The one-off litter pick is the cheap option — small time, small return.
///   Not everything has to be a commitment.
///
/// None of them pay money, and that is the point of the whole feature.
@immutable
class VolunteerPlace {
  const VolunteerPlace({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
    required this.accent,
    required this.happiness,
    required this.smarts,
    required this.health,
    required this.hours,
    required this.outcome,
    this.teaches,
    this.minAge = 10,
  });

  final String id;
  final String label;

  /// One line on the row: what it is and what it asks of you.
  final String blurb;

  final IconData icon;
  final Color accent;

  final int happiness;
  final int smarts;
  final int health;

  /// Hours a week. Shown to the player, because it is the price.
  final int hours;

  /// What lands in the feed afterwards.
  final String outcome;

  /// The money idea this can introduce, if any.
  final FinanceConcept? teaches;

  /// Some of these need a bit more of you than a ten-year-old has.
  final int minAge;

  /// Happiness per hour, which is how you compare two of these honestly.
  double get happinessPerHour => happiness / hours;
}

const List<VolunteerPlace> kVolunteerPlaces = <VolunteerPlace>[
  VolunteerPlace(
    id: 'litter_pick',
    label: 'Saturday litter pick',
    blurb: 'Two hours, a bag and a grabber. Home by lunch.',
    icon: Icons.cleaning_services_rounded,
    accent: Color(0xFF9CCC65),
    happiness: 4,
    smarts: 1,
    health: 2,
    hours: 2,
    outcome:
        'Two hours and the street looks better. Small things you can finish '
        'are worth more than big ones you cannot start.',
  ),
  VolunteerPlace(
    id: 'animal_shelter',
    label: 'The animal shelter',
    blurb: 'Walking dogs and cleaning out. Four hours a week.',
    icon: Icons.pets_rounded,
    accent: Color(0xFFFF8FB1),
    happiness: 11,
    smarts: 0,
    health: 3,
    hours: 4,
    outcome:
        'Four hours of dogs. You learned nothing and felt better all week, '
        'which is a good enough reason to do something.',
  ),
  VolunteerPlace(
    id: 'food_bank',
    label: 'The food bank',
    blurb: 'Sorting, packing, carrying. Six hours and you will feel it.',
    icon: Icons.volunteer_activism_rounded,
    accent: Color(0xFFFFD45C),
    happiness: 14,
    smarts: 3,
    health: -2,
    hours: 6,
    outcome:
        'Six hours on your feet and a very tired back. You also met people '
        'one bad month away from where you are, which is most of what a food '
        'bank teaches.',
    teaches: FinanceConcept.emergencyFund,
    minAge: 12,
  ),
  VolunteerPlace(
    id: 'charity_shop',
    label: 'The charity shop',
    blurb: 'Till, stock and pricing. Five hours, and it is real training.',
    icon: Icons.storefront_rounded,
    accent: Color(0xFF69C6FF),
    happiness: 7,
    smarts: 5,
    health: 0,
    hours: 5,
    outcome:
        'Five hours on a till and a shop floor. Unpaid, and you now know how '
        'to price stock and handle a queue — which is a job you could be paid '
        'for.',
    teaches: FinanceConcept.incomeVsWealth,
    minAge: 13,
  ),
  VolunteerPlace(
    id: 'tutoring',
    label: 'Tutoring younger kids',
    blurb: 'Three hours explaining things you thought you understood.',
    icon: Icons.school_rounded,
    accent: Color(0xFFB388FF),
    happiness: 8,
    smarts: 7,
    health: 0,
    hours: 3,
    outcome:
        'Three hours of explaining. You found out which bits you actually '
        'understood, which is the fastest way anybody has ever found to '
        'learn something.',
    minAge: 13,
  ),
];

/// The places open to somebody of [age].
List<VolunteerPlace> volunteerPlacesFor(int age) =>
    kVolunteerPlaces.where((p) => age >= p.minAge).toList(growable: false);
