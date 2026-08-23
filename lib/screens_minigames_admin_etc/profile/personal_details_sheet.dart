import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../../widgets_custom_lotties/game_toast.dart';

/// Collects the player's self-described age band and gender.
///
/// Shown once after sign-up and re-openable any time from the profile screen.
/// Both answers are optional — "Rather not say" is a first-class choice, and
/// the app works identically either way.
class PersonalDetailsSheet extends StatefulWidget {
  const PersonalDetailsSheet({
    super.key,
    required this.initialAgeBand,
    required this.initialGender,
    this.isFirstRun = false,
  });

  final AgeBand initialAgeBand;
  final GenderIdentity initialGender;

  /// First run gets a friendlier intro and no "cancel" affordance beyond skip.
  final bool isFirstRun;

  static Future<bool?> show(
    BuildContext context, {
    required AgeBand ageBand,
    required GenderIdentity gender,
    bool isFirstRun = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !isFirstRun,
      enableDrag: !isFirstRun,
      builder: (_) => PersonalDetailsSheet(
        initialAgeBand: ageBand,
        initialGender: gender,
        isFirstRun: isFirstRun,
      ),
    );
  }

  @override
  State<PersonalDetailsSheet> createState() => _PersonalDetailsSheetState();
}

class _PersonalDetailsSheetState extends State<PersonalDetailsSheet> {
  late AgeBand _ageBand = widget.initialAgeBand;
  late GenderIdentity _gender = widget.initialGender;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);

    final result = await context
        .read<UserStatsController>()
        .updatePersonalDetails(ageBand: _ageBand, gender: _gender);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
    GameToast.show(
      context,
      title: 'Profile saved',
      message: result.message,
      icon: Icons.person_rounded,
      accent: const Color(0xFF85EFAC),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    // Cap the sheet so it stays usable in landscape, where the available
    // height can be under 400pt.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D2B20),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isFirstRun ? 'Welcome aboard' : 'About you',
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This tailors the money examples in the Academy so the '
                          'numbers actually match your life. Both answers are '
                          'optional and you can change them any time.',
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _SectionLabel('HOW OLD ARE YOU?'),
                        const SizedBox(height: 10),
                        _ChoiceWrap<AgeBand>(
                          values: AgeBand.values,
                          selected: _ageBand,
                          labelOf: (band) => band.label,
                          onSelected: (band) => setState(() => _ageBand = band),
                        ),
                        const SizedBox(height: 22),
                        const _SectionLabel('HOW DO YOU DESCRIBE YOURSELF?'),
                        const SizedBox(height: 10),
                        _ChoiceWrap<GenderIdentity>(
                          values: GenderIdentity.values,
                          selected: _gender,
                          labelOf: (gender) => gender.label,
                          onSelected: (gender) =>
                              setState(() => _gender = gender),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Only you see this. It never changes which '
                                  'skins, games, or lessons you can reach.',
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: [
                      if (widget.isFirstRun)
                        Expanded(
                          child: TextButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: const Text('Skip for now'),
                          ),
                        ),
                      if (widget.isFirstRun) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2F9E68),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: GoogleFonts.pixelifySans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.pixelifySans(
        color: const Color(0xFFB8F5D1),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(labelOf(value)),
            selected: value == selected,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelected(value);
            },
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            selectedColor: const Color(0xFF2F9E68),
            side: BorderSide(
              color: value == selected
                  ? const Color(0xFF85EFAC)
                  : Colors.white.withValues(alpha: 0.14),
            ),
            labelStyle: TextStyle(
              color: value == selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            showCheckmark: false,
          ),
      ],
    );
  }
}
