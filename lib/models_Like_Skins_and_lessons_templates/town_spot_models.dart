import 'package:flutter/material.dart';

/// Data for the Adventure town's interactable places.
///
/// This is the RPG half of "BitLife plus more": the Life sim asks money
/// questions on a scrolling feed, and these ask the *same shape* of
/// question ([TownChoice] mirrors `LifeChoice` — a label, an outcome line,
/// and stat deltas) except you have to physically walk to the building
/// first. Walking there is the game; the decision is the lesson.

/// Which town you are walking around in.
///
/// Two of them now. The second was drawn and exported only as a flat PNG,
/// with no tile grid and no collider flags, so for a long time it could be
/// shown as a picture and not played — three attempts at inferring its
/// collision from the image alone all marked the main promenade solid, which
/// cuts the town in half. `tool/build_map_two.py` gets it by *learning* the
/// collidable tile ids from map 1, which is authored data rather than a
/// guess, and the result is 99.6% one connected space.
///
/// Kept separate from `MapVariant` (the decorative backdrop behind the menus)
/// on purpose. They look like the same idea and are not: one is a picture, the
/// other is a level with colliders and twelve marker positions that have to
/// land on doorsteps.
enum TownMap {
  village('assets/images/maps/map.json'),
  market('assets/images/maps/map_two.json');

  const TownMap(this.asset);

  /// Sprite Fusion export. `SpritefusionAssetReader` reads from under
  /// `assets/images/` and wants `spritesheet.png` beside the JSON, so both
  /// maps share the one sheet and neither can move.
  final String asset;
}

enum TownSpotKind {
  store('Corner Store', Icons.storefront_rounded, Color(0xFFFFD45C)),
  bank('Town Bank', Icons.account_balance_rounded, Color(0xFF69C6FF)),
  school('School', Icons.school_rounded, Color(0xFFB388FF)),
  job('Job Board', Icons.work_rounded, Color(0xFF4BD2A3)),
  home('Your House', Icons.cottage_rounded, Color(0xFFFF8FB1)),
  noticeBoard('Notice Board', Icons.push_pin_rounded, Color(0xFFFFB74D)),

  // --- The second six -------------------------------------------------
  //
  // The first six cover the money decisions a school lesson would list.
  // These cover the ones a *week* contains: somewhere to eat, somewhere to
  // get better without paying, somewhere that charges you for being ill,
  // somewhere that buys your things back for less than you paid. The town is
  // meant to be where the realistic simulation happens, and a town with six
  // buildings is a lesson plan with a map behind it.
  market('Market Stalls', Icons.storefront_rounded, Color(0xFF9CCC65)),
  cafe('The Cafe', Icons.local_cafe_rounded, Color(0xFFD4A373)),
  clinic('Clinic', Icons.local_hospital_rounded, Color(0xFFFF8A80)),
  library('Library', Icons.menu_book_rounded, Color(0xFF80CBC4)),
  pawnShop('Pawn Shop', Icons.watch_rounded, Color(0xFFCE93D8)),
  park('The Park', Icons.park_rounded, Color(0xFF66BB6A)),

  // --- The next four: what the life sim grew -------------------------------
  //
  // A life is now school, a career, a home, a pet and a body, and the town had
  // twelve buildings and none of them was about any of those. Each of these is
  // where one of them is walked to, and each teaches the money idea that part
  // of a life is about: a membership you may not use, the total cost of a
  // course, the cost of a home that is not the price, and what a pet costs
  // every year after the day it comes home.
  gym('Gym', Icons.fitness_center_rounded, Color(0xFFFF8A65)),
  campus('Campus Office', Icons.workspace_premium_rounded, Color(0xFF9FA8DA)),
  housing('Housing Office', Icons.apartment_rounded, Color(0xFF4DB6AC)),
  petShop('Pet Shop', Icons.pets_rounded, Color(0xFFF48FB1));

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
    this.hires = false,
  });

  final String label;

  /// Shown after picking, so every choice teaches even when it costs you.
  final String outcome;
  final int gold;
  final int xp;

  /// Whether taking this actually gets the character a job.
  ///
  /// **Why the board needed this.** The town's job board handed out 15 or 40
  /// coins and nothing else, so the one building in the game named after
  /// employment could not employ you — it was a coin dispenser with a career
  /// theme. Meanwhile the only real way to get hired was a menu row, which is
  /// the wrong way round: the board is the thing a person walks to.
  ///
  /// Only meaningful inside a life (the town is also playable on its own),
  /// and only when the character is old enough and does not already have a
  /// job — see `LifeSimController.findJob`, which is what this ends up
  /// calling with `viaJobBoard: true`.
  final bool hires;
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
    required this.tileX2,
    required this.tileY2,
    required this.choices,
  });

  final String id;
  final TownSpotKind kind;
  final String title;

  /// The line of dialogue shown when you walk in.
  final String prompt;

  /// Tile coordinates on the 50x50 village map.
  ///
  /// Not hand-tuned any more: `tool/place_town_spots.py` snaps every one of
  /// these to a walkable tile that actually touches a building. The
  /// hand-placed originals had drifted — the cafe and the clinic were sitting
  /// *four tiles* from the nearest solid thing, which on screen is a coloured
  /// circle floating in the middle of a road. `town_layout_test` holds them
  /// there.
  final int tileX;
  final int tileY;

  /// The same marker on the second map, which has its buildings in entirely
  /// different places. Generated by the same tool.
  final int tileX2;
  final int tileY2;

  int xOn(TownMap map) => map == TownMap.village ? tileX : tileX2;

  int yOn(TownMap map) => map == TownMap.village ? tileY : tileY2;

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
    tileY: 13,
    tileX2: 9,
    tileY2: 14,
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
    tileY: 12,
    tileX2: 43,
    tileY2: 3,
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
    tileX2: 6,
    tileY2: 42,
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
    tileY: 36,
    tileX2: 41,
    tileY2: 32,
    choices: [
      TownChoice(
        label: 'Ask about the proper job on the card',
        outcome:
            'You asked instead of scrolling. Turning up in person puts you in '
            'front of somebody, which is most of why it works better.',
        xp: 10,
        literacy: 6,
        hires: true,
      ),
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
    tileX: 23,
    tileY: 44,
    tileX2: 25,
    tileY2: 40,
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
    tileX: 37,
    tileY: 20,
    tileX2: 39,
    tileY2: 17,
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

  // --- The second six --------------------------------------------------
  TownSpot(
    id: 'spot_market',
    kind: TownSpotKind.market,
    title: 'Market Stalls',
    prompt:
        'Loose apples are \$2 a bag at one stall and \$3 at the next, where '
        'they look better. Neither has a price per kilo.',
    tileX: 29,
    tileY: 19,
    tileX2: 19,
    tileY2: 5,
    choices: [
      TownChoice(
        label: 'Take the \$2 bag',
        outcome:
            'Cheaper, and you have no idea whether it was better value — '
            'without a weight there is nothing to compare. That is why shops '
            'are made to print a unit price.',
        gold: -2,
        xp: 5,
        literacy: 5,
      ),
      TownChoice(
        label: 'Pay \$3 for the better-looking ones',
        outcome:
            'Sometimes right. Quality is a real thing to buy — the trap is '
            'paying for the *display* and calling it quality.',
        gold: -3,
        xp: 5,
      ),
      TownChoice(
        label: 'Ask both stalls what the bag weighs',
        outcome:
            'The \$3 bag is nearly twice the weight, so it is cheaper per '
            'apple. One question turned a guess into a number.',
        gold: -3,
        xp: 9,
        literacy: 10,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_cafe',
    kind: TownSpotKind.cafe,
    title: 'The Cafe',
    prompt:
        'A hot chocolate is \$4.50. You have been in three times this week '
        'already.',
    tileX: 22,
    tileY: 31,
    tileX2: 17,
    tileY2: 32,
    choices: [
      TownChoice(
        label: 'Get one — it is only \$4.50',
        outcome:
            'It is only \$4.50, and four times a week is \$936 a year. Small '
            'repeated spending is the hardest kind to see, because no single '
            'one of them is the problem.',
        gold: -5,
        xp: 4,
        literacy: 6,
      ),
      TownChoice(
        label: 'Skip it today',
        outcome:
            'Nothing dramatic happened. That is what most good money '
            'decisions look like — a thing you did not do, and no story '
            'afterwards.',
        xp: 8,
        literacy: 6,
      ),
      TownChoice(
        label: 'Work out what the week has cost',
        outcome:
            'Three visits is \$13.50 — about what a whole meal costs. '
            'Counting it is the only way a habit ever becomes a decision.',
        xp: 10,
        literacy: 10,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_clinic',
    kind: TownSpotKind.clinic,
    title: 'Clinic',
    prompt:
        'You have had a cough for two weeks. The visit is \$40, or free if '
        'you wait nine days for the community slot.',
    tileX: 22,
    tileY: 18,
    tileX2: 0,
    tileY2: 18,
    choices: [
      TownChoice(
        label: 'Pay the \$40 and be seen today',
        outcome:
            'Money buys time, which is most of what money buys. Nine days of '
            'a cough for \$40 is a trade only you can price.',
        gold: -40,
        xp: 6,
        literacy: 7,
      ),
      TownChoice(
        label: 'Wait for the free slot',
        outcome:
            'You keep the \$40 and cough for another nine days. A perfectly '
            'good answer — and the reason free options are worth knowing '
            'about *before* you need one.',
        xp: 8,
        literacy: 8,
      ),
      TownChoice(
        label: 'Ask what happens if it gets worse',
        outcome:
            'They tell you which symptoms mean come back immediately. The '
            'cheapest thing in any healthcare system is knowing when the '
            'cheap option stops being the cheap option.',
        xp: 10,
        literacy: 10,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_library',
    kind: TownSpotKind.library,
    title: 'Library',
    prompt:
        'A free course on Saturday mornings: six weeks, three hours each. '
        'The paid version online is \$180 and you can do it whenever.',
    tileX: 8,
    tileY: 18,
    tileX2: 0,
    tileY2: 24,
    choices: [
      TownChoice(
        label: 'Sign up for the free one',
        outcome:
            'Eighteen hours of your Saturdays, and \$180 kept. Free never '
            'means free — it means paid for in time, which is the currency '
            'you have most of when you are young.',
        xp: 10,
        literacy: 10,
      ),
      TownChoice(
        label: 'Buy the online one',
        outcome:
            '\$180 to do it at your own pace. Worth it if your Saturdays are '
            'already spoken for, and worth nothing if you never open it — '
            'which is what happens to most of them.',
        gold: -60,
        xp: 6,
        literacy: 7,
      ),
      TownChoice(
        label: 'Borrow the book on it instead',
        outcome:
            'Free, slower, and entirely up to you whether it happens. The '
            'library is the most under-used free thing in any town.',
        xp: 9,
        literacy: 9,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_pawn',
    kind: TownSpotKind.pawnShop,
    title: 'Pawn Shop',
    prompt:
        'The console you paid \$300 for last year. They offer \$85 for it, or '
        '\$60 now as a loan you can buy back for \$80.',
    tileX: 28,
    tileY: 38,
    tileX2: 34,
    tileY2: 43,
    choices: [
      TownChoice(
        label: 'Sell it for \$85',
        outcome:
            'A year of use cost you \$215. That is depreciation, and it is why '
            'almost nothing you buy is an investment.',
        gold: 85,
        xp: 7,
        literacy: 9,
      ),
      TownChoice(
        label: 'Take the \$60 loan',
        outcome:
            '\$20 to borrow \$60 for a month is a third of it — an enormous '
            'rate, and the reason pawn shops exist. Sometimes it is still the '
            'only door open.',
        gold: 60,
        xp: 5,
        literacy: 10,
      ),
      TownChoice(
        label: 'Keep it and sell it privately',
        outcome:
            'Listing it yourself gets nearer \$140, for the cost of a week of '
            'messages and meeting a stranger. Convenience always has a price '
            'and it is rarely printed.',
        xp: 9,
        literacy: 9,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_park',
    kind: TownSpotKind.park,
    title: 'The Park',
    prompt:
        'An afternoon free. The park costs nothing; the arcade across the '
        'road is \$12 for the same three hours.',
    tileX: 21,
    tileY: 33,
    tileX2: 22,
    tileY2: 32,
    choices: [
      TownChoice(
        label: 'Stay in the park',
        outcome:
            'Three hours, nothing spent, and a good afternoon. Not every '
            'thing worth doing costs money — a budget with no free days in it '
            'is a budget nobody keeps.',
        xp: 9,
        literacy: 7,
      ),
      TownChoice(
        label: 'Go to the arcade',
        outcome:
            'Also a good afternoon, for \$12. Spending on something you '
            'actually enjoy is what the money is for — as long as it was a '
            'choice and not a default.',
        gold: -12,
        xp: 6,
      ),
      TownChoice(
        label: 'Park now, arcade next week',
        outcome:
            'You get both, a week apart, for \$12 instead of \$24. Spacing '
            'things out is the quietest saving there is.',
        xp: 10,
        literacy: 8,
      ),
    ],
  ),

  // --- The next four ----------------------------------------------------------
  //
  // Tile positions are set by `tool/make_town_map.py` (the first town) and
  // `tool/add_map_two_places.py` (the second), which put a building there, and
  // then snapped to a doorstep by `tool/place_town_spots.py` and
  // `tool/assign_town_buildings.py`.
  TownSpot(
    id: 'spot_gym',
    kind: TownSpotKind.gym,
    title: 'Gym',
    prompt:
        'A membership is \$20 a month. A single class is \$5. The park next '
        'door has a running track, and it is free.',
    tileX: 43,
    tileY: 31,
    tileX2: 33,
    tileY2: 23,
    choices: [
      TownChoice(
        label: 'Join for the month (\$20)',
        outcome:
            'A month of the gym, paid upfront. Most people go a lot in week '
            'one and less each week after. A membership only pays if you use '
            'it, and buying it feels like doing it.',
        gold: -20,
        xp: 6,
        literacy: 6,
      ),
      TownChoice(
        label: 'Pay for one class (\$5)',
        outcome:
            'You paid only for what you used. That is the honest way to buy '
            'something you are not sure you will keep doing.',
        gold: -5,
        xp: 10,
        literacy: 10,
      ),
      TownChoice(
        label: 'Run on the free track',
        outcome:
            'Free, and it counts just the same. What a gym adds is a place '
            'and a reason to turn up, which some people need and some do not.',
        xp: 8,
        literacy: 6,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_campus',
    kind: TownSpotKind.campus,
    title: 'Campus Office',
    prompt:
        'A poster says tuition is due Friday. Beside it is a form for a '
        'scholarship that closes the same day.',
    tileX: 18,
    tileY: 7,
    tileX2: 41,
    tileY2: 26,
    choices: [
      TownChoice(
        label: 'Fill in the scholarship form',
        outcome:
            'An hour of paperwork for money you never pay back. '
            'Scholarships go unclaimed every year because people assume they '
            'will not win one.',
        xp: 12,
        literacy: 14,
      ),
      TownChoice(
        label: 'Ask what the whole course costs',
        outcome:
            'Tuition is charged every year and courses run for several. The '
            'total is the number to compare, and the fee on the poster is '
            'only the first bill.',
        xp: 10,
        literacy: 12,
      ),
      TownChoice(
        label: 'Ask about a student loan',
        outcome:
            'A loan lets you study now and pay later, with interest on top. '
            'That is fine if the course leads to work that pays, and costly '
            'if it does not, so ask what it leads to first.',
        xp: 8,
        literacy: 10,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_housing',
    kind: TownSpotKind.housing,
    title: 'Housing Office',
    prompt:
        'A board lists homes to rent and homes to buy. Some are small and '
        'cheap, and some are big and cost far more. What matters most when '
        'you choose one?',
    tileX: 29,
    tileY: 33,
    tileX2: 19,
    tileY2: 20,
    choices: [
      TownChoice(
        label: 'The rent or the price',
        outcome:
            'It matters, and it is only part of it. Bills, repairs, tax and '
            'getting to work are paid on top, every month, for as long as you '
            'live there.',
        xp: 8,
        literacy: 8,
      ),
      TownChoice(
        label: 'How close it is to work and school',
        outcome:
            'A cheaper home far away can cost more once the fares and the '
            'hours are counted. Time is a bill too, and it is the one people '
            'forget to add up.',
        xp: 10,
        literacy: 10,
      ),
      TownChoice(
        label: 'What it costs to run each month',
        outcome:
            'This is the number people skip and the one that decides whether '
            'you can afford the place. A home is the price plus a running '
            'cost, and the running cost never stops.',
        xp: 12,
        literacy: 12,
      ),
    ],
  ),
  TownSpot(
    id: 'spot_pet',
    kind: TownSpotKind.petShop,
    title: 'Pet Shop',
    prompt:
        'A puppy costs \$200 to adopt. The bowl, the food, the vet and the '
        'walks all come after that.',
    tileX: 20,
    tileY: 12,
    tileX2: 31,
    tileY2: 7,
    choices: [
      TownChoice(
        label: 'Add up a year of running costs',
        outcome:
            'Food, vet visits and supplies cost more each year than the price '
            'tag did. The sticker is only the first bill.',
        xp: 10,
        literacy: 12,
      ),
      TownChoice(
        label: 'Volunteer at the shelter first',
        outcome:
            'You met the work before you signed up for it. Trying something '
            'before you buy it is worth more than any review.',
        xp: 12,
        literacy: 8,
      ),
      TownChoice(
        label: 'Adopt one (\$15 today)',
        outcome:
            'A big yes, and a long bill. The running costs come back every '
            'year for as long as they live, which is why it is a decision '
            'and not a purchase.',
        gold: -15,
        xp: 12,
        literacy: 6,
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
    required this.tileX2,
    required this.tileY2,
    required this.lines,
    this.patrolTiles = 0,
    this.patrolHorizontal = true,
  });

  final String id;
  final String name;
  final TownNpcLook look;
  final int tileX;
  final int tileY;

  /// The same person, standing somewhere sensible on the second map.
  ///
  /// **Why these had to exist.** The renderer used to draw NPCs and coins
  /// only when the map was `village`, because there was nowhere to put them
  /// otherwise — `TownSpot` grew `tileX2`/`tileY2` when the second map
  /// arrived and these did not. The guard was an honest short-term answer
  /// that then stayed, so half of all town visits landed somewhere with no
  /// people in it and nothing to pick up.
  ///
  /// Generated by `tool/populate_map_two.py` against map two's real collision
  /// data, obeying the clearance rules `town_map_test.dart` already enforces
  /// for map one.
  final int tileX2;
  final int tileY2;

  int xOn(TownMap map) => map == TownMap.village ? tileX : tileX2;

  int yOn(TownMap map) => map == TownMap.village ? tileY : tileY2;

  /// How far this NPC paces, in tiles, and along which axis.
  ///
  /// **Why a short patrol rather than free wandering.** A town of people
  /// standing perfectly still reads as a diorama, and that was the note: the
  /// map looked stale. But an NPC that wanders anywhere needs pathfinding,
  /// can walk into the sea, and — worst of all — can walk *away* from the
  /// player who is trying to reach them. Pacing a few tiles along one axis
  /// makes the town alive and keeps every NPC exactly where the player last
  /// saw them.
  ///
  /// Zero means standing still, which is right for the ones positioned
  /// behind counters.
  final int patrolTiles;

  /// True to pace left/right, false to pace up/down.
  final bool patrolHorizontal;

  /// Cycled through on repeat visits so a second conversation isn't a
  /// copy of the first.
  final List<String> lines;
}

/// Every position here was checked against the collider data for a clear
/// 3x3 around it, so an NPC never spawns wedged inside a wall.
const List<TownNpc> kTownNpcs = <TownNpc>[
  TownNpc(
    id: 'npc_taxer',
    patrolTiles: 3,
    name: 'Tax Collector',
    look: TownNpcLook.taxer,
    tileX: 34,
    tileY: 16,
    tileX2: 6,
    tileY2: 12,
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
    patrolTiles: 4,
    name: 'Shopper',
    look: TownNpcLook.customer,
    tileX: 14,
    tileY: 16,
    tileX2: 25,
    tileY2: 12,
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
    patrolTiles: 2,
    patrolHorizontal: false,
    name: 'Careful Spender',
    look: TownNpcLook.fancy,
    tileX: 22,
    tileY: 24,
    tileX2: 40,
    tileY2: 12,
    lines: [
      'I pay myself first — a slice goes to savings the day money arrives, '
          'before anything else gets a turn.',
      'The trick was never earning more. It was noticing where it went.',
      'Small amounts, tracked, beat big amounts, ignored.',
    ],
  ),
  TownNpc(
    id: 'npc_worker',
    patrolTiles: 3,
    patrolHorizontal: false,
    name: 'Shift Worker',
    look: TownNpcLook.worker,
    tileX: 33,
    tileY: 27,
    tileX2: 8,
    tileY2: 37,
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
    patrolTiles: 4,
    name: 'Student',
    look: TownNpcLook.customer,
    // Was (17, 17), which sat right against the west ledge with a solid
    // tile two rows up — the NPC sprite is ~2 tiles tall and drawn upward
    // from its feet, so its head visibly clipped into the scenery above.
    // Every NPC tile is now checked for two clear rows overhead; see
    // `test/town_map_test.dart`.
    tileX: 13,
    tileY: 27,
    tileX2: 25,
    tileY2: 37,
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
    tileX2: 41,
    tileY2: 37,
    lines: [
      'An emergency fund is boring right up until the week it saves you.',
      'Start with one month of costs. That first month changes the most.',
    ],
  ),
];

/// Where the player appears when they walk into town — just outside their
/// own front door.
///
/// **Derived from `spot_home`, not written down beside it.** This used to be
/// a hardcoded tile with a comment claiming the house was at 13,30. The house
/// was at 27,42 by then, and moved again when the markers were reassigned to
/// distinct buildings — so the constant had drifted twice, and the comment
/// documenting it was wrong both times. A spawn point that restates a
/// position owned by something else is a second copy of that position, and
/// second copies go stale silently.
///
/// Not the map centre: you leave home to go into town and come back to it,
/// so spawning in the middle of the square made the map read as a level
/// select rather than somewhere you live. `test/town_map_test.dart` checks
/// the tile is walkable, reachable, and has two clear rows overhead so the
/// sprite does not clip the house.
/// Which town a given life walks around in.
///
/// **Derived from the life, not rolled per visit.** The screen used to hold
/// `late final _townMap = TownMap.values[Random().nextInt(...)]`, with a
/// comment explaining that rolling in `build` would swap the map mid-step.
/// That reasoning was right and the scope was wrong: the field is `late
/// final` per *screen instance*, and the screen is built fresh every time you
/// walk into town. So one life could leave the village, come back, and be
/// somewhere else — reported as "why does it change in between if a run has
/// started".
///
/// A life is identified by the name and origin it was created with, both
/// fixed for its whole run, so hashing them gives one town per life with
/// nothing to store and nothing that can drift. Re-entering is the same
/// place by construction rather than by remembering.
///
/// FNV-1a rather than `Object.hash`, which Dart seeds per isolate — a map
/// chosen with that would change on every app restart, which is the same bug
/// one layer down. It has been shipped in this town once already.
TownMap townMapForLife(String lifeName, String origin) {
  var hash = 0x811c9dc5;
  for (final unit in '$lifeName|$origin'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return TownMap.values[hash % TownMap.values.length];
}

({int x, int y}) townSpawnTile(TownMap map) {
  final home = kTownSpots.firstWhere((s) => s.kind == TownSpotKind.home);
  return (x: home.xOn(map), y: home.yOn(map));
}

/// Coin pickups scattered on confirmed-walkable tiles across the open
/// middle of the map, so exploring pays a little on its own.
/// Coin pickups for the second map.
///
/// Same values as the village's, placed against map two's own collision data
/// and spread across it rather than clustered — see
/// `tool/populate_map_two.py`. Doorsteps are excluded, because a coin on a
/// shop's threshold makes "pick this up" and "walk in here" the same gesture.
const List<({int x, int y, int value})> kTownCoinsTwo =
    <({int x, int y, int value})>[
      (x: 8, y: 8, value: 3),
      (x: 25, y: 8, value: 3),
      (x: 41, y: 8, value: 3),
      (x: 8, y: 25, value: 5),
      (x: 25, y: 25, value: 5),
      (x: 41, y: 25, value: 3),
      (x: 8, y: 41, value: 5),
    ];

/// The coins for a given map.
List<({int x, int y, int value})> townCoinsFor(TownMap map) =>
    map == TownMap.village ? kTownCoins : kTownCoinsTwo;

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
