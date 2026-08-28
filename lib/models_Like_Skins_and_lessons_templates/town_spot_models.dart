import 'package:flutter/material.dart';

/// Data for the Adventure town's interactable places.
///
/// This is the RPG half of "BitLife plus more": the Life sim asks money
/// questions on a scrolling feed, and these ask the *same shape* of
/// question ([TownChoice] mirrors `LifeChoice` — a label, an outcome line,
/// and stat deltas) except you have to physically walk to the building
/// first. Walking there is the game; the decision is the lesson.

enum TownSpotKind {
  store('Corner Store', Icons.storefront_rounded, Color(0xFFFFD45C)),
  bank('Town Bank', Icons.account_balance_rounded, Color(0xFF69C6FF)),
  school('School', Icons.school_rounded, Color(0xFFB388FF)),
  job('Job Board', Icons.work_rounded, Color(0xFF4BD2A3)),
  home('Your House', Icons.cottage_rounded, Color(0xFFFF8FB1)),
  noticeBoard('Notice Board', Icons.push_pin_rounded, Color(0xFFFFB74D));

  const TownSpotKind(this.label, this.icon, this.accent);
  final String label;
  final IconData icon;
  final Color accent;
}

/// One option inside a town interaction. [gold] may be negative — that's
/// the point of a spending choice.
@immutable
class TownChoice {
  const TownChoice({
    required this.label,
    required this.outcome,
    this.gold = 0,
    this.xp = 0,
    this.literacy = 0,
  });

  final String label;

  /// Shown after picking, so every choice teaches even when it costs you.
  final String outcome;
  final int gold;
  final int xp;
  final int literacy;
}

@immutable
class TownSpot {
  const TownSpot({
    required this.id,
    required this.kind,
    required this.title,
    required this.prompt,
    required this.tileX,
    required this.tileY,
    required this.choices,
  });

  final String id;
  final TownSpotKind kind;
  final String title;

  /// The line of dialogue shown when you walk in.
  final String prompt;

  /// Tile coordinates on the 50x50 map. Every one of these was picked
  /// against the collider data in `map.json` so it sits on a walkable tile
  /// right beside the building it represents — see
  /// `assets/images/maps/README.md`.
  final int tileX;
  final int tileY;

  final List<TownChoice> choices;
}

/// Pixel position for a tile, using the map's 16px tile size.
Offset townTileToPixels(int tileX, int tileY) =>
    Offset(tileX * 16.0, tileY * 16.0);

const List<TownSpot> kTownSpots = <TownSpot>[
  TownSpot(
    id: 'spot_store',
    kind: TownSpotKind.store,
    title: 'Corner Store',
    prompt:
        'The shelf label says CHIPS — \$4. There is also a bigger bag for '
        '\$6 that holds three times as much.',
    tileX: 11,
    tileY: 14,
    choices: [
      TownChoice(
        label: 'Buy the \$4 bag',
        outcome:
            'Fine — but the big bag was cheaper per chip. That is called '
            'unit price, and stores count on you not checking it.',
        gold: -4,
        xp: 4,
      ),
      TownChoice(
        label: 'Buy the \$6 bag',
        outcome:
            'Good call. Triple the chips for 50% more money is a better unit '
            'price — as long as you actually eat it all.',
        gold: -6,
        xp: 6,
        literacy: 6,
      ),
      TownChoice(
        label: 'Walk out without buying',
        outcome:
            'You kept all \$4. Not buying is always the cheapest option — the '
            'trick is knowing when that is the right one.',
        xp: 8,
        literacy: 4,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_bank',
    kind: TownSpotKind.bank,
    title: 'Town Bank',
    prompt:
        'A teller waves you over. "Want to open a savings account? Money in '
        'here grows a little every year on its own."',
    tileX: 37,
    tileY: 13,
    choices: [
      TownChoice(
        label: 'Deposit 20 coins',
        outcome:
            'Deposited. Interest means the bank pays *you* for leaving it '
            'alone — the opposite of how borrowing works.',
        gold: -20,
        xp: 10,
        literacy: 12,
      ),
      TownChoice(
        label: 'Ask how interest works first',
        outcome:
            '"A little extra gets added to whatever is sitting in there. '
            'Small at first, then it snowballs." Asking cost you nothing.',
        xp: 12,
        literacy: 10,
      ),
      TownChoice(
        label: 'Keep it all as cash',
        outcome:
            'Cash in your pocket is easy to spend by accident. That is not '
            'wrong — just know that is the trade you made.',
        xp: 4,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_school',
    kind: TownSpotKind.school,
    title: 'School',
    prompt: 'The library is open and nobody is using the money-skills shelf.',
    tileX: 10,
    tileY: 37,
    choices: [
      TownChoice(
        label: 'Read for an hour',
        outcome:
            'You picked up something about budgeting that will make the next '
            'decision easier. Learning pays later, not instantly.',
        xp: 14,
        literacy: 16,
      ),
      TownChoice(
        label: 'Skim the first page',
        outcome: 'A little stuck. Better than nothing.',
        xp: 5,
        literacy: 4,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_job',
    kind: TownSpotKind.job,
    title: 'Job Board',
    prompt:
        'Two cards are pinned up. One pays 15 coins today. One pays 40 coins '
        'but takes all weekend.',
    tileX: 36,
    tileY: 37,
    choices: [
      TownChoice(
        label: 'Take the quick job (15)',
        outcome:
            'Paid fast. Quick money is real money — just check what you gave '
            'up to get it.',
        gold: 15,
        xp: 8,
      ),
      TownChoice(
        label: 'Take the weekend job (40)',
        outcome:
            'More coins, less free time. Almost every money choice is really '
            'a time choice wearing a money costume.',
        gold: 40,
        xp: 12,
        literacy: 8,
      ),
      TownChoice(
        label: 'Take neither today',
        outcome:
            'Your time stayed yours. Rest is not free money, but it is not '
            'nothing either.',
        xp: 4,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_home',
    kind: TownSpotKind.home,
    title: 'Your House',
    prompt:
        'Your budget notebook is open on the kitchen table, a few days '
        'behind.',
    tileX: 27,
    tileY: 42,
    choices: [
      TownChoice(
        label: 'Fill in the missing days',
        outcome:
            'Now you can actually see where it went. A budget you update is '
            'working; one you ignore is decoration.',
        xp: 12,
        literacy: 14,
      ),
      TownChoice(
        label: 'Close it and deal with it later',
        outcome:
            '"Later" is where budgets go to die. No harm done today, though.',
        xp: 3,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_notice',
    kind: TownSpotKind.noticeBoard,
    title: 'Notice Board',
    prompt:
        'A hand-written note is pinned here: "Whoever keeps track of the '
        'small stuff ends up with the big stuff. — a neighbour"',
    tileX: 32,
    tileY: 24,
    choices: [
      TownChoice(
        label: 'Take the note',
        outcome:
            'Pocketed. Small amounts, tracked, turn into big amounts — that '
            'is the whole trick, written on a scrap of paper.',
        xp: 10,
        literacy: 8,
      ),
    ],
  ),
];

/// Which sprite set an NPC uses. Each maps to a folder of individual frame
/// PNGs under `assets/map_assets_coins/` — see `AppAssets`.
enum TownNpcLook { taxer, customer, fancy, worker }

/// A person standing in the town who says something when you walk up.
///
/// NPCs are deliberately *simpler* than [TownSpot]s: no choices, no stat
/// changes, just a line of advice. They exist to make the town feel
/// inhabited and to put a money idea in front of you without demanding a
/// decision — the town's equivalent of overhearing something useful.
@immutable
class TownNpc {
  const TownNpc({
    required this.id,
    required this.name,
    required this.look,
    required this.tileX,
    required this.tileY,
    required this.lines,
  });

  final String id;
  final String name;
  final TownNpcLook look;
  final int tileX;
  final int tileY;

  /// Cycled through on repeat visits so a second conversation isn't a
  /// copy of the first.
  final List<String> lines;
}

/// Every position here was checked against the collider data for a clear
/// 3x3 around it, so an NPC never spawns wedged inside a wall.
const List<TownNpc> kTownNpcs = <TownNpc>[
  TownNpc(
    id: 'npc_taxer',
    name: 'Tax Collector',
    look: TownNpcLook.taxer,
    tileX: 34,
    tileY: 16,
    lines: [
      'Your paycheck is smaller than your pay rate. The gap is taxes — '
          'and it comes out before you ever see the money.',
      'Gross pay is the number on the offer. Net pay is the number that '
          'lands. Budget on the second one.',
      'Nobody enjoys me. But a person who plans around tax never gets '
          'surprised by it.',
    ],
  ),
  TownNpc(
    id: 'npc_shopper',
    name: 'Shopper',
    look: TownNpcLook.customer,
    tileX: 14,
    tileY: 16,
    lines: [
      'I nearly bought this twice. Waiting a day is the cheapest trick '
          'I know.',
      'Check the price per unit, not the price on the sticker. Bigger is '
          'not always cheaper.',
      'A sale on something you did not need is not saving money.',
    ],
  ),
  TownNpc(
    id: 'npc_saver',
    name: 'Careful Spender',
    look: TownNpcLook.fancy,
    tileX: 22,
    tileY: 24,
    lines: [
      'I pay myself first — a slice goes to savings the day money arrives, '
          'before anything else gets a turn.',
      'The trick was never earning more. It was noticing where it went.',
      'Small amounts, tracked, beat big amounts, ignored.',
    ],
  ),
  TownNpc(
    id: 'npc_worker',
    name: 'Shift Worker',
    look: TownNpcLook.worker,
    tileX: 33,
    tileY: 27,
    lines: [
      'Every job is really trading hours for money. Worth asking what an '
          'hour of yours is worth.',
      'First paycheck? Look at the deductions line before you plan how to '
          'spend it.',
      'Overtime looks great until you count what the extra hours cost you.',
    ],
  ),
  TownNpc(
    id: 'npc_student',
    name: 'Student',
    look: TownNpcLook.customer,
    // Was (17, 17), which sat right against the west ledge with a solid
    // tile two rows up — the NPC sprite is ~2 tiles tall and drawn upward
    // from its feet, so its head visibly clipped into the scenery above.
    // Every NPC tile is now checked for two clear rows overhead; see
    // `test/town_map_test.dart`.
    tileX: 13,
    tileY: 27,
    lines: [
      'The library has a whole shelf on money and nobody touches it.',
      'I learned more about budgeting from tracking one week of spending '
          'than from any lecture.',
    ],
  ),
  TownNpc(
    id: 'npc_neighbour',
    name: 'Neighbour',
    look: TownNpcLook.fancy,
    tileX: 28,
    tileY: 27,
    lines: [
      'An emergency fund is boring right up until the week it saves you.',
      'Start with one month of costs. That first month changes the most.',
    ],
  ),
];

/// Where the player appears when they walk into town — just outside their
/// own front door (`spot_home` sits at 13,30).
///
/// Not the map centre: you leave home to go into town and come back to it,
/// so spawning in the middle of the square made the map read as a level
/// select rather than somewhere you live. `test/town_map_test.dart` checks
/// this tile is walkable, reachable, and has two clear rows overhead so the
/// sprite does not clip the house.
const ({int x, int y}) kTownSpawnTile = (x: 26, y: 42);

/// Coin pickups scattered on confirmed-walkable tiles across the open
/// middle of the map, so exploring pays a little on its own.
const List<({int x, int y, int value})> kTownCoins =
    <({int x, int y, int value})>[
      (x: 25, y: 8, value: 3),
      (x: 25, y: 17, value: 3),
      (x: 8, y: 24, value: 3),
      (x: 41, y: 24, value: 5),
      (x: 25, y: 31, value: 5),
      (x: 18, y: 24, value: 3),
      (x: 25, y: 44, value: 5),
    ];
