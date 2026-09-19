import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../themes_colors/app_theme.dart';

/// What Life contains, said once before the first life.
///
/// **Asked for as:** *"for the ages, don't restrict anything, just give
/// warnings, and only make it ages 9 and up."* Life used to filter itself by the
/// account's age band: grown-up money words were held back from some players
/// and gambling from others. That is now one gate (nine and up) and one honest
/// list of what is inside, which is more use to a player and a parent than a
/// filter nobody can see.
///
/// The list is deliberately specific. "Contains mature themes" tells a parent
/// nothing; "a loved one can pass away, and it is handled gently" lets them
/// decide.
class LifeAdvisory {
  const LifeAdvisory._();

  /// One line per theme, in the order a player is likely to meet them.
  static const List<LifeAdvisoryNote> notes = <LifeAdvisoryNote>[
    LifeAdvisoryNote(
      icon: Icons.payments_rounded,
      title: 'Money and debt',
      body:
          'You will earn, spend, borrow and sometimes get it wrong. Loans and '
          'interest are part of the game because they are part of life.',
    ),
    LifeAdvisoryNote(
      icon: Icons.school_rounded,
      title: 'School and work',
      body:
          'Grades, degrees, jobs, and losing a job. Choices here change what '
          'you can do later.',
    ),
    LifeAdvisoryNote(
      icon: Icons.favorite_rounded,
      title: 'Family and friends',
      body:
          'People drift apart, move away, and a loved one can pass away. It is '
          'written gently, and you can carry on.',
    ),
    LifeAdvisoryNote(
      icon: Icons.monitor_heart_rounded,
      title: 'Health',
      body: 'Illness, injuries and getting older happen to every character.',
    ),
  ];

  /// The line under the list. Says what is *not* here, because that is the
  /// half a parent looks for.
  static const String reassurance =
      'Life keeps to family friendly topics, with no gambling. You can stop at '
      'any time. Retire ends a life safely.';
}

@immutable
class LifeAdvisoryNote {
  const LifeAdvisoryNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// Shows the advisory. Resolves true when the player chooses to start.
Future<bool> showLifeAdvisory(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const LifeAdvisoryDialog(),
  );
  return go ?? false;
}

class LifeAdvisoryDialog extends StatelessWidget {
  const LifeAdvisoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.panelStrong,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFF58C7FF),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Before you start Life',
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Life is for players 9 and up. It follows a whole life, so some '
                'parts are serious. Here is what to expect.',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final note in LifeAdvisory.notes)
                        _NoteRow(note: note),
                      const SizedBox(height: 4),
                      Text(
                        LifeAdvisory.reassurance,
                        style: GoogleFonts.quicksand(
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.4,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Not now',
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF43D07E),
                      foregroundColor: const Color(0xFF07200F),
                    ),
                    child: Text(
                      'Start my life',
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final LifeAdvisoryNote note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(note.icon, color: const Color(0xFF85EFAC), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note.body,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.35,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of Life to an account under nine.
Future<void> showLifeAgeGate(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.panelStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      title: Text(
        'Life is for ages 9 and up',
        style: GoogleFonts.pixelifySans(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Life follows a whole life, with grown up money choices and some '
        'serious moments, so it is for players 9 and up. Ask a grown up to '
        'help you, or try the Academy, the games and the town for now.',
        style: GoogleFonts.quicksand(
          color: Colors.white.withValues(alpha: 0.85),
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            'Okay',
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFF85EFAC),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
