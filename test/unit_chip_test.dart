import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Academy's unit strip.
///
/// Two separate bugs put clipped text on those chips, and only one of them was
/// about width.
void main() {
  /// What the chip shows: the unit's name with its "Unit N: " prefix removed.
  ///
  /// Mirrors the expression in `lesson_screen.dart`. Kept here as a pure
  /// function so the rule can be checked against all 13 units without pumping
  /// a widget for each.
  String chipTitle(String unitTitle) => unitTitle.contains(': ')
      ? unitTitle.split(': ').skip(1).join(': ')
      : unitTitle;

  group('the chip title', () {
    test('never still contains its own prefix', () {
      // The bug: the prefix was stripped by matching the chip's *position* —
      // `replaceFirst('Unit ${index + 1}: ', '')`. Unit ids are permanent and
      // display order is not (`unit_10` is titled "Unit 1"), so the moment
      // those disagree the strip does nothing and the chip renders
      // "Unit 3 / Unit 3: Budgeting" — twice the text in the same space.
      for (final unit in lessonUnits) {
        final title = chipTitle(unit.title);
        expect(
          title,
          isNot(startsWith('Unit ')),
          reason: '${unit.id} still shows its prefix as "$title"',
        );
      }
    });

    test('is never empty', () {
      for (final unit in lessonUnits) {
        expect(chipTitle(unit.title), isNotEmpty, reason: unit.id);
      }
    });

    test('keeps a colon that is part of the name', () {
      // Splitting on ": " and rejoining the tail rather than taking element
      // [1]: a unit called "Unit 4: Credit: The Basics" should keep its
      // second colon rather than losing everything after it.
      expect(chipTitle('Unit 4: Credit: The Basics'), 'Credit: The Basics');
    });

    test('leaves an unprefixed title alone', () {
      expect(chipTitle('Budgeting'), 'Budgeting');
    });
  });

  group('the chip is wide enough for what it holds', () {
    // The other half of the bug. The chip declared a 146px minimum while its
    // contents need icon (22) + gap (10) + a text column inside 14px of
    // padding either side, so titles were clipped mid-word: "Stocks and
    // Tradin", "Protecting Your Mone".
    //
    // The column width is 132 rather than 118 because the second test below
    // caught "Retirement and the 401(k)" needing ~124px even at
    // `FittedLabel`'s 62% floor — it would have been ellipsised rather than
    // scaled, which is the same visible bug by a different route.
    const iconWidth = 22.0;
    const gap = 10.0;
    const columnWidth = 132.0;
    const horizontalPadding = 14.0 * 2;
    // Read from the screen rather than copied, so the two cannot drift. They
    // already did once in the other direction: the strip's scroll estimate
    // carried its own hardcoded 156 and kept it when the chip went to 196, so
    // every jump landed 40px per chip short of the unit it was jumping to.
    const declaredMinWidth = unitChipMinWidth;

    test('the declared minimum covers the content', () {
      const needed = iconWidth + gap + columnWidth + horizontalPadding;
      expect(
        declaredMinWidth,
        greaterThanOrEqualTo(needed),
        reason: 'the chip reserves ${declaredMinWidth}px for ${needed}px of '
            'content, so the title will be cut off',
      );
    });

    test('the longest unit name still fits the column', () {
      // A rough proxy — Pixelify Sans at 14px averages a little under 8px a
      // character — but enough to catch a new unit whose name is far longer
      // than anything the layout was designed around. `FittedLabel` scales
      // down to 62% before it truncates, so the real ceiling is generous.
      final longest = lessonUnits
          .map((unit) => chipTitle(unit.title))
          .reduce((a, b) => a.length >= b.length ? a : b);
      final estimated = longest.length * 8.0;
      expect(
        estimated * 0.62,
        lessThanOrEqualTo(columnWidth),
        reason: '"$longest" cannot fit ${columnWidth}px even scaled down',
      );
    });
  });
}
