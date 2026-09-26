import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';

import 'support/fixed_random.dart';

/// Things owned, and money owed against them.
///
/// **Asked for as:** the Assets tab, with *"real estate, vehicles, jewelry, pets
/// and investments. Tapping an asset opens options to repair, sell, upgrade or
/// mortgage it."* The only thing this game had to own was one number.
void main() {
  LifeSimController person({
    int age = 30,
    int money = 5000,
    int salary = 0,
    bool lucky = false,
  }) => LifeSimController(
    random: lucky ? FixedRandom.lucky() : FixedRandom.unlucky(),
    name: 'Tester',
    initialAge: age,
    startMoney: money,
    startJob: salary > 0 ? 'Barista' : null,
    startSalary: salary,
  );

  AssetDef asset(String id) => assetById(id)!;

  void year(LifeSimController life) {
    life.ageUp();
    life.debugClearEvent();
  }

  String feed(LifeSimController life) =>
      life.history.map((e) => e.text).join(' | ');

  group('the catalogue', () {
    test('has unique ids and honest numbers', () {
      final ids = <String>{};
      for (final a in kAssets) {
        expect(ids.add(a.id), isTrue, reason: 'duplicate ${a.id}');
        expect(a.price, greaterThan(0));
        expect(a.downPayment + a.loanAmount, a.price, reason: a.id);
      }
    });

    test('a vehicle loses value and a home gains, which is the point', () {
      for (final a in assetsOfKind(AssetKind.vehicle)) {
        expect(a.drift, lessThan(0), reason: '${a.name} should wear out');
      }
      for (final a in assetsOfKind(AssetKind.home)) {
        expect(a.drift, greaterThan(0), reason: '${a.name} should hold up');
      }
    });

    test('a pet has a lifespan and no resale value', () {
      for (final a in assetsOfKind(AssetKind.pet)) {
        expect(a.lifespan, isNotNull, reason: a.name);
        expect(a.upkeep, greaterThan(0));
      }
    });

    test('a car needs a licence, a bicycle does not', () {
      expect(asset('veh_used').needsLicense, isTrue);
      expect(asset('veh_bike').needsLicense, isFalse);
    });

    test('everything that can be financed has a sensible loan', () {
      for (final a in kAssets.where((a) => a.canFinance)) {
        expect(a.loanYears, greaterThan(0), reason: a.name);
        expect(a.loanRate, inInclusiveRange(0.03, 0.12), reason: a.name);
      }
    });

    test('the five kinds are all there to buy', () {
      for (final kind in AssetKind.values) {
        expect(assetsOfKind(kind), isNotEmpty, reason: kind.label);
      }
    });
  });

  group('a loan', () {
    test('the fixed payment follows the standard formula', () {
      // 1000 at 6% over 10 years is 135.87 a year, rounded up.
      expect(amortizedPayment(1000, 0.06, 10), 136);
      expect(amortizedPayment(1200, 0, 12), 100);
      expect(amortizedPayment(0, 0.06, 10), 0);
    });

    test('costs more in total than the price, and that is shown', () {
      final payment = amortizedPayment(2000, 0.07, 5);
      expect(payment * 5, greaterThan(2000));
    });

    test('a student loan waits, then starts', () {
      final loan = Loan(
        uid: 1,
        kind: LoanKind.student,
        label: 'Student loan',
        balance: 1000,
        rate: 0.05,
        years: 10,
        deferred: true,
      );
      expect(loan.payment, 0);
      final waiting = loanYear(loan);
      expect(waiting.due, 0);
      expect(waiting.interest, 50, reason: 'interest still runs while waiting');

      loan.startRepaying();
      expect(loan.deferred, isFalse);
      expect(loan.payment, greaterThan(0));
    });
  });

  group('buying', () {
    test('with cash takes the price and adds the asset', () {
      final life = person();
      final before = life.netWorth;
      final owned = life.buyAsset(asset('val_watch'));

      expect(owned, isNotNull);
      expect(life.money, 5000 - 90);
      expect(life.assets.single.name, 'Watch');
      expect(life.assetsValue, 90);
      expect(life.netWorth, before, reason: 'cash became something else');
    });

    test('says why it cannot, in the numbers of this life', () {
      final broke = person(money: 100);
      expect(broke.buyGate(asset('veh_family')), 'You need a driving licence');
      expect(broke.buyGate(asset('home_flat')), contains('It costs 1400'));

      final child = person(age: 7);
      expect(child.buyGate(asset('pet_dog')), 'You need to be 8');
    });

    test('a car needs the licence first, and the test costs money', () {
      final life = person(money: 2000);
      expect(life.buyAsset(asset('veh_used')), isNull);
      expect(life.licenseGate(), isNull);
      expect(life.getLicense(), isTrue);
      expect(life.money, 1960);
      expect(life.hasLicense, isTrue);
      expect(life.buyAsset(asset('veh_used')), isNotNull);
      expect(life.getLicense(), isFalse, reason: 'only one licence');
    });

    test('nobody under sixteen can take the test', () {
      expect(person(age: 15).licenseGate(), 'You need to be 16');
    });

    test('a mortgage: 15% down, the rest borrowed at its own rate', () {
      final life = person(age: 30, money: 5000, salary: 800);
      final flat = asset('home_flat'); // 1400, 15% down
      final owned = life.buyAsset(flat, financed: true)!;

      expect(life.money, 5000 - 210);
      final loan = life.loans.single;
      expect(loan.kind, LoanKind.mortgage);
      expect(loan.balance, 1190);
      expect(loan.rate, 0.06);
      expect(owned.loanUid, loan.uid);
      expect(life.netWorth, 5000 - 210 + 1400 - 1190 + life.emergencyFund);
      expect(life.conceptsMet, contains(FinanceConcept.interestCost));
    });

    test('a lender wants to see an income', () {
      final life = person(salary: 0);
      expect(
        life.buyGate(asset('home_flat'), financed: true),
        'A lender wants to see an income',
      );
    });

    test('buying a home ends the rent', () {
      final life = person(salary: 800)..moveTo(kRentals[2]);
      expect(life.housingCost, 130);
      life.buyAsset(asset('home_flat'));
      expect(life.ownsHome, isTrue);
      expect(life.housingCost, 0);
      expect(life.rentalId, kFamilyHome.id);
    });

    test('a child can have a pet and a bicycle and not much else', () {
      final kid = person(age: 10, money: 500);
      expect(kid.buyGate(asset('pet_cat')), isNull);
      expect(kid.buyGate(asset('veh_bike')), isNull);
      expect(kid.buyGate(asset('home_flat')), contains('21'));
      expect(kid.buyGate(asset('veh_used')), contains('18'));
    });
  });

  group('the years', () {
    test('a car is worth less every year and a flat is not', () {
      final life = person(money: 9000);
      life.getLicense();
      life.buyAsset(asset('veh_used'));
      life.buyAsset(asset('home_flat'));
      for (var i = 0; i < 3; i++) {
        year(life);
      }
      final car = life.assetsOf(AssetKind.vehicle).single;
      final home = life.assetsOf(AssetKind.home).single;
      expect(car.value, lessThan(450 * 0.7));
      expect(home.value, greaterThanOrEqualTo(1400 * 0.95));
    });

    test('things wear, and say so', () {
      final life = person(money: 9000);
      life.getLicense();
      life.buyAsset(asset('veh_used'));
      final car = life.assetsOf(AssetKind.vehicle).single;
      expect(car.condition, 100);
      expect(car.conditionLabel, 'Excellent');
      for (var i = 0; i < 4; i++) {
        year(life);
      }
      expect(car.condition, lessThan(70));
    });

    test(
      'the running cost is named, because the price tag was only the start',
      () {
        final life = person(money: 9000);
        life.getLicense();
        life.buyAsset(asset('veh_used')); // 45 a year
        year(life);
        expect(feed(life), contains('cost 45 to keep'));
      },
    );

    test('a pet lives its span and its passing is written gently', () {
      final life = person(money: 500);
      life.buyAsset(asset('pet_fish'), name: 'Bubbles'); // lives 4 years
      String? card;
      for (var i = 0; i < 5; i++) {
        life.ageUp();
        final e = life.currentEvent;
        if (e != null && e.id.startsWith('pet_loss')) card = e.prompt;
        life.debugClearEvent();
      }
      expect(life.assets, isEmpty);
      expect(card, isNotNull);
      expect(card, contains('Bubbles'));
      expect(card, contains('good life'));
    });

    test('a business can lose money, and says that is the risk', () {
      final good = person(money: 2000)..buyAsset(asset('biz_stall'));
      final bad = person(money: 2000, lucky: true)
        ..buyAsset(asset('biz_stall'));
      final goodBefore = good.money;
      final badBefore = bad.money;
      year(good);
      year(bad);
      expect(good.money, greaterThan(goodBefore));
      expect(bad.money, lessThan(badBefore));
      expect(feed(bad), contains('That is what the risk is'));
    });

    test('a loan payment comes out of pay before the budget splits it', () {
      final withLoan = person(money: 5000, salary: 800);
      final without = person(money: 5000, salary: 800);
      withLoan.buyAsset(asset('home_flat'), financed: true);
      without.buyAsset(asset('home_flat'));
      year(withLoan);
      year(without);
      expect(
        withLoan.emergencyFund,
        lessThan(without.emergencyFund),
        reason: 'the payment took a share of the pay first',
      );
    });

    test('a loan is paid down over its term', () {
      final life = person(money: 5000, salary: 800);
      life.buyAsset(asset('home_flat'), financed: true);
      final start = life.loanBalance;
      year(life);
      final loan = life.loans.single;
      expect(loan.yearsLeft, 19);
      // The payment is mostly interest at first, so the balance barely moves.
      expect(loan.balance, lessThan(start));
      expect(loan.balance, greaterThan(start * 0.9));
    });

    test('a missed payment adds a fee and hurts', () {
      final life = person(money: 500, salary: 0);
      // No income and no cash, with a loan that is asking for a payment.
      final owed = life.debugAddLoanForTest();
      life.debugSetStats(money: 0);
      final before = life.happiness;
      year(life);
      expect(feed(life), contains('late fee'));
      expect(life.loanBalance, greaterThan(owed));
      expect(life.happiness, lessThan(before));
    });
  });

  group('looking after it', () {
    test('a repair costs a share of the value and puts the condition back', () {
      final life = person(money: 9000);
      life.getLicense();
      life.buyAsset(asset('veh_used'));
      for (var i = 0; i < 4; i++) {
        year(life);
      }
      final car = life.assets.single;
      final before = car.condition;
      final cost = car.repairCost;
      final cash = life.money;
      expect(life.repairAsset(car.uid), isTrue);
      expect(car.condition, before + 45);
      expect(life.money, cash - cost);
    });

    test('something in good condition needs nothing', () {
      final life = person();
      life.buyAsset(asset('val_watch'));
      expect(life.repairAsset(life.assets.single.uid), isFalse);
    });

    test('a vet visit is a repair for a pet', () {
      final life = person();
      life.buyAsset(asset('pet_dog'));
      final dog = life.assets.single;
      dog.condition = 40;
      expect(life.repairAsset(dog.uid), isTrue);
      expect(dog.condition, 85);
      expect(feed(life), contains('vet'));
    });

    test('an upgrade costs a quarter and adds a fifth, a poor return', () {
      final life = person();
      life.buyAsset(asset('home_flat'));
      final home = life.assets.single;
      final cash = life.money;
      expect(home.upgradeCost, 350);
      expect(life.upgradeAsset(home.uid), isTrue);
      expect(home.value, 1680);
      expect(life.money, cash - 350);
      expect(1680 - 1400, lessThan(350), reason: 'costs more than it adds');
    });
  });

  group('selling', () {
    test('brings in less than the value, because of the dealer', () {
      final life = person();
      life.buyAsset(asset('val_watch'));
      final owned = life.assets.single;
      expect(life.saleValue(owned), 77); // 85% of 90
      final cash = life.money;
      expect(life.sellAsset(owned.uid), isTrue);
      expect(life.money, cash + 77);
      expect(life.assets, isEmpty);
      expect(feed(life), contains('You paid 90'));
    });

    test('settles the loan from the money', () {
      final life = person(money: 5000, salary: 800);
      life.buyAsset(asset('home_flat'), financed: true);
      final owned = life.assets.single;
      final cash = life.money;
      life.sellAsset(owned.uid);
      // 94% of 1400 is 1316, less the 1190 loan.
      expect(life.money, cash + 126);
      expect(life.loans, isEmpty);
    });

    test('selling underwater leaves a debt, which is the lesson', () {
      final life = person(money: 5000, salary: 800);
      life.buyAsset(asset('home_flat'), financed: true);
      final owned = life.assets.single;
      owned.value = 800; // the market fell
      final debt = life.debt;
      life.sellAsset(owned.uid);
      expect(life.debt, greaterThan(debt));
      expect(feed(life), contains('now debt'));
    });

    test('a pet is rehomed, not sold', () {
      final life = person();
      life.buyAsset(asset('pet_cat'));
      final cash = life.money;
      final joy = life.happiness;
      life.sellAsset(life.assets.single.uid);
      expect(life.money, cash);
      expect(life.happiness, lessThan(joy));
      expect(feed(life), contains('new home'));
    });
  });

  group('where you live', () {
    test('renting is a need, so it lives in the cost of living', () {
      final life = person(money: 500, salary: 800);
      final base = life.housingCost;
      life.moveTo(kRentals[2]); // 130
      expect(life.housingCost, base + 130);
      expect(life.rental.name, 'Small apartment');
    });

    test('says why not', () {
      final life = person(age: 19);
      expect(life.moveGate(kRentals[3]), contains('21'));
      expect(life.moveGate(kFamilyHome), 'You already live here');
    });

    test('moving out is a happy day and moving home is allowed', () {
      final life = person(salary: 800)
        ..debugAddPerson('Mum', kind: RelationshipKind.family);
      final joy = life.happiness;
      life.moveTo(kRentals[1]);
      expect(life.happiness, greaterThan(joy));
      life.moveTo(kFamilyHome);
      expect(life.housingCost, 0);
    });

    test('nobody is at home to move back to when the family is gone', () {
      final life = person(salary: 800)..moveTo(kRentals[1]);
      expect(life.moveGate(kFamilyHome), contains('nobody to move back in'));
    });

    test('rent makes the same salary go less far', () {
      LifeSimController at(RentalDef place) {
        final life = person(money: 0, salary: 500);
        life.moveTo(place);
        life.setBudget(needs: 50, wants: 30, savings: 20);
        year(life);
        return life;
      }

      expect(at(kRentals[0]).money, greaterThan(at(kRentals[2]).money));
    });
  });

  group('moving money between pots', () {
    test('savings to cash and back', () {
      final life = person(money: 1000);
      expect(life.depositSavings(400), 400);
      expect(life.emergencyFund, 400);
      expect(life.money, 600);
      expect(life.withdrawSavings(150), 150);
      expect(life.emergencyFund, 250);
      expect(life.money, 750);
    });

    test('never more than there is', () {
      final life = person(money: 100);
      expect(life.depositSavings(500), 100);
      expect(life.withdrawSavings(500), 100);
      expect(life.withdrawSavings(500), 0);
    });

    test('investments can be sold, and stop growing from that day', () {
      final life = person(money: 1000);
      life.invest(300);
      expect(life.investments, 300);
      expect(life.withdrawInvestments(200), 200);
      expect(life.investments, 100);
      expect(life.money, 900);
    });

    test('net worth counts every pot, and every debt', () {
      final life = person(money: 1000, salary: 800);
      life.depositSavings(200);
      life.invest(100);
      life.buyAsset(asset('val_art'));
      life.debugAddLoanForTest();
      expect(
        life.netWorth,
        life.money +
            life.emergencyFund +
            life.investments +
            life.assetsValue -
            life.debt -
            life.loanBalance,
      );
    });
  });
}
