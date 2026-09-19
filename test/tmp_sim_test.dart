import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

/// A player who makes real decisions.
void play(LifeSimController life, {required bool college}) {
  for (var y = 0; y < 90 && !life.finished; y++) {
    if (life.currentEvent != null) {
      final e = life.currentEvent!;
      // the graduation card: college or a job
      if (e.id.startsWith('v2_next_step')) {
        life.chooseOption(college ? 0 : 2);
      } else {
        life.chooseOption(0);
      }
      switch (life.takeFollowUp()) {
        case LifeFollowUp.openCollege:
          final options = programsAt(SchoolStage.college).where(
            (p) => life.programGate(p) == null && life.admissionChance(p) > 30,
          );
          for (final p in options) {
            if (life.applyToProgram(p) == ApplyResult.accepted) break;
          }
        case LifeFollowUp.openJobs:
          _bestJob(life);
        default:
          break;
      }
    }
    // study while at school
    if (life.isStudent) life.study();
    if (life.age >= 16 && !life.hasJob && !life.isStudent) _bestJob(life);
    if (life.hasJob) {
      life.workHarder();
      if (life.promotionBlocker() == null) life.applyForPromotion();
    }
    if (life.age >= 22 && life.rentalId == 'family' && life.hasJob) {
      life.moveTo(kRentals[2]);
    }
    if (life.age >= 24 && life.hasJob && !life.hasLicense) life.getLicense();
    if (life.age >= 26 && life.hasLicense && life.assetsOf(AssetKind.vehicle).isEmpty) {
      final car = kAssets.firstWhere((a) => a.id == 'veh_used');
      life.buyAsset(car, financed: true);
    }
    if (life.age >= 20 && life.partners.isEmpty) {
      life.doActivity('dating_app');
    }
    life.ageUp();
  }
}

void _bestJob(LifeSimController life) {
  final open = life.jobListings().where((l) => l.qualified).toList()
    ..sort((a, b) => b.job.salary.compareTo(a.job.salary));
  for (final l in open.take(3)) {
    if (life.applyForJob(l.job.id) == JobOutcome.hired) return;
  }
}

void main() {
  test('a life with real choices', () {
    for (final college in [true, false]) {
      var totalNw = 0, totalSal = 0, degrees = 0, n = 0, dead = 0;
      var maxSal = 0;
      final levels = <EducationLevel, int>{};
      for (var seed = 0; seed < 60; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          name: 'Alex Morgan',
          withFamily: true,
          startMoney: 150,
        );
        play(life, college: college);
        n++;
        totalNw += life.netWorth;
        totalSal += life.salary;
        maxSal = max(maxSal, life.salary);
        levels[life.educationLevel] = (levels[life.educationLevel] ?? 0) + 1;
        degrees += life.degreesEarned;
        if (life.remembered.isNotEmpty) dead++;
        if (seed < 2) {
          // ignore: avoid_print
          print('--- seed $seed college=$college age=${life.age} '
              'edu=${life.educationLevel.label} job=${life.job} sal=${life.salary} '
              'perf=${life.performance} nw=${life.netWorth} cash=${life.money} '
              'fund=${life.emergencyFund} debt=${life.debt} loans=${life.loanBalance} '
              'assets=${life.assets.map((a) => a.name).join(",")} '
              'people=${life.people.length} lost=${life.remembered.length} '
              'creds=${life.credentials}');
        }
      }
      // ignore: avoid_print
      print('college=$college avgNW=${totalNw ~/ n} avgSalary=${totalSal ~/ n} '
          'maxSalary=$maxSal degrees=$degrees levels=$levels lostSomeone=$dead');
    }
  });
}
