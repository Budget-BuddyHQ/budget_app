import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../../../utils/number_format.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import 'past_life_screen.dart';

/// Every life you've finished, and the three you did best at.
///
/// **Why.** Life resets completely on every visit — a fresh controller, a
/// fresh character, no carry-over. That is right for the game, but it left
/// the main mode with no memory at all: a tenth run was indistinguishable
/// from a first, and there was nothing to beat. `LifeRecordBook` gives the
/// mode a history; this is where you read it.
///
/// Bests come first because they are the reason to open the screen. The
/// history below is the evidence for them.
class PastLivesScreen extends StatelessWidget {
  const PastLivesScreen({super.key});

  static const _gold = Color(0xFFFFD45C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Past Lives',
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<UserStatsController>(
        builder: (context, controller, _) {
          final book = controller.stats.lifeRecords;

          if (book.isEmpty) {
            return const _EmptyState();
          }

          final history = book.newestFirst;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _BestsGrid(book: book),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'History',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    book.totalLives == 1
                        ? '1 life'
                        : '${book.totalLives} lives',
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final record in history) ...[
                _RecordRow(
                  key: ValueKey(
                    'life-${record.finishedAt.toIso8601String()}-${record.name}',
                  ),
                  record: record,
                  book: book,
                ),
                const SizedBox(height: 8),
              ],
              if (book.totalLives >= LifeRecordBook.maxRecords)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Only your last ${LifeRecordBook.maxRecords} lives are '
                    'kept — your best scores above are safe either way.',
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 52,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No lives yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Finish a life — retire, or reach the end — and it gets '
              'recorded here with your best scores.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three personal bests, each naming the life that set it.
class _BestsGrid extends StatelessWidget {
  const _BestsGrid({required this.book});

  final LifeRecordBook book;

  @override
  Widget build(BuildContext context) {
    // Keyed because the same figure legitimately appears twice on this
    // screen — "14 ideas" is both a personal best up here and a stat chip on
    // the row that set it — so a plain text lookup is ambiguous by design.
    final tiles = <Widget>[
      _BestTile(
        key: const ValueKey('best-netWorth'),
        best: LifeBest.netWorth,
        record: book.richest,
        value: (r) => '${groupedNumber(r.netWorth)} coins',
        icon: Icons.savings_rounded,
        accent: const Color(0xFF85EFAC),
      ),
      _BestTile(
        key: const ValueKey('best-age'),
        best: LifeBest.age,
        record: book.longest,
        value: (r) => '${r.age} years',
        icon: Icons.cake_rounded,
        accent: const Color(0xFF69C6FF),
      ),
      _BestTile(
        key: const ValueKey('best-concepts'),
        best: LifeBest.concepts,
        record: book.wisest,
        value: (r) => '${r.conceptsMet} ideas',
        icon: Icons.school_rounded,
        accent: const Color(0xFFB388FF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across only when each tile still gets a usable width; two
        // narrow columns beat three cramped ones.
        final wide = constraints.maxWidth >= 460;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                Expanded(child: tiles[i]),
                if (i != tiles.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i != tiles.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _BestTile extends StatelessWidget {
  const _BestTile({
    super.key,
    required this.best,
    required this.record,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final LifeBest best;
  final LifeRecord? record;
  final String Function(LifeRecord) value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.getPuffyDecoration(
        accent: accent,
        fillColor: const Color(0xFF15302A),
        borderRadius: AppTheme.radiusLarge,
        restAlpha: 0.14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedLabel(
                  best.label,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                FittedLabel(
                  r == null ? '—' : value(r),
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (r != null && r.name.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  FittedLabel(
                    r.name,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One finished life in the history list.
class _RecordRow extends StatelessWidget {
  const _RecordRow({super.key, required this.record, required this.book});

  final LifeRecord record;
  final LifeRecordBook book;

  @override
  Widget build(BuildContext context) {
    final archetype = record.archetype;
    final accent = archetype?.color ?? const Color(0xFF85EFAC);

    // A row can hold more than one crown (the same life can be both the
    // richest and the longest), and identity matters rather than equality —
    // two runs can tie on a value without both being the record holder.
    final crowns = <LifeBest>{
      if (identical(book.richest, record)) LifeBest.netWorth,
      if (identical(book.longest, record)) LifeBest.age,
      if (identical(book.wisest, record)) LifeBest.concepts,
    };

    final radius = BorderRadius.circular(AppTheme.radiusMedium);
    final hasStory = record.facts != null;

    // Opens the life's own diagnostic. Every row is tappable, and the ones that
    // kept their story say so, because a row that looks like a plain card is a
    // row nobody thinks to press.
    return Semantics(
      button: true,
      label:
          '${record.name.isEmpty ? 'Unnamed' : record.name}, '
          '${archetype?.label ?? 'unknown ending'}. Opens how this life went.',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: radius,
            border: Border.all(
              color: crowns.isEmpty
                  ? Colors.white.withValues(alpha: 0.10)
                  : PastLivesScreen._gold.withValues(alpha: 0.38),
            ),
          ),
          child: InkWell(
            key: ValueKey('open-life-${record.finishedAt.toIso8601String()}'),
            borderRadius: radius,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PastLifeScreen(record: record, book: book),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: _rowBody(record, archetype, accent, crowns, hasStory),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowBody(
    LifeRecord record,
    LifeEndingArchetype? archetype,
    Color accent,
    Set<LifeBest> crowns,
    bool hasStory,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                archetype?.icon ?? Icons.person_rounded,
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedLabel(
                    record.name.isEmpty ? 'Unnamed' : record.name,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  FittedLabel(
                    archetype?.label ?? 'Unknown ending',
                    style: GoogleFonts.quicksand(
                      color: accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (crowns.isNotEmpty)
              Icon(
                Icons.workspace_premium_rounded,
                color: PastLivesScreen._gold,
                size: 19,
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Stat(
              icon: Icons.cake_rounded,
              text: record.died
                  ? 'died at ${record.age}'
                  : 'retired at ${record.age}',
            ),
            _Stat(
              icon: Icons.savings_rounded,
              text: '${groupedNumber(record.netWorth)} net',
            ),
            _Stat(
              icon: Icons.school_rounded,
              text: '${record.conceptsMet} ideas',
            ),
            if (record.goldEarned > 0)
              _Stat(
                icon: Icons.monetization_on_rounded,
                text: '+${record.goldEarned} gold',
              ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          hasStory ? 'Tap to see how this life went' : 'Tap for the summary',
          style: GoogleFonts.quicksand(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
