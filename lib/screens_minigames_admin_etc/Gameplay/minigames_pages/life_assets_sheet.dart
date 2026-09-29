import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_assets.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../utils/number_format.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'life_ui_kit.dart';

/// **Assets:** everything you own, everything you owe, and how to look after
/// both.
///
/// **Asked for as:** the BitLife Assets tab, *"real estate, vehicles, jewelry,
/// pets and financial investments. Tapping an asset opens options to repair,
/// sell, upgrade or mortgage it."* And, from a screenshot of a life with 4,000
/// in cash that fell to 0, *"the budget amount is still weird."* That number is
/// answered here too: cash, savings, investments, property and debt are all on
/// one card, so there is never a moment where a rich life reads as a broke one.
const Color _accent = Color(0xFF85EFAC);

Future<void> openAssets(
  BuildContext context,
  LifeSimController life, {
  required VoidCallback onBudget,
  required VoidCallback onPowers,
  required VoidCallback onConcepts,
}) {
  return showLifeSheet<void>(
    context,
    builder: (_) => AssetsSheet(
      life: life,
      onBudget: onBudget,
      onPowers: onPowers,
      onConcepts: onConcepts,
    ),
  );
}

class AssetsSheet extends StatelessWidget {
  const AssetsSheet({
    super.key,
    required this.life,
    required this.onBudget,
    required this.onPowers,
    required this.onConcepts,
  });

  final LifeSimController life;
  final VoidCallback onBudget;
  final VoidCallback onPowers;
  final VoidCallback onConcepts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final kinds = [
          for (final k in AssetKind.values)
            if (life.assetsOf(k).isNotEmpty) k,
        ];
        return LifeSheet(
          title: 'Assets',
          icon: Icons.home_work_rounded,
          accent: _accent,
          subtitle: 'Net worth ${groupedNumber(life.netWorth)}',
          children: [
            _WorthCard(life: life),
            const LifeSection('Money tools'),
            LifeRow(
              icon: Icons.pie_chart_rounded,
              title: life.budgetSet ? 'Adjust your budget' : 'Set your budget',
              subtitle: life.canBudget
                  ? '${life.needsPct}% needs · ${life.wantsPct}% wants · '
                        '${life.savingsPct}% savings.'
                  : 'Split your pay across needs, wants and savings.',
              accent: _accent,
              disabledReason: life.canBudget
                  ? null
                  : 'You need a paying job first',
              onTap: onBudget,
            ),
            LifeRow(
              icon: Icons.swap_horiz_rounded,
              title: 'Move money',
              subtitle:
                  'Cash, savings and investments. Move it where it will work.',
              accent: _accent,
              disabledReason: life.age < 16 ? 'You need to be 16' : null,
              onTap: () => showLifeSheet<void>(
                context,
                builder: (_) => MoveMoneySheet(life: life),
              ),
            ),
            if (life.debt > 0)
              LifeRow(
                icon: Icons.credit_card_off_rounded,
                title: 'Pay back what you owe',
                subtitle:
                    'You owe ${life.debt}, which costs about '
                    '${(life.debt * 0.18).round()} a year in interest. Uses '
                    'cash first, then savings.',
                accent: const Color(0xFFFF8FB1),
                disabledReason: life.money + life.emergencyFund > 0
                    ? null
                    : 'Cash and savings are both empty',
                onTap: life.payDownDebt,
              ),
            LifeRow(
              icon: Icons.bolt_rounded,
              title: 'Money ideas at work',
              subtitle: life.activePowers.isEmpty
                  ? (life.armablePowers.isEmpty
                        ? 'Meet an idea first. They show up as your choices raise them.'
                        : '${life.armablePowers.length} ready to switch on.')
                  : life.activePowers.map((a) => a.power.name).join(', '),
              accent: _accent,
              onTap: onPowers,
            ),
            LifeRow(
              icon: Icons.lightbulb_rounded,
              title: 'Money ideas you have met',
              subtitle: '${life.conceptsMet.length} so far.',
              accent: _accent,
              onTap: onConcepts,
            ),
            const LifeSection('Where you live'),
            _HomeCard(life: life),
            for (final kind in kinds) ...[
              LifeSection(kind.label),
              for (final a in life.assetsOf(kind))
                _OwnedRow(life: life, asset: a),
            ],
            if (life.loans.isNotEmpty) ...[
              const LifeSection('What you owe on loans'),
              for (final l in life.loans) _LoanRow(life: life, loan: l),
            ],
            const LifeSection('Go shopping'),
            LifeRow(
              icon: Icons.storefront_rounded,
              title: 'Browse and buy',
              subtitle:
                  'Property, vehicles, pets, valuables and businesses. See '
                  'what it really costs to own before you buy.',
              accent: _accent,
              disabledReason: life.age < 6 ? 'You are too young to shop' : null,
              onTap: () => showLifeSheet<void>(
                context,
                builder: (_) => ShopSheet(life: life),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The whole picture in one card.
class _WorthCard extends StatelessWidget {
  const _WorthCard({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    return LifeCard(
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net worth',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            groupedNumber(life.netWorth),
            style: AppTheme.numeric(
              color: life.netWorth < 0 ? errorInk() : const Color(0xFFFFD45C),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Line('Cash', life.money),
          _Line('Savings', life.emergencyFund),
          _Line('Invested', life.investments),
          _Line('What you own', life.assetsValue),
          if (life.debt > 0) _Line('Credit debt', -life.debt, bad: true),
          if (life.loanBalance > 0)
            _Line('Loans', -life.loanBalance, bad: true),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bad = false});

  final String label;
  final int value;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            groupedNumber(value),
            style: AppTheme.numeric(
              color: bad ? errorInk() : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    final home = life.assetsOf(AssetKind.home);
    final title = home.isNotEmpty ? home.first.name : life.rental.name;
    final detail = home.isNotEmpty
        ? 'You own it. Upkeep ${home.first.def.upkeep} a year.'
        : life.rental.rent == 0
        ? 'Free, as long as your family is happy to have you.'
        : 'Rent is ${life.rental.rent} a year, paid from the needs part of '
              'your budget.';
    return LifeRow(
      icon: Icons.cottage_rounded,
      title: title,
      subtitle: detail,
      accent: _accent,
      onTap: home.isNotEmpty
          ? null
          : () => showLifeSheet<void>(
              context,
              builder: (_) => HousingSheet(life: life),
            ),
      trailing: home.isNotEmpty
          ? null
          : const Icon(Icons.chevron_right_rounded, color: Colors.white54),
    );
  }
}

class _OwnedRow extends StatelessWidget {
  const _OwnedRow({required this.life, required this.asset});

  final LifeSimController life;
  final OwnedAsset asset;

  @override
  Widget build(BuildContext context) {
    final def = asset.def;
    final loan = life.loans.where((l) => l.uid == asset.loanUid).toList();
    return LifeRow(
      icon: _iconFor(def),
      title: asset.name,
      subtitle: def.isPet
          ? '${def.name} · with you ${asset.yearsOwned} '
                '${asset.yearsOwned == 1 ? 'year' : 'years'}'
          : 'Worth ${groupedNumber(asset.value)} · paid ${groupedNumber(def.price)}',
      accent: _accent,
      chips: [
        if (loan.isNotEmpty)
          LifeChip(
            '${loan.first.label} ${groupedNumber(loan.first.balance)}',
            color: const Color(0xFFFF8474),
          ),
        if (def.upkeep > 0)
          LifeChip('Upkeep ${def.upkeep}', color: const Color(0xFFF2C66D)),
      ],
      bar: LifeBar(
        label: def.isPet ? 'Health' : 'Condition',
        value: asset.condition,
        color: valueColor(asset.condition),
        trailing: asset.conditionLabel,
        height: 6,
      ),
      onTap: () => showLifeSheet<void>(
        context,
        builder: (_) => AssetDetailSheet(life: life, uid: asset.uid),
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.life, required this.loan});

  final LifeSimController life;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    return LifeRow(
      icon: Icons.account_balance_rounded,
      title: loan.label,
      subtitle: loan.deferred
          ? '${groupedNumber(loan.balance)} at ${(loan.rate * 100).round()}%. '
                'Waiting until school ends, and growing.'
          : '${groupedNumber(loan.balance)} at ${(loan.rate * 100).round()}%. '
                '${groupedNumber(loan.payment)} a year for ${loan.yearsLeft} more '
                '${loan.yearsLeft == 1 ? 'year' : 'years'}.',
      accent: const Color(0xFFFF8474),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
      onTap: () => showLifeSheet<void>(
        context,
        builder: (_) => LoanSheet(life: life, uid: loan.uid),
      ),
    );
  }
}

IconData _iconFor(AssetDef def) => switch (def.kind) {
  AssetKind.home => Icons.house_rounded,
  AssetKind.vehicle =>
    def.id == 'veh_bike'
        ? Icons.pedal_bike_rounded
        : Icons.directions_car_rounded,
  AssetKind.pet => Icons.pets_rounded,
  AssetKind.valuable => Icons.diamond_rounded,
  AssetKind.business => Icons.storefront_rounded,
};

// ---------------------------------------------------------------------------
// One asset
// ---------------------------------------------------------------------------

/// Tapping an asset: what it is worth and what can be done with it.
class AssetDetailSheet extends StatelessWidget {
  const AssetDetailSheet({super.key, required this.life, required this.uid});

  final LifeSimController life;
  final int uid;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final matches = life.assets.where((a) => a.uid == uid).toList();
        if (matches.isEmpty) {
          // Sold, or gone. Close rather than draw an empty page.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }
        final a = matches.first;
        final def = a.def;
        final loan = life.loans.where((l) => l.uid == a.loanUid).toList();
        final proceeds = life.saleValue(a);
        final owed = loan.isEmpty ? 0 : loan.first.balance;
        return LifeSheet(
          title: a.name,
          icon: _iconFor(def),
          accent: _accent,
          subtitle: def.name,
          children: [
            LifeCard(
              accent: _accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!def.isPet) ...[
                    _Line('Worth today', a.value),
                    _Line('You paid', def.price),
                    _Line(
                      a.value >= def.price ? 'Gained' : 'Lost',
                      a.value - def.price,
                      bad: a.value < def.price,
                    ),
                  ],
                  if (def.upkeep > 0) _Line('Upkeep each year', def.upkeep),
                  const SizedBox(height: 10),
                  LifeBar(
                    label: def.isPet ? 'Health' : 'Condition',
                    value: a.condition,
                    color: valueColor(a.condition),
                    trailing: a.conditionLabel,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    def.blurb,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (loan.isNotEmpty) ...[
              const LifeSection('The loan'),
              LifeCard(
                child: Column(
                  children: [
                    _Line('Still owed', loan.first.balance, bad: true),
                    _Line('Rate', (loan.first.rate * 100).round()),
                    _Line('Payment each year', loan.first.payment),
                    _Line('Years left', loan.first.yearsLeft),
                  ],
                ),
              ),
            ],
            const LifeSection('What you can do'),
            LifeRow(
              icon: Icons.build_rounded,
              title: def.isPet ? 'Take to the vet' : 'Repair',
              subtitle: a.condition >= 95
                  ? 'Nothing needs doing.'
                  : 'Costs ${def.isPet ? (def.upkeep < 15 ? 15 : def.upkeep) : a.repairCost} and puts the condition back by 45.',
              accent: _accent,
              disabledReason: a.condition >= 95 ? 'Nothing needs doing' : null,
              onTap: () => life.repairAsset(uid),
            ),
            if (!def.isPet)
              LifeRow(
                icon: Icons.upgrade_rounded,
                title: 'Upgrade',
                subtitle:
                    'Costs ${a.upgradeCost}, brings it back to new and adds a '
                    'fifth to its value. Rarely pays for itself.',
                accent: _accent,
                onTap: () => life.upgradeAsset(uid),
              ),
            if (loan.isNotEmpty)
              LifeRow(
                icon: Icons.payments_rounded,
                title: 'Pay off the loan',
                subtitle:
                    'Clears ${loan.first.balance}. Uses cash first, then '
                    'savings.',
                accent: _accent,
                disabledReason: life.money + life.emergencyFund <= 0
                    ? 'Cash and savings are both empty'
                    : null,
                onTap: () => life.payLoan(loan.first.uid),
              ),
            LifeRow(
              icon: Icons.sell_rounded,
              title: def.isPet ? 'Find a new home for it' : 'Sell',
              subtitle: def.isPet
                  ? 'The right call sometimes, and it will hurt.'
                  : loan.isEmpty
                  ? 'Brings in $proceeds, less than it is worth, because the '
                        'buyer has to make a margin.'
                  : proceeds >= owed
                  ? 'Brings in $proceeds. The loan of $owed is cleared from it.'
                  : 'Brings in $proceeds but you owe $owed. The ${owed - proceeds} '
                        'left over becomes debt.',
              accent: const Color(0xFFFF8FB1),
              onTap: () => life.sellAsset(uid),
            ),
          ],
        );
      },
    );
  }
}

class LoanSheet extends StatelessWidget {
  const LoanSheet({super.key, required this.life, required this.uid});

  final LifeSimController life;
  final int uid;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final matches = life.loans.where((l) => l.uid == uid).toList();
        if (matches.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }
        final loan = matches.first;
        final total = loan.payment * loan.yearsLeft;
        return LifeSheet(
          title: loan.label,
          icon: Icons.account_balance_rounded,
          accent: const Color(0xFFFF8474),
          subtitle: 'Owed ${groupedNumber(loan.balance)}',
          children: [
            LifeCard(
              child: Column(
                children: [
                  _Line('Still owed', loan.balance, bad: true),
                  _Line('Interest rate (percent)', (loan.rate * 100).round()),
                  if (loan.deferred)
                    const _Line('Payment each year (not started)', 0)
                  else ...[
                    _Line('Payment each year', loan.payment),
                    _Line('Years left', loan.yearsLeft),
                    _Line('Paid in total if you only pay the minimum', total),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              loan.deferred
                  ? 'While you are in school the loan asks for nothing, and '
                        'the interest still runs. That is why it grows.'
                  : 'The payment is fixed and, early on, mostly interest. Paying '
                        'extra early is the cheapest way to shorten a loan.',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            for (final amount in const [50, 100, 250])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LifeButton(
                  label: 'Pay $amount',
                  icon: Icons.payments_rounded,
                  filled: false,
                  color: _accent,
                  onPressed: life.money + life.emergencyFund > 0
                      ? () => life.payLoan(uid, amount)
                      : null,
                ),
              ),
            LifeButton(
              label: 'Pay it all off',
              icon: Icons.check_circle_rounded,
              onPressed: life.money + life.emergencyFund > 0
                  ? () => life.payLoan(uid)
                  : null,
              note: life.money + life.emergencyFund >= loan.balance
                  ? null
                  : 'You can put in what you have and pay the rest later.',
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Where to live
// ---------------------------------------------------------------------------

class HousingSheet extends StatelessWidget {
  const HousingSheet({super.key, required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        return LifeSheet(
          title: 'Where to live',
          icon: Icons.cottage_rounded,
          accent: _accent,
          subtitle:
              'Rent is a need, so it comes out of the needs part of your budget',
          children: [
            for (final place in kRentals)
              LifeRow(
                icon: place.id == life.rentalId
                    ? Icons.check_circle_rounded
                    : Icons.home_rounded,
                title: place.name,
                subtitle:
                    '${place.rent == 0 ? 'Free' : '${place.rent} a year'}. ${place.blurb}',
                accent: _accent,
                disabledReason: life.moveGate(place),
                onTap: () => life.moveTo(place),
              ),
            const SizedBox(height: 6),
            Text(
              'Buying a place is under Go shopping, and it ends the rent.',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Moving money between pots
// ---------------------------------------------------------------------------

enum _Move {
  save('Put cash into savings'),
  spend('Take savings out as cash'),
  invest('Invest cash'),
  sell('Sell investments for cash');

  const _Move(this.label);

  final String label;
}

class MoveMoneySheet extends StatefulWidget {
  const MoveMoneySheet({super.key, required this.life});

  final LifeSimController life;

  @override
  State<MoveMoneySheet> createState() => _MoveMoneySheetState();
}

class _MoveMoneySheetState extends State<MoveMoneySheet> {
  _Move _move = _Move.save;
  int _amount = 100;

  int _available(LifeSimController life) => switch (_move) {
    _Move.save || _Move.invest => life.money,
    _Move.spend => life.emergencyFund,
    _Move.sell => life.investments,
  };

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final have = _available(life);
        final amount = _amount.clamp(0, have);
        return LifeSheet(
          title: 'Move money',
          icon: Icons.swap_horiz_rounded,
          accent: _accent,
          subtitle:
              'Cash ${groupedNumber(life.money)} · Savings ${groupedNumber(life.emergencyFund)} · Invested ${groupedNumber(life.investments)}',
          children: [
            LifeDropdown<_Move>(
              label: 'What to do',
              value: _move,
              accent: _accent,
              items: [
                for (final m in _Move.values)
                  LifeDropdownItem<_Move>(value: m, label: m.label),
              ],
              onChanged: (m) => setState(() => _move = m),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in const [50, 100, 250, 500])
                  ChoiceChip(
                    label: Text('$n'),
                    selected: _amount == n,
                    onSelected: (_) => setState(() => _amount = n),
                    selectedColor: _accent.withValues(alpha: 0.35),
                    labelStyle: AppTheme.numeric(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: const Text('Everything'),
                  selected: _amount >= 1000000,
                  onSelected: (_) => setState(() => _amount = 1000000),
                  selectedColor: _accent.withValues(alpha: 0.35),
                  labelStyle: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              switch (_move) {
                _Move.save =>
                  'Savings are harder to spend by accident, and they are what a '
                      'bill lands on first.',
                _Move.spend =>
                  'Your savings are for emergencies. Spending them on wants is '
                      'allowed, and it is worth noticing that it is easy.',
                _Move.invest =>
                  'Investments grow about 7% a year. They are for money you '
                      'will not need soon.',
                _Move.sell =>
                  'You can sell any time. It stops growing from that day.',
              },
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            LifeButton(
              label: 'Move $amount',
              icon: Icons.swap_horiz_rounded,
              onPressed: amount > 0 ? () => _do(context, life, amount) : null,
              note: have <= 0
                  ? 'Nothing there to move'
                  : 'Up to ${groupedNumber(have)} available',
            ),
          ],
        );
      },
    );
  }

  void _do(BuildContext context, LifeSimController life, int amount) {
    switch (_move) {
      case _Move.save:
        life.depositSavings(amount);
      case _Move.spend:
        life.withdrawSavings(amount);
      case _Move.invest:
        life.invest(amount);
      case _Move.sell:
        life.withdrawInvestments(amount);
    }
  }
}

// ---------------------------------------------------------------------------
// The shop
// ---------------------------------------------------------------------------

const List<String> _petNames = <String>[
  'Biscuit',
  'Mochi',
  'Pixel',
  'Rocket',
  'Waffles',
  'Shadow',
  'Clover',
  'Nugget',
];

class ShopSheet extends StatefulWidget {
  const ShopSheet({
    super.key,
    required this.life,
    this.initialKind = AssetKind.vehicle,
  });

  final LifeSimController life;

  /// Which aisle to open on.
  final AssetKind initialKind;

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  late AssetKind _kind = widget.initialKind;

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        return LifeSheet(
          title: 'Shop',
          icon: Icons.storefront_rounded,
          accent: _accent,
          subtitle: 'Cash ${groupedNumber(life.money)}',
          children: [
            LifeDropdown<AssetKind>(
              label: 'Browse',
              value: _kind,
              accent: _accent,
              items: [
                for (final k in AssetKind.values)
                  LifeDropdownItem<AssetKind>(value: k, label: k.label),
              ],
              onChanged: (k) => setState(() => _kind = k),
            ),
            if (_kind == AssetKind.vehicle) ...[
              const SizedBox(height: 10),
              LifeRow(
                icon: Icons.badge_rounded,
                title: life.hasLicense
                    ? 'You have a driving license'
                    : 'Take your driving test',
                subtitle: life.hasLicense
                    ? 'A car is possible.'
                    : 'Costs 40. Needed before you can buy any car.',
                accent: _accent,
                disabledReason: life.hasLicense
                    ? 'You already have one'
                    : life.licenseGate(),
                onTap: life.getLicense,
              ),
            ],
            const SizedBox(height: 10),
            for (final def in assetsOfKind(_kind))
              _ShopCard(life: life, def: def),
          ],
        );
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.life, required this.def});

  final LifeSimController life;
  final AssetDef def;

  @override
  Widget build(BuildContext context) {
    final cashGate = life.buyGate(def);
    final loanGate = def.canFinance
        ? life.buyGate(def, financed: true)
        : 'No loan';
    final total = def.canFinance
        ? def.downPayment +
              amortizedPayment(def.loanAmount, def.loanRate, def.loanYears) *
                  def.loanYears
        : def.price;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LifeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(def), color: _accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    def.name,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  groupedNumber(def.price),
                  style: AppTheme.numeric(
                    color: const Color(0xFFFFD45C),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              def.blurb,
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (def.upkeep > 0)
                  LifeChip(
                    'Upkeep ${def.upkeep} a year',
                    color: const Color(0xFFF2C66D),
                  ),
                if (def.drift < 0)
                  LifeChip(
                    'Loses about ${(-def.drift * 100).round()}% a year',
                    color: const Color(0xFFFF8474),
                  ),
                if (def.drift > 0)
                  LifeChip(
                    'Gains about ${(def.drift * 100).round()}% a year',
                    color: const Color(0xFF85EFAC),
                  ),
                if (def.swing >= 0.10)
                  const LifeChip(
                    'Value swings a lot',
                    color: Color(0xFFB388FF),
                  ),
                if (def.happiness > 0)
                  LifeChip(
                    '+${def.happiness} happiness a year',
                    color: const Color(0xFF85EFAC),
                  ),
                if (def.kind == AssetKind.business)
                  const LifeChip('Can lose money', color: Color(0xFFFF8474)),
              ],
            ),
            const SizedBox(height: 10),
            LifeButton(
              label: 'Buy for ${groupedNumber(def.price)}',
              icon: Icons.shopping_bag_rounded,
              onPressed: cashGate == null
                  ? () => _buy(context, financed: false)
                  : null,
              note: cashGate,
            ),
            if (def.canFinance) ...[
              const SizedBox(height: 8),
              LifeButton(
                label: 'Buy on a loan',
                icon: Icons.account_balance_rounded,
                filled: false,
                onPressed: loanGate == null
                    ? () => _buy(context, financed: true)
                    : null,
                note:
                    loanGate ??
                    '${groupedNumber(def.downPayment)} now, then '
                        '${groupedNumber(amortizedPayment(def.loanAmount, def.loanRate, def.loanYears))} a year for '
                        '${def.loanYears} years at ${(def.loanRate * 100).round()}%. '
                        'You pay ${groupedNumber(total)} in all.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _buy(BuildContext context, {required bool financed}) {
    final name = def.isPet
        ? _petNames[(life.assets.length + life.age) % _petNames.length]
        : null;
    final owned = life.buyAsset(def, financed: financed, name: name);
    if (owned == null) return;
    GameToast.show(
      context,
      title: 'Bought',
      message: '${owned.name} is yours.',
      icon: Icons.shopping_bag_rounded,
      accent: _accent,
    );
  }
}
