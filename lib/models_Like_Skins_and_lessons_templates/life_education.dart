import 'dart:math';

import 'package:flutter/foundation.dart';

/// School, and what it leads to.
///
/// **Asked for as:** *"the school and sports and everything else still doesn't
/// fully work, everything is still randomized, unlike BitLife where the user has
/// options and can choose... some jobs need degrees."* School was a Smarts
/// button and there was no such thing as a degree, so a job could not ask for
/// one. This is the model that fixes both: a ladder of levels, a set of real
/// programs to apply to, grades that move with what the player actually does,
/// and a price.
///
/// Pure Dart with no widgets, so the whole thing is testable without a screen.
/// The rules that spend money and move stats live in `LifeSimController`, which
/// owns the state; this file owns the vocabulary and the arithmetic.

/// How far somebody has got.
///
/// Ordered, because the only question a job or a program ever asks is "at least
/// this far?".
enum EducationLevel {
  none('No schooling yet'),
  primary('Primary school'),
  secondary('High school diploma'),
  certificate('Trade certificate'),
  bachelor("Bachelor's degree"),
  graduate('Graduate degree');

  const EducationLevel(this.label);

  final String label;

  bool atLeast(EducationLevel other) => index >= other.index;
}

/// What a qualification is in. Jobs ask for a field ("a nurse needs health"),
/// programs grant one, and that is the whole link between the two.
enum StudyField {
  general('General studies'),
  business('Business'),
  tech('Technology'),
  health('Health'),
  education('Education'),
  law('Law'),
  arts('Arts and media'),
  trades('Skilled trades'),
  science('Science'),
  finance('Finance'),
  publicService('Public service'),
  hospitality('Food and hospitality');

  const StudyField(this.label);

  final String label;
}

/// Where a student is right now.
enum SchoolStage {
  none('Not in school'),
  elementary('Elementary school'),
  middle('Middle school'),
  high('High school'),
  trade('Trade school'),
  college('College'),
  graduate('Graduate school');

  const SchoolStage(this.label);

  final String label;

  /// Compulsory years, which need no decision and no fee.
  bool get isCompulsory => this == elementary || this == middle || this == high;

  /// Years at a stage that the player paid to be at.
  bool get isPostSecondary =>
      this == trade || this == college || this == graduate;

  /// The stage a character of [age] is in by default, before anything is chosen.
  static SchoolStage forAge(int age) {
    if (age < 5) return none;
    if (age < 11) return elementary;
    if (age < 14) return middle;
    if (age < 18) return high;
    return none;
  }
}

/// One thing a person can apply to study.
@immutable
class StudyProgram {
  const StudyProgram({
    required this.id,
    required this.name,
    required this.stage,
    required this.years,
    required this.tuition,
    required this.field,
    required this.minSmarts,
    required this.blurb,
    this.grants,
    this.needsField = const <StudyField>{},
    this.minAge = 18,
  });

  final String id;

  /// "Business Administration", "Electrician".
  final String name;

  /// Trade, college or graduate. Decides what it grants and what it needs.
  final SchoolStage stage;

  final int years;

  /// Per year at a state school. A private one costs more, see [tuitionFor].
  final int tuition;

  final StudyField field;
  final int minSmarts;
  final String blurb;

  /// What finishing earns, when that is not simply the stage's usual level.
  final EducationLevel? grants;

  /// For a graduate program: the fields a bachelor's must be in. Empty means
  /// any bachelor's will do.
  final Set<StudyField> needsField;

  final int minAge;

  /// The level this program awards on completion.
  EducationLevel get awards =>
      grants ??
      switch (stage) {
        SchoolStage.trade => EducationLevel.certificate,
        SchoolStage.college => EducationLevel.bachelor,
        SchoolStage.graduate => EducationLevel.graduate,
        _ => EducationLevel.secondary,
      };

  /// The credential's name as it appears on a record.
  String get credential => switch (stage) {
    SchoolStage.trade => '$name certificate',
    SchoolStage.college => 'Bachelor of $name',
    SchoolStage.graduate => name,
    _ => name,
  };

  /// What the whole thing costs before help, at a state school.
  int get totalTuition => tuition * years;

  /// Tuition per year, at a state school or a private one.
  ///
  /// Private costs more than twice as much and asks more of you. What it buys is
  /// a stronger name on the application, see `applicationChance`. Whether that
  /// is worth borrowing for is exactly the question the game wants asked.
  int tuitionFor({required bool privateSchool}) =>
      privateSchool && stage == SchoolStage.college
      ? (tuition * 2.2).round()
      : tuition;

  /// Smarts needed at the school actually applied to.
  int minSmartsFor({required bool privateSchool}) =>
      privateSchool && stage == SchoolStage.college ? minSmarts + 8 : minSmarts;
}

/// Why somebody cannot apply, or null when they can.
String? whyCannotApply(
  StudyProgram program, {
  required int age,
  required EducationLevel level,
  required Set<StudyField> fields,
  required bool alreadyStudying,
}) {
  if (alreadyStudying) return 'Finish or leave your current course first';
  if (age < program.minAge) return 'You need to be ${program.minAge}';
  switch (program.stage) {
    case SchoolStage.trade:
    case SchoolStage.college:
      if (!level.atLeast(EducationLevel.secondary)) {
        return 'You need a high school diploma';
      }
      if (program.stage == SchoolStage.college &&
          level.atLeast(EducationLevel.bachelor)) {
        return 'You already have a bachelor\'s degree';
      }
    case SchoolStage.graduate:
      if (!level.atLeast(EducationLevel.bachelor)) {
        return "You need a bachelor's degree first";
      }
      if (level.atLeast(EducationLevel.graduate)) {
        return 'You already have a graduate degree';
      }
      if (program.needsField.isNotEmpty &&
          fields.intersection(program.needsField).isEmpty) {
        final wanted = program.needsField.map((f) => f.label).join(' or ');
        return "Your bachelor's needs to be in $wanted";
      }
    default:
      return 'Not something you apply to';
  }
  return null;
}

/// The chance of being accepted, 0 to 100.
///
/// Smarts is the gate and grades are the margin. A player under the bar gets 0
/// and is told why, because a hidden refusal teaches nothing. A private school
/// asks more and is harder to get into, which is the honest trade for what it
/// costs.
int applicationChance(
  StudyProgram program, {
  required int smarts,
  required int grades,
  required bool privateSchool,
}) {
  final need = program.minSmartsFor(privateSchool: privateSchool);
  if (smarts < need) return 0;
  if (program.stage == SchoolStage.trade) return 95;
  final margin = (smarts - need) * 1.4;
  final record = (grades - 50) * 0.45;
  final base = program.stage == SchoolStage.graduate ? 55.0 : 62.0;
  final harder = privateSchool && program.stage == SchoolStage.college
      ? -12.0
      : 0.0;
  return (base + margin + record + harder).round().clamp(4, 98);
}

/// A word for a chance, so a row can say "Good" and mean it.
String oddsLabel(int chance) {
  if (chance <= 0) return 'Not yet';
  if (chance < 40) return 'Long shot';
  if (chance < 65) return 'Fair';
  if (chance < 85) return 'Good';
  return 'Very likely';
}

/// The share of tuition a family pays, by how well off it is.
///
/// Origin was a free choice worth 0 or 2,500 starting coins and nothing else in
/// this game ever asked what it meant. This is where it does: a wealthy family
/// pays for most of a degree and a struggling one pays for none, which is how it
/// works and is the reason "just go to college" is not the same advice for
/// everybody.
double familyTuitionShare(int familyMoney) {
  if (familyMoney >= 2500) return 0.9;
  if (familyMoney >= 600) return 0.5;
  if (familyMoney >= 150) return 0.2;
  return 0.0;
}

/// A scholarship, as a share of tuition, earned by what the student has done.
///
/// [teamStanding] is 0 for somebody with no sport, so a sports scholarship is a
/// thing that has to have been worked for.
double scholarshipShare({
  required int grades,
  required int smarts,
  int teamStanding = 0,
}) {
  var share = 0.0;
  if (grades >= 85 && smarts >= 70) {
    share += 0.5;
  } else if (grades >= 75 && smarts >= 60) {
    share += 0.25;
  }
  if (teamStanding >= 80) share += 0.3;
  return share.clamp(0.0, 0.8);
}

/// Next year's grades.
///
/// A blend of where the student was and where this year's effort points, so a
/// bad year dents a good record instead of erasing it, and a good year does not
/// rescue a bad one. Smarts sets the level, studying moves it, and being unwell
/// or miserable takes some back.
int nextGrades({
  required int grades,
  required int smarts,
  required int studyUses,
  required int health,
  required int happiness,
  required Random random,
}) {
  var target = 50 + (smarts - 50) * 0.8 + studyUses * 6.0;
  if (health < 40) target -= 5;
  if (happiness < 30) target -= 4;
  target += random.nextInt(9) - 4;
  return (grades * 0.5 + target * 0.5).round().clamp(0, 100);
}

/// A grade as a letter, for the school card.
String gradeLetter(int grades) {
  if (grades >= 90) return 'A';
  if (grades >= 80) return 'B';
  if (grades >= 70) return 'C';
  if (grades >= 60) return 'D';
  return 'F';
}

/// Where somebody is in their education, and what they have finished.
///
/// Mutable and owned by the controller, which is the one thing that survives
/// from year to year. Everything here is plain data with a few small questions
/// answered; the decisions are the controller's.
class EducationState {
  EducationState({
    this.level = EducationLevel.none,
    this.stage = SchoolStage.none,
    this.grades = 60,
  });

  EducationLevel level;
  SchoolStage stage;

  /// The post-secondary course being taken, if any.
  StudyProgram? program;

  /// Whether the college is a private one.
  bool privateSchool = false;

  /// Years done in the current stage.
  int yearInStage = 0;

  /// 0 to 100, a running record. See [nextGrades].
  int grades;

  /// The share of tuition covered by a scholarship, set at enrolment.
  double scholarship = 0;

  /// Fields the player holds a post-secondary qualification in.
  final Set<StudyField> fields = <StudyField>{};

  /// Everything earned, in the order it was earned.
  final List<String> credentials = <String>[];

  /// Whether the "what next" prompt at eighteen has been put to the player.
  bool nextStepOffered = false;

  /// Whether the player left school before finishing something.
  bool droppedOut = false;

  bool get inSchool => stage != SchoolStage.none;
  bool get inPostSecondary => stage.isPostSecondary;

  /// Years still to do on the current course, or 0.
  int get yearsLeft {
    final p = program;
    if (p == null) return 0;
    return (p.years - yearInStage).clamp(0, p.years);
  }

  /// A line for the top of the school card.
  String get status {
    if (!inSchool) return level.label;
    final p = program;
    if (p != null) {
      return '${p.name}, year ${yearInStage + 1} of ${p.years}';
    }
    return stage.label;
  }
}

/// Every program a player can apply to.
///
/// Prices are game coins and sit against this economy's pay, not against real
/// tuition: a state degree costs about a year of a graduate's starting salary
/// in total, which is roughly the proportion in life and the one worth
/// weighing. They are not real figures and are not presented as any.
const List<StudyProgram> kStudyPrograms = <StudyProgram>[
  // ---- College: four years -------------------------------------------------
  StudyProgram(
    id: 'college_business',
    name: 'Business Administration',
    stage: SchoolStage.college,
    years: 4,
    tuition: 110,
    field: StudyField.business,
    minSmarts: 45,
    blurb: 'How companies run. Opens management, sales and finance.',
  ),
  StudyProgram(
    id: 'college_cs',
    name: 'Computer Science',
    stage: SchoolStage.college,
    years: 4,
    tuition: 130,
    field: StudyField.tech,
    minSmarts: 58,
    blurb: 'Writing software. Some of the best-paid starting jobs.',
  ),
  StudyProgram(
    id: 'college_engineering',
    name: 'Engineering',
    stage: SchoolStage.college,
    years: 4,
    tuition: 140,
    field: StudyField.tech,
    minSmarts: 62,
    blurb: 'Designing things that have to work. Hard, and it pays.',
  ),
  StudyProgram(
    id: 'college_nursing',
    name: 'Nursing',
    stage: SchoolStage.college,
    years: 4,
    tuition: 120,
    field: StudyField.health,
    minSmarts: 52,
    blurb: 'Caring for patients. Always in demand.',
  ),
  StudyProgram(
    id: 'college_education',
    name: 'Education',
    stage: SchoolStage.college,
    years: 4,
    tuition: 100,
    field: StudyField.education,
    minSmarts: 42,
    blurb: 'Becoming a teacher. Modest pay, steady work.',
  ),
  StudyProgram(
    id: 'college_finance',
    name: 'Accounting and Finance',
    stage: SchoolStage.college,
    years: 4,
    tuition: 115,
    field: StudyField.finance,
    minSmarts: 50,
    blurb: 'Money for a living: accounts, audits and advice.',
  ),
  StudyProgram(
    id: 'college_biology',
    name: 'Biology',
    stage: SchoolStage.college,
    years: 4,
    tuition: 120,
    field: StudyField.science,
    minSmarts: 55,
    blurb: 'Life science. The road to medicine or research.',
  ),
  StudyProgram(
    id: 'college_environment',
    name: 'Environmental Science',
    stage: SchoolStage.college,
    years: 4,
    tuition: 115,
    field: StudyField.science,
    minSmarts: 50,
    blurb: 'Land, water and climate. Field work and labs.',
  ),
  StudyProgram(
    id: 'college_polisci',
    name: 'Political Science',
    stage: SchoolStage.college,
    years: 4,
    tuition: 110,
    field: StudyField.publicService,
    minSmarts: 50,
    blurb: 'How governments work. A start for law and public office.',
  ),
  StudyProgram(
    id: 'college_justice',
    name: 'Criminal Justice',
    stage: SchoolStage.college,
    years: 4,
    tuition: 100,
    field: StudyField.publicService,
    minSmarts: 40,
    blurb: 'Courts and public safety.',
  ),
  StudyProgram(
    id: 'college_media',
    name: 'Communications and Media',
    stage: SchoolStage.college,
    years: 4,
    tuition: 105,
    field: StudyField.arts,
    minSmarts: 44,
    blurb: 'Writing, video and getting a message across.',
  ),
  StudyProgram(
    id: 'college_art',
    name: 'Fine Arts',
    stage: SchoolStage.college,
    years: 4,
    tuition: 110,
    field: StudyField.arts,
    minSmarts: 35,
    blurb: 'Making things. Rewarding, and harder to turn into a salary.',
  ),
  StudyProgram(
    id: 'college_liberal',
    name: 'Liberal Arts',
    stage: SchoolStage.college,
    years: 4,
    tuition: 95,
    field: StudyField.general,
    minSmarts: 38,
    blurb: 'A broad degree. Flexible, and it asks you to find your own way.',
  ),

  // ---- Trade school: one or two years -------------------------------------
  StudyProgram(
    id: 'trade_electrician',
    name: 'Electrician',
    stage: SchoolStage.trade,
    years: 2,
    tuition: 60,
    field: StudyField.trades,
    minSmarts: 30,
    blurb: 'Wiring homes and buildings. Paid while you learn.',
  ),
  StudyProgram(
    id: 'trade_plumbing',
    name: 'Plumbing and Heating',
    stage: SchoolStage.trade,
    years: 2,
    tuition: 60,
    field: StudyField.trades,
    minSmarts: 30,
    blurb: 'Pipes, boilers and emergencies at any hour.',
  ),
  StudyProgram(
    id: 'trade_auto',
    name: 'Automotive Technician',
    stage: SchoolStage.trade,
    years: 2,
    tuition: 55,
    field: StudyField.trades,
    minSmarts: 28,
    blurb: 'Keeping cars on the road.',
  ),
  StudyProgram(
    id: 'trade_medassist',
    name: 'Medical Assistant',
    stage: SchoolStage.trade,
    years: 1,
    tuition: 70,
    field: StudyField.health,
    minSmarts: 35,
    blurb: 'Clinic work after one year.',
  ),
  StudyProgram(
    id: 'trade_dental',
    name: 'Dental Hygiene',
    stage: SchoolStage.trade,
    years: 2,
    tuition: 85,
    field: StudyField.health,
    minSmarts: 45,
    blurb: 'Teeth, and a very good salary for two years of school.',
  ),
  StudyProgram(
    id: 'trade_culinary',
    name: 'Culinary Arts',
    stage: SchoolStage.trade,
    years: 2,
    tuition: 65,
    field: StudyField.hospitality,
    minSmarts: 25,
    blurb: 'Professional cooking. Long hours, real skill.',
  ),
  StudyProgram(
    id: 'trade_webdev',
    name: 'Web Development Bootcamp',
    stage: SchoolStage.trade,
    years: 1,
    tuition: 90,
    field: StudyField.tech,
    minSmarts: 45,
    blurb: 'One intense year of coding. A quick way into tech.',
  ),
  StudyProgram(
    id: 'trade_paralegal',
    name: 'Paralegal Studies',
    stage: SchoolStage.trade,
    years: 2,
    tuition: 75,
    field: StudyField.law,
    minSmarts: 45,
    blurb: 'Supporting lawyers with research and paperwork.',
  ),
  StudyProgram(
    id: 'trade_police',
    name: 'Police Academy',
    stage: SchoolStage.trade,
    years: 1,
    tuition: 40,
    field: StudyField.publicService,
    minSmarts: 35,
    blurb: 'Training for a career in public safety.',
    minAge: 20,
  ),

  // ---- Graduate school ------------------------------------------------------
  StudyProgram(
    id: 'grad_medicine',
    name: 'Doctor of Medicine',
    stage: SchoolStage.graduate,
    years: 4,
    tuition: 260,
    field: StudyField.health,
    minSmarts: 68,
    needsField: {StudyField.health, StudyField.science},
    blurb: 'Becoming a doctor. The longest road and the highest pay.',
  ),
  StudyProgram(
    id: 'grad_law',
    name: 'Juris Doctor',
    stage: SchoolStage.graduate,
    years: 3,
    tuition: 230,
    field: StudyField.law,
    minSmarts: 62,
    blurb: 'Law school. Three years to become a lawyer.',
  ),
  StudyProgram(
    id: 'grad_mba',
    name: 'Master of Business Administration',
    stage: SchoolStage.graduate,
    years: 2,
    tuition: 200,
    field: StudyField.business,
    minSmarts: 55,
    blurb: 'Two years that open the top of a company.',
  ),
  StudyProgram(
    id: 'grad_education',
    name: 'Master of Education',
    stage: SchoolStage.graduate,
    years: 2,
    tuition: 130,
    field: StudyField.education,
    minSmarts: 48,
    needsField: {StudyField.education, StudyField.general},
    blurb: 'For leading a school, not just a classroom.',
  ),
  StudyProgram(
    id: 'grad_cs',
    name: 'Master of Computer Science',
    stage: SchoolStage.graduate,
    years: 2,
    tuition: 180,
    field: StudyField.tech,
    minSmarts: 62,
    needsField: {StudyField.tech, StudyField.science},
    blurb: 'Advanced software, data and research.',
  ),
  StudyProgram(
    id: 'grad_mpa',
    name: 'Master of Public Administration',
    stage: SchoolStage.graduate,
    years: 2,
    tuition: 140,
    field: StudyField.publicService,
    minSmarts: 50,
    blurb: 'Running public services. A step towards elected office.',
  ),
  StudyProgram(
    id: 'grad_phd',
    name: 'Doctor of Philosophy in Science',
    stage: SchoolStage.graduate,
    years: 4,
    tuition: 100,
    field: StudyField.science,
    minSmarts: 70,
    needsField: {StudyField.science, StudyField.tech, StudyField.health},
    blurb: 'Original research. Cheap to attend, slow to finish.',
  ),
];

/// Looks a program up by id.
StudyProgram? studyProgramById(String id) {
  for (final program in kStudyPrograms) {
    if (program.id == id) return program;
  }
  return null;
}

/// Programs of one kind, in the order the catalogue lists them.
List<StudyProgram> programsAt(SchoolStage stage) => [
  for (final p in kStudyPrograms)
    if (p.stage == stage) p,
];
