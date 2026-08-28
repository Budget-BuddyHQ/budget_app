import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson_data.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson_sources.dart';
import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../themes_colors/app_theme.dart';

/// The Academy's credibility panel: what the curriculum contains, and who
/// says so.
///
/// **Why this is on the screen rather than in a settings page.** A learning
/// app is asking to be believed. Most of them ask implicitly — clean design,
/// confident tone, no attribution anywhere — and a reader has no way to tell
/// a carefully researched lesson from one somebody wrote from memory. Putting
/// the count of lessons, the count of questions and the list of publishers on
/// the front of the Academy makes the claim checkable in one tap, which is
/// both the honest thing to do and the habit the app is trying to teach.
///
/// The numbers are computed from the data rather than typed in, so they
/// cannot drift out of date the way a hardcoded "50+ lessons!" would.
class CurriculumSourcesCard extends StatelessWidget {
  const CurriculumSourcesCard({super.key, this.compact = false});

  final bool compact;

  static int get _lessonCount => lessonUnits
      .expand((unit) => unit.lessons)
      .where((lesson) => lesson.type == LessonNodeType.lesson)
      .length;

  static int get _questionCount => allQuizQuestions.length;

  /// Distinct publishers across the whole citation catalogue.
  static List<String> get publishers {
    final names = <String>{
      for (final source in kLessonSources.values) source.publisher,
    }.toList()..sort();
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(const Color(0xFF69C6FF), alpha: 0.14);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: const Color(0xFF69C6FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 18, color: chip.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Every lesson is sourced',
                  style: GoogleFonts.pixelifySans(
                    color: chip.ink,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_lessonCount lessons and $_questionCount questions, checked '
            'against the agencies that publish the rules — not against a '
            'bank that sells the products.',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final publisher in publishers.take(compact ? 4 : 6))
                _PublisherChip(name: publisher),
              if (publishers.length > (compact ? 4 : 6))
                _PublisherChip(
                  name: '+${publishers.length - (compact ? 4 : 6)} more',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showAllSources(context),
              style: TextButton.styleFrom(
                foregroundColor: chip.ink,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.library_books_outlined, size: 16),
              label: Text(
                'See all sources',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The full citation list, grouped by publisher.
  static Future<void> showAllSources(BuildContext context) {
    final byPublisher = <String, List<LessonSource>>{};
    for (final source in kLessonSources.values) {
      byPublisher.putIfAbsent(source.publisher, () => []).add(source);
    }
    final publisherNames = byPublisher.keys.toList()..sort();

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.deepForest,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(
              'Where this comes from',
              style: GoogleFonts.pixelifySans(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Federal agencies and the regulators\' own education arms. '
              'Nothing here is selling a financial product, which is the '
              'point — a source with something to sell is an advertisement '
              'with footnotes.',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            for (final publisher in publisherNames) ...[
              Text(
                publisher,
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFF9CDBFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final source in byPublisher[publisher]!)
                _SourceRow(source: source),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _PublisherChip extends StatelessWidget {
  const _PublisherChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        name,
        style: GoogleFonts.quicksand(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final LessonSource source;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final launched = await launchUrl(
          Uri.parse(source.url),
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          // Showing the URL beats a failure toast: it can still be read,
          // typed or copied, which is the entire purpose of a citation.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(source.url)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: Color(0xFF69C6FF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Uri.parse(source.url).host,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
