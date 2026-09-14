import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/leak_patrol_page.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

import 'support/app_fonts.dart';

/// Leak Patrol at every window size, *while it is being played*.
///
/// **Reported as:** a screenshot of a laptop-sized window with one row of
/// three holes in the middle of an empty field. The grid sized its cells from
/// the board's width alone, so on a wide window six of the nine holes were
/// laid out below the bottom of the screen and could never be tapped. The
/// responsive sweep never saw it because it only renders the start screen —
/// the board does not exist until you press Start.
///
/// Set `LEAK_SHOTS=1` to also write each size to `build/screens/` to look at.
void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const sizes = <String, Size>{
    'reported window': Size(974, 746),
    'laptop 1280x720': Size(1280, 720),
    'desktop 1920x1080': Size(1920, 1080),
    'tablet landscape': Size(1024, 768),
    'tablet portrait': Size(768, 1024),
    'phone portrait': Size(390, 844),
    'small phone portrait': Size(320, 568),
    'phone landscape': Size(812, 375),
    'small phone landscape': Size(568, 320),
  };
  final shots = Platform.environment['LEAK_SHOTS'] == '1';
  final shotKey = GlobalKey();

  Widget host() => RepaintBoundary(
    key: shotKey,
    child: ChangeNotifierProvider<UserStatsController>(
      create: (_) => UserStatsController(service: SupabaseService.instance),
      child: const MaterialApp(home: LeakPatrolPage()),
    ),
  );

  Future<void> shoot(WidgetTester tester, String name) async {
    if (!shots) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/screens').createSync(recursive: true);
      File(
        'build/screens/leak_patrol_$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  group('the board fits the space it is given', () {
    test('nine holes are always three by three', () {
      for (final space in const [
        Size(900, 500),
        Size(300, 700),
        Size(500, 500),
      ]) {
        final layout = LeakBoardLayout.fit(9, space.width, space.height);
        expect((layout.columns, layout.rows), (3, 3));
        expect(layout.width, lessThanOrEqualTo(space.width + 0.001));
        expect(layout.height, lessThanOrEqualTo(space.height + 0.001));
      }
    });

    test('six holes lie down on a wide window and stand up on a tall one', () {
      final wide = LeakBoardLayout.fit(6, 900, 400);
      expect((wide.columns, wide.rows), (3, 2));
      final tall = LeakBoardLayout.fit(6, 340, 700);
      expect((tall.columns, tall.rows), (2, 3));
    });

    test('never taller than the space, which is the reported bug', () {
      // The old sizing on the reported window: ~310px cells, 3 rows, ~550px.
      final layout = LeakBoardLayout.fit(9, 918, 540);
      expect(layout.height, lessThanOrEqualTo(540));
      expect(layout.cell, greaterThan(150));
    });
  });

  for (final entry in sizes.entries) {
    testWidgets(
      'every hole is reachable at ${entry.key}',
      (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;

        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host());
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '${entry.key}_intro');

        final start = find.text('Start');
        await tester.ensureVisible(start);
        await tester.pump();
        await tester.tap(start);
        await tester.pump();

        // Long enough for several things to be up, short enough that the
        // first ones have not dropped back down.
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 450));
        }
        await shoot(tester, entry.key);
        FlutterError.onError = previous;

        final screen = Offset.zero & entry.value;
        final holes = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('leak-hole-'),
        );
        final count = holes.evaluate().length;
        expect(count, anyOf(6, 9));

        final rects = <Rect>[
          for (var i = 0; i < count; i++) tester.getRect(holes.at(i)),
        ];
        for (var i = 0; i < rects.length; i++) {
          final rect = rects[i];
          expect(
            screen.contains(rect.topLeft) &&
                screen.contains(rect.bottomRight - const Offset(0.5, 0.5)),
            isTrue,
            reason: 'hole $i at $rect is not fully on a ${entry.value} screen',
          );
          expect(
            rect.shortestSide,
            greaterThan(44),
            reason: 'hole $i too small to tap',
          );
          for (var j = i + 1; j < rects.length; j++) {
            expect(
              rects[i].intersect(rects[j]).width > 0.5 &&
                  rects[i].intersect(rects[j]).height > 0.5,
              isFalse,
              reason: 'holes $i and $j overlap',
            );
          }
        }

        // Whatever is up has its label and creature inside its own hole — the
        // reported screenshot had a label sitting on a hole with no creature.
        var occupied = 0;
        for (var i = 0; i < count; i++) {
          final inHole = find.descendant(
            of: holes.at(i),
            matching: find.byType(Image),
          );
          if (inHole.evaluate().isEmpty) continue;
          occupied++;
          // Something that popped on the last frame is still sliding up, and
          // its rect includes that slide (the part below the rim is clipped).
          // Measure where it is heading, not where it is mid-rise.
          final slide = tester
              .widget<Transform>(
                find
                    .descendant(
                      of: holes.at(i),
                      matching: find.byType(Transform),
                    )
                    .first,
              )
              .transform
              .getTranslation()
              .y;
          final sprite = tester.getRect(inHole.first).shift(Offset(0, -slide));
          expect(
            sprite.height,
            greaterThan(20),
            reason: 'creature in hole $i is a speck',
          );
          expect(sprite.top, greaterThanOrEqualTo(rects[i].top - 1));
          expect(sprite.bottom, lessThanOrEqualTo(rects[i].bottom + 1));
          final label = tester
              .getRect(
                find
                    .descendant(of: holes.at(i), matching: find.byType(Text))
                    .first,
              )
              .shift(Offset(0, -slide));
          expect(label.top, greaterThanOrEqualTo(rects[i].top - 1));
          expect(label.bottom, lessThanOrEqualTo(sprite.top + 1));
        }
        expect(occupied, greaterThan(0), reason: 'nothing popped up');

        expect(
          errors.map((e) => e.exceptionAsString()).toList(),
          isEmpty,
          reason: 'layout errors at ${entry.key}',
        );

        // Run the clock out so no timer outlives the test.
        for (var i = 0; i < 65; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        // Fixed pumps, not pumpAndSettle: the town map behind the game keeps
        // animating once its images have really decoded, so it never settles.
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(find.text('Go again'), findsOneWidget);
        if (entry.key == 'reported window' || entry.key == 'phone portrait') {
          await shoot(tester, '${entry.key}_results');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}
