import 'dart:io';
import 'dart:ui' as ui;

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_record.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_life_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/coach/coach_report_view.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'contrast_audit_test.dart' show auditContrast;
import 'support/app_fonts.dart';
import 'support/debrief_fixture.dart';

/// The screens that read a life back: Past Lives, one past life, and the Coach.
///
/// Each is drawn at the smallest phone up to a tablet, checked for legibility by
/// WCAG AA, and saved as a picture, because whether a row reads as something you
/// can press, or a card looks finished, is the part a test cannot judge.
void main() {
  const outDir = 'build/screens';

  setUpAll(() async {
    await loadAppFonts();
    Directory(outDir).createSync(recursive: true);
  });

  final story = richRunFacts();
  final records = <LifeRecord>[
    LifeRecord(
      endingId: 'comfortableRetiree',
      name: 'Alex Morgan',
      age: 68,
      netWorth: 8400,
      happiness: 70,
      died: false,
      conceptsMet: 9,
      goldEarned: 120,
      finishedAt: DateTime.utc(2026, 3, 3),
      detail: const LifeDetail(
        degrees: 1,
        promotions: 3,
        workYears: 34,
        ownedHome: true,
        assetsValue: 9000,
      ),
      facts: story,
    ),
    LifeRecord(
      endingId: 'brokeButHappy',
      name: 'Sam Rivera',
      age: 74,
      netWorth: 300,
      happiness: 88,
      died: false,
      conceptsMet: 5,
      goldEarned: 60,
      finishedAt: DateTime.utc(2026, 2, 2),
      detail: const LifeDetail(workYears: 30),
    ),
    LifeRecord(
      endingId: 'quietLife',
      name: 'Old Save',
      age: 61,
      netWorth: 1500,
      happiness: 55,
      died: false,
      conceptsMet: 4,
      goldEarned: 30,
      finishedAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  UserStatsController controllerWith(List<LifeRecord> list) {
    final controller = UserStatsController(service: SupabaseService.instance);
    final base = UserStats.defaults('test_user');
    controller.seedStatsForTest(
      base.copyWith(
        spendingHabits: <String, dynamic>{
          ...base.spendingHabits,
          'life_records': LifeRecordBook(list).toJson(),
        },
      ),
    );
    return controller;
  }

  Widget host(Widget home, UserStatsController controller) =>
      ChangeNotifierProvider<UserStatsController>.value(
        value: controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(),
          home: home,
        ),
      );

  final lives = <LifeReading>[
    const LifeReading(
      age: 68,
      netWorth: 8400,
      happiness: 70,
      degrees: 1,
      borrowedForSchool: 4000,
      promotions: 3,
      workYears: 34,
      assetsValue: 9000,
      loansOwed: 1200,
      ownedHome: true,
    ),
    const LifeReading(
      age: 74,
      netWorth: 300,
      happiness: 88,
      workYears: 30,
      promotions: 0,
    ),
    const LifeReading(
      age: 66,
      netWorth: 5200,
      happiness: 40,
      degrees: 1,
      borrowedForSchool: 3000,
      promotions: 2,
      workYears: 30,
      assetsValue: 2000,
      loansOwed: 2600,
    ),
  ];

  MoneySnapshot snapshot() => MoneySnapshot(
    loggedDaysLast14: 8,
    daysSinceLastLog: 1,
    pinnedHabits: 3,
    habitsLoggedLast14: 3,
    pastLifeNetWorths: [for (final l in lives) l.netWorth],
    lives: lives,
  );

  final screens = <String, Widget Function(UserStatsController)>{
    'past lives list': (c) => host(const PastLivesScreen(), c),
    'past life story': (c) => host(PastLifeScreen(record: records.first), c),
    'past life older': (c) => host(PastLifeScreen(record: records.last), c),
    'coach with lives': (c) => host(
      Scaffold(
        backgroundColor: AppTheme.deepForest,
        body: CoachReportView(snapshot: snapshot()),
      ),
      c,
    ),
  };

  const sizes = <String, Size>{
    '320x568': Size(320, 568),
    '393x852': Size(393, 852),
    'tablet': Size(768, 1024),
  };

  group('nothing overflows', () {
    for (final entry in screens.entries) {
      for (final size in sizes.entries) {
        testWidgets('${entry.key} at ${size.key}', (tester) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final controller = controllerWith(records);
          addTearDown(controller.dispose);

          await tester.pumpWidget(entry.value(controller));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
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
        final controller = controllerWith(records);
        addTearDown(controller.dispose);

        await tester.pumpWidget(entry.value(controller));
        await tester.pump(const Duration(milliseconds: 300));
        final findings = auditContrast(tester, entry.key);
        expect(
          findings,
          isEmpty,
          reason: findings.map((f) => '  • $f').join('\n'),
        );
      });
    }
  });

  group('pictures, for a person to look at', () {
    final shotKey = GlobalKey();
    for (final entry in screens.entries) {
      testWidgets(entry.key, (tester) async {
        tester.view.physicalSize = const Size(393, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final controller = controllerWith(records);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          RepaintBoundary(key: shotKey, child: entry.value(controller)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          final layer =
              shotKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await layer.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$outDir/history_${entry.key.replaceAll(' ', '_')}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  });
}
