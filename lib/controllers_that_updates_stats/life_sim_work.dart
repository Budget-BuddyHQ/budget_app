part of 'life_sim_controller.dart';

/// One line on the job board: a job, whether the player can take it, and how
/// likely they are to get it.
class JobListing {
  const JobListing({
    required this.job,
    required this.blockers,
    required this.chance,
  });

  final JobDef job;

  /// Everything standing in the way. Empty when the player qualifies.
  final List<String> blockers;

  /// 0 to 100, only meaningful when [blockers] is empty.
  final int chance;

  bool get qualified => blockers.isEmpty;

  String get odds => qualified ? oddsLabel(chance) : 'Not qualified';
}

/// What happened to a job application.
enum JobOutcome { hired, rejected, blocked }

/// What happened when the player asked for a promotion.
enum PromotionOutcome { promoted, refused, blocked }

/// Work, in the controller. See `life_careers.dart` for the catalogue.
extension LifeSimWork on LifeSimController {
  /// The catalogue job held, or null when the job came from an event.
  JobDef? get currentJob {
    final id = _jobId;
    return id == null ? null : jobById(id);
  }

  /// How the job is going, 0 to 100.
  int get performance => _performance;

  /// Promotions won over the whole life.
  int get promotionsEarned => _promotions;
  int get yearsInRole => _yearsInRole;

  int experienceIn(CareerTrack track) => _experience[track] ?? 0;

  /// The line of work the player is in, if their job is on a ladder.
  CareerTrack? get careerTrack => currentJob?.track;

  /// Test seam: set how the job is going.
  @visibleForTesting
  void debugSetPerformance(int value, {int? yearsInRole}) {
    _performance = value.clamp(0, 100);
    if (yearsInRole != null) _yearsInRole = yearsInRole;
    _changed();
  }

  /// Test seam: set years of experience in a line of work.
  @visibleForTesting
  void debugSetExperience(CareerTrack track, int years) {
    _experience[track] = years;
  }

  /// Whether the player can look for work at all right now.
  bool get canApplyForJobs => !finished && _age >= 16;

  /// The job board, filtered to [track] when one is given.
  ///
  /// Every first rung is on it. A higher rung is only advertised to somebody
  /// with the years behind them, so the board changes as a career does. Locked
  /// jobs are included with their reasons, because a job you cannot yet take
  /// tells you what to go and do.
  List<JobListing> jobListings({CareerTrack? track}) {
    final out = <JobListing>[];
    for (final job in kJobs) {
      if (track != null && job.track != track) continue;
      if (!isListed(job, experienceYears: experienceIn(job.track))) continue;
      final blockers = whyCannotTake(
        job,
        age: _age,
        level: _edu.level,
        fields: _edu.fields,
        smarts: _smarts,
        studying: _edu.inSchool,
      );
      out.add(
        JobListing(
          job: job,
          blockers: blockers,
          chance: hireChance(
            job,
            smarts: _smarts,
            networkStrength: networkReading.strength,
            experienceYears: experienceIn(job.track),
            prestige:
                _edu.privateSchool &&
                    _edu.level.atLeast(EducationLevel.bachelor)
                ? 1
                : 0,
          ),
        ),
      );
    }
    return out;
  }

  /// Why the player cannot apply right now, or null.
  String? applyGate() {
    if (finished) return 'This life is over';
    if (_age < 16) return 'You need to be 16';
    if (budgetFor(LifeAction.applyJob).exhausted) {
      return 'You have applied for enough jobs this year';
    }
    return null;
  }

  /// Applies for [jobId].
  ///
  /// The odds are shown before and the roll is real. Somebody who already has a
  /// job may apply for another: getting it means leaving the old one, which is
  /// how careers actually move, and is the only way to a higher rung than a
  /// promotion offers.
  JobOutcome applyForJob(String jobId, {String? referredBy}) {
    final job = jobById(jobId);
    if (job == null || applyGate() != null) return JobOutcome.blocked;
    final listing = jobListings().firstWhere(
      (l) => l.job.id == jobId,
      orElse: () =>
          JobListing(job: job, blockers: const ['Not on the board'], chance: 0),
    );
    if (!listing.qualified) return JobOutcome.blocked;
    if (!_spend(LifeAction.applyJob)) return JobOutcome.blocked;
    // Somebody vouching for you adds to the odds and is used up doing it.
    final chance = referredBy != null
        ? (listing.chance + 18).clamp(5, 98)
        : listing.chance;
    if (_random.nextInt(100) < chance) {
      _hire(job, referredBy: referredBy, addCoworkers: true);
      _changed();
      return JobOutcome.hired;
    }
    _happiness = _clamp(_happiness - 4);
    _setLog(
      'You applied to be a ${job.title}, and they went with somebody else. '
      'It stings, and it is normal. Try again or aim a rung lower.',
      kind: LifeLogKind.career,
    );
    _changed();
    return JobOutcome.rejected;
  }

  /// Puts the player in [job].
  void _hire(
    JobDef job, {
    String? referredBy,
    bool addCoworkers = false,
    bool viaJobBoard = false,
    bool legacyWording = false,
  }) {
    final previous = hasJob ? _job : null;
    _job = job.title;
    _salary = job.salary;
    _jobId = job.id;
    _performance = 60;
    _yearsInRole = 0;
    _lowPerformanceYears = 0;
    _firstJobAge ??= _age;
    _happiness = _clamp(_happiness + 6);
    if (referredBy != null) _referrals++;
    final leaving = previous == null ? '' : ' You left $previous behind.';
    if (legacyWording) {
      _setLog(
        referredBy != null
            ? '$referredBy put your name forward, and it counted. Hired as a '
                  '${job.title} on ${job.salary} a year. Open Money to split '
                  'that before it splits itself.'
            : viaJobBoard
            ? 'Saw the card on the board in town and asked. Hired as a '
                  '${job.title} on ${job.salary} a year. Open Money to split '
                  'that before it splits itself.'
            : 'Applied online and got it. Hired as a ${job.title} on '
                  '${job.salary} a year. Open Money to split that before it '
                  'splits itself.',
        kind: LifeLogKind.career,
      );
    } else {
      _setLog(
        'You are hired: ${job.title}, ${job.salary} a year.$leaving '
        'Open Money to split that before it splits itself.',
        kind: LifeLogKind.career,
      );
    }
    if (addCoworkers) _meetCoworkers(job);
    _teach(FinanceConcept.budgetRule);
  }

  /// A new job comes with new people: a manager and a colleague, warm enough to
  /// count as a start and not as friends.
  void _meetCoworkers(JobDef job) {
    final workmates = _people
        .where((p) => p.kind == RelationshipKind.colleague && p.isAlive)
        .length;
    if (workmates >= 8) return;
    final taken = {for (final p in _people) p.name};
    final boss = freshContactName(_random, taken);
    taken.add(boss);
    final peer = freshContactName(_random, taken);
    _people
      ..add(
        Relationship(
          name: boss,
          kind: RelationshipKind.colleague,
          closeness: 40,
          metAtAge: _age,
          lastSeenAge: _age,
          role: 'Manager',
        ),
      )
      ..add(
        Relationship(
          name: peer,
          kind: RelationshipKind.colleague,
          closeness: 48,
          metAtAge: _age,
          lastSeenAge: _age,
          role: 'Coworker',
        ),
      );
    _contactsMade += 2;
  }

  /// The old "look for work" button, kept for the town's notice board and for
  /// the referral that a contact passes on.
  ///
  /// It picks for you, which is the thing the job board replaced, so nothing in
  /// the menus calls it any more. What is left is the case where somebody hands
  /// you a lead and the game chooses the job: it now only draws from jobs the
  /// player actually qualifies for, so it cannot hand out a job that needs a
  /// degree the character does not have.
  bool findJob({bool viaJobBoard = false, String? referredBy}) {
    if (!canJobHunt || !allows(LifeAction.findJob)) return false;
    final open =
        kJobs
            .where(
              (j) =>
                  j.rung == 0 &&
                  // Only what is advertised. A signed athlete and an elected
                  // councillor are not on any board, and a part-time job is
                  // for somebody who is studying.
                  j.boardListed &&
                  (j.partTime == _edu.inSchool) &&
                  whyCannotTake(
                    j,
                    age: _age,
                    level: _edu.level,
                    fields: _edu.fields,
                    smarts: _smarts,
                    studying: _edu.inSchool,
                  ).isEmpty,
            )
            .toList()
          ..sort((a, b) => a.salary.compareTo(b.salary));
    if (open.isEmpty) {
      _setLog(
        'Nothing you are qualified for is going right now. Study and try '
        'again.',
        kind: LifeLogKind.career,
      );
      _changed();
      return false;
    }
    // Keep the best of several rolls, so raising Smarts is felt: three for
    // turning up in person, two for a form, four with somebody vouching.
    var pick = 0;
    final rolls = referredBy != null ? 4 : (viaJobBoard ? 3 : 2);
    for (var i = 0; i < rolls; i++) {
      final roll = _random.nextInt(open.length);
      if (roll > pick) pick = roll;
    }
    _hire(
      open[pick],
      referredBy: referredBy,
      viaJobBoard: viaJobBoard,
      legacyWording: true,
    );
    _changed();
    return true;
  }

  /// Walk away from a job. Salary goes to zero immediately.
  void quitJob() {
    if (finished || !hasJob) return;
    _job = 'Unemployed';
    _salary = 0;
    _jobId = null;
    _yearsInRole = 0;
    _performance = 60;
    _lowPerformanceYears = 0;
    _happiness = _clamp(_happiness + 4);
    _setLog(
      'You quit. Freedom now, no paycheck next year.',
      kind: LifeLogKind.career,
    );
    _changed();
  }

  /// Put in extra effort. Builds performance, which is what raises and
  /// promotions are decided on, at a cost to health and mood.
  ///
  /// It used to hand out a flat +200 to +600 on a roll, which on a 560 salary
  /// was a raise of a hundred percent and made pay a matter of pressing a
  /// button. Effort now moves a bar you can see, and the bar moves the pay.
  void workHarder() {
    if (finished || !allows(LifeAction.workHarder)) return;
    if (!hasJob) {
      _setLog('You need a job first.', kind: LifeLogKind.career);
      _changed();
      return;
    }
    final rate = _yield(LifeAction.workHarder);
    if (!_spend(LifeAction.workHarder)) return;
    final worn = workStrain.missesWork ? 0.5 : 1.0;
    final gain = max(1, (9 * rate * worn).round());
    _performance = (_performance + gain).clamp(0, 100);
    _happiness = _clamp(_happiness - 5);
    _health = _clamp(_health - 2);
    _setLog(
      worn < 1
          ? 'You put in the extra hours, but you were too run down for it to '
                'count for much. Performance +$gain. Rest first.'
          : 'You put in the extra hours and it showed. Performance +$gain.',
      kind: LifeLogKind.career,
    );
    _changed();
  }

  /// Ask outright. Once a year, and the odds follow performance.
  void askForRaise() {
    if (finished || !allows(LifeAction.askForRaise)) return;
    if (!hasJob) {
      _setLog(
        'You need a job before you can ask for a raise.',
        kind: LifeLogKind.career,
      );
      _changed();
      return;
    }
    if (budgetFor(LifeAction.askForRaise).exhausted) {
      _setLog(
        'You already asked this year. Asking twice is not a second chance, '
        'it is a worse first ask.',
        kind: LifeLogKind.career,
      );
      _changed();
      return;
    }
    _spend(LifeAction.askForRaise);
    final worn = workStrain.missesWork ? 15 : 0;
    final chance =
        (18 + _performance * 0.45 + networkReading.strength ~/ 10 - worn)
            .round()
            .clamp(5, 90);
    if (_random.nextInt(100) < chance) {
      final percent = 4 + _random.nextInt(7);
      final bump = max(1, (_salary * percent / 100).round());
      _salary += bump;
      _raisesEarned++;
      _happiness = _clamp(_happiness + 6);
      _setLog(
        'You asked, and got it: salary up $bump, which is $percent%. '
        'Asking is free.',
        kind: LifeLogKind.career,
      );
    } else {
      _happiness = _clamp(_happiness - 8);
      _setLog(
        worn > 0
            ? 'They said no, and mentioned the missed shifts. Look after '
                  'yourself first, then ask.'
            : _performance < 50
            ? 'They said no. Your performance is not where a raise needs it '
                  'to be yet.'
            : 'They said no. Worth asking. It only cost you a bad day.',
        kind: LifeLogKind.career,
      );
    }
    _changed();
  }

  /// What is in the way of a promotion, or null when one can be asked for.
  String? promotionBlocker() {
    if (finished) return 'This life is over';
    if (!hasJob) return 'You need a job first';
    final job = currentJob;
    if (job == null) return 'Your job has no ladder to climb';
    final next = nextRung(job);
    if (next == null) return 'You are at the top of this ladder';
    if (_yearsInRole < 2) {
      return 'Needs 2 years in the role. You have $_yearsInRole';
    }
    if (_performance < 60) {
      return 'Your performance has to reach 60. It is $_performance';
    }
    final reasons = whyCannotTake(
      next,
      age: _age,
      level: _edu.level,
      fields: _edu.fields,
      smarts: _smarts,
      studying: false,
    );
    if (reasons.isNotEmpty) return '${next.title}: ${reasons.first}';
    if (budgetFor(LifeAction.applyPromotion).exhausted) {
      return 'You have already asked this year';
    }
    return null;
  }

  /// The rung above the current one, if there is one.
  JobDef? get nextPromotion {
    final job = currentJob;
    return job == null ? null : nextRung(job);
  }

  /// The odds of a promotion right now.
  int get promotionChance =>
      (25 +
              _performance * 0.5 +
              networkReading.strength ~/ 10 +
              (_yearsInRole - 2) * 3)
          .round()
          .clamp(10, 92);

  PromotionOutcome applyForPromotion() {
    if (promotionBlocker() != null) return PromotionOutcome.blocked;
    if (!_spend(LifeAction.applyPromotion)) return PromotionOutcome.blocked;
    final next = nextPromotion!;
    if (_random.nextInt(100) < promotionChance) {
      final salary = promotedSalary(current: _salary, next: next);
      final rise = salary - _salary;
      _job = next.title;
      _salary = salary;
      _jobId = next.id;
      _yearsInRole = 0;
      _performance = 55;
      _raisesEarned++;
      _promotions++;
      _happiness = _clamp(_happiness + 9);
      _setLog(
        'You were promoted to ${next.title}. Salary up $rise, to $salary.',
        kind: LifeLogKind.career,
      );
      _changed();
      return PromotionOutcome.promoted;
    }
    _happiness = _clamp(_happiness - 4);
    _performance = (_performance - 3).clamp(0, 100);
    _setLog(
      'They gave the ${next.title} role to somebody else this time. Keep '
      'building your record and ask again next year.',
      kind: LifeLogKind.career,
    );
    _changed();
    return PromotionOutcome.refused;
  }

  /// A year at work: performance drifts to where effort and ability point, a
  /// good record earns a modest raise, and a long bad one loses the job.
  ///
  /// [workedHarder] is how many times the player put in extra hours last year.
  void _applyWorkYear(int workedHarder) {
    if (!hasJob) {
      _yearsInRole = 0;
      _lowPerformanceYears = 0;
      return;
    }
    // Careers in sport end early, which is why the money matters so much while
    // it lasts.
    if (isProAthlete && _age >= 38) {
      _job = 'Unemployed';
      _salary = 0;
      _jobId = null;
      _yearsInRole = 0;
      _sport = null;
      _sportStanding = 0;
      _setLog(
        'You retired from professional sport at $_age. The body has done what '
        'it can. What you saved while it paid is what carries you now.',
        kind: LifeLogKind.career,
      );
      return;
    }
    _yearsInRole++;
    final track = currentJob?.track;
    if (track != null) _experience[track] = (_experience[track] ?? 0) + 1;

    final charisma = (_skills[LifeSkill.charisma] ?? 0) / 10;
    final target = 50 + (_smarts - 50) * 0.5 + workedHarder * 9 + charisma;
    final noise = _random.nextInt(9) - 4;
    _performance = (_performance * 0.6 + target * 0.4 + noise).round().clamp(
      0,
      100,
    );

    if (_performance >= 72 && _random.nextInt(100) < 60) {
      final percent = 2 + ((_performance - 72) / 9).floor();
      final bump = max(1, (_salary * percent / 100).round());
      _salary += bump;
      _raisesEarned++;
      _setLog(
        'Your manager noticed the work. Salary up $bump, which is $percent%.',
        kind: LifeLogKind.career,
      );
    }

    if (_performance < 22) {
      _lowPerformanceYears++;
      if (_lowPerformanceYears >= 2) {
        final lost = _job;
        _job = 'Unemployed';
        _salary = 0;
        _jobId = null;
        _yearsInRole = 0;
        _lowPerformanceYears = 0;
        _timesLaidOff++;
        _happiness = _clamp(_happiness - 12);
        _setLog(
          'You were let go from $lost after two years of poor reviews. It is '
          'a setback, not the end. Building your skills and your record is '
          'how you come back from it.',
          kind: LifeLogKind.career,
        );
      } else {
        _setLog(
          'Your review was poor. Another like it and you could lose the job.',
          kind: LifeLogKind.career,
        );
      }
    } else {
      _lowPerformanceYears = 0;
    }
  }
}
