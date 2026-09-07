import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../themes_colors/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_seed.dart';

/// What character creation hands back to the Life screen.
@immutable
class LifeCharacter {
  const LifeCharacter({
    required this.name,
    required this.gender,
    required this.origin,
    required this.seed,
    this.graded = true,
  });

  final String name;
  final Gender gender;

  /// Rolled from [seed], never chosen. See [LifeSeed].
  final LifeOrigin origin;

  /// The seed this life was rolled from, so it can be shown and replayed.
  final LifeSeed seed;

  /// Whether this run should count toward records and the coach's reading.
  final bool graded;
}

const List<String> _firstNames = [
  'Alex',
  'Sam',
  'Jordan',
  'Riley',
  'Casey',
  'Morgan',
  'Quinn',
  'Avery',
  'Rowan',
  'Kai',
  'Noor',
  'Ellis',
  'Frankie',
  'Sasha',
  'Devon',
];
const List<String> _lastNames = [
  'Morgan',
  'Reyes',
  'Okafor',
  'Lindqvist',
  'Nakamura',
  'Silva',
  'Bennett',
  'Haddad',
  'Kowalski',
  'Osei',
  'Romano',
  'Fischer',
];

/// Character creation for a new life: name, gender, and the family you are
/// born into. Kept to one screen so starting a life takes seconds.
class LifeCharacterSheet extends StatefulWidget {
  const LifeCharacterSheet({super.key});

  @override
  State<LifeCharacterSheet> createState() => _LifeCharacterSheetState();
}

class _LifeCharacterSheetState extends State<LifeCharacterSheet> {
  final Random _random = Random();

  /// The seed this life is rolled from.
  ///
  /// The family you are born into comes from here rather than from a picker.
  /// It supplied **0 coins for Struggling against 2,500 for Wealthy** — the
  /// largest advantage in the game, previously a free choice made before the
  /// first year. Nobody picks the family they are born into, and an app about
  /// money that let you pick a rich one was teaching the opposite of its own
  /// subject.
  LifeSeed _seed = LifeSeed.fresh();

  late final TextEditingController _nameController = TextEditingController(
    text: _seed.suggestedName(_firstNames, _lastNames),
  );
  late final TextEditingController _seedController = TextEditingController(
    text: _seed.display,
  );

  Gender _gender = Gender.nonBinary;

  /// Whether this run counts.
  ///
  /// Players deliberately wreck a run to reach an unusual ending or to farm
  /// quick gold, and the coach was reading every one of those as evidence
  /// they were getting worse at money. An ungraded run still plays and still
  /// pays; it simply does not go into the record the coach reasons over.
  bool _graded = true;

  LifeOrigin get _origin => _seed.origin;

  String _randomName() =>
      '${_firstNames[_random.nextInt(_firstNames.length)]} '
      '${_lastNames[_random.nextInt(_lastNames.length)]}';

  /// A whole new life: new seed, new family, new suggested name.
  ///
  /// The weighting (35/35/22/8) moved into [LifeSeed] so the same odds apply
  /// whether a life is rolled here or restored from a typed seed.
  void _reroll() {
    HapticFeedback.selectionClick();
    setState(() {
      _seed = LifeSeed.fresh();
      _seedController.text = _seed.display;
      _nameController.text = _seed.suggestedName(_firstNames, _lastNames);
      _gender = Gender.values[_random.nextInt(Gender.values.length)];
    });
  }

  /// Applies a seed the player typed in.
  ///
  /// The point of a readable seed is that somebody can replay the exact start
  /// they just had, or hand it to a friend and compare what each of them did
  /// with the same beginning. That only works if typing it back in actually
  /// restores the life.
  void _applyTypedSeed() {
    final next = LifeSeed.parse(_seedController.text);
    setState(() {
      _seed = next;
      _seedController.text = next.display;
      _nameController.text = next.suggestedName(_firstNames, _lastNames);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  void _start() {
    final typed = _nameController.text.trim();
    Navigator.of(context).pop(
      LifeCharacter(
        name: typed.isEmpty ? _randomName() : typed,
        gender: _gender,
        origin: _origin,
        seed: _seed,
        graded: _graded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: AppTheme.deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'New Life',
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Text(
              'Who are you?',
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You will be born and live one year at a time.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            _Label('Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                hintText: 'Your character name',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                suffixIcon: IconButton(
                  tooltip: 'Random name',
                  onPressed: () =>
                      setState(() => _nameController.text = _randomName()),
                  icon: const Icon(Icons.casino_rounded, color: Colors.white54),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _Label('Gender'),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final option in Gender.values) ...[
                  Expanded(
                    child: _ChoiceTile(
                      label: option.label,
                      icon: option.icon,
                      selected: option == _gender,
                      onTap: () => setState(() => _gender = option),
                    ),
                  ),
                  if (option != Gender.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 22),

            // The seed, and the family it rolled.
            //
            // This replaced a four-option picker for `LifeOrigin`, which
            // supplies the starting money — **0 coins for Struggling against
            // 2,500 for Wealthy**. It was the largest advantage in the game,
            // free, chosen before the first year. Nobody picks the family
            // they are born into, and an app about money that let you pick a
            // rich one was teaching against itself.
            //
            // The seed is shown rather than hidden because a hidden roll is
            // indistinguishable from the game cheating when a run goes badly.
            // Readable and typeable means a player can replay the exact start
            // they just had, or hand it to somebody and compare.
            _Label('Seed'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seedController,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _applyTypedSeed(),
                    style: AppTheme.numeric(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a seed to replay a life',
                      filled: true,
                      fillColor: AppTheme.panel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Use this seed',
                        onPressed: _applyTypedSeed,
                        icon: const Icon(Icons.check_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Roll a new life',
                  onPressed: _reroll,
                  icon: const Icon(Icons.casino_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Label('Family you are born into'),
            const SizedBox(height: 8),
            _OriginTile(origin: _origin, selected: true, onTap: null),
            const SizedBox(height: 6),
            Text(
              'Rolled from the seed — nobody chooses this one.',
              style: AppTheme.numeric(
                color: AppTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 22),
            _Label('Does this run count?'),
            const SizedBox(height: 8),
            // Graded or not, chosen up front.
            //
            // Players deliberately wreck a run to reach an unusual ending or
            // to farm quick gold, and the coach was reading every one of
            // those as evidence they were getting worse with money. An
            // ungraded run still plays and still pays — it just stays out of
            // the record the coach reasons over.
            SwitchListTile.adaptive(
              value: _graded,
              onChanged: (value) => setState(() => _graded = value),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: const Color(0xFF43D07E),
              title: Text(
                _graded ? 'Graded' : 'Just messing about',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _graded
                    ? 'Saved to your past lives, and your coach reads it.'
                    : 'Still pays out and still unlocks endings — your coach '
                          'just will not judge you on it.',
                style: AppTheme.numeric(
                  color: AppTheme.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),

            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _reroll,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD45C),
                side: BorderSide(
                  color: const Color(0xFFFFD45C).withValues(alpha: 0.55),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.casino_rounded),
              label: Text(
                'Roll a different life',
                style: GoogleFonts.pixelifySans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF43D07E),
                foregroundColor: const Color(0xFF06251A),
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              icon: const Icon(Icons.child_care_rounded),
              label: Text(
                'Begin life',
                style: GoogleFonts.pixelifySans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.pixelifySans(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF43D07E).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF43D07E)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF43D07E) : Colors.white54,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OriginTile extends StatelessWidget {
  const _OriginTile({
    required this.origin,
    required this.selected,
    this.onTap,
  });

  final LifeOrigin origin;
  final bool selected;

  /// Null when the tile is a read-out rather than a choice.
  ///
  /// The family is rolled from the seed now, so this renders the result
  /// instead of offering four of them. Keeping the same tile means the
  /// rolled family is presented exactly as prominently as it used to be
  /// chosen — it still matters, it is simply not yours to pick.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF43D07E).withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF43D07E)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFF43D07E) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    origin.label,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    origin.blurb,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.3,
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
