import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart';

import 'support/app_fonts.dart';

/// The town's bottom sheets, at every phone size.
///
/// **Reported as:** screenshots of the neighbor's mission sheet and the Pawn
/// Shop's locked sheet with Flutter's yellow overflow stripes across them,
/// "BOTTOM OVERFLOWED BY 104 PIXELS" and by 28. Each sheet was a fixed-height
/// column inside a plain `showModalBottomSheet`, which caps at half the
/// screen. The town map locks landscape, so the normal case is a screen about
/// 460 logical pixels tall, and the reward line and the button under it were
/// off the bottom and unreachable.
///
/// Nothing caught it because the layout sweep renders whole screens, and
/// these sheets only exist once you walk up to a person or a locked door.
void main() {
  setUpAll(loadAppFonts);

  const sizes = <String, Size>{
    'phone landscape, as reported': Size(1024, 461),
    'small phone landscape': Size(568, 320),
    'phone portrait': Size(390, 844),
    'small phone portrait': Size(320, 568),
  };

  for (final sheet in debugTownSheets().entries) {
    for (final size in sizes.entries) {
      testWidgets('${sheet.key} fits ${size.key}', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;

        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              // How a bottom sheet is laid out: pinned to the bottom, free to
              // be as tall as it likes.
              body: Align(
                alignment: Alignment.bottomCenter,
                child: sheet.value,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        FlutterError.onError = previous;

        expect(
          errors.map((e) => e.exceptionAsString()).toList(),
          isEmpty,
          reason: '${sheet.key} overflows at ${size.key}',
        );

        // On screen, in full. An overflowing sheet still "fits" by rect, so
        // this is checked alongside the exception above, not instead of it.
        final rect = tester.getRect(find.byWidget(sheet.value));
        expect(rect.top, greaterThanOrEqualTo(-0.5));
        expect(rect.bottom, lessThanOrEqualTo(size.value.height + 0.5));

        // Anything too tall for the screen has to be reachable by scrolling.
        final content = find.descendant(
          of: find.byWidget(sheet.value),
          matching: find.byType(Scrollable),
        );
        expect(
          content,
          findsWidgets,
          reason:
              '${sheet.key} cannot scroll, so a long sheet traps its own '
              'buttons off screen',
        );
      });
    }
  }
}
