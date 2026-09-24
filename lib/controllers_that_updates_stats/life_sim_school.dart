part of 'life_sim_controller.dart';

/// What a year of a course costs the player, after everybody else has paid.
///
/// Shown before the application is sent, because "how much will this cost me" is
/// the question a person should be able to answer before they commit, and
/// because the answer is different for everybody: a scholarship, a family that
/// can help, or neither.
class TuitionQuote {
  const TuitionQuote({
    required this.perYear,
    required this.scholarship,
    required this.family,
    required this.years,
  });

  /// The sticker price for one year.
  final int perYear;

  /// Coins a scholarship takes off each year.
  final int scholarship;

  /// Coins the family covers each year.
  final int family;

  final int years;

  /// What the player pays each year.
  int get you => (perYear - scholarship - family).clamp(0, perYear);

  /// What the player pays across the whole course.
  int get total => you * years;

  /// The sticker price for the whole course.
  int get sticker => perYear * years;
}

/// What happened to an application.
enum ApplyResult { accepted, rejected, blocked }

/// School, in the controller. See `life_education.dart` for the model.
extension LifeSimSchool on LifeSimController {
  EducationLevel get educationLevel => _edu.level;
  SchoolStage get schoolStage => _edu.stage;
  StudyProgram? get currentProgram => _edu.program;
  bool get isPrivateSchool => _edu.privateSchool;

  /// 0 to 100. The bar on the school card.
  int get grades => _edu.grades;

  bool get isStudent => _edu.inSchool;

  /// Qualifications earned over the whole life, and what was borrowed to earn
  /// them. The debrief reads both.
  int get degreesEarned => _degreesEarned;
  int get studentBorrowed => _studentBorrowed;
  bool get isPostSecondaryStudent => _edu.inPostSecondary;
  bool get hasDroppedOut => _edu.droppedOut;
  int get yearsLeftInCourse => _edu.yearsLeft;
  int get yearsInStage => _edu.yearInStage;
  double get scholarshipShareNow => _edu.scholarship;

  /// Fields the player holds a post-secondary qualification in.
  Set<StudyField> get studyFields => Set.unmodifiable(_edu.fields);

  /// Everything earned, oldest first.
  List<String> get credentials => List.unmodifiable(_edu.credentials);

  /// A line for the top of the school card.
  String get educationStatus => _edu.status;

  /// Whether the "what next" question is still open: somebody who has finished
  /// school, is not studying, and has never been asked.
  bool get canPickNextStep =>
      !finished && _age >= 18 && !_edu.inSchool && !_edu.nextStepOffered;

  /// Test seam: set what somebody has studied without living through it.
  @visibleForTesting
  void debugSetEducation({
    EducationLevel? level,
    Set<StudyField>? fields,
    int? grades,
  }) {
    if (level != null) _edu.level = level;
    if (fields != null) {
      _edu.fields
        ..clear()
        ..addAll(fields);
    }
    if (grades != null) _edu.grades = grades.clamp(0, 100);
    _changed();
  }

  /// Sets up school for a character created partway through a life.
  ///
  /// Called once, from the constructor. A child starts in the stage their age
  /// puts them in; an adult is taken to have finished high school, so a test
  /// that begins at thirty is not shut out of half the job board.
  void _startEducation() {
    if (_age >= 18) {
      _edu.level = EducationLevel.secondary;
      _edu.credentials.add('High school diploma');
      _edu.nextStepOffered = true;
      return;
    }
    _edu.stage = SchoolStage.forAge(_age);
    if (_age >= 11) _edu.level = EducationLevel.primary;
  }

  /// The tuition for [program], after a scholarship and family help.
  ///
  /// A scholarship is earned by grades and, for a team, by standing. Family help
  /// follows how well off the family is, and stops at 25, when people are
  /// expected to have found their feet.
  TuitionQuote tuitionQuote(
    StudyProgram program, {
    bool privateSchool = false,
  }) {
    final perYear = program.tuitionFor(privateSchool: privateSchool);
    final share = program.stage == SchoolStage.college
        ? scholarshipShare(
            grades: _edu.grades,
            smarts: _smarts,
            teamStanding: _sportStanding,
          )
        : 0.0;
    final scholarship = (perYear * share).round();
    final family = _age < 25
        ? ((perYear - scholarship) * familyTuitionShare(origin.familyMoney))
              .round()
        : 0;
    return TuitionQuote(
      perYear: perYear,
      scholarship: scholarship,
      family: family,
      years: program.years,
    );
  }

  /// Why the player cannot apply to [program] right now, or null.
  String? programGate(StudyProgram program) {
    if (finished) return 'This life is over';
    final why = whyCannotApply(
      program,
      age: _age,
      level: _edu.level,
      fields: _edu.fields,
      alreadyStudying: _edu.inPostSecondary,
    );
    if (why != null) return why;
    if (hasJob && currentJob?.partTime != true) {
      return 'Resign from your job before you enrol';
    }
    if (budgetFor(LifeAction.applyCollege).exhausted) {
      return 'You have applied to enough places this year';
    }
    return null;
  }

  /// The chance of being accepted, for the application screen.
  int admissionChance(StudyProgram program, {bool privateSchool = false}) =>
      applicationChance(
        program,
        smarts: _smarts,
        grades: _edu.grades,
        privateSchool: privateSchool && program.stage == SchoolStage.college,
      );

  /// Sends an application and, if it is accepted, enrols.
  ///
  /// Odds are shown first and the roll is real, so a long shot can be turned
  /// down and a good candidate is not certain either. A refusal costs a little
  /// happiness and one of the year's applications, and nothing else.
  ApplyResult applyToProgram(
    StudyProgram program, {
    bool privateSchool = false,
  }) {
    if (programGate(program) != null) return ApplyResult.blocked;
    if (!_spend(LifeAction.applyCollege)) return ApplyResult.blocked;
    final usePrivate = privateSchool && program.stage == SchoolStage.college;
    final chance = admissionChance(program, privateSchool: usePrivate);
    if (_random.nextInt(100) < chance) {
      _enrol(program, usePrivate);
      _changed();
      return ApplyResult.accepted;
    }
    _happiness = _clamp(_happiness - 3);
    _setLog(
      'You applied to study ${program.name}, and they said no this time. '
      'Higher grades and more Smarts change the odds.',
      kind: LifeLogKind.learning,
    );
    _changed();
    return ApplyResult.rejected;
  }

  void _enrol(StudyProgram program, bool privateSchool) {
    final quote = tuitionQuote(program, privateSchool: privateSchool);
    _edu.stage = program.stage;
    _edu.program = program;
    _edu.privateSchool = privateSchool;
    _edu.yearInStage = 0;
    _edu.scholarship = program.stage == SchoolStage.college
        ? scholarshipShare(
            grades: _edu.grades,
            smarts: _smarts,
            teamStanding: _sportStanding,
          )
        : 0.0;
    // Everybody starts a course at a similar footing, with a nod to how they
    // did before.
    _edu.grades = ((_edu.grades + 65) / 2).round().clamp(0, 100);
    _edu.nextStepOffered = true;
    _happiness = _clamp(_happiness + 6);
    _payTuitionYear(program);
    final help = quote.scholarship + quote.family;
    _setLog(
      'You are in. ${program.name}, ${program.years} '
      '${program.years == 1 ? 'year' : 'years'}. '
      '${quote.perYear} a year'
      '${help > 0 ? ', of which ${quote.scholarship > 0 ? 'a scholarship covers ${quote.scholarship}' : ''}'
                '${quote.scholarship > 0 && quote.family > 0 ? ' and ' : ''}'
                '${quote.family > 0 ? 'your family covers ${quote.family}' : ''}' : ''}'
      '. You pay ${quote.you} a year.',
      kind: LifeLogKind.learning,
    );
    _teach(FinanceConcept.opportunityCost);
  }

  /// Pays one year of tuition: what is left after help comes out of cash, and
  /// whatever cash cannot cover becomes a student loan.
  ///
  /// The emergency fund is left alone, because it is for emergencies. A student
  /// loan is cheaper than the general debt this game has always had (about 5%
  /// against 18%) and does not ask for a payment until school is over, which is
  /// why taking one for a degree is a different decision from putting a
  /// holiday on a card.
  void _payTuitionYear(StudyProgram program) {
    final quote = tuitionQuote(program, privateSchool: _edu.privateSchool);
    // The scholarship is fixed at enrolment, so quote against that.
    final scholarship = (quote.perYear * _edu.scholarship).round();
    final family = _age < 25
        ? ((quote.perYear - scholarship) *
                  familyTuitionShare(origin.familyMoney))
              .round()
        : 0;
    final you = (quote.perYear - scholarship - family).clamp(0, quote.perYear);
    if (you <= 0) return;
    final fromCash = you.clamp(0, _money);
    _money -= fromCash;
    final borrow = you - fromCash;
    if (borrow > 0) _addStudentLoan(borrow);
  }

  void _addStudentLoan(int amount) {
    for (final loan in _loans) {
      if (loan.kind == LoanKind.student) {
        loan.balance += amount;
        _studentBorrowed += amount;
        return;
      }
    }
    _loans.add(
      Loan(
        uid: _nextUid++,
        kind: LoanKind.student,
        label: 'Student loan',
        balance: amount,
        rate: 0.05,
        years: 10,
        deferred: true,
      ),
    );
    _studentBorrowed += amount;
    _teach(FinanceConcept.interestCost);
  }

  /// Called once a year for every character, before the year's money.
  ///
  /// [studied] is how many times the player studied last year, which is what
  /// moves grades. It has to be passed in because the yearly tallies are cleared
  /// at the top of `ageUp`.
  void _advanceSchooling(int studied) {
    // ---- The compulsory years, which need no decision --------------------
    if (!_edu.droppedOut && _age >= 5 && _age < 18) {
      final want = SchoolStage.forAge(_age);
      if (_edu.stage != want) {
        _edu.stage = want;
        _edu.yearInStage = 0;
        if (want == SchoolStage.middle) {
          _edu.level = EducationLevel.primary;
          _setLog('You started middle school.', kind: LifeLogKind.learning);
        } else if (want == SchoolStage.high) {
          _setLog('You started high school.', kind: LifeLogKind.learning);
        }
      } else {
        _edu.yearInStage++;
      }
    }

    // ---- Grades for the year that has just gone -------------------------------
    if (_edu.inSchool) {
      final before = _edu.grades;
      _edu.grades = nextGrades(
        grades: _edu.grades,
        smarts: _smarts,
        studyUses: studied,
        health: _health,
        happiness: _happiness,
        random: _random,
      );
      if (_edu.stage.isCompulsory) {
        // Kept quiet on ordinary years. A feed line every year for twelve
        // years is the repetition this pass exists to remove, so it speaks
        // when something changes: the honour roll, or falling behind.
        if (_edu.grades >= 85 && before < 85) {
          _happiness = _clamp(_happiness + 3);
          _setLog(
            'You made the honour roll. Studying pays.',
            kind: LifeLogKind.learning,
          );
        } else if (_edu.grades < 40 && before >= 40) {
          _happiness = _clamp(_happiness - 3);
          _setLog(
            'Your grades slipped and school got harder. A few evenings of '
            'studying would help.',
            kind: LifeLogKind.learning,
          );
        }
      }
    }

    // ---- The end of high school ------------------------------------------
    if (_age >= 18 && _edu.stage == SchoolStage.high) {
      _graduateHighSchool();
    } else if (_edu.inPostSecondary) {
      _advanceCourse();
    }
  }

  void _graduateHighSchool() {
    final passed = _edu.grades >= 30;
    _edu.stage = SchoolStage.none;
    _edu.yearInStage = 0;
    if (passed) {
      _edu.level = EducationLevel.secondary;
      _edu.credentials.add('High school diploma');
      _happiness = _clamp(_happiness + 6);
      final honours = _edu.grades >= 85;
      _setLog(
        honours
            ? 'You graduated from high school with honours.'
            : 'You graduated from high school.',
        kind: LifeLogKind.learning,
      );
    } else {
      _edu.level = EducationLevel.primary;
      _happiness = _clamp(_happiness - 4);
      _setLog(
        'You did not pass enough to graduate. You can earn your diploma '
        'later, and plenty of people do.',
        kind: LifeLogKind.learning,
      );
    }
    _queueNextStepCard(withDiploma: passed);
  }

  /// A year of a paid course is done.
  void _advanceCourse() {
    final program = _edu.program;
    if (program == null) {
      _edu.stage = SchoolStage.none;
      return;
    }
    _edu.yearInStage++;
    if (_edu.yearInStage >= program.years) {
      _completeCourse(program);
      return;
    }
    _payTuitionYear(program);
    _setLog(
      'Year ${_edu.yearInStage + 1} of ${program.years}: ${program.name}. '
      'Your grades are ${gradeLetter(_edu.grades)}.',
      kind: LifeLogKind.learning,
    );
  }

  void _completeCourse(StudyProgram program) {
    final passed = _edu.grades >= 35;
    _edu.stage = SchoolStage.none;
    _edu.program = null;
    _edu.yearInStage = 0;
    _edu.scholarship = 0;
    if (passed) {
      if (program.awards.index > _edu.level.index) {
        _edu.level = program.awards;
      }
      _edu.fields.add(program.field);
      _edu.credentials.add(program.credential);
      _degreesEarned++;
      _smarts = _clamp(_smarts + 4);
      _happiness = _clamp(_happiness + 8);
      _setLog(
        'You graduated: ${program.credential}. ${_repaymentNote()}',
        kind: LifeLogKind.learning,
      );
    } else {
      _edu.droppedOut = true;
      _happiness = _clamp(_happiness - 6);
      _setLog(
        'You finished ${program.name} without the grades to be awarded it. '
        'The loan still has to be paid. ${_repaymentNote()}',
        kind: LifeLogKind.learning,
      );
    }
    _startRepaying();
  }

  /// Student loans start asking for a payment once school is over.
  void _startRepaying() {
    for (final loan in _loans) {
      if (loan.kind == LoanKind.student && loan.deferred) {
        loan.startRepaying();
      }
    }
  }

  String _repaymentNote() {
    for (final loan in _loans) {
      if (loan.kind == LoanKind.student && loan.balance > 0) {
        return 'Your student loan is ${loan.balance}, and it starts asking for '
            '${amortizedPayment(loan.balance, loan.rate, 10)} a year.';
      }
    }
    return 'You finish with no student debt.';
  }

  /// Puts the "what next" card to the player.
  void _queueNextStepCard({required bool withDiploma}) {
    if (_edu.nextStepOffered) return;
    _edu.nextStepOffered = true;
    _queuedEvents.add(
      LifeEvent(
        id: 'v2_next_step_$_age',
        prompt: withDiploma
            ? 'You have finished school. Everything is open, and it is your '
                  'call. What next?'
            : 'School is over, without the diploma. You have options.',
        icon: Icons.school_rounded,
        choices: [
          if (withDiploma)
            const LifeChoice(
              label: 'Apply to college',
              outcome:
                  'A degree takes four years and can change what you earn.',
              followUp: LifeFollowUp.openCollege,
              teaches: FinanceConcept.opportunityCost,
            ),
          const LifeChoice(
            label: 'Learn a trade',
            outcome:
                'Shorter, cheaper, and people who can do it are always needed.',
            followUp: LifeFollowUp.openTrades,
            teaches: FinanceConcept.opportunityCost,
          ),
          const LifeChoice(
            label: 'Start working',
            outcome:
                'Earning now means learning on the job and starting to save '
                'early. It also means fewer doors to start with.',
            followUp: LifeFollowUp.openJobs,
            teaches: FinanceConcept.opportunityCost,
          ),
          const LifeChoice(
            label: 'Take a year to travel',
            outcome:
                'A year of seeing the world. It cost real money, and you '
                'came back with stories and no income.',
            money: -150,
            happiness: 10,
            smarts: 2,
            teaches: FinanceConcept.opportunityCost,
          ),
        ],
      ),
    );
  }

  /// Leaves school.
  ///
  /// From sixteen for the compulsory years, and at any time for a paid course.
  /// What has been finished is kept, and so is what is owed.
  bool leaveSchool() {
    if (finished || !_edu.inSchool) return false;
    if (_edu.stage.isCompulsory) {
      if (_age < 16) return false;
      _edu.droppedOut = true;
      _edu.stage = SchoolStage.none;
      _happiness = _clamp(_happiness + 2);
      _smarts = _clamp(_smarts - 2);
      _setLog(
        'You left school. It is a real choice, and it closes some doors. '
        'You can go back for your diploma any time.',
        kind: LifeLogKind.learning,
      );
    } else {
      final name = _edu.program?.name ?? 'your course';
      _edu.stage = SchoolStage.none;
      _edu.program = null;
      _edu.yearInStage = 0;
      _edu.scholarship = 0;
      _edu.droppedOut = true;
      _happiness = _clamp(_happiness - 3);
      _setLog(
        'You left $name without finishing. ${_repaymentNote()}',
        kind: LifeLogKind.learning,
      );
      _startRepaying();
    }
    _changed();
    return true;
  }

  /// A second chance at the diploma, for anyone eighteen or over.
  bool earnDiploma() {
    if (finished || _age < 18 || _edu.inSchool) return false;
    if (_edu.level.atLeast(EducationLevel.secondary)) return false;
    const cost = 40;
    if (_money < cost) {
      _setLog(
        'The equivalency exam costs $cost and you do not have it yet.',
        kind: LifeLogKind.money,
      );
      _changed();
      return false;
    }
    _money -= cost;
    _edu.level = EducationLevel.secondary;
    _edu.credentials.add('High school equivalency');
    _edu.droppedOut = false;
    _smarts = _clamp(_smarts + 3);
    _happiness = _clamp(_happiness + 8);
    _setLog(
      'You passed the equivalency exam and have your diploma. It is never too '
      'late, and it opens the door to college and most jobs.',
      kind: LifeLogKind.learning,
    );
    _changed();
    return true;
  }
}
