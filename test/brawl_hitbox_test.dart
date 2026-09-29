import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_enemies.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_movement.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Finance Brawl feels like the picture, and the stick does what the thumb does.
///
/// **Reported as:** *"a player tester called the game janky: the hitboxes are
/// weird, and sometimes the joystick just stops."*
///
/// Neither of those is a thing a passing unit test can see on its own, which is
/// how they got to a player. So this file measures the art and holds the
/// collision to it, and it drives the real screen with real fingers.
///
///  * **Hitboxes.** The trees were solid about 46 units above where the tree was
///    drawn, and every enemy hurt across the empty corners of its own square.
///    Both are numbers that come out of the PNGs, so these tests read the PNGs.
///  * **Movement.** The fighter now slides round what it meets instead of
///    sticking, and cannot end up inside anything.
///  * **The stick.** It answers the instant a thumb lands, belongs to one finger,
///    and lets go every way a touch can end.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// The opaque part of a sprite as a share of its frame, read off the PNG.
  ///
  /// [threshold] is the alpha above which a pixel counts as part of the picture,
  /// the same one the measuring script used to choose the numbers.
  Future<({double w, double h, double cx, double cy})> measure(
    WidgetTester tester,
    String path,
  ) async {
    return (await tester.runAsync(() async {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = (await image.toByteData())!;
      var x0 = image.width, y0 = image.height, x1 = -1, y1 = -1;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final alpha = data.getUint8((y * image.width + x) * 4 + 3);
          if (alpha > 24) {
            if (x < x0) x0 = x;
            if (x > x1) x1 = x;
            if (y < y0) y0 = y;
            if (y > y1) y1 = y;
          }
        }
      }
      final w = image.width.toDouble();
      final h = image.height.toDouble();
      return (
        w: (x1 - x0 + 1) / w,
        h: (y1 - y0 + 1) / h,
        cx: (x0 + x1 + 1) / 2 / w,
        cy: (y0 + y1 + 1) / 2 / h,
      );
    }))!;
  }

  group('what touches an enemy is what you can see of it', () {
    testWidgets('every archetype hits about as wide as its picture is', (
      tester,
    ) async {
      for (final enemy in kBrawlEnemies) {
        final m = await measure(
          tester,
          'assets/images/finance_brawl_ui/enemies/${enemy.id}.png',
        );
        // The mean of the opaque width and height, as a share of the frame.
        final seen = (m.w + m.h) / 2;
        expect(
          enemy.hitScale,
          closeTo(seen, 0.13),
          reason:
              '${enemy.id} is drawn ${(seen * 100).round()}% of its frame and '
              'hits at ${(enemy.hitScale * 100).round()}%',
        );
        expect(
          enemy.hitScale,
          lessThanOrEqualTo(1.0),
          reason: '${enemy.id} would hurt from outside its own picture',
        );
      }
    });

    testWidgets('and so does the boss', (tester) async {
      final m = await measure(
        tester,
        'assets/images/finance_brawl_ui/brawl_boss.png',
      );
      expect(kBrawlBossHitScale, closeTo((m.w + m.h) / 2, 0.13));
    });

    test('a swarm of specks is not a wall', () {
      // The smallest picture in the roster fills 59% of its frame. It used to
      // hurt across the whole frame.
      final speck = kBrawlEnemies.firstWhere(
        (e) => e.id == 'subscription_creep',
      );
      expect(speck.hitScale, lessThan(0.7));
    });

    test('no enemy is asked to hit harder than it looks', () {
      for (final enemy in kBrawlEnemies) {
        expect(enemy.hitScale, inInclusiveRange(0.4, 1.0), reason: enemy.id);
      }
    });
  });

  group('trees and rocks are solid where they are drawn', () {
    testWidgets('the tree is drawn so its body sits on its collision circle', (
      tester,
    ) async {
      final m = await measure(
        tester,
        'assets/images/finance_brawl_ui/brawl_tree.png',
      );
      // The game draws the 256-square sprite into a 175 by 206.5 box with
      // BoxFit.contain, which scales it to 175 across.
      const drawn = 175.0;
      final bodyCenter = Offset((m.cx - 0.5) * drawn, (m.cy - 0.5) * drawn);
      final placed = -kBrawlTreeArtShift;
      expect(
        (placed - bodyCenter).distance,
        lessThan(3.0),
        reason:
            'the tree body is ${bodyCenter.dx.toStringAsFixed(1)}, '
            '${bodyCenter.dy.toStringAsFixed(1)} from the middle of its frame '
            'and the art is shifted by ${kBrawlTreeArtShift.dx}, '
            '${kBrawlTreeArtShift.dy}',
      );
    });

    testWidgets('the tree is as wide as the thing you bump into', (
      tester,
    ) async {
      final m = await measure(
        tester,
        'assets/images/finance_brawl_ui/brawl_tree.png',
      );
      const drawn = 175.0;
      // The solid circle is 35 across each way.
      expect(m.w * drawn / 2, closeTo(35.0, 8.0));
    });

    testWidgets('the rock is as wide as the thing you bump into', (
      tester,
    ) async {
      final m = await measure(
        tester,
        'assets/images/finance_brawl_ui/brawl_rock.png',
      );
      const rockRadius = 20.0;
      final visibleRadius = m.w * rockRadius * kBrawlRockArtScale / 2;
      expect(visibleRadius, closeTo(rockRadius, 3.0));
      // And it is drawn on its circle, not beside it.
      final drawn = rockRadius * kBrawlRockArtScale;
      final centerY = (m.cy - 0.5) * drawn;
      expect(kBrawlRockArtShift.dy, closeTo(-centerY, 1.5));
    });
  });

  group('the fighter slides instead of sticking', () {
    const tree = Offset(500, 500);
    Offset walk(Offset from, Offset step) => moveAndSlide(
      from: from,
      step: step,
      radius: 24,
      mapWidth: 2400,
      mapHeight: 2400,
      trees: const [tree],
      treeRadius: 35,
      rocks: const [],
      rockRadius: 20,
    );

    test('walking into a tree never ends inside it', () {
      var pos = const Offset(400, 500);
      for (var i = 0; i < 200; i++) {
        pos = walk(pos, const Offset(3.5, 0));
        expect((pos - tree).distance, greaterThanOrEqualTo(59 - 1e-6));
      }
    });

    test('and glides round it when the push is a little off center', () {
      // Pushing right at a tree from just below its middle line. Testing each
      // axis in turn catches and lets go; sliding carries the fighter round.
      var pos = const Offset(430, 520);
      for (var i = 0; i < 120; i++) {
        pos = walk(pos, const Offset(3.5, -0.4));
      }
      expect(pos.dx, greaterThan(tree.dx + 20), reason: 'got past the tree');
    });

    test('a fighter inside something is pushed out by standing still', () {
      final pos = walk(const Offset(505, 505), Offset.zero);
      expect((pos - tree).distance, greaterThanOrEqualTo(59 - 1e-6));
    });

    test('dead center still gets out', () {
      final pos = walk(tree, const Offset(2, 0));
      expect((pos - tree).distance, greaterThanOrEqualTo(59 - 1e-6));
    });

    test('the arena wall holds', () {
      final pos = walk(const Offset(30, 30), const Offset(-500, -500));
      expect(pos.dx, greaterThanOrEqualTo(24));
      expect(pos.dy, greaterThanOrEqualTo(24));
    });

    test('a fighter wedged between two obstacles ends inside neither', () {
      // Two trees a hair narrower than the fighter, and a push into the gap.
      final pos = moveAndSlide(
        from: const Offset(500, 420),
        step: const Offset(0, 40),
        radius: 24,
        mapWidth: 2400,
        mapHeight: 2400,
        trees: const [Offset(460, 500), Offset(540, 500)],
        treeRadius: 35,
        rocks: const [],
        rockRadius: 20,
      );
      for (final t in const [Offset(460, 500), Offset(540, 500)]) {
        expect((pos - t).distance, greaterThanOrEqualTo(59 - 0.5));
      }
    });

    test('no random walk in a field ever ends up inside an obstacle', () {
      final rng = Random(4);
      final trees = [
        for (var i = 0; i < 20; i++)
          Offset(100 + rng.nextDouble() * 900, 100 + rng.nextDouble() * 900),
      ];
      final rocks = [
        for (var i = 0; i < 20; i++)
          Offset(100 + rng.nextDouble() * 900, 100 + rng.nextDouble() * 900),
      ];
      var pos = const Offset(50, 50);
      for (var i = 0; i < 4000; i++) {
        final angle = rng.nextDouble() * pi * 2;
        pos = moveAndSlide(
          from: pos,
          step: Offset(cos(angle), sin(angle)) * 6,
          radius: 24,
          mapWidth: 1200,
          mapHeight: 1200,
          trees: trees,
          treeRadius: 35,
          rocks: rocks,
          rockRadius: 20,
        );
        // A little slack: a fighter squeezed between three obstacles is allowed
        // a fraction of a unit of overlap, never a visible one.
        expect(
          overlapsObstacle(
            pos: pos,
            radius: 24 - 1.5,
            trees: trees,
            treeRadius: 35,
            rocks: rocks,
            rockRadius: 20,
          ),
          isFalse,
          reason: 'inside something at step $i, $pos',
        );
      }
    });
  });

  group('what the stick reads', () {
    test('nothing inside the dead zone', () {
      expect(StickReading.from(const Offset(4, 0)).vector, Offset.zero);
      expect(StickReading.from(Offset.zero).vector, Offset.zero);
    });

    test('a nudge moves slowly and a full push moves at full speed', () {
      final nudge = StickReading.from(const Offset(8, 0)).vector.distance;
      final full = StickReading.from(const Offset(60, 0)).vector.distance;
      expect(nudge, greaterThan(0));
      expect(nudge, lessThan(0.5));
      expect(full, closeTo(1.0, 1e-9));
    });

    test('strength only ever goes up as the thumb goes out', () {
      var last = 0.0;
      for (var d = 7.0; d <= 60; d += 1) {
        final now = StickReading.from(Offset(d, 0)).vector.distance;
        expect(now, greaterThanOrEqualTo(last - 1e-9));
        last = now;
      }
    });

    test('it points where the thumb points', () {
      final up = StickReading.from(const Offset(0, -30)).vector;
      expect(up.dx, closeTo(0, 1e-9));
      expect(up.dy, lessThan(0));
    });

    test('the knob never leaves the ring', () {
      expect(
        StickReading.from(const Offset(400, 0)).knob.distance,
        lessThanOrEqualTo(StickReading.maxTravel + 1e-9),
      );
    });
  });

  group('the arena is walkable', () {
    Future<dynamic> pumpGame(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStatsController>(
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

    testWidgets('no two obstacles leave a gap the fighter cannot pass', (
      tester,
    ) async {
      // A fresh arena is drawn each time the screen opens, so look at several.
      for (var round = 0; round < 6; round++) {
        final game = await pumpGame(tester);
        final trees = game.treesForTest as List<Offset>;
        final rocks = game.rocksForTest as List<Offset>;
        // The fighter is 48 across; keep 60 between edges.
        const pass = 60.0;
        for (var i = 0; i < trees.length; i++) {
          for (var j = i + 1; j < trees.length; j++) {
            expect(
              (trees[i] - trees[j]).distance,
              greaterThanOrEqualTo(35 + 35 + pass),
              reason: 'two trees close enough to trap somebody',
            );
          }
          for (final rock in rocks) {
            expect(
              (trees[i] - rock).distance,
              greaterThanOrEqualTo(35 + 20 + pass),
              reason: 'a tree and a rock close enough to trap somebody',
            );
          }
        }
        for (var i = 0; i < rocks.length; i++) {
          for (var j = i + 1; j < rocks.length; j++) {
            expect(
              (rocks[i] - rocks[j]).distance,
              greaterThanOrEqualTo(20 + 20 + pass),
            );
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
      }
    });

    testWidgets('the fighter does not start inside anything', (tester) async {
      final game = await pumpGame(tester);
      final start = game.playerPosForTest as Offset;
      for (final t in game.treesForTest as List<Offset>) {
        expect((start - t).distance, greaterThan(59));
      }
      for (final r in game.rocksForTest as List<Offset>) {
        expect((start - r).distance, greaterThan(44));
      }
    });
  });

  group('the joystick', () {
    Future<dynamic> pumpGame(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStatsController>(
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

    Future<void> settle(WidgetTester tester) =>
        tester.pump(const Duration(seconds: 4));

    testWidgets('answers a short drag at once, without a slop first', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final finger = await tester.startGesture(const Offset(300, 400));
      await tester.pump();
      // Ten pixels. A pan gesture would still be waiting for eighteen.
      await finger.moveBy(const Offset(10, 0));
      await tester.pump();

      expect(game.stickHeldForTest, isTrue);
      expect((game.stickVectorForTest as Offset).dx, greaterThan(0));

      await finger.up();
      await tester.pump();
      await settle(tester);
    });

    testWidgets('anchors where the thumb lands', (tester) async {
      final game = await pumpGame(tester);
      final finger = await tester.startGesture(const Offset(300, 400));
      await tester.pump();
      // Landing alone is not a push.
      expect(game.stickVectorForTest, Offset.zero);
      expect(game.stickHeldForTest, isTrue);
      await finger.up();
      await tester.pump();
      await settle(tester);
    });

    testWidgets('moves the fighter, and stops when the thumb lifts', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final start = game.playerPosForTest as Offset;

      final finger = await tester.startGesture(const Offset(300, 400));
      await finger.moveBy(const Offset(40, 0));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final moved = game.playerPosForTest as Offset;
      expect(moved.dx, greaterThan(start.dx + 100));

      await finger.up();
      await tester.pump();
      final atLift = game.playerPosForTest as Offset;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(game.playerPosForTest, atLift, reason: 'kept walking after lift');
      expect(game.stickHeldForTest, isFalse);
      await settle(tester);
    });

    testWidgets('a nudge walks slower than a full push', (tester) async {
      Future<double> travelled(WidgetTester tester, double drag) async {
        final game = await pumpGame(tester);
        final start = game.playerPosForTest as Offset;
        final finger = await tester.startGesture(const Offset(300, 400));
        await finger.moveBy(Offset(drag, 0));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }
        final end = game.playerPosForTest as Offset;
        await finger.up();
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
        return (end - start).distance;
      }

      final nudge = await travelled(tester, 10);
      final full = await travelled(tester, 45);
      expect(nudge, greaterThan(0));
      expect(nudge, lessThan(full * 0.75));
    });

    testWidgets('a second finger does not steal or release the stick', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final first = await tester.startGesture(const Offset(300, 400));
      await first.moveBy(const Offset(30, 0));
      await tester.pump();
      final before = game.stickVectorForTest as Offset;

      final second = await tester.startGesture(const Offset(700, 200));
      await second.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(
        game.stickVectorForTest,
        before,
        reason: 'the second finger moved it',
      );

      await second.up();
      await tester.pump();
      expect(game.stickHeldForTest, isTrue, reason: 'lifting a palm let go');

      await first.up();
      await tester.pump();
      expect(game.stickHeldForTest, isFalse);
      await settle(tester);
    });

    testWidgets('a touch the system takes away lets go', (tester) async {
      final game = await pumpGame(tester);
      final finger = await tester.startGesture(const Offset(300, 400));
      await finger.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(game.stickVectorForTest, isNot(Offset.zero));

      await finger.cancel();
      await tester.pump();
      expect(game.stickHeldForTest, isFalse);
      expect(game.stickVectorForTest, Offset.zero);
      await settle(tester);
    });

    testWidgets('and the next touch works straight away', (tester) async {
      final game = await pumpGame(tester);
      final lost = await tester.startGesture(const Offset(300, 400));
      await lost.moveBy(const Offset(30, 0));
      await lost.cancel();
      await tester.pump();

      final again = await tester.startGesture(const Offset(320, 420));
      await again.moveBy(const Offset(0, 12));
      await tester.pump();
      expect((game.stickVectorForTest as Offset).dy, greaterThan(0));

      await again.up();
      await tester.pump();
      await settle(tester);
    });

    testWidgets('leaving the app lets go of all of it', (tester) async {
      final game = await pumpGame(tester);
      final finger = await tester.startGesture(const Offset(300, 400));
      await finger.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(game.stickVectorForTest, isNot(Offset.zero));

      game.onAppBackgrounded();
      await tester.pump();

      expect(
        game.stickVectorForTest,
        Offset.zero,
        reason: 'the knob was reset and the vector was not, so it kept running',
      );
      expect(game.stickHeldForTest, isFalse);

      await finger.up();
      await tester.pump();
      // The pause card is up; close it so the test can end.
      final resume = find.text('RESUME');
      if (resume.evaluate().isNotEmpty) {
        await tester.tap(resume);
        await tester.pump();
      }
      await settle(tester);
    });

    testWidgets('a checkpoint card over the screen lets go too', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final finger = await tester.startGesture(const Offset(300, 400));
      await finger.moveBy(const Offset(40, 0));
      await tester.pump();

      game.runCheckpointForTest(perfect: false);
      await tester.pump();

      expect(game.stickVectorForTest, Offset.zero);
      expect(game.stickHeldForTest, isFalse);

      await finger.up();
      await tester.pump();
      await settle(tester);
    });

    testWidgets('a slow frame is played, not thrown away', (tester) async {
      final game = await pumpGame(tester);
      final finger = await tester.startGesture(const Offset(300, 400));
      await finger.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final before = game.playerPosForTest as Offset;

      // One long frame, the way a busy wave on a phone produces them. The old
      // rule dropped anything over a tenth of a second and the fighter froze.
      await tester.pump(const Duration(milliseconds: 500));
      final after = game.playerPosForTest as Offset;

      expect(after.dx, greaterThan(before.dx), reason: 'the game froze');
      expect(
        after.dx - before.dx,
        lessThan(20),
        reason: 'one slow frame must not throw the fighter across the map',
      );

      await finger.up();
      await tester.pump();
      await settle(tester);
    });
  });
}
