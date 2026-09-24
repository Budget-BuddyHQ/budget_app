import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

import 'support/fixed_random.dart';

/// School: what a child does without being asked, and what an adult can choose.
///
/// **Asked for as:** *"the school and sports and everything else still doesn't
/// fully work, everything is still randomized, unlike BitLife where the user has
/// options... some jobs need degrees."* School used to be a Smarts button.
void main() {
  LifeSimController person({
    int age = 18,
    int money = 500,
    LifeOrigin origin = LifeOrigin.struggling,
    bool lucky = false,
  }) => LifeSimController(
    random: lucky ? FixedRandom.lucky() : FixedRandom.unlucky(),
    name: 'Tester',
    origin: origin,
    initialAge: age,
    startMoney: money,
  );

  void year(LifeSimController life) {
    life.ageUp();
    life.debugClearEvent();
  }

  StudyProgram program(String id) => studyProgramById(id)!;

  group('the compulsory years happen by themselves', () {
    test('school starts at five and moves up with age', () {
      final life = person(age: 4);
      expect(life.schoolStage, SchoolStage.none);
      year(life);
      expect(life.schoolStage, SchoolStage.elementary);
      while (life.age < 11) {
        year(life);
      }
      expect(life.schoolStage, SchoolStage.middle);
      expect(life.educationLevel, EducationLevel.primary);
      while (life.age < 14) {
        year(life);
      }
      expect(life.schoolStage, SchoolStage.high);
    });

    test('an ordinary year says nothing, so the feed is not a repeat', () {
      final life = person(age: 6);
      final before = life.history.length;
      year(life);
      final lines = life.history.skip(before).map((e) => e.text).join(' | ');
      expect(lines, isNot(contains('grades')));
    });

    test('a character created adult is taken to have a diploma', () {
      final life = person(age: 30);
      expect(life.educationLevel, EducationLevel.secondary);
      expect(life.credentials, contains('High school diploma'));
      expect(life.canPickNextStep, isFalse);
    });
  });

  group('the end of high school', () {
    test('passing earns the diploma and puts the big question to you', () {
      final life = person(age: 17);
      life.ageUp();

      expect(life.educationLevel, EducationLevel.secondary);
      expect(life.credentials, contains('High school diploma'));
      final card = life.currentEvent!;
      expect(card.id, startsWith('v2_next_step'));
      final follows = card.choices.map((c) => c.followUp).toSet();
      expect(
        follows,
        containsAll(<LifeFollowUp>{
          LifeFollowUp.openCollege,
          LifeFollowUp.openTrades,
          LifeFollowUp.openJobs,
        }),
      );
      expect(life.canPickNextStep, isFalse, reason: 'it has been asked');
    });

    test('every choice on the card teaches what it costs', () {
      final life = person(age: 17)..ageUp();
      for (final choice in life.currentEvent!.choices) {
        expect(choice.teaches, isNotNull, reason: choice.label);
      }
    });

    test('a choice hands the screen a form to open', () {
      final life = person(age: 17)..ageUp();
      final index = life.currentEvent!.choices.indexWhere(
        (c) => c.followUp == LifeFollowUp.openCollege,
      );
      life.chooseOption(index);
      expect(life.takeFollowUp(), LifeFollowUp.openCollege);
      expect(life.takeFollowUp(), LifeFollowUp.none, reason: 'read once');
    });

    test('not passing means no diploma and no college on the card', () {
      final life = person(age: 17)..debugSetEducation(grades: 4);
      life.ageUp();
      expect(life.educationLevel, EducationLevel.primary);
      final follows = life.currentEvent!.choices.map((c) => c.followUp);
      expect(follows, isNot(contains(LifeFollowUp.openCollege)));
      expect(follows, contains(LifeFollowUp.openJobs));
    });

    test('the diploma can be earned later, for a fee', () {
      final life = person(age: 17)..debugSetEducation(grades: 4);
      life.ageUp();
      life.debugClearEvent();
      expect(life.educationLevel, EducationLevel.primary);

      final before = life.money;
      expect(life.earnDiploma(), isTrue);
      expect(life.educationLevel, EducationLevel.secondary);
      expect(life.money, before - 40);
      expect(life.earnDiploma(), isFalse, reason: 'already has one');
    });

    test('the second chance needs the fee', () {
      final life = person(age: 17, money: 0)..debugSetEducation(grades: 4);
      life.ageUp();
      life.debugClearEvent();
      expect(life.earnDiploma(), isFalse);
      expect(life.educationLevel, EducationLevel.primary);
    });
  });

  group('grades follow what you do', () {
    test('studying moves them now, not only at the end of the year', () {
      final life = person(age: 12, money: 0);
      expect(life.grades, 60);
      life.study();
      expect(life.grades, greaterThan(60));
    });

    test('a year with more studying ends with better grades', () {
      int gradesAfter(int studies) {
        final life = person(age: 12, money: 0);
        for (var i = 0; i < studies; i++) {
          life.study();
        }
        final before = life.grades;
        life.ageUp();
        return life.grades - before;
      }

      expect(gradesAfter(3), greaterThan(gradesAfter(0)));
    });

    test('being unwell and unhappy costs marks', () {
      final random = Random(1);
      final well = nextGrades(
        grades: 60,
        smarts: 60,
        studyUses: 0,
        health: 80,
        happiness: 70,
        random: Random(1),
      );
      final unwell = nextGrades(
        grades: 60,
        smarts: 60,
        studyUses: 0,
        health: 20,
        happiness: 10,
        random: random,
      );
      expect(unwell, lessThan(well));
    });

    test('grades stay in range whatever happens', () {
      for (var seed = 0; seed < 50; seed++) {
        final g = nextGrades(
          grades: seed * 2,
          smarts: seed * 2,
          studyUses: 3,
          health: seed * 2,
          happiness: seed * 2,
          random: Random(seed),
        );
        expect(g, inInclusiveRange(0, 100));
      }
    });

    test('there is a letter for every mark', () {
      expect(gradeLetter(95), 'A');
      expect(gradeLetter(85), 'B');
      expect(gradeLetter(75), 'C');
      expect(gradeLetter(65), 'D');
      expect(gradeLetter(20), 'F');
    });
  });

  group('who can apply to what', () {
    test('somebody without a diploma cannot apply to college', () {
      final life = person(age: 17)..debugSetEducation(grades: 4);
      life.ageUp();
      life.debugClearEvent();
      expect(
        life.programGate(program('college_business')),
        'You need a high school diploma',
      );
    });

    test('graduate school needs a bachelor\'s, and the right field', () {
      final life = person(age: 30);
      expect(
        life.programGate(program('grad_medicine')),
        "You need a bachelor's degree first",
      );
      life.debugSetEducation(
        level: EducationLevel.bachelor,
        fields: {StudyField.arts},
      );
      expect(life.programGate(program('grad_medicine')), contains('Health'));
      life.debugSetEducation(fields: {StudyField.science});
      expect(life.programGate(program('grad_medicine')), isNull);
    });

    test('a full-time job has to be left first', () {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 25,
        startJob: 'Barista',
        startSalary: 300,
      );
      expect(
        life.programGate(program('college_business')),
        'Resign from your job before you enrol',
      );
      life.quitJob();
      expect(life.programGate(program('college_business')), isNull);
    });

    test('the bar is Smarts, and being under it is not a gamble', () {
      final p = program('college_cs'); // 58 Smarts
      expect(
        applicationChance(p, smarts: 50, grades: 90, privateSchool: false),
        0,
      );
      expect(
        applicationChance(p, smarts: 58, grades: 60, privateSchool: false),
        greaterThan(0),
      );
    });

    test('better Smarts and better grades raise the odds', () {
      final p = program('college_business');
      int odds(int smarts, int grades) => applicationChance(
        p,
        smarts: smarts,
        grades: grades,
        privateSchool: false,
      );
      expect(odds(70, 60), greaterThan(odds(50, 60)));
      expect(odds(60, 90), greaterThan(odds(60, 40)));
    });

    test('a private school asks more, costs more, and is harder to enter', () {
      final p = program('college_business');
      expect(p.tuitionFor(privateSchool: true), greaterThan(p.tuition * 2));
      expect(p.minSmartsFor(privateSchool: true), p.minSmarts + 8);
      expect(
        applicationChance(p, smarts: 70, grades: 70, privateSchool: true),
        lessThan(
          applicationChance(p, smarts: 70, grades: 70, privateSchool: false),
        ),
      );
    });

    test('a trade is open to anybody who clears a low bar', () {
      expect(
        applicationChance(
          program('trade_electrician'),
          smarts: 40,
          grades: 20,
          privateSchool: false,
        ),
        95,
      );
    });

    test('odds have a word', () {
      expect(oddsLabel(0), 'Not yet');
      expect(oddsLabel(30), 'Long shot');
      expect(oddsLabel(50), 'Fair');
      expect(oddsLabel(75), 'Good');
      expect(oddsLabel(95), 'Very likely');
    });

    test('a year of applications is limited', () {
      final life = person(age: 18, lucky: false);
      // Unlucky always rolls 99, so a middling chance is refused each time.
      final p = program('college_cs');
      for (var i = 0; i < 3; i++) {
        life.applyToProgram(p);
      }
      expect(life.programGate(p), contains('enough places'));
    });
  });

  group('the cost, and who pays', () {
    test('a struggling family pays nothing, a wealthy one most of it', () {
      final poor = person(origin: LifeOrigin.struggling);
      final rich = person(origin: LifeOrigin.wealthy);
      final p = program('college_business');
      expect(poor.tuitionQuote(p).family, 0);
      expect(rich.tuitionQuote(p).family, 99);
      expect(rich.tuitionQuote(p).you, 11);
    });

    test('family help stops at 25', () {
      final rich = person(age: 26, origin: LifeOrigin.wealthy);
      expect(rich.tuitionQuote(program('college_business')).family, 0);
    });

    test('a strong record earns a scholarship', () {
      expect(scholarshipShare(grades: 90, smarts: 75), 0.5);
      expect(scholarshipShare(grades: 78, smarts: 62), 0.25);
      expect(scholarshipShare(grades: 60, smarts: 50), 0);
      expect(scholarshipShare(grades: 90, smarts: 75, teamStanding: 85), 0.8);
    });

    test('the whole course is priced before anybody signs', () {
      final quote = person().tuitionQuote(program('college_business'));
      expect(quote.perYear, 110);
      expect(quote.years, 4);
      expect(quote.sticker, 440);
      expect(quote.total, 440);
    });
  });

  group('going to college', () {
    test('an accepted application enrols and pays the first year', () {
      final life = person(lucky: true, money: 500);
      final result = life.applyToProgram(program('college_business'));

      expect(result, ApplyResult.accepted);
      expect(life.schoolStage, SchoolStage.college);
      expect(life.currentProgram!.name, 'Business Administration');
      expect(life.money, 390);
      expect(life.loans, isEmpty);
      expect(life.isStudent, isTrue);
    });

    test('what cash cannot cover becomes a student loan, and waits', () {
      final life = person(lucky: true, money: 50);
      life.applyToProgram(program('college_business'));

      expect(life.money, 0);
      final loan = life.loans.single;
      expect(loan.kind, LoanKind.student);
      expect(loan.balance, 60);
      expect(loan.deferred, isTrue, reason: 'no payment while in school');
      expect(loan.rate, lessThan(0.18), reason: 'cheaper than a credit card');
    });

    test('a rejection costs a little, and only that', () {
      final life = person(money: 500); // unlucky: always rolls 99
      final before = life.happiness;
      final result = life.applyToProgram(program('college_cs'));
      expect(result, ApplyResult.rejected);
      expect(life.isStudent, isFalse);
      expect(life.money, 500);
      expect(life.happiness, before - 3);
    });

    test('four years later there is a degree, a field and a loan to repay', () {
      final life = person(lucky: true, money: 0);
      life.applyToProgram(program('college_business'));
      for (var i = 0; i < 4; i++) {
        year(life);
      }

      expect(life.isStudent, isFalse);
      expect(life.educationLevel, EducationLevel.bachelor);
      expect(life.studyFields, contains(StudyField.business));
      expect(life.credentials, contains('Bachelor of Business Administration'));
      expect(life.degreesEarned, 1);

      expect(life.studentBorrowed, 440);
      final loan = life.loans.firstWhere((l) => l.kind == LoanKind.student);
      expect(loan.deferred, isFalse, reason: 'repayment starts after school');
      expect(loan.payment, greaterThan(0));
      expect(
        loan.balance,
        greaterThan(440),
        reason: 'interest ran while the student was in school',
      );
    });

    test('a student is not counted as unemployed', () {
      final life = person(lucky: true, money: 500);
      life.applyToProgram(program('college_business'));
      year(life);
      final tally = life.runTally;
      expect(tally.studentYears, 1);
      expect(tally.yearsUnemployed, 0);
    });

    test('a trade is quicker and cheaper and grants a certificate', () {
      final life = person(lucky: true, money: 500);
      life.applyToProgram(program('trade_medassist')); // one year
      year(life);
      expect(life.educationLevel, EducationLevel.certificate);
      expect(life.studyFields, contains(StudyField.health));
    });
  });

  group('leaving school', () {
    test('a child cannot leave before sixteen', () {
      final life = person(age: 12);
      expect(life.leaveSchool(), isFalse);
      expect(life.isStudent, isTrue);
    });

    test('at sixteen it is allowed, and it closes doors', () {
      final life = person(age: 16, money: 0);
      expect(life.leaveSchool(), isTrue);
      expect(life.isStudent, isFalse);
      expect(life.hasDroppedOut, isTrue);
      for (var i = 0; i < 3; i++) {
        year(life);
      }
      expect(
        life.educationLevel,
        isNot(EducationLevel.secondary),
        reason: 'no diploma without finishing',
      );
    });

    test('leaving college keeps the loan and does not award the degree', () {
      final life = person(lucky: true, money: 0);
      life.applyToProgram(program('college_business'));
      year(life);
      final owed = life.loanBalance;
      expect(owed, greaterThan(0));

      expect(life.leaveSchool(), isTrue);
      expect(life.isStudent, isFalse);
      expect(life.educationLevel, EducationLevel.secondary);
      expect(life.loanBalance, greaterThanOrEqualTo(owed));
      final loan = life.loans.firstWhere((l) => l.kind == LoanKind.student);
      expect(loan.deferred, isFalse, reason: 'the loan starts asking now');
    });
  });

  group('the catalogue', () {
    test('has ids that are unique and prices that make sense', () {
      final ids = <String>{};
      for (final p in kStudyPrograms) {
        expect(ids.add(p.id), isTrue, reason: 'duplicate id ${p.id}');
        expect(p.tuition, greaterThan(0));
        expect(p.years, inInclusiveRange(1, 4));
        expect(p.minSmarts, greaterThan(0));
      }
      expect(kStudyPrograms.length, greaterThanOrEqualTo(28));
    });

    test('a longer, harder program costs more than a short easy one', () {
      final trade = program('trade_electrician');
      final college = program('college_business');
      final graduate = program('grad_medicine');
      expect(trade.totalTuition, lessThan(college.totalTuition));
      expect(college.totalTuition, lessThan(graduate.totalTuition));
    });

    test('each stage grants the level it should', () {
      expect(program('trade_electrician').awards, EducationLevel.certificate);
      expect(program('college_cs').awards, EducationLevel.bachelor);
      expect(program('grad_law').awards, EducationLevel.graduate);
    });

    test('graduate programs name what they follow on from', () {
      for (final p in programsAt(SchoolStage.graduate)) {
        // Either any bachelor's will do, or a field is named. Not neither.
        expect(p.stage, SchoolStage.graduate);
        expect(p.minAge, greaterThanOrEqualTo(18));
      }
    });
  });
}
