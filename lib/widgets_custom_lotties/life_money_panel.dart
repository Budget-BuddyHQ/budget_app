import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers_that_updates_stats/life_sim_controller.dart';
import '../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../themes_colors/app_theme.dart';
import '../utils/number_format.dart';
import 'fitted_label.dart';
import 'pixel_kit.dart';
import 'pixel_panel.dart';

/// The money you actually have, on screen every single year.
///
/// **Why this exists.** The Life sim already modelled cash, an emergency
/// fund, investments, debt at 18%, and a needs/wants/savings split — but
/// all of it lived behind the Money menu. On the feed you saw a coin count
/// in the header and nothing else, so a player could live a whole life
/// without once being shown that a budget existed. The money model was
/// real and invisible, which is the same as not having one.
///
/// So this sits directly under the year card, in the space the feed leaves
/// empty at young ages, and it does three jobs:
///
/// 1. **Names the four places money can be** — cash, saved, invested,
///    owed. Four boxes, always the same four, so the categories become
///    familiar before the vocabulary is explained.
/// 2. **Shows the split as a bar**, not a number. A 50/30/20 bar is a
///    picture of a budget; "needsPct = 50" is a statistic.
/// 3. **Says what the emergency fund buys you** — months of cover, not
///    coins. That is the whole point of the concept, and it is the part a
///    balance alone never communicates.
///
/// Under 18 there is no paycheck to split, so it shows a dependent variant
/// instead of a disabled budget bar — an empty control you are not allowed
/// to touch teaches nothing.
class LifeMoneyPanel extends StatelessWidget {
  const LifeMoneyPanel({
    super.key,
    required this.life,
    required this.onOpenBudget,
    required this.onOpenMoney,
    required this.onOpenConcepts,
  });

  final LifeSimController life;

  /// Opens the budget sheet. Wired to the strip that appears the first year
  /// a salary exists — the moment budgeting becomes a real decision.
  final VoidCallback onOpenBudget;

  /// Opens the wider Money menu (invest, save, side jobs).
  final VoidCallback onOpenMoney;

  /// Opens the list of money ideas this life has met.
  final VoidCallback onOpenConcepts;

  /// Kept as an alias so the several call sites that already reach for
  /// `LifeMoneyPanel.coinsLabel` keep working; the implementation lives in
  /// [groupedNumber] now that three copies of it existed.
  static String coinsLabel(int value) => groupedNumber(value);

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LifeEmoji('\u{1F4B0}', size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: FittedLabel(
                  'Your money',
                  style: GoogleFonts.pixelifySans(
                    color: const Color(0xFFE9C46A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // net worth moves whenever any of the four boxes move so it
              // gets the headline slot. rigid on purpose — this is the
              // number that has to stay readable, the heading next to it is
              // the bit thats allowed to give
              Text(
                '${coinsLabel(life.netWorth)} net',
                style: GoogleFonts.pixelifySans(
                  color: life.netWorth < 0
                      ? const Color(0xFFFF8FB1)
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // two per row on a narrow phone, four across when theres room.
          // measured not assumed, because this app has already shipped
          // panels that shrank their text instead of rewrapping and ended up
          // showing *less* on a bigger screen. not doing that again
          LayoutBuilder(
            builder: (context, constraints) {
              final perRow = constraints.maxWidth >= 340 ? 4 : 2;
              final tileWidth =
                  (constraints.maxWidth - (perRow - 1) * 8) / perRow;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tile in _tiles())
                    SizedBox(
                      width: tileWidth,
                      child: _MoneyTile(
                        emoji: tile.emoji,
                        label: tile.label,
                        value: coinsLabel(tile.value),
                        accent: tile.accent,
                        dim: tile.value == 0,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          if (life.canBudget) ...[
            _BudgetStrip(
              needs: life.needsPct,
              wants: life.wantsPct,
              savings: life.savingsPct,
              isSet: life.budgetSet,
              onTap: onOpenBudget,
            ),
            const SizedBox(height: 8),
            _RunwayLine(months: life.emergencyMonths),
          ] else
            _DependentNote(
              age: life.age,
              canJobHunt: life.canJobHunt,
              onOpenMoney: onOpenMoney,
            ),
          const SizedBox(height: 8),
          _ConceptsStrip(met: life.conceptsMet, onTap: onOpenConcepts),
        ],
      ),
    );
  }

  List<_TileData> _tiles() => <_TileData>[
    _TileData('\u{1F4B5}', 'Cash', life.money, const Color(0xFF85EFAC)),
    _TileData(
      '\u{1F3E6}',
      'Saved',
      life.emergencyFund,
      const Color(0xFF69C6FF),
    ),
    _TileData(
      '\u{1F4C8}',
      'Invested',
      life.investments,
      const Color(0xFFE9C46A),
    ),
    _TileData('\u{1F4B3}', 'Owed', life.debt, const Color(0xFFFF8FB1)),
  ];
}

class _TileData {
  const _TileData(this.emoji, this.label, this.value, this.accent);
  final String emoji;
  final String label;
  final int value;
  final Color accent;
}

/// An emoji drawn as text, deliberately *not* in the pixel font.
///
/// `GoogleFonts.pixelifySans` has no emoji glyphs, so styling one with it
/// drops the character to a tofu box on some devices. Keeping emoji on the
/// platform default font is what makes them render at all.
///
/// Every use here sits beside a text label that says the same thing, so
/// they are hidden from screen readers rather than announced as "money
/// bag" before each heading.
class LifeEmoji extends StatelessWidget {
  const LifeEmoji(this.char, {super.key, this.size = 14});

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(char, style: TextStyle(fontSize: size, height: 1.1)),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accent,
    required this.dim,
  });

  final String emoji;
  final String label;
  final String value;
  final Color accent;

  /// Zero balances are shown, not hidden — an empty savings box is the
  /// point — but they recede so the boxes with something in them read
  /// first.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dim ? 0.05 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: dim ? 0.16 : 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LifeEmoji(emoji, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: FittedLabel(
                  label,
                  style: GoogleFonts.quicksand(
                    // Full-strength muted, not 62% white. These tiles are
                    // washed in their own accent, so knocking the label back
                    // with alpha pulls it toward the tile rather than toward
                    // grey — "Cash" and "Saved" both measured under 4:1.
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedLabel(
            value,
            style: GoogleFonts.pixelifySans(
              // The figure is the tile's point, so it keeps the accent — but
              // measured against the wash it actually sits on rather than
              // against the panel behind it.
              color: dim
                  ? AppTheme.textMuted
                  : AppTheme.legibleOn(
                      accent,
                      AppTheme.flatten(
                        accent.withValues(alpha: 0.12),
                        PixelFrameStyle.slate.surface,
                      ),
                      target: 3.0,
                    ),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The needs/wants/savings split, drawn as one bar.
///
/// Tapping it opens the budget sheet, so the picture is also the control —
/// the player never has to hunt for a menu item to change what they can
/// already see.
class _BudgetStrip extends StatelessWidget {
  const _BudgetStrip({
    required this.needs,
    required this.wants,
    required this.savings,
    required this.isSet,
    required this.onTap,
  });

  final int needs;
  final int wants;
  final int savings;
  final bool isSet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded on the heading, not a Spacer between two rigid
            // Texts: a Spacer is itself a flex child, so it competes with
            // any Flexible siblings for the same free space and the labels
            // end up squeezed rather than the gap. Two rigid labels plus a
            // Spacer overflowed this row by 9.8px at 288 wide.
            Row(
              children: [
                const LifeEmoji('\u{1F9FE}', size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedLabel(
                    isSet ? 'Your budget' : 'Pick a budget',
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSet ? 'Tap to change' : 'Tap to set',
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF85EFAC),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: [
                    _BudgetSegment(
                      percent: needs,
                      emoji: '\u{1F3E0}',
                      color: const Color(0xFF69C6FF),
                    ),
                    _BudgetSegment(
                      percent: wants,
                      emoji: '\u{1F389}',
                      color: const Color(0xFFE9C46A),
                    ),
                    _BudgetSegment(
                      percent: savings,
                      emoji: '\u{1F437}',
                      color: const Color(0xFF85EFAC),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Needs $needs%   Wants $wants%   Savings $savings%',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSegment extends StatelessWidget {
  const _BudgetSegment({
    required this.percent,
    required this.emoji,
    required this.color,
  });

  final int percent;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // A zero-percent slice must not take a flex of 0 — `Expanded(flex: 0)`
      // asserts. It collapses to a hairline instead, which also keeps all
      // three colours on screen while a slider is dragged to zero.
      flex: percent < 1 ? 1 : percent * 10,
      child: ColoredBox(
        color: color,
        child: Center(
          // Only label a slice wide enough to hold the glyph. A clipped
          // emoji reads as a rendering bug rather than as a tight fit.
          child: percent >= 12
              ? LifeEmoji(emoji, size: 10)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// What the emergency fund actually buys: months you could pay for.
class _RunwayLine extends StatelessWidget {
  const _RunwayLine({required this.months});

  final double months;

  @override
  Widget build(BuildContext context) {
    final (emoji, color, text) = switch (months) {
      < 0.5 => (
        '\u{1F6A8}',
        const Color(0xFFFF8FB1),
        'No safety net. One surprise bill and you borrow.',
      ),
      < 3 => (
        '\u{26A0}',
        const Color(0xFFE9C46A),
        'Savings cover ${months.toStringAsFixed(1)} months. Aim for 3.',
      ),
      _ => (
        '\u{1F6E1}',
        const Color(0xFF85EFAC),
        'Savings cover ${months.toStringAsFixed(1)} months — a real cushion.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LifeEmoji(emoji, size: 13),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The money ideas this life has actually run into, as a filling-up row of
/// glyphs.
///
/// This is the teaching layer made countable. Concepts were already being
/// recorded — every relevant choice calls `_teach(...)` — but the only way
/// to see them was to open a menu, so a player had no idea a collection
/// existed, let alone that it was two-thirds empty. A row that visibly
/// fills in gives the finance content the same pull the game already gets
/// from coins and skins.
///
/// Unmet ideas are shown as dim slots rather than hidden, because the empty
/// slots are the invitation.
class _ConceptsStrip extends StatelessWidget {
  const _ConceptsStrip({required this.met, required this.onTap});

  final List<FinanceConcept> met;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const all = FinanceConcept.values;
    final metSet = met.toSet();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LifeEmoji('\u{1F393}', size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedLabel(
                    'Money ideas met',
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${metSet.length}/${all.length}',
                  style: GoogleFonts.pixelifySans(
                    color: const Color(0xFFE9C46A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Wraps rather than scrolls: a horizontal strip inside a
            // vertical ListView would fight the parent for drags, which is
            // the same gesture-arena trap the price chart already hit.
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final concept in all)
                  Opacity(
                    opacity: metSet.contains(concept) ? 1 : 0.22,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: metSet.contains(concept) ? 0.12 : 0.05,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: LifeEmoji(concept.emoji, size: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Under 18 there is no paycheck to divide, so the panel teaches the thing
/// that *is* true at that age: money you are given still goes somewhere.
class _DependentNote extends StatelessWidget {
  const _DependentNote({
    required this.age,
    required this.canJobHunt,
    required this.onOpenMoney,
  });

  final int age;

  /// Old enough to work and not currently employed — the one case where
  /// this note has something the player can act on *right now*, so it says
  /// so instead of offering general advice.
  final bool canJobHunt;

  final VoidCallback onOpenMoney;

  @override
  Widget build(BuildContext context) {
    final line = canJobHunt
        ? 'No income yet. Open Career and look for work — a budget needs '
              'something to split.'
        : age < 6
        ? 'Grown-ups pay for everything right now. Watch what things cost.'
        : age < 13
        ? 'No paycheck yet — but every coin you keep is a coin you chose to keep.'
        : 'Take a side job and you can start splitting your own money.';

    return InkWell(
      onTap: onOpenMoney,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF69C6FF).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LifeEmoji('\u{1FA99}', size: 13),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                line,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
