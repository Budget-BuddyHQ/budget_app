import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Finance Brawl's level-up offers.
///
/// The brief was "make it into levels like survival.io" — and the thing that
/// makes that loop work is not the word *level*, it is that offers **narrow**.
/// Early on you are choosing between everything; by wave fifteen the tracks
/// you maxed are gone and the last few choices are between things you actively
/// want. An endless pool of the same eight sentences has no build in it.
///
/// These drive the real widget, because the levels live in its state.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Pumps the game and returns its state, so the upgrade pool can be driven
  /// directly. The screen is large enough that the level-up sheet lays out.
  Future<State<StatefulWidget>> pumpGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatsController>(
            // Never initialised: the service reads through a nullable client,
            // so an uninitialised Supabase yields signed-out defaults rather
            // than throwing. The upgrade pool does not depend on stats.
            create: (_) =>
                UserStatsController(service: SupabaseService.instance),
          ),
        ],
        child: const MaterialApp(home: FinanceBrawlScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    return tester.state(find.byType(FinanceBrawlScreen));
  }

  group('the offer card describes a level, not a slogan', () {
    test('a levelled upgrade says where it is going', () {
      const first = BrawlUpgrade(
        name: 'Rapid Payments',
        description: 'faster',
        icon: Icons.speed_rounded,
        action: _noop,
        level: 0,
        maxLevel: 8,
      );
      expect(first.isLevelled, isTrue);
      expect(first.levelLabel, 'Lv 0 → 1');

      const last = BrawlUpgrade(
        name: 'Rapid Payments',
        description: 'faster',
        icon: Icons.speed_rounded,
        action: _noop,
        level: 7,
        maxLevel: 8,
      );
      expect(
        last.levelLabel,
        'Lv 7 → MAX',
        reason: 'the final step should say so, or a player wastes a pick '
            'expecting more',
      );
    });

    test('a one-off effect shows no level at all', () {
      // The cash top-up is a consolation prize, not a track. Labelling it
      // "Lv 0 → 1" would promise a progression that does not exist.
      const bonus = BrawlUpgrade(
        name: 'Performance Bonus',
        description: 'cash',
        icon: Icons.savings,
        action: _noop,
      );
      expect(bonus.isLevelled, isFalse);
      expect(bonus.levelLabel, isEmpty);
    });
  });

  group('the pool narrows as a run goes on', () {
    testWidgets('every offer starts at level zero', (tester) async {
      final state = await pumpGame(tester);
      final offers = (state as dynamic).getUpgradeOptionsForTest()
          as List<BrawlUpgrade>;
      expect(offers, isNotEmpty);
      for (final offer in offers) {
        expect(offer.level, 0, reason: '${offer.name} started part-taken');
      }
    });

    testWidgets('taking an upgrade raises its level next time', (tester) async {
      final state = await pumpGame(tester);
      final dyn = state as dynamic;

      final first =
          (dyn.getUpgradeOptionsForTest() as List<BrawlUpgrade>).first;
      first.action();

      final again = (dyn.getUpgradeOptionsForTest() as List<BrawlUpgrade>)
          .firstWhere((u) => u.name == first.name);
      expect(
        again.level,
        1,
        reason: '${first.name} was taken and still offers Lv 0 → 1',
      );
    });

    testWidgets('a maxed track leaves the pool', (tester) async {
      // The property the whole design rests on. Without it the offers never
      // narrow and there is no reason to commit to anything.
      final state = await pumpGame(tester);
      final dyn = state as dynamic;

      final target =
          (dyn.getUpgradeOptionsForTest() as List<BrawlUpgrade>).firstWhere(
        (u) => u.isLevelled,
      );
      final name = target.name;
      final max = target.maxLevel;

      for (var i = 0; i < max; i++) {
        final offer = (dyn.getUpgradeOptionsForTest() as List<BrawlUpgrade>)
            .firstWhere((u) => u.name == name);
        offer.action();
      }

      final remaining = dyn.getUpgradeOptionsForTest() as List<BrawlUpgrade>;
      expect(
        remaining.where((u) => u.name == name),
        isEmpty,
        reason: '$name is maxed at $max and is still being offered',
      );
    });

    testWidgets('there is always something to pick', (tester) async {
      // Draining every track must not leave an empty level-up screen — the
      // run would stall on a sheet with no buttons.
      final state = await pumpGame(tester);
      final dyn = state as dynamic;

      for (var pick = 0; pick < 80; pick++) {
        final offers = dyn.getUpgradeOptionsForTest() as List<BrawlUpgrade>;
        expect(
          offers,
          isNotEmpty,
          reason: 'the pool emptied after $pick picks',
        );
        offers.first.action();
      }
    });

    testWidgets('fire rate and pierce are both levelled tracks', (
      tester,
    ) async {
      // Named directly in the brief. Fire rate multiplies everything else a
      // player has taken, and pierce is what turns a spread build from three
      // kills into a line of them.
      final state = await pumpGame(tester);
      final offers = (state as dynamic).getUpgradeOptionsForTest()
          as List<BrawlUpgrade>;
      final names = offers.map((u) => u.name).toSet();
      expect(names, contains('Rapid Payments'));
      expect(names, contains('Debt Consolidation'));
      for (final name in ['Rapid Payments', 'Debt Consolidation']) {
        final track = offers.firstWhere((u) => u.name == name);
        expect(
          track.maxLevel,
          greaterThan(1),
          reason: '$name is not a track, it is a one-off',
        );
      }
    });
  });
}

void _noop() {}
