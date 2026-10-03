import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_activities.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_activities_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_assets_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_occupation_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_people_sheet.dart';
import 'package:budget_app/themes_colors/app_theme.dart';

import 'contrast_audit_test.dart' show auditContrast;
import 'support/app_fonts.dart';
import 'support/fixed_random.dart';
import 'support/life_fixtures.dart';
import 'package:budget_app/widgets_custom_lotties/payday_card.dart';

/// Every Life screen, at every size, in the state that is hardest to lay out.
///
/// **Asked for as:** *"just implement BitLife with all of its functions,"* which
/// is four whole screens and a dozen more behind them. A screen that has never
/// been drawn with a job, a car, a loan and a family in it has never been laid
/// out, and this project's history is a list of exactly that kind of overflow.
///
/// Three things are held for each: it builds without an error at 320 wide (the
/// smallest phone) up to a tablet, nothing in it is illegible by WCAG AA, and a
/// picture of it is saved so a person can look. The picture is the part a test
/// cannot do.
void main() {
  const outDir = 'build/screens';

  setUpAll(() async {
    await loadAppFonts();
    Directory(outDir).createSync(recursive: true);
  });

  Widget host(Widget sheet) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.getLightTheme(),
    home: Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: Align(alignment: Alignment.bottomCenter, child: sheet),
    ),
  );

  final worker = busyAdult();
  // A year of work missed through poor health, for the Payday card.
  final sickWorker =
      LifeSimController(
          random: FixedRandom.unlucky(),
          name: 'Sam',
          initialAge: 25,
          startMoney: 500,
          startJob: 'Baker',
          startSalary: 1000,
        )
        ..debugSetStats(health: 20, happiness: 70)
        ..ageUp();
  final student = collegeStudent();
  final child = schoolChild();
  final seeker = jobSeeker();
  final pro = athlete();
  final car = worker.assetsOf(AssetKind.vehicle).first;
  final loan = worker.loans.first;
  final spouse = worker.personByName('Jo Lee')!;

  final screens = <String, Widget Function()>{
    'occupation worker': () => OccupationSheet(life: worker, onPerson: (_) {}),
    'occupation student': () =>
        OccupationSheet(life: student, onPerson: (_) {}),
    'occupation child': () => OccupationSheet(life: child, onPerson: (_) {}),
    'occupation seeker': () => OccupationSheet(life: seeker, onPerson: (_) {}),
    'job board worker': () => JobBoardSheet(life: worker),
    'job board seeker': () => JobBoardSheet(life: seeker),
    'programs college': () => ProgramSheet(life: seeker),
    'programs trade': () =>
        ProgramSheet(life: seeker, stage: SchoolStage.trade),
    'programs graduate': () =>
        ProgramSheet(life: worker, stage: SchoolStage.graduate),
    'assets worker': () => AssetsSheet(
      life: worker,
      onBudget: () {},
      onPowers: () {},
      onConcepts: () {},
    ),
    'assets child': () => AssetsSheet(
      life: child,
      onBudget: () {},
      onPowers: () {},
      onConcepts: () {},
    ),
    'assets seeker': () => AssetsSheet(
      life: seeker,
      onBudget: () {},
      onPowers: () {},
      onConcepts: () {},
    ),
    'asset detail': () => AssetDetailSheet(life: worker, uid: car.uid),
    // The year's pay, itemised, with missed work in red. See [PaydayCard].
    'payday': () => SingleChildScrollView(
      child: PaydayCard(
        life: sickWorker,
        onOpenBudget: () {},
        onFindJob: () {},
        onSeeDoctor: () {},
      ),
    ),
    'loan': () => LoanSheet(life: worker, uid: loan.uid),
    'housing': () => HousingSheet(life: worker),
    'move money': () => MoveMoneySheet(life: worker),
    'shop vehicles': () => ShopSheet(life: worker),
    'shop property': () => ShopSheet(life: worker, initialKind: AssetKind.home),
    'shop pets': () => ShopSheet(life: worker, initialKind: AssetKind.pet),
    'shop businesses': () =>
        ShopSheet(life: worker, initialKind: AssetKind.business),
    'people worker': () => PeopleSheet(life: worker),
    'people child': () => PeopleSheet(life: child),
    'person spouse': () => PersonSheet(life: worker, name: spouse.name),
    'person mother': () => PersonSheet(
      life: worker,
      name: worker
          .personByName(
            worker.familyMembers.firstWhere((p) => p.role == 'Mother').name,
          )!
          .name,
    ),
    'person remembered': () => PersonSheet(life: worker, name: 'Nana Morgan'),
    'person contact': () =>
        PersonSheet(life: worker, name: worker.workPeople.first.name),
    'activities grid': () =>
        ActivitiesSheet(life: worker, onVolunteer: () {}, onSkills: () {}),
    for (final c in [
      ActivityCategory.mindBody,
      ActivityCategory.social,
      ActivityCategory.love,
      ActivityCategory.travel,
      ActivityCategory.learning,
      ActivityCategory.money,
    ])
      'activities ${c.name}': () => ActivityListSheet(
        life: worker,
        category: c,
        onVolunteer: () {},
        onSkills: () {},
      ),
    'activities social child': () => ActivityListSheet(
      life: child,
      category: ActivityCategory.social,
      onVolunteer: () {},
      onSkills: () {},
    ),
    'sport on team': () => SportSheet(life: pro),
    'sport no team': () => SportSheet(life: worker),
    'special careers': () => SpecialCareersSheet(life: pro),
  };

  const sizes = <String, Size>{
    '320x568': Size(320, 568),
    '360x640': Size(360, 640),
    '393x852': Size(393, 852),
    'tablet': Size(768, 1024),
    'landscape': Size(852, 393),
  };

  group('no screen overflows at any size', () {
    for (final entry in screens.entries) {
      for (final size in sizes.entries) {
        testWidgets('${entry.key} at ${size.key}', (tester) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(host(entry.value()));
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} broke at ${size.key}',
          );
        });
      }
    }
  });

  group('nothing is illegible', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} passes WCAG AA', (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(entry.value()));
        await tester.pump(const Duration(milliseconds: 300));

        final findings = auditContrast(tester, entry.key);
        expect(
          findings,
          isEmpty,
          reason:
              'text that fails AA on ${entry.key}:\n'
              '${findings.map((f) => '  • $f').join('\n')}',
        );
      });
    }
  });

  group('pictures, for a person to look at', () {
    final shotKey = GlobalKey();
    const picked = <String>[
      'occupation worker',
      'occupation student',
      'job board seeker',
      'programs college',
      'assets worker',
      'shop vehicles',
      'people worker',
      'person spouse',
      'activities grid',
      'activities mindBody',
      'sport on team',
      'asset detail',
      'payday',
    ];
    for (final name in picked) {
      testWidgets(name, (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          RepaintBoundary(key: shotKey, child: host(screens[name]!())),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          final layer =
              shotKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await layer.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$outDir/life_${name.replaceAll(' ', '_')}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  });

  group('the fixtures are what they claim', () {
    test('the busy adult has all of it', () {
      expect(worker.hasJob, isTrue);
      expect(worker.educationLevel, EducationLevel.bachelor);
      expect(worker.assets.length, greaterThanOrEqualTo(3));
      expect(worker.loans, isNotEmpty);
      expect(worker.isMarried, isTrue);
      expect(worker.childrenOfYours, isNotEmpty);
      expect(worker.remembered, isNotEmpty);
      expect(
        worker.people.any((p) => p.kind == RelationshipKind.colleague),
        isTrue,
      );
    });

    test('the student is studying and owes', () {
      expect(student.isPostSecondaryStudent, isTrue);
      expect(student.loanBalance, greaterThan(0));
    });
  });
}
