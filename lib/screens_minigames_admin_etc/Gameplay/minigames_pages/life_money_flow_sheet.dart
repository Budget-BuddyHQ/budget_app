import 'package:flutter/material.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../utils/number_format.dart';
import 'life_ui_kit.dart';

/// **Where does my money go?** One year, from pay to what is left, in the order
/// the year does it.
///
/// **Asked for as:** ten-year-olds playing said *"they don't know what is taking
/// money from them."* Rent, food, loan payments, interest and the budget split
/// were all charged every year and each was named once in a scrolling feed, so
/// unless you had been watching you could not tell what a year cost. Here it is
/// all in one place, with a sentence on each row, and it opens from the money
/// panel that shows the four boxes it moves.
const Color _gold = Color(0xFFFFD45C);

Future<void> openMoneyFlow(BuildContext context, LifeSimController life) {
  return showLifeSheet<void>(
    context,
    builder: (_) => MoneyFlowSheet(life: life),
  );
}

class MoneyFlowSheet extends StatelessWidget {
  const MoneyFlowSheet({super.key, required this.life});

  final LifeSimController life;

  static IconData _icon(MoneyFlowKind kind) => switch (kind) {
    MoneyFlowKind.pay => Icons.payments_rounded,
    MoneyFlowKind.loan => Icons.request_quote_rounded,
    MoneyFlowKind.need => Icons.home_rounded,
    MoneyFlowKind.want => Icons.celebration_rounded,
    MoneyFlowKind.saved => Icons.savings_rounded,
    MoneyFlowKind.interest => Icons.trending_up_rounded,
    MoneyFlowKind.family => Icons.family_restroom_rounded,
  };

  static Color _color(MoneyFlowKind kind) => switch (kind) {
    MoneyFlowKind.pay => const Color(0xFF85EFAC),
    MoneyFlowKind.loan => const Color(0xFFFF8FB1),
    MoneyFlowKind.need => const Color(0xFF69C6FF),
    MoneyFlowKind.want => const Color(0xFFB388FF),
    MoneyFlowKind.saved => _gold,
    MoneyFlowKind.interest => const Color(0xFFFF8FB1),
    MoneyFlowKind.family => const Color(0xFF85EFAC),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final flow = life.moneyFlow;
        final coming = [
          for (final l in flow.lines)
            if (l.isIncome) l,
        ];
        final going = [
          for (final l in flow.lines)
            if (!l.isIncome) l,
        ];

        Widget row(MoneyFlowLine line) {
          final color = _color(line.kind);
          final family = line.kind == MoneyFlowKind.family;
          return LifeRow(
            key: ValueKey('flow-${line.label}'),
            icon: _icon(line.kind),
            title: line.label,
            subtitle: line.why,
            accent: color,
            trailing: family
                ? const LifeChip('Paid for you', color: Color(0xFF85EFAC))
                : LifeChip(
                    '${line.isIncome ? '+' : '-'}${groupedNumber(line.amount)}',
                    color: color,
                  ),
          );
        }

        return LifeSheet(
          title: 'Where does my money go?',
          icon: Icons.account_balance_wallet_rounded,
          accent: _gold,
          subtitle: 'One year, from your pay to what is left.',
          children: [
            if (coming.isNotEmpty) ...[
              const LifeSection('Coming in'),
              for (final l in coming) row(l),
            ],
            if (going.isNotEmpty) ...[
              LifeSection(coming.isEmpty ? 'Who pays' : 'Going out'),
              for (final l in going) row(l),
            ],
            if (!life.isDependent) ...[
              const LifeSection('What is left'),
              LifeRow(
                key: const ValueKey('flow-left'),
                icon: Icons.account_balance_wallet_rounded,
                title: flow.leftOver >= 0
                    ? 'Left in your pocket'
                    : 'Short this year by',
                subtitle: flow.leftOver >= 0
                    ? 'What you keep if nothing else happens.'
                    : 'A gap like this is borrowed, and borrowing has a price.',
                accent: flow.leftOver >= 0
                    ? const Color(0xFF85EFAC)
                    : const Color(0xFFFF8FB1),
                trailing: LifeChip(
                  groupedNumber(flow.leftOver.abs()),
                  color: flow.leftOver >= 0
                      ? const Color(0xFF85EFAC)
                      : const Color(0xFFFF8FB1),
                ),
              ),
            ],
            if (flow.note != null)
              LifeCard(
                key: const ValueKey('flow-note'),
                accent: _gold,
                child: Text(
                  flow.note!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            const LifeCard(
              key: ValueKey('flow-surprises'),
              accent: Color(0xFF69C6FF),
              child: Text(
                'Then there are the surprises: a broken car, a big bill, a boss '
                'who lets you go. They are not in this list because nobody '
                'knows when they will come. Savings are how you get through '
                'them.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
