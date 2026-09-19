part of 'life_sim_controller.dart';

/// Things owned and money owed against them, in the controller. See
/// `life_assets.dart` for the catalogue.
extension LifeSimAssets on LifeSimController {
  List<OwnedAsset> get assets => List.unmodifiable(_assets);
  List<Loan> get loans => List.unmodifiable(_loans);
  bool get hasLicense => _hasLicense;
  String get rentalId => _rentalId;

  /// The rented place the character lives in.
  RentalDef get rental => rentalById(_rentalId) ?? kFamilyHome;

  /// What everything owned is worth today, pets excluded because a pet is not
  /// something anybody could sell.
  int get assetsValue {
    var total = 0;
    for (final a in _assets) {
      if (!a.def.isPet) total += a.value;
    }
    return total;
  }

  /// Everything owed on loans, apart from the credit-card style debt.
  int get loanBalance {
    var total = 0;
    for (final l in _loans) {
      total += l.balance;
    }
    return total;
  }

  /// Everything owed, of every kind.
  int get totalOwed => _debt + loanBalance;

  bool get ownsHome => _assets.any((a) => a.def.kind == AssetKind.home);

  List<OwnedAsset> assetsOf(AssetKind kind) => [
    for (final a in _assets)
      if (a.def.kind == kind) a,
  ];

  /// Rent, which is a need. Nothing once the place is owned, and nothing while
  /// still a child.
  int get housingCost {
    if (isDependent || ownsHome) return 0;
    return rental.rent;
  }

  /// A child costs money until they are grown: the same cost of feeding and
  /// clothing that a parent carried for the player.
  int get childCost {
    var kids = 0;
    for (final p in _people) {
      if (p.kind != RelationshipKind.child || !p.isAlive) continue;
      final age = p.ageWhen(_age);
      if (age == null || age < 18) kids++;
    }
    return kids * 40;
  }

  /// Test seam: put an ordinary loan on the character without buying anything.
  /// Returns the amount borrowed.
  @visibleForTesting
  int debugAddLoanForTest({int balance = 600}) {
    _loans.add(
      Loan(
        uid: _nextUid++,
        kind: LoanKind.car,
        label: 'Car loan',
        balance: balance,
        rate: 0.07,
        years: 5,
      ),
    );
    return balance;
  }

  // ---- Licence ----------------------------------------------------------------

  String? licenseGate() {
    if (finished) return 'This life is over';
    if (_hasLicense) return 'You already have one';
    if (_age < 16) return 'You need to be 16';
    if (_money < 40) return 'The test costs 40 coins';
    return null;
  }

  /// Passing the driving test. Needed before any car can be bought.
  bool getLicense() {
    if (licenseGate() != null) return false;
    _money -= 40;
    _hasLicense = true;
    _happiness = _clamp(_happiness + 5);
    _setLog(
      'You passed your driving test on the first try. A car is now possible, '
      'and so is the cost of one.',
      kind: LifeLogKind.life,
    );
    _changed();
    return true;
  }

  // ---- Where to live -----------------------------------------------------------

  String? moveGate(RentalDef place) {
    if (finished) return 'This life is over';
    if (place.id == _rentalId) return 'You already live here';
    if (_age < place.minAge) return 'You need to be ${place.minAge}';
    if (ownsHome) return 'You own your home';
    if (place.id == kFamilyHome.id) {
      final family = _people.any(
        (p) => p.kind == RelationshipKind.family && p.isAlive,
      );
      if (!family) return 'There is nobody to move back in with';
    }
    return null;
  }

  bool moveTo(RentalDef place) {
    if (moveGate(place) != null) return false;
    _moveIn(place.id);
    _changed();
    return true;
  }

  void _moveIn(String id) {
    final place = rentalById(id);
    if (place == null || id == _rentalId) return;
    final movingOut = _rentalId == kFamilyHome.id && id != kFamilyHome.id;
    _rentalId = id;
    if (place.rent == 0) {
      _setLog(
        'You moved back in with your family. It is free, and it is allowed.',
        kind: LifeLogKind.life,
      );
      return;
    }
    _happiness = _clamp(_happiness + (movingOut ? 6 : 1));
    _setLog(
      'You moved into ${place.name}. Rent is ${place.rent} a year, which comes '
      'out of the needs part of your budget.',
      kind: LifeLogKind.life,
    );
    _teach(FinanceConcept.needsVsWants);
  }

  // ---- Buying -------------------------------------------------------------------

  /// Why [def] cannot be bought right now, or null.
  String? buyGate(AssetDef def, {bool financed = false}) {
    if (finished) return 'This life is over';
    if (_age < def.minAge) return 'You need to be ${def.minAge}';
    if (def.needsLicense && !_hasLicense) return 'You need a driving licence';
    if (financed) {
      if (!def.canFinance) return 'This cannot be bought on a loan';
      if (isDependent) return 'You cannot borrow yet';
      if (_money < def.downPayment) {
        return 'The down payment is ${def.downPayment}. You have $_money';
      }
      if (_salary <= 0) return 'A lender wants to see an income';
    } else if (_money < def.price) {
      return 'It costs ${def.price}. You have $_money in cash';
    }
    return null;
  }

  /// Buys [def], outright or on a loan.
  ///
  /// A loan puts the down payment down now and borrows the rest at the asset's
  /// rate over its term. It costs more than the price in the end, and that
  /// difference is shown on the screen before anything is signed.
  OwnedAsset? buyAsset(AssetDef def, {bool financed = false, String? name}) {
    if (buyGate(def, financed: financed) != null) return null;
    final uid = _nextUid++;
    int? loanUid;
    if (financed) {
      _money -= def.downPayment;
      final loan = Loan(
        uid: _nextUid++,
        kind: def.kind == AssetKind.home ? LoanKind.mortgage : LoanKind.car,
        label: def.kind == AssetKind.home ? 'Mortgage' : 'Car loan',
        balance: def.loanAmount,
        rate: def.loanRate,
        years: def.loanYears,
        assetUid: uid,
      );
      loanUid = loan.uid;
      _loans.add(loan);
      _teach(FinanceConcept.interestCost);
    } else {
      _money -= def.price;
    }
    final owned = OwnedAsset(
      uid: uid,
      def: def,
      value: def.price,
      boughtAtAge: _age,
      loanUid: loanUid,
      name: name,
    );
    _assets.add(owned);
    _assetsBought++;
    _happiness = _clamp(_happiness + 5);
    if (def.kind == AssetKind.home && _rentalId != kFamilyHome.id) {
      _rentalId = kFamilyHome.id;
    }
    _setLog(
      financed
          ? 'You bought ${owned.name} on a loan: ${def.downPayment} down, '
                '${def.loanAmount} borrowed at '
                '${(def.loanRate * 100).round()}% over ${def.loanYears} years.'
          : 'You bought ${owned.name} for ${def.price}.',
      kind: LifeLogKind.money,
    );
    if (def.kind == AssetKind.vehicle || def.kind == AssetKind.valuable) {
      _teach(FinanceConcept.sunkCost);
    }
    _changed();
    return owned;
  }

  OwnedAsset? _assetByUid(int uid) {
    for (final a in _assets) {
      if (a.uid == uid) return a;
    }
    return null;
  }

  Loan? _loanByUid(int? uid) {
    if (uid == null) return null;
    for (final l in _loans) {
      if (l.uid == uid) return l;
    }
    return null;
  }

  /// What selling would bring in. Below the value, because that is what a
  /// dealer, an agent or a pawn shop does, and the gap is part of the lesson.
  int saleValue(OwnedAsset asset) {
    final factor = switch (asset.def.kind) {
      AssetKind.vehicle => 0.95,
      AssetKind.valuable => 0.85,
      AssetKind.home => 0.94,
      AssetKind.business => 0.85,
      AssetKind.pet => 0.0,
    };
    return (asset.value * factor).round();
  }

  /// Sells, or for a pet finds it a new home. Any loan against it is settled
  /// from the money, and if the money does not cover it the rest is owed.
  bool sellAsset(int uid) {
    final asset = _assetByUid(uid);
    if (asset == null || finished) return false;
    final proceeds = saleValue(asset);
    final loan = _loanByUid(asset.loanUid);
    var note = '';
    var net = proceeds;
    if (loan != null) {
      final owed = loan.balance;
      net = proceeds - owed;
      _loans.remove(loan);
      note = net < 0
          ? ' You owed ${owed - proceeds} more than it sold for, and that is now '
                'debt.'
          : ' The loan of $owed was cleared from the sale.';
    }
    _assets.remove(asset);
    if (net >= 0) {
      _money += net;
    } else {
      _debt += -net;
    }
    if (asset.def.isPet) {
      _happiness = _clamp(_happiness - 6);
      _setLog(
        'You found ${asset.name} a good new home. It was the right call and it '
        'still hurt.',
        kind: LifeLogKind.life,
      );
    } else {
      _setLog(
        'You sold ${asset.name} for $proceeds. You paid '
        '${asset.def.price}.$note',
        kind: LifeLogKind.money,
      );
      _teach(
        asset.def.drift < 0
            ? FinanceConcept.sunkCost
            : FinanceConcept.incomeVsWealth,
      );
    }
    _changed();
    return true;
  }

  /// Puts an asset right. For a pet that is a vet visit.
  bool repairAsset(int uid) {
    final asset = _assetByUid(uid);
    if (asset == null || finished) return false;
    final cost = asset.def.isPet ? max(15, asset.def.upkeep) : asset.repairCost;
    if (asset.condition >= 95) {
      _setLog(
        '${asset.name} is fine and needs nothing.',
        kind: LifeLogKind.life,
      );
      _changed();
      return false;
    }
    if (_money < cost) {
      _setLog(
        'Putting ${asset.name} right costs $cost and you have $_money.',
        kind: LifeLogKind.money,
      );
      _changed();
      return false;
    }
    _money -= cost;
    asset.condition = (asset.condition + 45).clamp(0, 100);
    _setLog(
      asset.def.isPet
          ? 'A visit to the vet for ${asset.name}: $cost. Looking after '
                'something costs money, and it is cheaper than the alternative.'
          : 'You had ${asset.name} repaired for $cost. Small repairs now cost '
                'less than big ones later.',
      kind: LifeLogKind.money,
    );
    _changed();
    return true;
  }

  /// Renovates or upgrades. Costs a quarter of the value, puts the condition
  /// right and adds a fifth to the value, which is a poor return on paper and
  /// the reason people are careful about it.
  bool upgradeAsset(int uid) {
    final asset = _assetByUid(uid);
    if (asset == null || finished || asset.def.isPet) return false;
    final cost = asset.upgradeCost;
    if (_money < cost) {
      _setLog(
        'Upgrading ${asset.name} costs $cost and you have $_money.',
        kind: LifeLogKind.money,
      );
      _changed();
      return false;
    }
    _money -= cost;
    asset.value = (asset.value * 1.2).round();
    asset.condition = 100;
    _happiness = _clamp(_happiness + 3);
    _setLog(
      'You upgraded ${asset.name} for $cost. It is now worth ${asset.value}. '
      'Money spent on something is not always money gained.',
      kind: LifeLogKind.money,
    );
    _changed();
    return true;
  }

  /// Pays down a loan from cash, then savings. Pays it off completely when the
  /// amount is at least the balance.
  int payLoan(int loanUid, [int? amount]) {
    final loan = _loanByUid(loanUid);
    if (loan == null || finished) return 0;
    final want = (amount ?? loan.balance).clamp(1, loan.balance);
    final fromCash = want.clamp(0, _money);
    final fromFund = (want - fromCash).clamp(0, _emergencyFund);
    final paid = fromCash + fromFund;
    if (paid <= 0) {
      _setLog('You have nothing to pay it with yet.', kind: LifeLogKind.money);
      _changed();
      return 0;
    }
    _money -= fromCash;
    _emergencyFund -= fromFund;
    loan.balance -= paid;
    _debtRepaid += paid;
    if (loan.balance <= 0) {
      _clearLoan(loan);
    } else {
      _setLog(
        'You paid $paid off the ${loan.label.toLowerCase()}. Still owing '
        '${loan.balance}.',
        kind: LifeLogKind.money,
      );
    }
    _changed();
    return paid;
  }

  void _clearLoan(Loan loan) {
    _loans.remove(loan);
    for (final a in _assets) {
      if (a.loanUid == loan.uid) a.loanUid = null;
    }
    _happiness = _clamp(_happiness + 4);
    _setLog(
      'You paid off the ${loan.label.toLowerCase()}. That is one less thing '
      'taking a slice of every year.',
      kind: LifeLogKind.money,
    );
  }

  // ---- Moving money between pots ---------------------------------------------------

  /// Savings to cash. The fund is for emergencies, and the game lets it be spent
  /// on anything, which is what people do and is worth feeling.
  int withdrawSavings(int amount) {
    if (finished || amount <= 0) return 0;
    final moved = amount.clamp(0, _emergencyFund);
    if (moved <= 0) return 0;
    _emergencyFund -= moved;
    _money += moved;
    _setLog(
      'You moved $moved from savings into cash. It is easier to spend when it '
      'is in your pocket.',
      kind: LifeLogKind.money,
    );
    _changed();
    return moved;
  }

  /// Cash to savings.
  int depositSavings(int amount) {
    if (finished || amount <= 0 || _age < 16) return 0;
    final moved = amount.clamp(0, _money);
    if (moved <= 0) return 0;
    _money -= moved;
    _emergencyFund += moved;
    _savedTotal += moved;
    _setLog(
      'You put $moved into savings, where it is harder to spend by accident.',
      kind: LifeLogKind.money,
    );
    _teach(FinanceConcept.payYourselfFirst);
    _changed();
    return moved;
  }

  /// Investments back to cash. Selling early is allowed, and the market's
  /// growth is lost from that day.
  int withdrawInvestments(int amount) {
    if (finished || amount <= 0) return 0;
    final moved = amount.clamp(0, _investments);
    if (moved <= 0) return 0;
    _investments -= moved;
    _money += moved;
    _setLog(
      'You sold $moved of your investments. It stops growing from today.',
      kind: LifeLogKind.money,
    );
    _changed();
    return moved;
  }

  // ---- The year ------------------------------------------------------------------

  /// What a year does to everything owned: value, wear, running costs, the
  /// happiness it brings, and what a pet or a business does.
  void _ageAssets() {
    if (_assets.isEmpty) return;
    var joy = 0;
    var wellbeing = 0;
    var upkeep = 0;
    final gone = <OwnedAsset>[];
    for (final asset in List<OwnedAsset>.of(_assets)) {
      final aged = ageAsset(asset, _random);
      asset.value = aged.value;
      asset.condition = aged.condition;
      asset.yearsOwned++;
      joy += asset.def.happiness;
      wellbeing += asset.def.health;
      if (!isDependent) upkeep += asset.def.upkeep;

      if (asset.def.kind == AssetKind.business) {
        final profit = businessProfit(asset, _random);
        if (profit >= 0) {
          _money += profit;
          _setLog(
            'Your ${asset.name} made $profit this year.',
            kind: LifeLogKind.money,
          );
        } else {
          _applyEventMoney(profit);
          _setLog(
            'Your ${asset.name} lost ${-profit} this year. Some years do. '
            'That is what the risk is.',
            kind: LifeLogKind.shock,
          );
        }
        _teach(FinanceConcept.diversification);
      }

      if (asset.def.isPet) {
        final span = asset.def.lifespan ?? 12;
        if (asset.yearsOwned >= span || asset.condition <= 0) {
          gone.add(asset);
        }
      } else if (asset.def.kind == AssetKind.vehicle && asset.condition < 30) {
        if (_random.nextInt(100) < 35) {
          final cost = max(20, (asset.value * 0.2).round());
          applyShock(cost, '${asset.name} broke down');
        }
      } else if (asset.def.kind == AssetKind.home && asset.condition < 30) {
        if (_random.nextInt(100) < 25) {
          final cost = max(40, (asset.value * 0.05).round());
          applyShock(cost, 'A repair on ${asset.name}');
        }
      }
    }

    if (joy != 0) _happiness = _clamp(_happiness + joy.clamp(-4, 8));
    if (wellbeing != 0) _health = _clamp(_health + wellbeing.clamp(-3, 3));

    if (upkeep > 0) {
      _applyEventMoney(-upkeep);
      _setLog(
        'What you own cost $upkeep to keep this year: insurance, fuel, food '
        'and repairs. The price tag was only the start.',
        kind: LifeLogKind.money,
      );
      _teach(FinanceConcept.lifestyleCreep);
    }

    for (final pet in gone) {
      _assets.remove(pet);
      _queuedEvents.add(
        petLossEvent(
          petName: pet.name,
          kind: pet.def.name.toLowerCase(),
          playerAge: _age,
        ),
      );
    }
  }

  /// Interest and payments on every loan, for a year.
  ///
  /// [fromPay] is what this year's paycheck can put towards them. Anything more
  /// comes from cash, then savings, and whatever is still missing is added to
  /// the loan with a small penalty, which is what a missed payment costs. It
  /// returns how much of the paycheck was taken.
  int _settleLoans(int fromPay) {
    if (_loans.isEmpty) return 0;
    var takenFromPay = 0;
    var available = fromPay;
    for (final loan in List<Loan>.of(_loans)) {
      final year = loanYear(loan);
      loan.balance += year.interest;
      _interestPaid += year.interest;
      if (loan.deferred) continue;
      var due = year.due;
      final fromPaycheck = due.clamp(0, available);
      available -= fromPaycheck;
      takenFromPay += fromPaycheck;
      due -= fromPaycheck;
      final fromCash = due.clamp(0, _money);
      _money -= fromCash;
      due -= fromCash;
      final fromFund = due.clamp(0, _emergencyFund);
      _emergencyFund -= fromFund;
      due -= fromFund;
      final paid = year.due - due;
      loan.balance -= paid;
      loan.yearsLeft--;
      if (due > 0) {
        final penalty = max(1, (due * 0.05).round());
        loan.balance += penalty;
        _happiness = _clamp(_happiness - 4);
        _setLog(
          'You could not make the whole payment on your '
          '${loan.label.toLowerCase()}. $due went unpaid and a $penalty late '
          'fee was added. Missing payments is expensive.',
          kind: LifeLogKind.shock,
        );
        _teach(FinanceConcept.creditScore);
      }
      if (loan.balance <= 0) {
        _clearLoan(loan);
      } else if (loan.yearsLeft <= 0) {
        // The term is up. Whatever is left is due, so it moves to the general
        // debt where it keeps costing.
        _debt += loan.balance;
        _loans.remove(loan);
        _setLog(
          'The term on your ${loan.label.toLowerCase()} ended with ${loan.balance} '
          'still owing, and it has moved to your general debt.',
          kind: LifeLogKind.shock,
        );
      }
    }
    return takenFromPay;
  }
}
