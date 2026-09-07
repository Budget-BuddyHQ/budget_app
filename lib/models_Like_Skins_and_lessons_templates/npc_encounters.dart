import 'finance_concepts.dart';

/// Things a townsperson can do to you, rather than say at you.
///
/// # Why
///
/// Reported twice: *"the NPCs still just give out dialogue, we want action
/// from the NPC — like that NPC stealing from you and then running away with
/// your money, and side quests."*
///
/// Both times the answer had been to write more lines, and more lines is not
/// the fix. A line of dialogue cannot be *acted on*, so seven people saying
/// sensible things about money is seven posters you walk up to. What makes a
/// person in a game a person is that meeting them changes something.
///
/// # The rule every encounter follows
///
/// **It has to teach the thing it does to you.** A pickpocket is not here for
/// drama — it is the only way this app can make "carry less cash than you can
/// afford to lose" a thing that happened to you rather than a sentence you
/// read. A too-good-to-be-true offer has to actually take the money, or it is
/// a warning poster again.
///
/// # Why losses are small and always survivable
///
/// This is played by four-year-olds. An encounter that wipes a run would
/// teach avoidance of the town, not care with money — and the town is where
/// the game is. Every loss here is a percentage with a hard cap, every one is
/// recoverable, and each one names what would have prevented it. Being robbed
/// and being *told why you were an easy target* is a lesson; being robbed is
/// just tax.
enum NpcActionKind {
  /// Takes a slice of carried cash and runs.
  pickpocket,

  /// Offers something that sounds too good. Taking it costs money.
  scam,

  /// Offers a genuine, small, honest deal.
  fairDeal,

  /// Gives you something for nothing. Rare, and real.
  kindness,

  /// Offers paid work you can take now.
  hustle,
}

/// One thing that can happen when you talk to somebody.
class NpcAction {
  const NpcAction({
    required this.id,
    required this.kind,
    required this.npcId,
    required this.headline,
    required this.detail,
    required this.acceptLabel,
    required this.declineLabel,
    required this.outcomeAccepted,
    required this.outcomeDeclined,
    required this.concept,
    this.goldDelta = 0,
    this.acceptedGoldPercent = 0,
    this.minAge = 0,
    this.maxLoss = 60,
  });

  final String id;
  final NpcActionKind kind;
  final String npcId;

  final String headline;
  final String detail;
  final String acceptLabel;
  final String declineLabel;

  /// What you are told after choosing. Both name the lesson.
  final String outcomeAccepted;
  final String outcomeDeclined;

  final FinanceConcept concept;

  /// Flat change on accepting. Negative costs, positive pays.
  final int goldDelta;

  /// Change as a share of carried cash, 0..1.
  ///
  /// Percentages rather than flat amounts for anything that *takes*, so the
  /// same encounter is proportionate to a six-year-old with 40 coins and a
  /// teenager with 4,000. A flat 200 is nothing to one and the end of the
  /// run for the other.
  final double acceptedGoldPercent;

  final int minAge;

  /// Hard ceiling on any loss, whatever the percentage works out to.
  final int maxLoss;

  /// What accepting costs or pays, given what the player is carrying.
  int resolveGold(int carriedGold) {
    final proportional = (carriedGold * acceptedGoldPercent).round();
    final total = goldDelta + proportional;
    if (total < 0) {
      final capped = total < -maxLoss ? -maxLoss : total;
      // Never take more than is there. Debt from a pickpocket would be a
      // punishment the player had no way to decline.
      return capped.abs() > carriedGold ? -carriedGold : capped;
    }
    return total;
  }
}

/// Everything the town's people can do.
const List<NpcAction> kNpcActions = <NpcAction>[
  // --- the pickpocket ---------------------------------------------------
  //
  // The only encounter the player does not get to decline, and the reason it
  // exists: carrying everything you own is a decision, and no amount of
  // reading makes that land the way losing some of it does.
  NpcAction(
    id: 'npc_pickpocket',
    kind: NpcActionKind.pickpocket,
    npcId: 'npc_worker',
    headline: 'Someone bumps into you',
    detail:
        'They apologise, steady you by the elbow, and are already walking '
        'the other way before you check your pockets.',
    acceptLabel: 'Check your pockets',
    declineLabel: 'Check your pockets',
    outcomeAccepted:
        'Some of your carried coins are gone. Money in savings was never '
        'at risk — that is most of what savings is for.',
    outcomeDeclined:
        'Some of your carried coins are gone. Money in savings was never '
        'at risk — that is most of what savings is for.',
    concept: FinanceConcept.emergencyFund,
    acceptedGoldPercent: -0.12,
    maxLoss: 45,
    minAge: 8,
  ),

  // --- the scam ---------------------------------------------------------
  NpcAction(
    id: 'npc_double_your_coins',
    kind: NpcActionKind.scam,
    npcId: 'npc_taxer',
    headline: '"I can double your coins"',
    detail:
        'A stranger explains a system. It is guaranteed, it is only for '
        'today, and they need the money now to set it up.',
    acceptLabel: 'Hand it over',
    declineLabel: 'Walk away',
    outcomeAccepted:
        'They are gone. Guaranteed, urgent, and only today are the three '
        'things a real offer never needs to be.',
    outcomeDeclined:
        'You kept it. Guaranteed, urgent, and only today are the three '
        'things a real offer never needs to be.',
    concept: FinanceConcept.impulseSpending,
    acceptedGoldPercent: -0.25,
    maxLoss: 80,
    minAge: 10,
  ),

  // --- honest work ------------------------------------------------------
  NpcAction(
    id: 'npc_hustle_deliveries',
    kind: NpcActionKind.hustle,
    npcId: 'npc_shopper',
    headline: 'Fancy an afternoon of work?',
    detail:
        'Deliveries, this afternoon, cash at the end. It is not much and it '
        'is not glamorous, and it is real.',
    acceptLabel: 'Take the work',
    declineLabel: 'Not today',
    outcomeAccepted:
        'Paid, in full, for a known amount of effort. Boring money is the '
        'kind that actually arrives.',
    outcomeDeclined:
        'Fair enough — turning down work is allowed. The offer comes round '
        'again, which is worth knowing before you say yes to a worse one.',
    concept: FinanceConcept.incomeVsWealth,
    goldDelta: 35,
    minAge: 12,
  ),
  NpcAction(
    id: 'npc_hustle_tutoring',
    kind: NpcActionKind.hustle,
    npcId: 'npc_student',
    headline: 'Could you help me revise?',
    detail:
        'An hour of your time, explaining things you already know. They will '
        'pay for it.',
    acceptLabel: 'Help them',
    declineLabel: 'No time',
    outcomeAccepted:
        'Paid for something you already knew. The most valuable thing most '
        'people own is a skill somebody else needs.',
    outcomeDeclined:
        'They find somebody else. Time you could have sold is the one thing '
        'you cannot get back and sell later.',
    concept: FinanceConcept.incomeVsWealth,
    goldDelta: 45,
    minAge: 13,
  ),

  // --- a fair trade -----------------------------------------------------
  NpcAction(
    id: 'npc_fair_swap',
    kind: NpcActionKind.fairDeal,
    npcId: 'npc_neighbour',
    headline: 'Want to split the cost?',
    detail:
        'They are buying in bulk and offering you half at half the price. '
        'The maths checks out if you look at it.',
    acceptLabel: 'Split it',
    declineLabel: 'Pass',
    outcomeAccepted:
        'Cheaper per unit for both of you. Not every offer is a trick — the '
        'skill is telling which is which, not refusing all of them.',
    outcomeDeclined:
        'You passed on a good one. Being careful costs something too, and '
        'that is worth knowing.',
    concept: FinanceConcept.opportunityCost,
    goldDelta: -20,
    minAge: 9,
  ),

  // --- someone being kind ----------------------------------------------
  //
  // Rare, unconditional, and here on purpose. A town where every stranger is
  // a threat teaches suspicion, which is not financial literacy — it is just
  // a worse way to live. Some people are simply decent.
  NpcAction(
    id: 'npc_found_it',
    kind: NpcActionKind.kindness,
    npcId: 'npc_saver',
    headline: 'You dropped this',
    detail: 'They hand it back without being asked and carry on walking.',
    acceptLabel: 'Thank them',
    declineLabel: 'Thank them',
    outcomeAccepted:
        'Nothing was asked for in return. Most people are like this, which '
        'is exactly why the ones who are not can get away with it.',
    outcomeDeclined:
        'Nothing was asked for in return. Most people are like this, which '
        'is exactly why the ones who are not can get away with it.',
    concept: FinanceConcept.needsVsWants,
    goldDelta: 15,
  ),
];

/// Actions this person could take, at this age.
List<NpcAction> actionsFor(String npcId, {required int age}) => [
  for (final a in kNpcActions)
    if (a.npcId == npcId && age >= a.minAge) a,
];

/// Whether an encounter can be refused.
///
/// A pickpocket and a stranger handing your wallet back are things that
/// *happen*; a scam and a job are things you *choose*. Offering a decline
/// button on the first pair would be a lie about what the moment is.
bool isDeclinable(NpcActionKind kind) =>
    kind != NpcActionKind.pickpocket && kind != NpcActionKind.kindness;

/// Picks the encounter for this visit, or null for ordinary conversation.
///
/// [roll] is 0..1 from the caller, so the choice stays testable.
///
/// **Most visits are still just a chat.** An encounter every time would make
/// the town exhausting and would make the pickpocket routine rather than a
/// shock. One in three, and never the same one twice running.
NpcAction? encounterFor(
  String npcId, {
  required int age,
  required double roll,
  String? lastActionId,
}) {
  final available = [
    for (final a in actionsFor(npcId, age: age))
      if (a.id != lastActionId) a,
  ];
  if (available.isEmpty) return null;
  if (roll > 0.34) return null;

  final index = ((roll * 1000).floor()) % available.length;
  return available[index];
}
