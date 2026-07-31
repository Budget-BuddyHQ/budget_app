import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';

/// What character creation hands back to the Life screen.
@immutable
class LifeCharacter {
  const LifeCharacter({
    required this.name,
    required this.gender,
    required this.origin,
  });

  final String name;
  final Gender gender;
  final LifeOrigin origin;
}

const List<String> _firstNames = [
  'Alex', 'Sam', 'Jordan', 'Riley', 'Casey', 'Morgan', 'Quinn', 'Avery',
  'Rowan', 'Kai', 'Noor', 'Ellis', 'Frankie', 'Sasha', 'Devon',
];
const List<String> _lastNames = [
  'Morgan', 'Reyes', 'Okafor', 'Lindqvist', 'Nakamura', 'Silva', 'Bennett',
  'Haddad', 'Kowalski', 'Osei', 'Romano', 'Fischer',
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
  late final TextEditingController _nameController = TextEditingController(
    text: _randomName(),
  );
  Gender _gender = Gender.nonBinary;
  LifeOrigin _origin = LifeOrigin.workingClass;

  String _randomName() =>
      '${_firstNames[_random.nextInt(_firstNames.length)]} '
      '${_lastNames[_random.nextInt(_lastNames.length)]}';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    final typed = _nameController.text.trim();
    Navigator.of(context).pop(
      LifeCharacter(
        name: typed.isEmpty ? _randomName() : typed,
        gender: _gender,
        origin: _origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071711),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Life',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            const Text(
              'Who are you?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
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
            _Label('Family you are born into'),
            const SizedBox(height: 8),
            for (final option in LifeOrigin.values) ...[
              _OriginTile(
                origin: option,
                selected: option == _origin,
                onTap: () => setState(() => _origin = option),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF43D07E),
                foregroundColor: const Color(0xFF06251A),
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              icon: const Icon(Icons.child_care_rounded),
              label: const Text(
                'Begin life',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 11,
        fontWeight: FontWeight.w900,
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
    required this.onTap,
  });

  final LifeOrigin origin;
  final bool selected;
  final VoidCallback onTap;

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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
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
