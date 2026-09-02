import 'dart:math';

import 'package:flutter/material.dart';

import 'town_spot_models.dart';

/// What the town is like today.
///
/// **The problem.** The town resets every time you walk in, and the scene
/// behind each door rotates with the day and your age — so it was already not
/// the same twice. It still *read* the same, because nothing on screen ever
/// said so. A place that changes invisibly is indistinguishable from a place
/// that does not change, and it was reported, fairly, as a map with nothing
/// going on.
///
/// **What this adds.** One line at the top of the map saying what today is,
/// and prices that follow it. That does two things at once: it gives you a
/// reason to look around before spending, and it teaches the thing a static
/// price list cannot — that **the same item costs different amounts on
/// different days**, and that noticing is worth money.
///
/// It is the groundwork for comparison shopping, sales, and inflation, none
/// of which land as a sentence in a lesson. A player who learns to check the
/// banner before buying food has learned to check the shelf label.
///
/// **Ordinary days are the common case on purpose.** If every visit were an
/// event, none of them would be. [ordinary] carries more weight than the rest
/// put together, so a market day is something you notice.
@immutable
class TownCondition {
  const TownCondition({
    required this.id,
    required this.label,
    required this.note,
    required this.icon,
    required this.accent,
    required this.weight,
    this.cheaper = const <TownSpotKind>{},
    this.dearer = const <TownSpotKind>{},
    this.paysMore = const <TownSpotKind>{},
  });

  final String id;

  /// Short enough for the map banner, which sits over the tiles.
  final String label;

  /// The sentence under it. Says what it means for your money rather than
  /// setting a scene — "food is cheaper here today" is useful; "the stalls
  /// are bustling" is decoration.
  final String note;

  final IconData icon;
  final Color accent;

  /// Relative likelihood. See the class note on why [ordinary] dominates.
  final double weight;

  /// Where things cost less today.
  final Set<TownSpotKind> cheaper;

  /// Where they cost more.
  final Set<TownSpotKind> dearer;

  /// Where *selling* gets you more — the pawn shop, mostly. Separate from
  /// [cheaper] because they move opposite ways: a good day to sell is a bad
  /// day to buy, and collapsing them into one multiplier would quietly teach
  /// that a shop's prices and its offers rise together.
  final Set<TownSpotKind> paysMore;

  bool get isOrdinary => cheaper.isEmpty && dearer.isEmpty && paysMore.isEmpty;

  /// [amount] adjusted for today, at a [kind] of building.
  ///
  /// Signs matter here and they are easy to get backwards. A negative amount
  /// is money leaving you, so "cheaper" means moving it *towards* zero; a
  /// positive amount is money arriving, and only [paysMore] touches those.
  int priceFor(int amount, TownSpotKind kind) {
    if (amount == 0) return 0;
    if (amount > 0) {
      return paysMore.contains(kind) ? (amount * 1.4).round() : amount;
    }
    if (cheaper.contains(kind)) return (amount * 0.7).round();
    if (dearer.contains(kind)) return (amount * 1.25).round();
    return amount;
  }

  /// A one-line hint for a spot, or null when today changes nothing there.
  ///
  /// Shown on the interaction sheet rather than only on the banner, because
  /// the banner is at the top of the map and the decision happens at the
  /// door — by the time somebody is choosing whether to buy lunch, the line
  /// telling them lunch is cheap today has scrolled out of their attention.
  String? hintFor(TownSpotKind kind) {
    if (cheaper.contains(kind)) return 'Cheaper than usual today.';
    if (dearer.contains(kind)) return 'Dearer than usual today.';
    if (paysMore.contains(kind)) return 'Paying more than usual today.';
    return null;
  }
}

const List<TownCondition> kTownConditions = <TownCondition>[
  TownCondition(
    id: 'ordinary',
    label: 'An ordinary day',
    note: 'Nothing special going on. Prices are what they usually are.',
    icon: Icons.wb_sunny_rounded,
    accent: Color(0xFF85EFAC),
    // Heavier than everything else combined. A town where something is always
    // happening is a town where nothing is.
    weight: 5.0,
  ),
  TownCondition(
    id: 'market_day',
    label: 'Market day',
    note: 'The stalls are out and food is cheaper than usual. Worth doing '
        'your shopping now if you can.',
    icon: Icons.storefront_rounded,
    accent: Color(0xFF9CCC65),
    weight: 1.6,
    cheaper: <TownSpotKind>{TownSpotKind.market, TownSpotKind.cafe},
  ),
  TownCondition(
    id: 'sale',
    label: 'Sale at the store',
    note: 'Everything in the shop is marked down. A sale makes things '
        'cheaper — it does not make them things you need.',
    icon: Icons.sell_rounded,
    accent: Color(0xFFFFD45C),
    weight: 1.4,
    cheaper: <TownSpotKind>{TownSpotKind.store},
  ),
  TownCondition(
    id: 'quiet_week',
    label: 'A quiet week',
    note: 'The pawn shop is short of stock and paying over the odds. Selling '
        'is worth more today than it will be next week.',
    icon: Icons.watch_rounded,
    accent: Color(0xFFCE93D8),
    weight: 1.2,
    paysMore: <TownSpotKind>{TownSpotKind.pawnShop},
  ),
  TownCondition(
    id: 'prices_up',
    label: 'Prices have gone up',
    note: 'Food and fuel cost more this month than last. Nobody decided it '
        'and nobody announced it — that is what inflation looks like.',
    icon: Icons.trending_up_rounded,
    accent: Color(0xFFFF8474),
    weight: 1.3,
    dearer: <TownSpotKind>{
      TownSpotKind.market,
      TownSpotKind.cafe,
      TownSpotKind.store,
    },
  ),
  TownCondition(
    id: 'clinic_free',
    label: 'Free check-ups',
    note: 'The clinic is running a free day. The thing you have been putting '
        'off because of the cost costs nothing today.',
    icon: Icons.local_hospital_rounded,
    accent: Color(0xFFFF8A80),
    weight: 1.0,
    cheaper: <TownSpotKind>{TownSpotKind.clinic},
  ),
  TownCondition(
    id: 'rain',
    label: 'Pouring with rain',
    note: 'The cafe is packed and charging for it. The library is dry, warm '
        'and still free.',
    icon: Icons.water_drop_rounded,
    accent: Color(0xFF69C6FF),
    weight: 1.2,
    dearer: <TownSpotKind>{TownSpotKind.cafe},
  ),
];

/// The condition for one visit.
///
/// Takes a [Random] rather than reading the clock so a test can pin it, and
/// so the caller decides what "a visit" means. Rolled once when the town
/// opens and held for as long as you are in it — re-rolling on rebuild would
/// change the weather every time the player took a step.
TownCondition rollTownCondition(Random random) {
  final total = kTownConditions.fold<double>(0, (sum, c) => sum + c.weight);
  var roll = random.nextDouble() * total;
  for (final condition in kTownConditions) {
    roll -= condition.weight;
    if (roll <= 0) return condition;
  }
  return kTownConditions.first;
}

/// Looked up by id, for restoring a pinned condition.
TownCondition townConditionById(String id) => kTownConditions.firstWhere(
  (c) => c.id == id,
  orElse: () => kTownConditions.first,
);
