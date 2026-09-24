import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lives a few hundred random lives and checks that the story and the
/// Assets/People screens never disagree about the same fact.
///
/// **The bug this exists for.** A friend asked to split a flat, the player
/// said yes, and the Assets tab still showed them living with their parents:
/// the story card set a [LifeFlag] and the screen read a separate record of
/// the same fact, and nothing kept the two in step. The same split existed
/// for a pet, a car, home ownership and a student loan. See
/// `LifeSimController._effectiveFlags`, which now reads each of these flags
/// back from what is actually owned — a future card that grants an asset
/// without going through that machinery is the only way to break this again.
void main() {
  test('the story and the Assets/People screens always agree', () {
    final seen = <String, Set<String>>{};
    void note(String what, String eventId) =>
        seen.putIfAbsent(what, () => <String>{}).add(eventId);

    for (var i = 0; i < 400; i++) {
      final rand = Random(i);
      final life = LifeSimController(
        random: Random(i * 7 + 1),
        name: 'Sim $i',
        initialAge: 0,
        startMoney: 2000,
      );
      var last = '';
      for (var y = 0; y < 90 && !life.finished; y++) {
        life.ageUp();
        final e = life.currentEvent;
        if (e != null) {
          last = e.id;
          life.chooseOption(rand.nextInt(e.choices.length));
        }
        final f = life.flags;
        if (f.contains(LifeFlag.hasPet) &&
            life.assetsOf(AssetKind.pet).isEmpty) {
          note('flag hasPet but no pet in Assets', last);
        }
        if (f.contains(LifeFlag.hasCar) &&
            life.assetsOf(AssetKind.vehicle).isEmpty) {
          note('flag hasCar but no vehicle in Assets', last);
        }
        if (f.contains(LifeFlag.ownsHome) && !life.ownsHome) {
          note('flag ownsHome but no home in Assets', last);
        }
        if (f.contains(LifeFlag.hasStudentLoan) &&
            !life.loans.any((l) => l.kind == LoanKind.student)) {
          note('flag hasStudentLoan but no student loan', last);
        }
        if (f.contains(LifeFlag.rentsWithFriend) &&
            life.rental.id == 'family' &&
            !life.ownsHome) {
          note('flag rentsWithFriend but Assets says family home', last);
        }
        if (f.contains(LifeFlag.carGone) &&
            life.assetsOf(AssetKind.vehicle).isNotEmpty) {
          note('flag carGone but a vehicle is still owned', last);
        }
        if (life.age < 18 && life.rental.id != 'family') {
          note('a minor is not living with family', last);
        }
        final kids = life.people.where((p) => p.kind == RelationshipKind.child);
        if (f.contains(LifeFlag.hasChild) && kids.isEmpty) {
          note('flag hasChild but no child listed', last);
        }
        final spouses = life.people
            .where((p) => p.isAlive && p.kind == RelationshipKind.spouse)
            .length;
        final partners = life.people
            .where((p) => p.isAlive && p.kind == RelationshipKind.partner)
            .length;
        if (spouses > 1) note('more than one spouse', last);
        if (spouses > 0 && partners > 0) note('a spouse and a partner', last);
        if (life.hasJob != (life.job != 'Unemployed' && life.salary > 0)) {
          note('job title and salary disagree', last);
        }
      }
    }

    expect(
      seen,
      isEmpty,
      reason: seen.entries
          .map(
            (e) =>
                '${e.key}: ${e.value.take(8).toList()} '
                '(${e.value.length} distinct event(s))',
          )
          .join('\n'),
    );
  });
}
