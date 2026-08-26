import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_record.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// A controller whose stats already hold [records], with no save round-trip.
UserStatsController _controllerWith(List<LifeRecord> records) {
  final controller = UserStatsController(service: SupabaseService.instance);
  final base = UserStats.defaults('test_user');
  controller.seedStatsForTest(
    base.copyWith(
      spendingHabits: <String, dynamic>{
        ...base.spendingHabits,
        'life_records': LifeRecordBook(records).toJson(),
      },
    ),
  );
  return controller;
}

LifeRecord _rec({
  String ending = 'quietLife',
  String name = 'Ada',
  int age = 70,
  int netWorth = 1000,
  int concepts = 5,
  int gold = 10,
  bool died = false,
  DateTime? at,
}) {
  return LifeRecord(
    endingId: ending,
    name: name,
    age: age,
    netWorth: netWorth,
    happiness: 50,
    died: died,
    conceptsMet: concepts,
    goldEarned: gold,
    finishedAt: at ?? DateTime.utc(2026, 1, 1),
  );
}

Widget _screenFor(UserStatsController controller) {
  return ChangeNotifierProvider<UserStatsController>.value(
    value: controller,
    child: MaterialApp(
      theme: AppTheme.getLightTheme(),
      home: const PastLivesScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<UserStatsController> pump(
    WidgetTester tester,
    List<LifeRecord> records, {
    Size size = const Size(1200, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = _controllerWith(records);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_screenFor(controller));
    await tester.pump();
    return controller;
  }

  testWidgets('empty history explains itself instead of showing zeroes', (
    tester,
  ) async {
    await pump(tester, <LifeRecord>[]);

    expect(find.text('No lives yet'), findsOneWidget);
    // A best tile reading "— coins" would look broken, so none render.
    expect(find.text('Richest life'), findsNothing);
  });

  testWidgets('shows the three bests naming the life that set each', (
    tester,
  ) async {
    await pump(tester, <LifeRecord>[
      _rec(name: 'Rich', netWorth: 9000, age: 40, concepts: 2),
      _rec(name: 'Old', netWorth: 100, age: 95, concepts: 3),
      _rec(name: 'Wise', netWorth: 500, age: 60, concepts: 14),
    ]);

    // Scoped to the tile: the same figure appears again as a stat chip on
    // the history row that set it, so a bare text lookup is ambiguous.
    Finder inTile(String key, String text) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.text(text),
    );

    expect(inTile('best-netWorth', 'Richest life'), findsOneWidget);
    expect(inTile('best-age', 'Longest life'), findsOneWidget);
    expect(inTile('best-concepts', 'Most ideas met'), findsOneWidget);

    expect(inTile('best-netWorth', '9,000 coins'), findsOneWidget);
    expect(inTile('best-age', '95 years'), findsOneWidget);
    expect(inTile('best-concepts', '14 ideas'), findsOneWidget);

    // ...and each names the life that set it.
    expect(inTile('best-netWorth', 'Rich'), findsOneWidget);
    expect(inTile('best-age', 'Old'), findsOneWidget);
    expect(inTile('best-concepts', 'Wise'), findsOneWidget);
  });

  testWidgets('lists every life, newest first', (tester) async {
    await pump(tester, <LifeRecord>[
      _rec(name: 'Oldest', at: DateTime.utc(2026, 1)),
      _rec(name: 'Newest', at: DateTime.utc(2026, 5)),
    ]);

    expect(find.text('2 lives'), findsOneWidget);

    // By row key, not by name text — a name also shows in the bests grid.
    final newest = tester
        .getTopLeft(find.byKey(const ValueKey(
          'life-2026-05-01T00:00:00.000Z-Newest',
        )))
        .dy;
    final oldest = tester
        .getTopLeft(find.byKey(const ValueKey(
          'life-2026-01-01T00:00:00.000Z-Oldest',
        )))
        .dy;
    expect(newest, lessThan(oldest));
  });

  testWidgets('singular label for a single life', (tester) async {
    await pump(tester, <LifeRecord>[_rec(name: 'Only')]);
    expect(find.text('1 life'), findsOneWidget);
  });

  testWidgets('distinguishes retiring from dying', (tester) async {
    await pump(tester, <LifeRecord>[
      _rec(name: 'Retiree', age: 65, died: false, at: DateTime.utc(2026, 2)),
      _rec(name: 'Departed', age: 41, died: true, at: DateTime.utc(2026, 1)),
    ]);

    expect(find.text('retired at 65'), findsOneWidget);
    expect(find.text('died at 41'), findsOneWidget);
  });

  testWidgets('renders an unknown ending id without crashing', (tester) async {
    // An old save can name an ending a later build no longer ships.
    await pump(tester, <LifeRecord>[
      _rec(name: 'Legacy', ending: 'ending_from_a_future_build'),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Unknown ending'), findsOneWidget);
  });

  testWidgets('lays out without overflow on a narrow phone', (tester) async {
    await pump(
      tester,
      List.generate(
        6,
        (i) => _rec(
          name: 'Life $i',
          netWorth: 1000 * i,
          at: DateTime.utc(2026, 1, i + 1),
        ),
      ),
      size: const Size(960, 2000), // ~320dp wide
    );

    expect(tester.takeException(), isNull);
  });
}
