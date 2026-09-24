part of 'life_sim_controller.dart';

/// What kind of money a row of [MoneyFlow] is.
enum MoneyFlowKind {
  /// Coming in.
  pay,

  /// A payment on a loan, taken from pay before it is split.
  loan,

  /// Rent, food and bills: the things that cannot be skipped.
  need,

  /// Fun. Set by the wants slice of the budget.
  want,

  /// Set aside. Not spent, but it leaves your pocket.
  saved,

  /// The price of owing money.
  interest,

  /// Somebody else is paying.
  family,
}

/// One row of "where does my money go".
class MoneyFlowLine {
  const MoneyFlowLine({
    required this.kind,
    required this.label,
    required this.amount,
    required this.why,
  });

  final MoneyFlowKind kind;
  final String label;

  /// Coins a year. Always positive; [kind] says which way it goes.
  final int amount;

  /// One plain sentence: what this is, in words a nine-year-old has met.
  final String why;

  bool get isIncome => kind == MoneyFlowKind.pay;
}

/// A year's money, itemised, for the sheet behind "Where does my money go?".
///
/// **Asked for as:** ten-year-olds playing said *"they don't know what is taking
/// money from them."* The game charged rent, food, loan payments, interest and a
/// budget split every single year and named them in a scrolling feed line, so the
/// only way to see them was to have been watching a year ago. This puts all of it
/// in one place, in the order the year does it, with a sentence on each.
///
/// It is a **preview of the coming year, computed from the same numbers
/// `_applyBudget` uses**, and it changes nothing. Where the two could disagree the
/// test in `life_money_where_test.dart` runs a real year and compares.
class MoneyFlow {
  const MoneyFlow({required this.lines, required this.leftOver, this.note});

  final List<MoneyFlowLine> lines;

  /// What stays in cash after the year, if nothing else happens. Negative when
  /// the year costs more than it pays, which is the day a shortfall is borrowed.
  final int leftOver;

  /// A sentence for the bottom, when the lines alone do not say it.
  final String? note;

  int get incomeTotal =>
      lines.where((l) => l.isIncome).fold<int>(0, (sum, l) => sum + l.amount);

  int get outTotal => lines
      .where((l) => !l.isIncome && l.kind != MoneyFlowKind.family)
      .fold<int>(0, (sum, l) => sum + l.amount);
}

extension LifeMoneyFlow on LifeSimController {
  /// The coming year, itemised. See [MoneyFlow].
  MoneyFlow get moneyFlow {
    // A child's food, home and school are somebody else's problem, and saying so
    // is the answer to "what is taking my money": nothing is, yet.
    if (isDependent) {
      return const MoneyFlow(
        lines: <MoneyFlowLine>[
          MoneyFlowLine(
            kind: MoneyFlowKind.family,
            label: 'Home, food and school',
            amount: 0,
            why:
                'Your family pays for these. They are not coming out of your money.',
          ),
        ],
        leftOver: 0,
        note:
            'Your coins are yours to spend on fun things or to save. When you '
            'grow up, the things above become your bills, so this is a good '
            'time to practise saving.',
      );
    }

    final lines = <MoneyFlowLine>[];
    final essentials = _livingCost();
    final rent = housingCost;
    final kids = childCost;
    final food = (essentials - rent - kids).clamp(0, essentials);

    if (_salary <= 0) {
      lines
        ..add(
          MoneyFlowLine(
            kind: MoneyFlowKind.need,
            label: rent > 0 ? 'Rent' : 'Home',
            amount: rent,
            why: rent > 0
                ? 'Somewhere to live. It is due every year, job or no job.'
                : 'You own it, so there is no rent.',
          ),
        )
        ..add(
          MoneyFlowLine(
            kind: MoneyFlowKind.need,
            label: 'Food and bills',
            amount: food,
            why: 'Eating, power, water and a phone. You cannot skip these.',
          ),
        );
      if (kids > 0) {
        lines.add(
          MoneyFlowLine(
            kind: MoneyFlowKind.need,
            label: 'Looking after your children',
            amount: kids,
            why: 'Food, clothes and school things.',
          ),
        );
      }
      return MoneyFlow(
        lines: lines,
        leftOver: -essentials,
        note:
            'With no job nothing is coming in. Savings and odd jobs cover it for '
            'a while, and then it is borrowed. Find work from the Occupation tab.',
      );
    }

    final gross =
        (_salary * (1 + powerStrength(PowerEffect.betterPay)) * _payShare)
            .round();
    lines.add(
      MoneyFlowLine(
        kind: MoneyFlowKind.pay,
        label: 'Your pay',
        amount: gross,
        why: 'What your job pays in one year.',
      ),
    );

    // Loans come out first, from the pay, before anything is split.
    var loanTotal = 0;
    for (final loan in _loans) {
      if (loan.deferred) continue;
      final due = loanYear(loan).due;
      if (due <= 0) continue;
      loanTotal += due;
      lines.add(
        MoneyFlowLine(
          kind: MoneyFlowKind.loan,
          label: loan.label,
          amount: due,
          why:
              'A payment on money you borrowed. It comes out of your pay first.',
        ),
      );
    }
    final income = (gross - loanTotal).clamp(0, gross);

    if (rent > 0) {
      lines.add(
        MoneyFlowLine(
          kind: MoneyFlowKind.need,
          label: 'Rent',
          amount: rent,
          why: 'Somewhere to live. It is due every year.',
        ),
      );
    }
    lines.add(
      MoneyFlowLine(
        kind: MoneyFlowKind.need,
        label: 'Food and bills',
        amount: food,
        why: 'Eating, power, water and a phone. You cannot skip these.',
      ),
    );
    if (kids > 0) {
      lines.add(
        MoneyFlowLine(
          kind: MoneyFlowKind.need,
          label: 'Looking after your children',
          amount: kids,
          why: 'Food, clothes and school things.',
        ),
      );
    }

    final wants = (income * _wantsPct / 100).round();
    final savings = (income * _savingsPct / 100).round();
    lines
      ..add(
        MoneyFlowLine(
          kind: MoneyFlowKind.want,
          label: 'Fun money',
          amount: wants,
          why:
              'Things you want and do not need. It makes you happier, up to a '
              'point.',
        ),
      )
      ..add(
        MoneyFlowLine(
          kind: MoneyFlowKind.saved,
          label: 'Put into savings',
          amount: savings,
          why: 'Not gone. It is your safety net for a bad day.',
        ),
      );

    final debtRate = 0.18 * (1 - powerStrength(PowerEffect.slowerDebt));
    final interest = _debt > 0 ? (_debt * debtRate).round() : 0;
    if (interest > 0) {
      lines.add(
        MoneyFlowLine(
          kind: MoneyFlowKind.interest,
          label: 'Interest on what you owe',
          amount: interest,
          why:
              'The price of borrowing. It is charged every year you still owe '
              'something.',
        ),
      );
    }

    final leftOver = income - essentials - wants - savings - interest;
    return MoneyFlow(
      lines: lines,
      leftOver: leftOver,
      note: leftOver < 0
          ? 'This year costs more than it pays, so the gap would be borrowed. '
                'Try turning fun money down, or look for a better job.'
          : null,
    );
  }
}
