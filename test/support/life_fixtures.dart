import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_activities.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';

import 'fixed_random.dart';

/// Lives to point the Life screens at.
///
/// A screen built for a person with a job, a car, a dog, a family and a loan is
/// laid out differently from the same screen for a nine-year-old, and only the
/// busy version finds the overflow. These are the busy ones on purpose.
///
/// Built with lucky dice so that every application succeeds, then the years are
/// lived with the dice off so nothing random lands on top of the fixture.

/// Somebody 34 with a degree, a job that is going well, a car on a loan, a dog,
/// a partner, a child, friends, work people and a person they have lost.
LifeSimController busyAdult() {
  final life = LifeSimController(
    random: FixedRandom.lucky(),
    name: 'Alex Morgan',
    initialAge: 34,
    startMoney: 4000,
    withFamily: true,
  );
  life.debugSetStats(smarts: 72, health: 78, happiness: 66, looks: 58);
  life.debugSetEducation(
    level: EducationLevel.bachelor,
    fields: {StudyField.business},
    grades: 78,
  );
  life.applyForJob('management_0');
  life.debugSetPerformance(74, yearsInRole: 3);
  life.getLicense();
  life.buyAsset(assetById('veh_used')!, financed: true);
  life.buyAsset(assetById('pet_dog')!, name: 'Biscuit');
  life.buyAsset(assetById('val_watch')!);
  life.depositSavings(600);
  life.invest(300);
  life.debugPutPerson(
    const Relationship(
      name: 'Jo Lee',
      kind: RelationshipKind.spouse,
      closeness: 84,
      metAtAge: 26,
      lastSeenAge: 33,
      role: 'Spouse',
    ),
  );
  life.debugPutPerson(
    const Relationship(
      name: 'Kit Morgan',
      kind: RelationshipKind.child,
      closeness: 90,
      metAtAge: 31,
      lastSeenAge: 34,
      role: 'Son',
      ageOffset: -31,
    ),
  );
  life.debugPutPerson(
    const Relationship(
      name: 'Sam Reyes',
      kind: RelationshipKind.friend,
      closeness: 46,
      metAtAge: 15,
      lastSeenAge: 30,
      role: 'Friend',
    ),
  );
  life.debugPutPerson(
    const Relationship(
      name: 'Nana Morgan',
      kind: RelationshipKind.family,
      closeness: 70,
      metAtAge: 0,
      lastSeenAge: 20,
      role: 'Grandmother',
      ageOffset: 60,
      passedAge: 29,
    ),
  );
  life.debugClearEvent();
  return life;
}

/// Somebody 19, in the second year of a degree, with a student loan growing.
LifeSimController collegeStudent() {
  final life = LifeSimController(
    random: FixedRandom.lucky(),
    name: 'Riley Chen',
    initialAge: 18,
    startMoney: 50,
    withFamily: true,
  );
  life.debugSetStats(smarts: 68, health: 80, happiness: 62);
  life.applyToProgram(studyProgramById('college_cs')!, privateSchool: true);
  life.ageUp();
  life.debugClearEvent();
  life.debugSetStats(health: 80, happiness: 62);
  return life;
}

/// Somebody 12, at school, with a family and one friend.
LifeSimController schoolChild() {
  final life = LifeSimController(
    random: FixedRandom.unlucky(),
    name: 'Sam Patel',
    initialAge: 12,
    startMoney: 40,
    withFamily: true,
  );
  life.debugPutPerson(
    const Relationship(
      name: 'Tess Wu',
      kind: RelationshipKind.friend,
      closeness: 62,
      metAtAge: 9,
      lastSeenAge: 11,
      role: 'Friend',
    ),
  );
  return life;
}

/// Somebody 22 with a diploma and no job, owing on a card.
LifeSimController jobSeeker() {
  final life = LifeSimController(
    random: FixedRandom.unlucky(),
    name: 'Jordan Ellis',
    initialAge: 22,
    startMoney: 30,
    withFamily: true,
  );
  life.debugSetStats(smarts: 55, health: 70, happiness: 50);
  life.applyShock(400, 'A repair');
  return life;
}

/// Somebody 20 who plays a sport at a high level.
LifeSimController athlete() {
  final life = LifeSimController(
    random: FixedRandom.lucky(),
    name: 'Dana Ortiz',
    initialAge: 20,
    startMoney: 300,
    withFamily: true,
  );
  life.debugSetSport(LifeSport.soccer, standing: 88);
  life.debugSetSkill(LifeSkill.charisma, 45);
  return life;
}
