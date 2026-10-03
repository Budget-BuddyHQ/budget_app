import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers_that_updates_stats/life_sim_controller.dart';
import '../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../themes_colors/app_theme.dart';
import '../utils/number_format.dart';

/// What this year's job paid, and where every coin of it went.
///
/// **Reported as** a younger tester *"wasn't understanding why he wasn't
/// getting any money from his job"* and *"didn't know when he missed work."*
/// The money was there: on a default budget, bills, the wants slice and
/// savings take most of a paycheck before any of it reaches Cash, so a 1,000
/// salary can move the Cash box by a few dozen coins. The game said so, in one
/// feed line among many, and missed weeks were another. This card says it as a
/// picture — one bar, cut into where the pay went — with the missed weeks in
/// red above it and the two things a player can do about either: change the
/// budget, or see a doctor.
///
/// An adult with no job gets the other half of the answer: no job, no payday,
/// and where to find one.
class PaydayCard extends StatelessWidget {
  const PaydayCard({
    super.key,
    required this.life,
    required this.onOpenBudget,
    required this.onFindJob,
    required this.onSeeDoctor,
  });

  final LifeSimController life;
  final VoidCallback onOpenBudget;
  final VoidCallback onFindJob;
  final VoidCallback onSeeDoctor;

  static const _bills = Color(0xFFFF8F70);
  static const _wants = Color(0xFFFFC800);
  static const _saved = Color(0xFF1CB0F6);
  static const _loans = Color(0xFFCE82FF);
  static const _cash = Color(0xFF9BE870);
  static const _other = Color(0xFF8FA3AE);

  @override
  Widget build(BuildContext context) {
    final slip = life.lastPaySlip;
    if (slip != null) return _payday(slip);
    if (!life.isDependent &&
        !life.hasJob &&
        life.canJobHunt &&
        !life.finished) {
      return _noJob();
    }
    return const SizedBox.shrink();
  }

  Widget _shell({required Color accent, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent, width: 2),
        boxShadow: AppTheme.ledgeShadow(accent, restAlpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _title(String emoji, String text, {Widget? trailing}) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _button(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _noJob() {
    return _shell(
      accent: AppTheme.outline,
      children: [
        _title('\u{1F4BC}', 'No job, no payday'),
        const SizedBox(height: 6),
        const Text(
          'Money from a job only comes while you have one. Find work and '
          'your pay arrives every year when you age up.',
          style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 12),
        _button(
          'Find a job',
          Icons.work_rounded,
          AppTheme.greenPrimary,
          onFindJob,
        ),
      ],
    );
  }

  Widget _payday(PaySlip slip) {
    // Everything the pay was cut into. Debt interest and the like are what is
    // left over once the named parts are taken away.
    final named = slip.loans + slip.bills + slip.wants + slip.saved;
    final other = (slip.pay - named - slip.toCash).clamp(0, slip.pay);
    final parts = <(String, String, int, Color)>[
      ('\u{1F3E0}', 'Bills: rent, food, the basics', slip.bills, _bills),
      if (slip.loans > 0) ('\u{1F4C4}', 'Loan payments', slip.loans, _loans),
      ('\u{1F389}', 'Fun money: spent on things you like', slip.wants, _wants),
      ('\u{1F3E6}', 'Saved: in your Saved box', slip.saved, _saved),
      if (other > 0) ('\u{1F9FE}', 'Debt and other costs', other, _other),
      if (slip.toCash > 0) ('\u{1F4B5}', 'Into your Cash', slip.toCash, _cash),
    ];
    final missed = slip.weeksMissed > 0 && slip.missedPay > 0;
    final unwell =
        slip.missedBecause?.contains('unwell') == true ||
        slip.missedBecause?.contains('health') == true;

    return _shell(
      accent: missed ? const Color(0xFFFF6B6B) : AppTheme.greenPrimary,
      children: [
        _title(
          '\u{1F4B5}',
          'Payday',
          trailing: Text(
            '+${groupedNumber(slip.pay)}',
            style: AppTheme.numeric(color: _cash, fontSize: 18),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          missed
              ? 'Your job pays ${groupedNumber(slip.fullPay)} a year. You got '
                    '${groupedNumber(slip.pay)}.'
              : 'Your job paid ${groupedNumber(slip.pay)} this year. Here is '
                    'where it went.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        if (missed) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.inset,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You missed ${slip.weeksMissed} '
                  '${slip.weeksMissed == 1 ? 'week' : 'weeks'} of work '
                  'because of ${slip.missedBecause ?? 'feeling run down'}, so '
                  'you were paid ${groupedNumber(slip.missedPay)} less.',
                  style: const TextStyle(
                    color: Color(0xFFFFB3B3),
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unwell
                      ? 'Get your Health back up and you will stop missing '
                            'work. Miss a lot two years running and you can '
                            'lose the job.'
                      : 'Do things that make you happy and rest. Miss a lot '
                            'two years running and you can lose the job.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (unwell) ...[
                  const SizedBox(height: 8),
                  _button(
                    'See the doctor',
                    Icons.medical_services_rounded,
                    const Color(0xFFFF8F8F),
                    onSeeDoctor,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // One bar, cut into where the pay went.
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                for (final (_, _, amount, color) in parts)
                  if (amount > 0)
                    Expanded(
                      flex: amount,
                      child: Container(color: color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final (emoji, label, amount, color) in parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
                Text(
                  groupedNumber(amount),
                  style: AppTheme.numeric(color: color, fontSize: 13),
                ),
              ],
            ),
          ),
        if (slip.toCash <= 0) ...[
          const SizedBox(height: 4),
          Text(
            slip.toCash < 0
                ? 'Your Cash went down by ${groupedNumber(-slip.toCash)} this '
                      'year: everything was spent and then some.'
                : 'Nothing was left over for Cash this year.',
            style: const TextStyle(
              color: Color(0xFFFFB3B3),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          life.budgetSet
              ? 'Your budget decides these slices.'
              : 'This is the starting 50/30/20 budget. Half is kept for '
                    'bills, and whatever the bills did not use comes back to '
                    'your Cash. About a third is fun money, and a fifth is '
                    'saved. You can choose your own split.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        _button(
          life.budgetSet ? 'Change my budget' : 'Set my budget',
          Icons.pie_chart_rounded,
          AppTheme.greenPrimary,
          onOpenBudget,
        ),
      ],
    );
  }
}

/// Whether the doctor can be seen right now, and if not, why — for the
/// Payday card's button. Kept beside the card so the page does not have to
/// know which action the card means.
String? doctorUnavailable(LifeSimController life) =>
    life.unavailableFor(LifeAction.doctor);
