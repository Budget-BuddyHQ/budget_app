import 'dart:math';

import 'relationship.dart';

/// Who you know, and what that is worth.
///
/// # Why a money game has a network in it
///
/// Most people do not find work by applying to it. They hear about it. A
/// large share of jobs are filled through somebody who knows somebody, and a
/// raise is far easier to get when a person other than you has said your name
/// in the right room. That is not a trick and it is not cheating, it is how
/// the labour market actually moves, and a game about money that left it out
/// would be teaching a version of working life that does not exist.
///
/// It is also the part of getting ahead that a teenager cannot see from where
/// they stand, which is the best reason to put it in front of them.
///
/// # The three things it does
///
///  * **Contacts.** People you meet at work, at a networking event, or by
///    talking to somebody in town. They are a different kind of relationship
///    from a friend (see `RelationshipKind.colleague`), and they are left out
///    of the loneliness measure the endings use.
///  * **Strength.** A single number, 0 to 100, from how many of them you have
///    and how warm each is. Four close contacts is a full network.
///  * **Referrals.** Once a year the game rolls whether one of them passes you
///    a lead, and the odds rise with strength. A lead is a job if you have
///    none, a good word to your manager if you have one, or a one-off gig.
///
/// # Why it decays
///
/// Contacts drift faster than family (see `driftRate`), because a network you
/// never touch stops being one. Keeping it warm costs a coffee and an hour,
/// which is what it costs in real life and is the whole reason people say it
/// is work.
///
/// Kept away from Flutter and from the controller so the maths is in one place
/// and can be tested as numbers.

/// First names for people you meet.
///
/// Deliberately plain and drawn from a spread of backgrounds. They are
/// combined with [kContactLastNames] rather than written out as full names, so
/// there is enough variety that nobody meets the same person twice in a life.
const List<String> kContactFirstNames = <String>[
  'Aisha',
  'Marcus',
  'Priya',
  'Diego',
  'Hannah',
  'Kwame',
  'Mei',
  'Luca',
  'Zainab',
  'Owen',
  'Sofia',
  'Tariq',
  'Ingrid',
  'Mateo',
  'Yuki',
  'Amara',
  'Callum',
  'Noor',
  'Elias',
  'Rosa',
  'Dev',
  'Freya',
  'Jamal',
  'Lena',
];

const List<String> kContactLastNames = <String>[
  'Okafor',
  'Bennett',
  'Sharma',
  'Alvarez',
  'Whitfield',
  'Nkosi',
  'Tanaka',
  'Moreau',
  'Haddad',
  'Kowalski',
  'Reyes',
  'Lindqvist',
  'Adeyemi',
  'Patel',
  'Fontaine',
  'Osei',
  'Brandt',
  'Castillo',
  'Nguyen',
  'Ferreira',
  'Holloway',
  'Mbeki',
  'Sato',
  'Vance',
];

/// A name nobody in [taken] already has.
///
/// Falls back to a numbered name if the whole space is somehow used, which
/// takes 576 contacts in one life and is there so this can never loop or throw.
String freshContactName(Random random, Set<String> taken) {
  for (var attempt = 0; attempt < 60; attempt++) {
    final name =
        '${kContactFirstNames[random.nextInt(kContactFirstNames.length)]} '
        '${kContactLastNames[random.nextInt(kContactLastNames.length)]}';
    if (!taken.contains(name)) return name;
  }
  return 'Contact ${taken.length + 1}';
}

/// Points one contact adds to the network's strength, out of 25.
///
/// Zero for somebody who has faded below the line where a person still counts,
/// because a name you used to know does not pass on leads.
int contactPoints(Relationship person) {
  if (!person.kind.isProfessional || !person.isPresent) return 0;
  return (person.closeness / 100 * 25).round();
}

/// The state of somebody's network, in numbers and in a word.
class NetworkReading {
  const NetworkReading({required this.contacts, required this.strength});

  /// How many professional contacts are still present.
  final int contacts;

  /// 0 to 100.
  final int strength;

  /// A word for it, for the menu.
  ///
  /// Plain language on purpose. "Thin" tells a fifteen-year-old what is wrong
  /// and what to do about it in a way "strength: 12" does not.
  String get label {
    if (contacts == 0) return 'None yet';
    if (strength >= 70) return 'Strong';
    if (strength >= 45) return 'Solid';
    if (strength >= 20) return 'Growing';
    return 'Thin';
  }

  /// The chance, per year, that somebody passes you a lead.
  ///
  /// 3% with nobody, which is the odd stroke of luck, rising to about 31% for a
  /// full network. Over a working life a solid network hands over a handful of
  /// leads, which is about how often it really happens.
  double get referralChance => 0.03 + strength * 0.0028;
}

/// Reads a whole list of people into one [NetworkReading].
NetworkReading readNetwork(Iterable<Relationship> people) {
  var contacts = 0;
  var points = 0;
  for (final person in people) {
    final add = contactPoints(person);
    if (add > 0) {
      contacts++;
      points += add;
    }
  }
  return NetworkReading(contacts: contacts, strength: points.clamp(0, 100));
}

/// What a lead turns out to be.
enum ReferralKind {
  /// You had no job, and somebody put your name forward for one.
  jobLead,

  /// You had a job, and somebody said good things about you to your manager.
  goodWord,

  /// A one-off piece of paid work, sent your way.
  gig,
}

/// Picks what a referral is, from where the player currently stands.
///
/// With no job the answer is always a job. With one it is a raise a little
/// more often than a gig, because the raise is the more valuable of the two
/// and the more common way a network actually pays.
ReferralKind pickReferralKind({
  required bool hasJob,
  required Random random,
}) {
  if (!hasJob) return ReferralKind.jobLead;
  return random.nextInt(100) < 55 ? ReferralKind.goodWord : ReferralKind.gig;
}
