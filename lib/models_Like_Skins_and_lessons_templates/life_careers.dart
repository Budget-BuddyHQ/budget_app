import 'package:flutter/foundation.dart';

import 'life_education.dart';

/// Work: what is on offer, what it asks for, and how a career climbs.
///
/// **Asked for as:** *"the options are so simple, it's so boring"* and *"some
/// jobs need degrees."* The job market was nine titles and a dice roll: you
/// pressed a button and were handed whichever entry-level job the roll landed
/// on, and nothing you had done at school could matter because there was no
/// such thing as a qualification.
///
/// It is a catalogue of **ladders** now. Each is a run of jobs in one line of
/// work, and the rungs get harder to reach: the first often wants nothing, the
/// middle wants a certificate or a degree, the top wants a graduate degree and
/// years of experience. A player chooses which job to apply for, is shown what
/// it needs and the odds before they do, and climbs by performing well.
///
/// Salaries are game coins, set against this economy's living costs and
/// tuition, and are not real wages.
///
/// Pure Dart. The controller owns the state and spends the money.

/// A line of work. Used to group the job board and to count experience.
enum CareerTrack {
  service('Retail and service'),
  hospitality('Food and hospitality'),
  care('Care work'),
  office('Office and admin'),
  trades('Skilled trades'),
  tech('Technology'),
  health('Health'),
  education('Education'),
  finance('Finance'),
  law('Law'),
  publicService('Public service'),
  creative('Media and design'),
  science('Science'),
  business('Business and sales');

  const CareerTrack(this.label);

  final String label;
}

/// One job somebody can hold.
@immutable
class JobDef {
  const JobDef({
    required this.id,
    required this.ladder,
    required this.rung,
    required this.track,
    required this.title,
    required this.salary,
    required this.blurb,
    this.minLevel = EducationLevel.none,
    this.fields = const <StudyField>{},
    this.minSmarts = 0,
    this.minAge = 16,
    this.partTime = false,
    this.boardListed = true,
  });

  final String id;

  /// Which line of promotion this belongs to. Jobs with the same ladder are
  /// the same career at different heights.
  final String ladder;

  /// 0 for the first job on a ladder, then up.
  final int rung;

  final CareerTrack track;
  final String title;

  /// Per year, before the budget splits it.
  final int salary;
  final String blurb;

  /// The lowest qualification that will do.
  final EducationLevel minLevel;

  /// If not empty, the player must hold a qualification in one of these.
  final Set<StudyField> fields;
  final int minSmarts;
  final int minAge;

  /// Something a student can do alongside school. Pays less and does not
  /// promote.
  final bool partTime;

  /// Whether it is advertised. A professional athlete is signed and a
  /// councillor is elected, so neither is a card on a notice board.
  final bool boardListed;
}

/// Why somebody cannot take a job, or an empty list when they can.
///
/// Every reason, not the first. A player who is short of a degree and of Smarts
/// should be told both, because they are two different things to go and do.
List<String> whyCannotTake(
  JobDef job, {
  required int age,
  required EducationLevel level,
  required Set<StudyField> fields,
  required int smarts,
  required bool studying,
}) {
  final reasons = <String>[];
  if (age < job.minAge) reasons.add('You need to be ${job.minAge}');
  if (!level.atLeast(job.minLevel)) {
    reasons.add('Needs ${_levelPhrase(job.minLevel)}');
  }
  if (job.fields.isNotEmpty && fields.intersection(job.fields).isEmpty) {
    final wanted = job.fields.map((f) => f.label).join(' or ');
    reasons.add('Needs a qualification in $wanted');
  }
  if (smarts < job.minSmarts) {
    reasons.add('Needs ${job.minSmarts} Smarts');
  }
  if (studying && !job.partTime) {
    reasons.add('You are studying, so only part-time work fits');
  }
  return reasons;
}

String _levelPhrase(EducationLevel level) => switch (level) {
  EducationLevel.none => 'no qualifications',
  EducationLevel.primary => 'primary school',
  EducationLevel.secondary => 'a high school diploma',
  EducationLevel.certificate => 'a trade certificate',
  EducationLevel.bachelor => "a bachelor's degree",
  EducationLevel.graduate => 'a graduate degree',
};

/// The chance of being hired, 0 to 100.
///
/// A rung that is harder to reach is harder to get. Beyond the requirements,
/// what helps is Smarts above the bar, years already spent in that line of
/// work, and who you know, which is the honest order of things.
int hireChance(
  JobDef job, {
  required int smarts,
  required int networkStrength,
  required int experienceYears,
  int prestige = 0,
}) {
  final base = switch (job.rung) {
    0 => 86,
    1 => 68,
    2 => 52,
    _ => 38,
  };
  final margin = ((smarts - job.minSmarts) * 0.5).clamp(0, 12);
  final experience = (experienceYears * 2).clamp(0, 12);
  final network = (networkStrength / 8).clamp(0, 12);
  return (base + margin + experience + network + prestige * 5).round().clamp(
    5,
    96,
  );
}

/// Whether a job is on the board for somebody with [experienceYears] in its
/// line of work.
///
/// Every first rung is always open. A higher rung is only advertised to people
/// with the years behind them, which is why a fresh graduate sees a junior job
/// and a decade-long veteran sees the senior ones.
bool isListed(JobDef job, {required int experienceYears}) =>
    job.boardListed && (job.rung <= 0 || experienceYears >= job.rung * 2);

// ---------------------------------------------------------------------------
// The catalogue
// ---------------------------------------------------------------------------

/// A rung, before it is given an id.
class _Rung {
  const _Rung(
    this.title,
    this.salary, {
    this.level = EducationLevel.none,
    this.fields = const <StudyField>{},
    this.smarts = 0,
    this.age = 16,
    this.blurb = '',
  });

  final String title;
  final int salary;
  final EducationLevel level;
  final Set<StudyField> fields;
  final int smarts;
  final int age;
  final String blurb;
}

List<JobDef> _ladder(
  String id,
  CareerTrack track,
  List<_Rung> rungs, {
  bool listed = true,
}) => [
  for (var i = 0; i < rungs.length; i++)
    JobDef(
      id: '${id}_$i',
      ladder: id,
      rung: i,
      track: track,
      title: rungs[i].title,
      salary: rungs[i].salary,
      minLevel: rungs[i].level,
      fields: rungs[i].fields,
      minSmarts: rungs[i].smarts,
      minAge: rungs[i].age,
      blurb: rungs[i].blurb,
      boardListed: listed,
    ),
];

const _hs = EducationLevel.secondary;
const _cert = EducationLevel.certificate;
const _ba = EducationLevel.bachelor;
const _grad = EducationLevel.graduate;

/// Every job in the game.
final List<JobDef> kJobs = <JobDef>[
  // ---- Retail and service: no degree, and it shows in the ceiling ---------
  ..._ladder('retail', CareerTrack.service, const [
    _Rung('Supermarket Cashier', 240, blurb: 'Tills, queues and a name badge.'),
    _Rung('Shift Supervisor', 340, smarts: 30, blurb: 'Running the floor.'),
    _Rung('Store Manager', 480, smarts: 42, level: _hs),
    _Rung('Regional Manager', 720, smarts: 55, level: _hs),
  ]),
  ..._ladder('warehouse', CareerTrack.service, const [
    _Rung('Warehouse Picker', 260, blurb: 'Boxes, scanners and steps.'),
    _Rung('Forklift Operator', 320, smarts: 20),
    _Rung('Warehouse Supervisor', 430, smarts: 38, level: _hs),
    _Rung('Logistics Manager', 650, smarts: 50, level: _hs),
  ]),
  ..._ladder('delivery', CareerTrack.service, const [
    _Rung('Delivery Driver', 310, smarts: 20, blurb: 'Your own routes.'),
    _Rung('Route Planner', 420, smarts: 38, level: _hs),
    _Rung('Fleet Manager', 640, smarts: 50, level: _hs),
  ]),
  ..._ladder('sales', CareerTrack.business, const [
    _Rung('Sales Associate', 300, smarts: 30, blurb: 'Talking people into it.'),
    _Rung(
      'Account Executive',
      650,
      level: _ba,
      fields: {StudyField.business, StudyField.arts},
      smarts: 46,
    ),
    _Rung('Sales Manager', 1000, level: _ba, smarts: 52),
    _Rung('Vice President of Sales', 1900, level: _ba, smarts: 60),
  ]),

  // ---- Food and hospitality ------------------------------------------------
  ..._ladder('cafe', CareerTrack.hospitality, const [
    _Rung('Barista', 275, blurb: 'Early mornings and regulars.'),
    _Rung('Head Barista', 345, smarts: 25),
    _Rung('Cafe Manager', 470, smarts: 40, level: _hs),
    _Rung('Hospitality Director', 700, smarts: 55, level: _hs),
  ]),
  ..._ladder('kitchen', CareerTrack.hospitality, const [
    _Rung(
      'Kitchen Hand',
      250,
      blurb: 'Washing up, which is where cooks start.',
    ),
    _Rung(
      'Line Cook',
      330,
      level: _cert,
      fields: {StudyField.hospitality},
      smarts: 25,
    ),
    _Rung(
      'Sous Chef',
      520,
      level: _cert,
      fields: {StudyField.hospitality},
      smarts: 35,
    ),
    _Rung(
      'Head Chef',
      850,
      level: _cert,
      fields: {StudyField.hospitality},
      smarts: 45,
    ),
    _Rung(
      'Executive Chef',
      1300,
      level: _cert,
      fields: {StudyField.hospitality},
      smarts: 52,
    ),
  ]),

  // ---- Care work -----------------------------------------------------------
  ..._ladder('care', CareerTrack.care, const [
    _Rung('Care Assistant', 340, smarts: 30, blurb: 'Looking after people.'),
    _Rung('Senior Carer', 420, smarts: 38, level: _hs),
    _Rung('Care Home Manager', 620, smarts: 50, level: _hs),
  ]),

  // ---- Office and admin ----------------------------------------------------
  ..._ladder('office', CareerTrack.office, const [
    _Rung('Office Administrator', 380, smarts: 42, level: _hs),
    _Rung('Office Manager', 540, smarts: 50, level: _hs),
    _Rung('Operations Manager', 900, smarts: 55, level: _ba),
    _Rung('Director of Operations', 1500, smarts: 62, level: _ba),
  ]),

  // ---- Skilled trades: a certificate, and then it pays ---------------------
  ..._ladder('electrical', CareerTrack.trades, const [
    _Rung('Apprentice Electrician', 380, smarts: 30, level: _hs),
    _Rung(
      'Electrician',
      650,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 35,
    ),
    _Rung(
      'Master Electrician',
      950,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 45,
    ),
    _Rung(
      'Electrical Contractor',
      1400,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 55,
    ),
  ]),
  ..._ladder('plumbing', CareerTrack.trades, const [
    _Rung("Plumber's Mate", 370, smarts: 28, level: _hs),
    _Rung(
      'Plumber',
      620,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 33,
    ),
    _Rung(
      'Master Plumber',
      900,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 42,
    ),
    _Rung(
      'Plumbing Contractor',
      1350,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 52,
    ),
  ]),
  ..._ladder('automotive', CareerTrack.trades, const [
    _Rung("Mechanic's Assistant", 340, smarts: 25, level: _hs),
    _Rung(
      'Mechanic',
      560,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 32,
    ),
    _Rung(
      'Master Technician',
      820,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 42,
    ),
    _Rung(
      'Garage Owner',
      1200,
      level: _cert,
      fields: {StudyField.trades},
      smarts: 52,
    ),
  ]),

  // ---- Technology ----------------------------------------------------------
  ..._ladder('software', CareerTrack.tech, const [
    _Rung(
      'Junior Developer',
      700,
      level: _ba,
      fields: {StudyField.tech},
      smarts: 58,
      blurb: 'Your first real codebase.',
    ),
    _Rung('Developer', 1000, level: _ba, fields: {StudyField.tech}, smarts: 60),
    _Rung(
      'Senior Developer',
      1500,
      level: _ba,
      fields: {StudyField.tech},
      smarts: 64,
    ),
    _Rung(
      'Engineering Lead',
      2200,
      level: _ba,
      fields: {StudyField.tech},
      smarts: 68,
    ),
    _Rung(
      'Director of Engineering',
      3200,
      level: _ba,
      fields: {StudyField.tech},
      smarts: 72,
    ),
  ]),
  ..._ladder('web', CareerTrack.tech, const [
    _Rung(
      'Web Developer',
      520,
      level: _cert,
      fields: {StudyField.tech},
      smarts: 45,
      blurb: 'A bootcamp is a quicker way in.',
    ),
    _Rung(
      'Full-Stack Developer',
      800,
      level: _cert,
      fields: {StudyField.tech},
      smarts: 52,
    ),
    _Rung(
      'Lead Web Developer',
      1200,
      level: _cert,
      fields: {StudyField.tech},
      smarts: 58,
    ),
  ]),
  ..._ladder('itsupport', CareerTrack.tech, const [
    _Rung('IT Support', 400, smarts: 45, level: _hs),
    _Rung('Systems Administrator', 650, smarts: 52, level: _hs),
    _Rung('IT Manager', 1000, smarts: 58, level: _ba),
  ]),

  // ---- Health --------------------------------------------------------------
  ..._ladder('medassist', CareerTrack.health, const [
    _Rung(
      'Medical Assistant',
      420,
      level: _cert,
      fields: {StudyField.health},
      smarts: 35,
    ),
    _Rung(
      'Senior Medical Assistant',
      520,
      level: _cert,
      fields: {StudyField.health},
      smarts: 42,
    ),
  ]),
  ..._ladder('dental', CareerTrack.health, const [
    _Rung(
      'Dental Hygienist',
      700,
      level: _cert,
      fields: {StudyField.health},
      smarts: 45,
    ),
    _Rung(
      'Lead Hygienist',
      900,
      level: _cert,
      fields: {StudyField.health},
      smarts: 52,
    ),
  ]),
  ..._ladder('nursing', CareerTrack.health, const [
    _Rung(
      'Registered Nurse',
      900,
      level: _ba,
      fields: {StudyField.health},
      smarts: 52,
      blurb: 'Patients, shifts and real responsibility.',
    ),
    _Rung(
      'Charge Nurse',
      1150,
      level: _ba,
      fields: {StudyField.health},
      smarts: 55,
    ),
    _Rung(
      'Nurse Manager',
      1500,
      level: _ba,
      fields: {StudyField.health},
      smarts: 58,
    ),
    _Rung(
      'Director of Nursing',
      2000,
      level: _ba,
      fields: {StudyField.health},
      smarts: 62,
    ),
  ]),
  ..._ladder('medicine', CareerTrack.health, const [
    _Rung(
      'Resident Doctor',
      1500,
      level: _grad,
      fields: {StudyField.health},
      smarts: 68,
      blurb: 'Long hours while you learn on the wards.',
    ),
    _Rung(
      'Doctor',
      2600,
      level: _grad,
      fields: {StudyField.health},
      smarts: 70,
    ),
    _Rung(
      'Specialist',
      3800,
      level: _grad,
      fields: {StudyField.health},
      smarts: 74,
    ),
    _Rung(
      'Chief of Medicine',
      5000,
      level: _grad,
      fields: {StudyField.health},
      smarts: 78,
    ),
  ]),

  // ---- Education -----------------------------------------------------------
  ..._ladder('teaching', CareerTrack.education, const [
    _Rung('Teaching Assistant', 300, smarts: 35, level: _hs),
    _Rung(
      'Teacher',
      650,
      level: _ba,
      fields: {StudyField.education},
      smarts: 42,
    ),
    _Rung(
      'Head of Department',
      900,
      level: _ba,
      fields: {StudyField.education},
      smarts: 46,
    ),
    _Rung(
      'Principal',
      1400,
      level: _grad,
      fields: {StudyField.education},
      smarts: 50,
    ),
  ]),
  ..._ladder('academia', CareerTrack.education, const [
    _Rung('University Lecturer', 1100, level: _grad, smarts: 62),
    _Rung('Professor', 1700, level: _grad, smarts: 68),
  ]),

  // ---- Finance -------------------------------------------------------------
  ..._ladder('banking', CareerTrack.finance, const [
    _Rung('Bank Teller', 320, smarts: 38, level: _hs),
    _Rung(
      'Loan Officer',
      700,
      level: _ba,
      fields: {StudyField.finance, StudyField.business},
      smarts: 46,
    ),
    _Rung(
      'Branch Manager',
      1100,
      level: _ba,
      fields: {StudyField.finance, StudyField.business},
      smarts: 52,
    ),
  ]),
  ..._ladder('accounting', CareerTrack.finance, const [
    _Rung(
      'Junior Accountant',
      800,
      level: _ba,
      fields: {StudyField.finance},
      smarts: 50,
    ),
    _Rung(
      'Accountant',
      1000,
      level: _ba,
      fields: {StudyField.finance},
      smarts: 54,
    ),
    _Rung(
      'Senior Accountant',
      1350,
      level: _ba,
      fields: {StudyField.finance},
      smarts: 58,
    ),
    _Rung(
      'Finance Manager',
      1800,
      level: _ba,
      fields: {StudyField.finance},
      smarts: 62,
    ),
    _Rung(
      'Chief Financial Officer',
      3200,
      level: _grad,
      fields: {StudyField.business, StudyField.finance},
      smarts: 68,
    ),
  ]),
  ..._ladder('advice', CareerTrack.finance, const [
    _Rung(
      'Financial Advisor',
      950,
      level: _ba,
      fields: {StudyField.finance, StudyField.business},
      smarts: 52,
      blurb: 'Helping other people with their budgets.',
    ),
    _Rung(
      'Senior Advisor',
      1400,
      level: _ba,
      fields: {StudyField.finance, StudyField.business},
      smarts: 58,
    ),
    _Rung(
      'Wealth Manager',
      2100,
      level: _ba,
      fields: {StudyField.finance, StudyField.business},
      smarts: 64,
    ),
  ]),

  // ---- Law -----------------------------------------------------------------
  ..._ladder('paralegal', CareerTrack.law, const [
    _Rung('Paralegal', 520, level: _cert, fields: {StudyField.law}, smarts: 45),
    _Rung(
      'Senior Paralegal',
      700,
      level: _cert,
      fields: {StudyField.law},
      smarts: 52,
    ),
  ]),
  ..._ladder('lawyer', CareerTrack.law, const [
    _Rung(
      'Associate Lawyer',
      1800,
      level: _grad,
      fields: {StudyField.law},
      smarts: 62,
    ),
    _Rung(
      'Senior Associate',
      2400,
      level: _grad,
      fields: {StudyField.law},
      smarts: 66,
    ),
    _Rung('Partner', 3500, level: _grad, fields: {StudyField.law}, smarts: 70),
  ]),
  ..._ladder('public_law', CareerTrack.law, const [
    _Rung(
      'Public Defender',
      1500,
      level: _grad,
      fields: {StudyField.law},
      smarts: 60,
      blurb: 'Representing people who cannot afford a lawyer.',
    ),
    _Rung(
      'Senior Public Defender',
      1900,
      level: _grad,
      fields: {StudyField.law},
      smarts: 64,
    ),
    _Rung(
      'District Attorney',
      2600,
      level: _grad,
      fields: {StudyField.law},
      smarts: 68,
      blurb: 'The pay is lower than corporate law the whole way up. Some '
          'people take it anyway.',
    ),
  ]),

  // ---- Public service ------------------------------------------------------
  ..._ladder('security', CareerTrack.publicService, const [
    _Rung('Security Guard', 300, smarts: 25, level: _hs),
    _Rung('Security Supervisor', 420, smarts: 35, level: _hs),
    _Rung('Head of Security', 650, smarts: 46, level: _hs),
  ]),
  ..._ladder('police', CareerTrack.publicService, const [
    _Rung(
      'Police Officer',
      500,
      level: _cert,
      fields: {StudyField.publicService},
      smarts: 35,
      age: 21,
    ),
    _Rung(
      'Detective',
      760,
      level: _cert,
      fields: {StudyField.publicService},
      smarts: 48,
      age: 21,
    ),
    _Rung(
      'Lieutenant',
      1000,
      level: _cert,
      fields: {StudyField.publicService},
      smarts: 52,
      age: 21,
    ),
    _Rung(
      'Chief of Police',
      1500,
      level: _ba,
      fields: {StudyField.publicService},
      smarts: 58,
      age: 21,
    ),
  ]),
  ..._ladder('government', CareerTrack.publicService, const [
    _Rung('Government Clerk', 380, smarts: 40, level: _hs),
    _Rung(
      'Program Officer',
      720,
      level: _ba,
      fields: {StudyField.publicService, StudyField.general},
      smarts: 48,
    ),
    _Rung(
      'Department Head',
      1100,
      level: _ba,
      fields: {StudyField.publicService, StudyField.general},
      smarts: 54,
    ),
    _Rung(
      'Agency Director',
      1700,
      level: _grad,
      fields: {StudyField.publicService},
      smarts: 60,
    ),
  ]),

  // ---- Media and design ----------------------------------------------------
  ..._ladder('design', CareerTrack.creative, const [
    _Rung('Freelance Designer', 300, smarts: 30, level: _hs),
    _Rung(
      'Graphic Designer',
      620,
      level: _ba,
      fields: {StudyField.arts},
      smarts: 40,
    ),
    _Rung(
      'Art Director',
      1000,
      level: _ba,
      fields: {StudyField.arts},
      smarts: 46,
    ),
    _Rung(
      'Creative Director',
      1600,
      level: _ba,
      fields: {StudyField.arts},
      smarts: 52,
    ),
  ]),
  ..._ladder('journalism', CareerTrack.creative, const [
    _Rung(
      'Junior Reporter',
      520,
      level: _ba,
      fields: {StudyField.arts, StudyField.general},
      smarts: 44,
    ),
    _Rung(
      'Reporter',
      760,
      level: _ba,
      fields: {StudyField.arts, StudyField.general},
      smarts: 48,
    ),
    _Rung(
      'Editor',
      1100,
      level: _ba,
      fields: {StudyField.arts, StudyField.general},
      smarts: 54,
    ),
    _Rung(
      'Editor in Chief',
      1700,
      level: _ba,
      fields: {StudyField.arts, StudyField.general},
      smarts: 60,
    ),
  ]),
  ..._ladder('marketing', CareerTrack.business, const [
    _Rung(
      'Marketing Coordinator',
      620,
      level: _ba,
      fields: {StudyField.business, StudyField.arts},
      smarts: 45,
    ),
    _Rung(
      'Marketing Manager',
      950,
      level: _ba,
      fields: {StudyField.business, StudyField.arts},
      smarts: 52,
    ),
    _Rung(
      'Marketing Director',
      1500,
      level: _ba,
      fields: {StudyField.business, StudyField.arts},
      smarts: 58,
    ),
    _Rung(
      'Chief Marketing Officer',
      2400,
      level: _ba,
      fields: {StudyField.business, StudyField.arts},
      smarts: 64,
    ),
  ]),
  ..._ladder('management', CareerTrack.business, const [
    _Rung(
      'Management Trainee',
      700,
      level: _ba,
      fields: {StudyField.business},
      smarts: 48,
    ),
    _Rung(
      'Manager',
      1000,
      level: _ba,
      fields: {StudyField.business},
      smarts: 54,
    ),
    _Rung(
      'Senior Manager',
      1500,
      level: _ba,
      fields: {StudyField.business},
      smarts: 60,
    ),
    _Rung(
      'Executive',
      2500,
      level: _ba,
      fields: {StudyField.business},
      smarts: 66,
    ),
    _Rung(
      'Chief Executive',
      4200,
      level: _grad,
      fields: {StudyField.business},
      smarts: 72,
    ),
  ]),

  // ---- Science -------------------------------------------------------------
  ..._ladder('lab', CareerTrack.science, const [
    _Rung(
      'Lab Technician',
      600,
      level: _ba,
      fields: {StudyField.science},
      smarts: 52,
    ),
    _Rung(
      'Research Scientist',
      1200,
      level: _grad,
      fields: {StudyField.science},
      smarts: 62,
    ),
    _Rung(
      'Senior Scientist',
      1700,
      level: _grad,
      fields: {StudyField.science},
      smarts: 66,
    ),
    _Rung(
      'Research Director',
      2400,
      level: _grad,
      fields: {StudyField.science},
      smarts: 72,
    ),
  ]),
  ..._ladder('environment', CareerTrack.science, const [
    _Rung(
      'Environmental Analyst',
      650,
      level: _ba,
      fields: {StudyField.science},
      smarts: 50,
    ),
    _Rung(
      'Senior Analyst',
      900,
      level: _ba,
      fields: {StudyField.science},
      smarts: 55,
    ),
    _Rung(
      'Sustainability Director',
      1400,
      level: _ba,
      fields: {StudyField.science},
      smarts: 60,
    ),
  ]),

  // ---- Paths that are not on the board -------------------------------------
  ..._ladder(
    'pro_sport',
    CareerTrack.publicService,
    const [
      _Rung('Professional Athlete', 1500, age: 18, smarts: 20),
      _Rung('Starting Player', 2600, age: 18, smarts: 20),
      _Rung('Star Player', 4200, age: 18, smarts: 20),
    ],
    listed: false,
  ),
  ..._ladder(
    'politics',
    CareerTrack.publicService,
    const [
      _Rung('City Councillor', 500, age: 25, smarts: 40, level: _hs),
      _Rung('Mayor', 900, age: 25, smarts: 46, level: _hs),
      _Rung('State Senator', 1600, age: 25, smarts: 52, level: _hs),
      _Rung('Governor', 2600, age: 25, smarts: 58, level: _hs),
    ],
    listed: false,
  ),

  // ---- Part-time: something a student can do alongside school ---------------
  const JobDef(
    id: 'pt_cashier',
    ladder: 'pt_cashier',
    rung: 0,
    track: CareerTrack.service,
    title: 'Part-time Cashier',
    salary: 120,
    partTime: true,
    blurb: 'A few shifts a week around lessons.',
  ),
  const JobDef(
    id: 'pt_tutor',
    ladder: 'pt_tutor',
    rung: 0,
    track: CareerTrack.education,
    title: 'Student Tutor',
    salary: 150,
    minSmarts: 45,
    partTime: true,
    blurb: 'Helping younger students. Good money for your hours.',
  ),
  const JobDef(
    id: 'pt_barista',
    ladder: 'pt_barista',
    rung: 0,
    track: CareerTrack.hospitality,
    title: 'Weekend Barista',
    salary: 110,
    partTime: true,
    blurb: 'Saturday and Sunday mornings.',
  ),
  const JobDef(
    id: 'pt_delivery',
    ladder: 'pt_delivery',
    rung: 0,
    track: CareerTrack.service,
    title: 'Evening Delivery Rider',
    salary: 130,
    minSmarts: 15,
    partTime: true,
    blurb: 'Flexible hours and your own bike.',
  ),
];

/// Looks a job up by id.
JobDef? jobById(String id) {
  for (final job in kJobs) {
    if (job.id == id) return job;
  }
  return null;
}

/// The next rung up the same ladder, or null at the top.
JobDef? nextRung(JobDef job) {
  if (job.partTime) return null;
  for (final candidate in kJobs) {
    if (candidate.ladder == job.ladder && candidate.rung == job.rung + 1) {
      return candidate;
    }
  }
  return null;
}

/// Every job in one line of work, lowest rung first.
List<JobDef> jobsIn(CareerTrack track) => [
  for (final job in kJobs)
    if (job.track == track) job,
];

/// The salary after a promotion.
///
/// The next rung's salary, but never less than a 12% rise, so a promotion
/// always feels like one even from a high starting point in the previous job.
int promotedSalary({required int current, required JobDef next}) =>
    next.salary > (current * 1.12).round()
    ? next.salary
    : (current * 1.12).round();
