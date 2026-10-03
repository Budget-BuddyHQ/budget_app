import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../themes_colors/app_theme.dart';

/// "Set a budget" — and how, in three steps a nine-year-old can follow.
///
/// **Reported as:** a younger tester *"didn't know how to set a budget after
/// reading the coach's feedback."* The Coach said "set your budget in the
/// Assets tab", and the end-of-life review said "set one the first year you
/// are paid". Both were right and neither said where the control is: it lives
/// inside a Life game, only once the character has a paycheck, as a bar under
/// "Your money". This sheet shows that bar, says when it appears, and names
/// the buttons by the words on them.
Future<void> showHowToSetBudget(
  BuildContext context, {
  bool offerPlayLife = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTheme.panel,
    builder: (sheetContext) => _HowToBudgetSheet(
      onPlayLife: offerPlayLife
          ? () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).pushNamed('/life');
            }
          : null,
    ),
  );
}

/// The button that opens [showHowToSetBudget], for advice that says "set a
/// budget".
class HowToBudgetButton extends StatelessWidget {
  const HowToBudgetButton({super.key, this.offerPlayLife = true});

  final bool offerPlayLife;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () =>
          showHowToSetBudget(context, offerPlayLife: offerPlayLife),
      icon: const Icon(Icons.help_outline_rounded, size: 18),
      label: Text(
        'How do I set a budget?',
        style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.greenPrimary,
        side: const BorderSide(color: AppTheme.greenPrimary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _HowToBudgetSheet extends StatelessWidget {
  const _HowToBudgetSheet({required this.onPlayLife});

  final VoidCallback? onPlayLife;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.turtleMentorWave,
                width: 64,
                height: 64,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => const SizedBox(width: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Setting a budget',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'A budget decides what happens to your pay before you get it: how '
            'much goes to bills, how much to fun, and how much you save. You '
            'set it in the Life game.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 18),
          const _Step(
            n: 1,
            title: 'Get a job in Life',
            body:
                'The budget appears once your character is paid. Age up to '
                '18, then tap the briefcase (Occupation) and find a job.',
          ),
          const _Step(
            n: 2,
            title: 'Tap the budget bar',
            body:
                'Under "Your money" there is a coloured bar that says "Pick a '
                'budget". Tap it. The Payday card has a "Set my budget" button '
                'too.',
            picture: _BarPicture(),
          ),
          const _Step(
            n: 3,
            title: 'Slide, then save',
            body:
                'Move Needs, Wants and Savings until they add up to 100%. Not '
                'sure? Tap "Use 50/30/20". Then tap "Save budget".',
          ),
          const SizedBox(height: 6),
          Text(
            'The earlier you set it, the more years it works for you.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          if (onPlayLife != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlayLife,
                icon: const Icon(Icons.explore_rounded),
                label: Text(
                  'Play Life',
                  style: GoogleFonts.pixelifySans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.greenPrimary,
                  foregroundColor: const Color(0xFF062017),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.body,
    this.picture,
  });

  final int n;
  final String title;
  final String body;
  final Widget? picture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.greenPrimary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$n',
              style: AppTheme.numeric(
                color: const Color(0xFF062017),
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                if (picture != null) ...[const SizedBox(height: 8), picture!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A drawing of the budget bar as it looks in the game, so the player
/// recognises it when they see it.
class _BarPicture extends StatelessWidget {
  const _BarPicture();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '\u{1F9FE} Pick a budget',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to set',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.touch_app_rounded,
                color: AppTheme.greenPrimary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: Container(color: const Color(0xFFFF8F70)),
                  ),
                  Expanded(
                    flex: 30,
                    child: Container(color: const Color(0xFFFFC800)),
                  ),
                  Expanded(
                    flex: 20,
                    child: Container(color: const Color(0xFF1CB0F6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Needs 50 · Wants 30 · Savings 20',
            style: AppTheme.numeric(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
