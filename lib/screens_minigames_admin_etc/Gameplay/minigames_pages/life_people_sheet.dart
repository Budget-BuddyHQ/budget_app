import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_people.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../models_Like_Skins_and_lessons_templates/relationship.dart';
import '../../../themes_colors/app_theme.dart';
import 'life_ui_kit.dart';

/// **People:** your family, your friends, the person you are with, and the ones
/// you have lost, each with a bar for how close you are.
///
/// **Asked for as:** *"make it like BitLife, where there is a progression bar on
/// how close you are."* The old list said "Friend, Good" in small print and hid
/// the number. Now every row is a person with a bar you can read at a glance, in
/// groups the way a real life is grouped, and tapping one opens what you can do
/// about them.
const Color _accent = Color(0xFFFF8FB1);

Future<void> openPeople(BuildContext context, LifeSimController life) {
  return showLifeSheet<void>(context, builder: (_) => PeopleSheet(life: life));
}

/// Opens one person's screen. Used from the list and from Occupation.
Future<void> openPerson(
  BuildContext context,
  LifeSimController life,
  Relationship person,
) {
  return showLifeSheet<void>(
    context,
    builder: (_) => PersonSheet(life: life, name: person.name),
  );
}

class PeopleSheet extends StatelessWidget {
  const PeopleSheet({super.key, required this.life});

  final LifeSimController life;

  /// Parents first, then grandparents, then brothers and sisters. A family is
  /// read in that order, not by who happens to be closest this year.
  static int _familyOrder(Relationship p) {
    const order = <String>[
      'Mother',
      'Father',
      'Grandmother',
      'Grandfather',
      'Brother',
      'Sister',
    ];
    final i = order.indexOf(p.role);
    return i < 0 ? order.length : i;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final family = [...life.familyMembers]
          ..sort((a, b) => _familyOrder(a).compareTo(_familyOrder(b)));
        final groups = <(String, List<Relationship>)>[
          ('Family', family),
          ('Partner', life.partners),
          ('Children', life.childrenOfYours),
          ('Friends', life.friendList),
          ('Work', life.workPeople),
          ('Remembered', life.remembered),
        ];
        final total = life.people.length;
        return LifeSheet(
          title: 'People',
          icon: Icons.favorite_rounded,
          accent: _accent,
          subtitle: total == 0
              ? 'Nobody yet'
              : '$total ${total == 1 ? 'person' : 'people'} · closeness ${life.connection}%',
          children: [
            if (total == 0)
              const LifeCard(
                child: Text(
                  'Nobody yet. People turn up as you live. Clubs, school and '
                  'work are good places to start.',
                ),
              ),
            for (final g in groups)
              if (g.$2.isNotEmpty) ...[
                LifeSection(g.$1),
                for (final p in g.$2) _PersonRow(life: life, person: p),
              ],
            const SizedBox(height: 8),
            Text(
              'Closeness fades a little every year you do not see somebody. '
              'Time together is the fastest way to bring it back.',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.life, required this.person});

  final LifeSimController life;
  final Relationship person;

  @override
  Widget build(BuildContext context) {
    final age = person.ageWhen(life.age);
    final gone = !person.isAlive;
    return LifeRow(
      icon: person.kind.icon,
      accent: person.kind.accent,
      title: person.name,
      subtitle:
          '${person.roleLabel}${age == null ? '' : ' · age $age'}'
          '${gone ? ' · passed away' : ''}',
      onTap: () => openPerson(context, life, person),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
      bar: gone
          ? null
          : LifeBar(
              label: person.status,
              value: person.closeness,
              color: person.statusColour,
              height: 7,
            ),
    );
  }
}

/// One person: how close you are, and what you can do about it.
class PersonSheet extends StatelessWidget {
  const PersonSheet({super.key, required this.life, required this.name});

  final LifeSimController life;
  final String name;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final person = life.personByName(name);
        if (person == null) return const SizedBox.shrink();
        final age = person.ageWhen(life.age);
        final years = life.age - person.metAtAge;
        final seen = person.lastSeenAge;
        final actions = life.actionsFor(name);
        return LifeSheet(
          title: person.name,
          icon: person.kind.icon,
          accent: person.kind.accent,
          subtitle:
              '${person.roleLabel}${age == null ? '' : ' · age $age'}'
              '${years <= 0 ? ' · you just met' : ''}',
          children: [
            LifeCard(
              accent: person.kind.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (person.isAlive)
                    LifeBar(
                      label: 'How close you are',
                      value: person.closeness,
                      color: person.statusColour,
                      trailing: '${person.status}  ${person.closeness}',
                      height: 11,
                    )
                  else
                    Text(
                      'Passed away when you were ${person.passedAge}.',
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    person.isAlive
                        ? (person.isPresent
                              ? 'Closeness fades a little every year you do not '
                                    'see them. Time brings it back faster than '
                                    'anything you can buy.'
                              : 'You lost touch. It is not too late, but it takes '
                                    'more than a present.')
                        : 'They stay in your story. What they gave you is still '
                              'there.',
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (person.isAlive && seen != null && seen < life.age) ...[
                    const SizedBox(height: 6),
                    Text(
                      life.age - seen == 1
                          ? 'Last saw them a year ago.'
                          : 'Last saw them ${life.age - seen} years ago.',
                      style: GoogleFonts.quicksand(
                        color: person.statusColour,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (person.isAlive) ...[
              const LifeSection('Do something together'),
              if (person.kind.isProfessional) ...[
                LifeRow(
                  icon: Icons.local_cafe_rounded,
                  title: 'Catch up over coffee',
                  subtitle:
                      'Contacts fade faster than family. An hour and a few '
                      'coins keeps them warm, and warm contacts pass on leads.\n'
                      '${life.budgetFor(LifeAction.network).label ?? ''}',
                  accent: const Color(0xFF58C7FF),
                  disabledReason:
                      life.unavailableFor(LifeAction.network) ??
                      (life.isDependent || life.money >= 10
                          ? null
                          : 'Not enough coins'),
                  trailing: life.isDependent
                      ? null
                      : const LifeChip('-10', color: Color(0xFFFFD45C)),
                  onTap: () => life.coffeeWith(name),
                ),
              ],
              for (final a in actions)
                LifeRow(
                  icon: a.icon,
                  title: a.label,
                  subtitle: _noteFor(a),
                  accent: person.kind.accent,
                  disabledReason: life.personActionGate(a, name),
                  trailing: switch (a) {
                    PersonAction.gift => const LifeChip(
                      '-50',
                      color: Color(0xFFFFD45C),
                    ),
                    PersonAction.date => const LifeChip(
                      '-40',
                      color: Color(0xFFFFD45C),
                    ),
                    _ => null,
                  },
                  onTap: () => life.doPersonAction(a, name),
                ),
            ],
          ],
        );
      },
    );
  }

  /// The blurb, with what is left of this year's allowance under it.
  String _noteFor(PersonAction a) {
    final budget = switch (a) {
      PersonAction.conversation ||
      PersonAction.askAdvice => life.budgetFor(LifeAction.conversation).label,
      PersonAction.compliment => life.budgetFor(LifeAction.compliment).label,
      PersonAction.spendTime => life.budgetFor(LifeAction.spendTime).label,
      PersonAction.gift => life.budgetFor(LifeAction.buyGift).label,
      PersonAction.askMoney => life.budgetFor(LifeAction.askMoney).label,
      PersonAction.date => life.budgetFor(LifeAction.date).label,
      _ => null,
    };
    return budget == null ? a.blurb : '${a.blurb}\n$budget';
  }
}
