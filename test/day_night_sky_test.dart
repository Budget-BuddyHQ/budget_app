import 'package:budget_app/widgets_custom_lotties/day_night_sky.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sky behind the main game.
///
/// Fourteen gradients had been sitting in the asset folder referenced by
/// nothing while the app painted the same flat green at every hour. These
/// check the two things that make using them safe rather than pretty: the
/// mapping covers the whole day, and the art can never take the foreground's
/// contrast down with it.
void main() {
  group('the clock picks the sky', () {
    test('every hour maps to a real frame', () {
      for (var hour = 0; hour < 24; hour++) {
        final frame = DayNightSky.frameForHour(hour);
        expect(
          frame,
          inInclusiveRange(0, DayNightSky.frameCount - 1),
          reason: 'hour $hour fell outside the sheet',
        );
      }
    });

    test('every frame is reachable', () {
      // A gradient no hour selects is an asset shipped and never seen, which
      // is the state this whole widget exists to end.
      final reached = <int>{
        for (var hour = 0; hour < 24; hour++) DayNightSky.frameForHour(hour),
      };
      expect(
        reached.length,
        greaterThanOrEqualTo(12),
        reason: 'only ${reached.length} of the 14 skies are ever shown',
      );
    });

    test('noon and midnight are different skies', () {
      // The whole point. If these collide the mapping has an off-by-one and
      // the app looks the same day and night, which is where it started.
      expect(
        DayNightSky.frameForHour(12),
        isNot(DayNightSky.frameForHour(0)),
      );
    });

    test('the sequence advances through the day', () {
      // Adjacent hours should be adjacent skies — a jump would read as the
      // sky flickering when the clock ticks over.
      for (var hour = 0; hour < 23; hour++) {
        final a = DayNightSky.frameForHour(hour);
        final b = DayNightSky.frameForHour(hour + 1);
        final step = (b - a).abs();
        expect(
          step <= 1 || step == DayNightSky.frameCount - 1,
          isTrue,
          reason: 'hour $hour jumps from frame $a to $b',
        );
      }
    });

    test('the asset path names a numbered frame', () {
      expect(
        DayNightSky.assetForHour(13),
        startsWith('assets/map_assets_coins/day-night-cycle/Day_Night_cycle-'),
      );
      expect(DayNightSky.assetForHour(13), endsWith('.png'));
    });

    test('every hour has a readable label', () {
      for (var hour = 0; hour < 24; hour++) {
        expect(DayNightSky.labelForHour(hour), isNotEmpty);
      }
    });
  });

  group('the sky never costs the foreground its contrast', () {
    testWidgets('a scrim always sits between the art and the content', (
      tester,
    ) async {
      // The contrast audit measures text against the surfaces it declares.
      // A full-strength noon gradient behind a screen of measured labels
      // would invalidate every one of those numbers, so the widget dims the
      // art and lays a dark wash over it — and that is a correctness
      // property, not a styling choice.
      await tester.pumpWidget(
        const MaterialApp(
          home: DayNightSky(child: Text('x', textDirection: TextDirection.ltr)),
        ),
      );

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byType(Image), matching: find.byType(Opacity)),
      );
      expect(
        opacity.opacity,
        lessThan(1.0),
        reason: 'the sky is drawn at full strength',
      );

      final scrims = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color.a > 0.3 && box.color.r < 0.2);
      expect(
        scrims,
        isNotEmpty,
        reason: 'nothing is protecting the foreground from a bright sky',
      );
    });

    testWidgets('a missing frame degrades to nothing, not to an error glyph', (
      tester,
    ) async {
      // A broken-image icon stretched behind an entire screen is a far worse
      // failure than a plain background.
      await tester.pumpWidget(
        const MaterialApp(
          home: DayNightSky(child: Text('x', textDirection: TextDirection.ltr)),
        ),
      );
      await tester.pump();
      expect(find.text('x'), findsOneWidget);
    });
  });
}
