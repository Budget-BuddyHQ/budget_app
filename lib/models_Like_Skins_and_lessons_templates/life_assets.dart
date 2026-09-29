import 'dart:math';

import 'package:flutter/foundation.dart';

/// Things a life can own, and money it can owe against them.
///
/// **Asked for as:** the Assets tab, with *"real estate, vehicles, jewelry, pets
/// and investments. Tapping an asset opens options to repair, sell, upgrade or
/// mortgage it."* The only thing this game had to own was a number called
/// investments. There was nothing to buy, so there was nothing to save for, and
/// nothing for a bill to land on.
///
/// The point of owning things in a game about money is what each one teaches. A
/// car loses value every year and a house usually does not. A watch is not an
/// investment. A loan costs more than its price tag. A pet is a small, steady
/// cost for a lot of happiness. Each entry below is chosen to show one of those,
/// and the numbers are set so the difference is visible within a few years.
///
/// Pure Dart. The controller owns the state and does the paying.

enum AssetKind {
  home('Property'),
  vehicle('Vehicles'),
  pet('Pets'),
  valuable('Valuables'),
  business('Businesses');

  const AssetKind(this.label);

  final String label;
}

/// One thing that can be bought.
@immutable
class AssetDef {
  const AssetDef({
    required this.id,
    required this.kind,
    required this.name,
    required this.price,
    required this.blurb,
    this.upkeep = 0,
    this.drift = 0,
    this.swing = 0,
    this.happiness = 0,
    this.health = 0,
    this.minAge = 18,
    this.needsLicense = false,
    this.lifespan,
    this.canFinance = false,
    this.downPaymentShare = 0.15,
    this.loanYears = 5,
    this.loanRate = 0.07,
  });

  final String id;
  final AssetKind kind;
  final String name;
  final int price;
  final String blurb;

  /// Running cost per year. The number nobody puts on the price tag.
  final int upkeep;

  /// Change in value per year, as a share. Negative for something that wears
  /// out, positive for something that appreciates.
  final double drift;

  /// How much the value can wander around that trend each year, as a share. A
  /// business swings a lot, a watch a little, a house hardly at all.
  final double swing;

  /// What owning it does to happiness and health each year.
  final int happiness;
  final int health;

  final int minAge;

  /// Needs a driving license, see `LifeSimController.getLicense`.
  final bool needsLicense;

  /// Years a pet lives. Null for everything else.
  final int? lifespan;

  /// Whether it can be bought with a loan.
  final bool canFinance;

  /// The share paid up front when financed.
  final double downPaymentShare;
  final int loanYears;
  final double loanRate;

  bool get isPet => kind == AssetKind.pet;

  /// The down payment for a financed purchase.
  int get downPayment => (price * downPaymentShare).round();

  /// The amount borrowed.
  int get loanAmount => price - downPayment;
}

/// Somewhere to live that is rented, not bought.
@immutable
class RentalDef {
  const RentalDef({
    required this.id,
    required this.name,
    required this.rent,
    required this.blurb,
    this.happiness = 0,
    this.minAge = 18,
  });

  final String id;
  final String name;

  /// Per year, and part of the cost of living: it comes out of the needs slice
  /// of the budget, which is where rent belongs.
  final int rent;
  final String blurb;
  final int happiness;
  final int minAge;
}

const RentalDef kFamilyHome = RentalDef(
  id: 'family',
  name: 'Live with family',
  rent: 0,
  blurb: 'Free, and it lasts as long as your family is happy to have you.',
  minAge: 0,
);

const List<RentalDef> kRentals = <RentalDef>[
  kFamilyHome,
  RentalDef(
    id: 'shared',
    name: 'Room in a shared house',
    rent: 60,
    happiness: 1,
    blurb: 'Cheap, and you split the bills with housemates.',
  ),
  RentalDef(
    id: 'studio',
    name: 'Small apartment',
    rent: 130,
    happiness: 2,
    blurb: 'Your own front door. Most of a first salary goes here.',
  ),
  RentalDef(
    id: 'apartment',
    name: 'Nice apartment',
    rent: 220,
    happiness: 4,
    minAge: 21,
    blurb: 'More space, a better street, and a much bigger bill.',
  ),
];

RentalDef? rentalById(String id) {
  for (final r in kRentals) {
    if (r.id == id) return r;
  }
  return null;
}

/// Everything that can be bought.
const List<AssetDef> kAssets = <AssetDef>[
  // ---- Property -------------------------------------------------------------
  AssetDef(
    id: 'home_flat',
    kind: AssetKind.home,
    name: 'Starter flat',
    price: 1400,
    upkeep: 28,
    drift: 0.03,
    swing: 0.02,
    happiness: 3,
    minAge: 21,
    canFinance: true,
    downPaymentShare: 0.15,
    loanYears: 20,
    loanRate: 0.06,
    blurb: 'Small, and yours. Usually holds its value, and sometimes gains.',
  ),
  AssetDef(
    id: 'home_house',
    kind: AssetKind.home,
    name: 'Family house',
    price: 3200,
    upkeep: 64,
    drift: 0.03,
    swing: 0.025,
    happiness: 5,
    minAge: 23,
    canFinance: true,
    downPaymentShare: 0.15,
    loanYears: 20,
    loanRate: 0.06,
    blurb: 'Room to grow. The biggest purchase most people ever make.',
  ),
  AssetDef(
    id: 'home_dream',
    kind: AssetKind.home,
    name: 'Dream home',
    price: 7500,
    upkeep: 150,
    drift: 0.035,
    swing: 0.03,
    happiness: 8,
    minAge: 26,
    canFinance: true,
    downPaymentShare: 0.2,
    loanYears: 25,
    loanRate: 0.06,
    blurb: 'Everything you wanted, and a mortgage to match.',
  ),

  // ---- Vehicles: they lose value every year ---------------------------------
  AssetDef(
    id: 'veh_bike',
    kind: AssetKind.vehicle,
    name: 'Bicycle',
    price: 40,
    upkeep: 4,
    drift: -0.10,
    happiness: 1,
    health: 1,
    minAge: 8,
    blurb: 'Cheap, free to run, and good for you.',
  ),
  AssetDef(
    id: 'veh_used',
    kind: AssetKind.vehicle,
    name: 'Used car',
    price: 450,
    upkeep: 45,
    drift: -0.15,
    swing: 0.02,
    happiness: 2,
    minAge: 18,
    needsLicense: true,
    canFinance: true,
    downPaymentShare: 0.1,
    loanYears: 4,
    blurb: 'It runs. It has already lost most of what it will lose.',
  ),
  AssetDef(
    id: 'veh_family',
    kind: AssetKind.vehicle,
    name: 'Family car',
    price: 1100,
    upkeep: 60,
    drift: -0.13,
    swing: 0.02,
    happiness: 3,
    minAge: 20,
    needsLicense: true,
    canFinance: true,
    downPaymentShare: 0.1,
    loanYears: 5,
    blurb: 'Safe and roomy. Worth less every year you own it.',
  ),
  AssetDef(
    id: 'veh_sports',
    kind: AssetKind.vehicle,
    name: 'Sports car',
    price: 2600,
    upkeep: 110,
    drift: -0.14,
    swing: 0.03,
    happiness: 5,
    minAge: 21,
    needsLicense: true,
    canFinance: true,
    downPaymentShare: 0.1,
    loanYears: 6,
    blurb: 'Fast and loud. The price tag is the small part of what it costs.',
  ),

  // ---- Pets: a steady cost for a lot of happiness ----------------------------
  AssetDef(
    id: 'pet_fish',
    kind: AssetKind.pet,
    name: 'Goldfish',
    price: 12,
    upkeep: 3,
    happiness: 2,
    minAge: 6,
    lifespan: 4,
    blurb: 'Quiet company. Does not need walking.',
  ),
  AssetDef(
    id: 'pet_rabbit',
    kind: AssetKind.pet,
    name: 'Rabbit',
    price: 45,
    upkeep: 10,
    happiness: 3,
    minAge: 8,
    lifespan: 8,
    blurb: 'Soft, curious and a little bit destructive.',
  ),
  AssetDef(
    id: 'pet_cat',
    kind: AssetKind.pet,
    name: 'Cat',
    price: 70,
    upkeep: 18,
    happiness: 4,
    minAge: 8,
    lifespan: 14,
    blurb: 'Independent, and sure the house is theirs.',
  ),
  AssetDef(
    id: 'pet_dog',
    kind: AssetKind.pet,
    name: 'Dog',
    price: 130,
    upkeep: 32,
    happiness: 5,
    health: 1,
    minAge: 8,
    lifespan: 12,
    blurb: 'Loyal, and it needs walking, feeding and vet visits.',
  ),

  // ---- Valuables: things people call investments and mostly are not ----------
  AssetDef(
    id: 'val_watch',
    kind: AssetKind.valuable,
    name: 'Watch',
    price: 90,
    drift: -0.03,
    swing: 0.04,
    happiness: 1,
    minAge: 12,
    blurb: 'Nice to wear. Sells for less than you paid.',
  ),
  AssetDef(
    id: 'val_jewelry',
    kind: AssetKind.valuable,
    name: 'Jewelry',
    price: 160,
    drift: 0.01,
    swing: 0.05,
    happiness: 1,
    minAge: 16,
    blurb: 'Holds its value if you are lucky. The shop still took a margin.',
  ),
  AssetDef(
    id: 'val_art',
    kind: AssetKind.valuable,
    name: 'Framed art',
    price: 70,
    drift: 0.02,
    swing: 0.10,
    happiness: 1,
    minAge: 12,
    blurb: 'Worth what somebody will pay, which is hard to know.',
  ),
  AssetDef(
    id: 'val_cards',
    kind: AssetKind.valuable,
    name: 'Collectible cards',
    price: 40,
    drift: 0,
    swing: 0.30,
    happiness: 1,
    minAge: 9,
    blurb: 'Could double. Could be worth nothing. That is the whole point.',
  ),

  // ---- Businesses: the risky end ---------------------------------------------
  AssetDef(
    id: 'biz_stall',
    kind: AssetKind.business,
    name: 'Market stall',
    price: 250,
    happiness: 2,
    minAge: 18,
    blurb: 'Your own small business. Some years pay, some do not.',
  ),
  AssetDef(
    id: 'biz_shop',
    kind: AssetKind.business,
    name: 'Online shop',
    price: 600,
    happiness: 2,
    minAge: 18,
    blurb: 'Bigger upside, and bigger ways to lose it.',
  ),
  AssetDef(
    id: 'biz_restaurant',
    kind: AssetKind.business,
    name: 'Small restaurant',
    price: 2000,
    happiness: 3,
    minAge: 21,
    blurb: 'Long hours and thin margins. It can also be wonderful.',
  ),
];

AssetDef? assetById(String id) {
  for (final a in kAssets) {
    if (a.id == id) return a;
  }
  return null;
}

List<AssetDef> assetsOfKind(AssetKind kind) => [
  for (final a in kAssets)
    if (a.kind == kind) a,
];

/// One thing the player owns.
///
/// Mutable and owned by the controller. [uid] tells two of the same thing
/// apart, so a person with two cars can sell the right one.
class OwnedAsset {
  OwnedAsset({
    required this.uid,
    required this.def,
    required this.value,
    required this.boughtAtAge,
    this.condition = 100,
    this.loanUid,
    String? name,
  }) : name = name ?? def.name;

  final int uid;
  final AssetDef def;
  int value;
  int condition;
  final int boughtAtAge;

  /// The loan taken out to buy it, if any.
  int? loanUid;

  /// What the player calls it. A dog has a name.
  String name;

  int yearsOwned = 0;

  /// What it costs to put right, as a share of its value. Cheap things cost
  /// more to fix than they are worth, which is a lesson too.
  int get repairCost =>
      max(8, ((100 - condition) / 100 * value * 0.35).round());

  /// What renovating or upgrading costs.
  int get upgradeCost => max(20, (value * 0.25).round());

  String get conditionLabel {
    if (condition >= 80) return 'Excellent';
    if (condition >= 60) return 'Good';
    if (condition >= 40) return 'Worn';
    if (condition >= 20) return 'Poor';
    return 'Falling apart';
  }
}

/// A year of an asset's life: what it is worth afterwards and how worn it is.
///
/// A business is different from the rest: its "value" is what it would sell for,
/// and each year it earns or loses money. The caller asks [businessProfit].
({int value, int condition}) ageAsset(
  OwnedAsset asset,
  Random random, {
  bool maintained = false,
}) {
  final def = asset.def;
  final wander = def.swing == 0
      ? 0.0
      : (random.nextDouble() * 2 - 1) * def.swing;
  var value = (asset.value * (1 + def.drift + wander)).round();
  if (value < 1) value = 1;
  final wear = switch (def.kind) {
    AssetKind.vehicle => 9 + random.nextInt(6),
    AssetKind.home => 3 + random.nextInt(4),
    AssetKind.pet => 0,
    AssetKind.valuable => 1,
    AssetKind.business => 4 + random.nextInt(5),
  };
  final condition = (asset.condition - wear).clamp(0, 100);
  return (value: value, condition: condition);
}

/// A business's result for the year, as a share of what was put in.
///
/// Wide on purpose: about a third of years lose money, and the average is
/// positive but not by much. That is a small business, and it is why lending
/// yourself money for one is not the same as saving.
int businessProfit(OwnedAsset asset, Random random) {
  final share = -0.25 + random.nextDouble() * 0.85; // -25% .. +60%
  final scale = asset.def.id == 'biz_restaurant' ? 0.9 : 1.0;
  return (asset.value * share * scale).round();
}

// ---------------------------------------------------------------------------
// Loans
// ---------------------------------------------------------------------------

enum LoanKind {
  student('Student loan'),
  car('Car loan'),
  mortgage('Mortgage');

  const LoanKind(this.label);

  final String label;
}

/// Money borrowed for one purpose, at one rate, repaid over a fixed time.
///
/// Separate from the general `debt` the game already had, which is a credit
/// card in all but name at 18%. A loan for a degree or a house is cheaper and
/// slower, and seeing both side by side is how a player learns why the kind of
/// borrowing matters as much as the amount.
class Loan {
  Loan({
    required this.uid,
    required this.kind,
    required this.label,
    required this.balance,
    required this.rate,
    required this.years,
    this.deferred = false,
    this.assetUid,
  }) : yearsLeft = years,
       payment = deferred ? 0 : amortizedPayment(balance, rate, years);

  final int uid;
  final LoanKind kind;
  final String label;
  int balance;
  final double rate;
  final int years;
  int yearsLeft;

  /// The fixed yearly payment. Zero while deferred.
  int payment;

  /// A student loan does not ask for anything while the student is still in
  /// school. Interest still runs, which is the part that surprises people.
  bool deferred;

  /// The asset it was taken out against, so selling the asset can settle it.
  final int? assetUid;

  /// Starts repayment, over a fresh ten years from now.
  void startRepaying({int termYears = 10}) {
    deferred = false;
    yearsLeft = termYears;
    payment = amortizedPayment(balance, rate, termYears);
  }
}

/// The fixed yearly payment that clears [balance] in [years] at [rate].
///
/// The standard annuity formula. A payment is fixed and, at first, mostly
/// interest, which is the thing a player is meant to see when they look at how
/// slowly the balance moves in the early years.
int amortizedPayment(int balance, double rate, int years) {
  if (balance <= 0 || years <= 0) return 0;
  if (rate <= 0) return (balance / years).ceil();
  final factor = rate / (1 - pow(1 + rate, -years));
  return (balance * factor).ceil();
}

/// What one year does to a loan, before anything is paid.
///
/// Returns the interest that accrued and the payment that is due. The caller
/// takes the payment, and whatever it could not take is added back with a small
/// penalty.
({int interest, int due}) loanYear(Loan loan) {
  final interest = (loan.balance * loan.rate).round();
  if (loan.deferred) return (interest: interest, due: 0);
  final due = min(loan.payment, loan.balance + interest);
  return (interest: interest, due: due);
}
