import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models_Like_Skins_and_lessons_templates/life_debrief.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../utils/number_format.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import 'life_debrief_view.dart';

/// One finished life, opened from Past Lives.
///
/// **Asked for as:** *"when they click on one of these past runs it pulls their
/// diagnostic."* The epilogue showed the diagnostic once, at the end of the life,
/// and then it was gone: the history list kept a name, an age and a net worth.
///
/// A record now keeps what the debrief was graded on, and this screen grades it
/// again. That is deliberate rather than storing the finished text: if a rule is
/// later corrected, an old life is read by the corrected rule instead of by
/// wording that was true when it was written.
///
/// **Older lives.** Only the newest few keep the full story, and every life filed
/// before this existed kept none. Those open to a plain summary that says so.
/// Running the rules on a record that has no cash, no debt and no savings would
/// grade an empty life and report that the player saved nothing, which would be
/// false, so it does not.
class PastLifeScreen extends StatelessWidget {
  const PastLifeScreen({super.key, required this.record, this.book});

  final LifeRecord record;

  /// The whole history, for the "how did this compare" line. Optional.
  final LifeRecordBook? book;

  @override
  Widget build(BuildContext context) {
    final facts = record.facts;
    final archetype = record.archetype;
    final accent = archetype?.color ?? const Color(0xFF85EFAC);

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FittedLabel(
          record.name.isEmpty ? 'A past life' : record.name,
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Header(record: record, accent: accent),
          const SizedBox(height: 16),
          if (facts != null)
            LifeDebriefView(
              key: const ValueKey('past-life-debrief'),
              debrief: debriefLife(facts),
              practice: !record.graded,
              thisNetWorth: record.netWorth,
              netWorthsOfEveryLife: [
                for (final r in book?.records ?? const <LifeRecord>[])
                  r.netWorth,
              ],
            )
          else
            const _NoStoryNote(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.record, required this.accent});

  final LifeRecord record;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final archetype = record.archetype;
    final chip = AppTheme.tintedChip(accent, alpha: 0.14);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(archetype?.icon ?? Icons.person_rounded, color: chip.ink),
              const SizedBox(width: 10),
              Expanded(
                child: FittedLabel(
                  archetype?.label ?? 'Unknown ending',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Fact(
                record.died
                    ? 'Died at ${record.age}'
                    : 'Retired at ${record.age}',
              ),
              _Fact('${groupedNumber(record.netWorth)} net worth'),
              _Fact('${record.conceptsMet} ideas met'),
              if (record.detail != null && record.detail!.degrees > 0)
                _Fact(
                  record.detail!.degrees == 1
                      ? '1 qualification'
                      : '${record.detail!.degrees} qualifications',
                ),
              if (record.detail?.ownedHome ?? false)
                const _Fact('Owned a home'),
              if (!record.graded) const _Fact('Practice run'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // A pill, as on the history rows, so a run of facts reads as separate facts
    // and not as one sentence with the punctuation missing.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.quicksand(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// What an older life opens to.
class _NoStoryNote extends StatelessWidget {
  const _NoStoryNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('past-life-no-story'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The full story was not kept for this one',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only your newest lives keep the year-by-year story that the '
            'diagnostic is built from, and lives filed before that existed '
            'never did. What is above is everything this one remembers.\n\n'
            'Finish another life and it will open like the ending screen '
            'did: what the run says about how it was played, and what to do '
            'differently next time.',
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
