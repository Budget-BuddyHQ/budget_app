import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_epilogue_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:budget_app/widgets_custom_lotties/pixel_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// Automated colour-contrast audit.
///
/// **Why this exists.** The report was "yellow text is kinda hard to see",
/// which is not something you can chase by reading source: the app has 128
/// hardcoded gold literals and whether any given one is legible depends
/// entirely on what ended up *behind* it, three or four widgets up the tree.
/// Reading `color:` at a call site tells you nothing.
///
/// So this measures the rendered result instead. It walks the real widget
/// tree of each screen, reads every `RichText`'s **resolved** colour (Text
/// merges `DefaultTextStyle` before it builds one, so by that point the style
/// is final), composites the backgrounds above it down to an opaque colour,
/// and computes the WCAG contrast ratio.
///
/// The threshold is WCAG AA: 4.5:1 for body text, relaxed to 3:1 for large
/// text (>=18pt, or >=14pt bold), which is the standard's own allowance and
/// not a fudge. Anything the walk cannot resolve is skipped rather than
/// guessed at — a false "everything is fine" from an unmeasurable case is
/// better than a false failure that trains people to ignore this test.

// --------------------------------------------------------------------------
// WCAG maths
// --------------------------------------------------------------------------

double _channel(int v) {
  final c = v / 255.0;
  return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _channel((c.r * 255).round()) +
    0.7152 * _channel((c.g * 255).round()) +
    0.0722 * _channel((c.b * 255).round());

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = max(la, lb);
  final lo = min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Source-over: [near] painted on top of [far], preserving alpha.
///
/// Preserving the alpha is the whole point and was the first version's bug.
/// A card built as "white at 6% over white at 10% over a dark page" is the
/// app's most common surface, and a composite that clamped the result to
/// opaque after one step reported that surface as **solid white** — so every
/// piece of white text on it looked like a 1:1 failure and the audit's first
/// run was almost entirely false positives.
Color _over(Color near, Color far) {
  final an = near.a;
  if (an >= 1.0) return near;
  final outA = an + far.a * (1 - an);
  if (outA <= 0) return const Color(0x00000000);
  double mix(double n, double f) =>
      (n * an + f * far.a * (1 - an)) / outA;
  return Color.from(
    alpha: outA,
    red: mix(near.r, far.r),
    green: mix(near.g, far.g),
    blue: mix(near.b, far.b),
  );
}

/// Flattens [fg] onto an already-opaque [bg].
Color _composite(Color fg, Color bg) {
  final a = fg.a;
  if (a >= 1.0) return fg;
  return Color.from(
    alpha: 1.0,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
}

// --------------------------------------------------------------------------
// Reading a background out of the tree
// --------------------------------------------------------------------------

/// The paint colour a single widget contributes, or null if it paints nothing.
///
/// Gradients collapse to their midpoint. That is an approximation, but the
/// alternative — testing every stop — flags a failure for a two-pixel band at
/// one end of a sweep, which is noise rather than a defect.
Color? _paintOf(Widget w) {
  // kit widgets paint their background from a nine-sliced PNG thats a
  // *sibling* of the text and not an ancestor, so the plain walk looks
  // straight through the art to the page behind it and measures the wrong
  // thing entirely. these three carry the measured mean of their own art for
  // exactly this reason.
  if (w is PixelFrame) return w.style.surface;
  if (w is PixelRibbon) return w.tone.surface;
  if (w is PixelButton) return w.tone.surface;
  if (w is ColoredBox) return w.color;
  if (w is Material) return w.color;
  if (w is Card) return w.color;
  if (w is Scaffold) return w.backgroundColor;
  if (w is AppBar) return w.backgroundColor;
  if (w is Container) {
    if (w.color != null) return w.color;
    final d = w.decoration;
    if (d is BoxDecoration) return _fromBoxDecoration(d);
  }
  if (w is DecoratedBox) {
    final d = w.decoration;
    if (d is BoxDecoration) return _fromBoxDecoration(d);
  }
  return null;
}

Color? _fromBoxDecoration(BoxDecoration d) {
  if (d.color != null) return d.color;
  final g = d.gradient;
  if (g is LinearGradient) return _midpoint(g.colors);
  if (g is RadialGradient) return _midpoint(g.colors);
  if (g is SweepGradient) return _midpoint(g.colors);
  return null;
}

Color _midpoint(List<Color> colors) {
  if (colors.length == 1) return colors.first;
  var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
  for (final c in colors) {
    r += c.r;
    g += c.g;
    b += c.b;
    a += c.a;
  }
  final n = colors.length;
  return Color.from(
    alpha: a / n,
    red: r / n,
    green: g / n,
    blue: b / n,
  );
}

/// The opaque colour behind [element], or null when the walk hits art.
///
/// Returns null on purpose when it reaches an [Image] before it reaches
/// anything opaque: text over a photo or a sprite has no single background
/// colour, and inventing one would produce a number that means nothing.
Color? backgroundBehind(Element element) {
  Color? acc;
  Color? result;

  element.visitAncestorElements((ancestor) {
    final w = ancestor.widget;

    // Art in the stack above us. Stop — there is nothing here to measure.
    if (w is Image || w is CustomPaint) {
      result = null;
      return false;
    }

    final paint = _paintOf(w);
    if (paint == null || paint.a == 0) return true;

    acc = acc == null ? paint : _over(acc!, paint);
    // Keep climbing while the stack is still see-through. Only an opaque
    // layer settles the question of what is actually behind the text.
    if (acc!.a >= 0.999) {
      result = acc;
      return false;
    }
    return true;
  });

  return result;
}

/// Whether every visible glyph in [label] paints its own colours.
///
/// Emoji are colour bitmaps: `Text('🐷', style: TextStyle(color: red))` draws
/// a pink pig, not a red one, so measuring the declared colour against the
/// background answers a question nobody asked. The app leans on emoji heavily
/// (they *are* a lot of the UI), and without this the audit's loudest
/// findings were all emoji sitting on bright chips — noise that would have
/// buried the handful of real ones.
///
/// Private-use codepoints are deliberately *not* excluded: those are icon
/// fonts, which do take the text colour, so those findings are real.
bool _isPictographic(String label) {
  var sawGlyph = false;
  for (final rune in label.runes) {
    if (rune <= 0x20) continue; // whitespace and control
    if (rune == 0xFE0F || rune == 0xFE0E || rune == 0x200D) continue;
    if (rune >= 0x1F300 && rune <= 0x1FAFF) {
      sawGlyph = true;
      continue;
    }
    if (rune >= 0x2600 && rune <= 0x27BF) {
      sawGlyph = true;
      continue;
    }
    if (rune >= 0x2190 && rune <= 0x21FF) {
      sawGlyph = true;
      continue;
    }
    return false; // something ordinary — measure it
  }
  return sawGlyph;
}

/// Whether this text is actually on screen and worth measuring.
bool _isVisible(Element element) {
  var visible = true;
  element.visitAncestorElements((ancestor) {
    final w = ancestor.widget;
    if (w is Offstage && w.offstage) {
      visible = false;
      return false;
    }
    if (w is Opacity && w.opacity < 0.05) {
      visible = false;
      return false;
    }
    if (w is Visibility && !w.visible) {
      visible = false;
      return false;
    }
    return true;
  });
  return visible;
}

class ContrastFinding {
  ContrastFinding({
    required this.screen,
    required this.text,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.required_,
  });

  final String screen;
  final String text;
  final Color foreground;
  final Color background;
  final double ratio;
  final double required_;

  String get hexFg =>
      '#${(foreground.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  String get hexBg =>
      '#${(background.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  String toString() =>
      '$screen: "${text.length > 34 ? '${text.substring(0, 34)}…' : text}" '
      '$hexFg on $hexBg = ${ratio.toStringAsFixed(2)}:1 '
      '(needs ${required_.toStringAsFixed(1)})';
}

/// Every legibility failure currently rendered by [tester].
List<ContrastFinding> auditContrast(WidgetTester tester, String screen) {
  final findings = <ContrastFinding>[];

  for (final element in tester.allElements) {
    final widget = element.widget;
    if (widget is! RichText) continue;

    final span = widget.text;
    if (span is! TextSpan) continue;
    final label = span.toPlainText(
      includeSemanticsLabels: false,
      includePlaceholders: false,
    );
    if (label.trim().isEmpty) continue;
    if (_isPictographic(label)) continue;

    final style = span.style;
    final fg = style?.color;
    if (fg == null || fg.a < 0.5) continue;
    if (!_isVisible(element)) continue;

    final bg = backgroundBehind(element);
    if (bg == null) continue;

    // WCAG's own large-text allowance: 18pt, or 14pt when bold. Flutter's
    // logical pixels are close enough to pt at the default text scale that
    // treating them as equal is the standard reading of this rule.
    final size = style?.fontSize ?? 14.0;
    final bold = (style?.fontWeight?.value ?? 3) >= FontWeight.w700.value;
    final large = size >= 18 || (bold && size >= 14);
    final needed = large ? 3.0 : 4.5;

    final effective = _composite(fg, bg);
    final ratio = contrastRatio(effective, bg);
    if (ratio + 0.005 < needed) {
      findings.add(
        ContrastFinding(
          screen: screen,
          text: label,
          foreground: effective,
          background: bg,
          ratio: ratio,
          required_: needed,
        ),
      );
    }
  }

  return findings;
}

// --------------------------------------------------------------------------
// Harness
// --------------------------------------------------------------------------

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
      ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
        create: (context) =>
            DailyPlanController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? DailyPlanController(userStats),
      ),
      ChangeNotifierProxyProvider<UserStatsController, MoneyHabitController>(
        create: (context) =>
            MoneyHabitController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? MoneyHabitController(userStats),
      ),
    ],
    child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
  );
}

LifeSimController _midLife() {
  final life = LifeSimController(random: Random(24), initialAge: 0);
  while (life.age < 34 && !life.finished) {
    final event = life.currentEvent;
    if (event != null) life.chooseOption(0);
    life.ageUp();
  }
  return life;
}

void main() {
  // Registers the real typefaces up front. `google_fonts` resolves a
  // bundled face asynchronously on first use, so without this only the
  // faces touched by the first build are loaded when anything is
  // measured — see test/support/app_fonts.dart.
  setUpAll(loadAppFonts);

  final screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Adventure': () => const MainGamePage(),
    'Arcade': () => const MinigamesPage(),
    'Customize': () => const CustomizeScreen(),
    'Academy': () => const LessonScreen(),
    'Money Habits': () => const MoneyHabitsScreen(),
    // The rebuilt jar tab: a painted jar on a mood-tinted plinth, a milestone
    // row, two tinted stat cards and a next-step card. Almost all of it is
    // the tinted-chip pattern that produced most of this audit's findings.
    'Money Habits — Jar': () => const MoneyHabitsScreen(initialTab: 3),
    'Money Habits — Coach': () => const MoneyHabitsScreen(initialTab: 4),
    'Past Lives': () => const PastLivesScreen(),
    'Life sim': () => LifeSimPage(debugInitialLife: _midLife()),
    'Life epilogue': () => LifeEpilogueScreen(
      summary: LifeSummary(
        name: 'Alexandria Montgomery-Whitfield',
        gender: Gender.nonBinary,
        origin: LifeOrigin.comfortable,
        job: 'Senior Financial Wellness Consultant',
        age: 84,
        yearsLived: 84,
        died: false,
        netWorth: 128400,
        happiness: 76,
        health: 62,
        smarts: 91,
        looks: 58,
        relationships: const ['Jordan', 'Priya', 'Marcus'],
        goldReward: 512,
        archetype: LifeEndingArchetype.legacyBuilder,
      ),
    ),
  };

  // Referenced so the unused-import analyser stays quiet about lesson data
  // that `LessonScreen` pulls in lazily.
  assert(lessonUnits.isNotEmpty);

  group('WCAG AA contrast', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} has no illegible text', (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_wrap(entry.value()));
        await tester.pump(const Duration(milliseconds: 400));

        final findings = auditContrast(tester, entry.key);
        expect(
          findings,
          isEmpty,
          reason:
              'text that fails WCAG AA on ${entry.key}:\n'
              '${findings.map((f) => '  • $f').join('\n')}',
        );
      });
    }
  });

  group('the maths itself', () {
    test('black on white is the reference 21:1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.01),
      );
    });

    test('gold on the app background is comfortably legible', () {
      // The colour the report was about, on the surface it usually sits on.
      // This passing is what proves the *background* is the variable, not
      // the gold — which is why the fixes below change surfaces and pick
      // per-surface inks rather than abandoning gold everywhere.
      expect(
        contrastRatio(const Color(0xFFFFD45C), AppTheme.deepForest),
        greaterThan(7.0),
      );
    });

    test('gold on parchment is not', () {
      expect(
        contrastRatio(const Color(0xFFFFD45C), const Color(0xFFEDE1C2)),
        lessThan(1.5),
      );
    });

    test('half-transparent white over black composites to grey', () {
      final c = _composite(const Color(0x80FFFFFF), const Color(0xFF000000));
      expect((c.r * 255).round(), closeTo(128, 2));
      expect(c.a, 1.0);
    });

    test('stacked translucent layers stay translucent', () {
      // The regression that made the audit's first run useless: two faint
      // white veils over a dark page are still faint, and treating them as
      // solid white turned every legible caption into a false failure.
      final veil = _over(
        const Color(0x0FFFFFFF),
        const Color(0x1AFFFFFF),
      );
      expect(veil.a, lessThan(0.2));

      final onPage = _composite(veil, AppTheme.deepForest);
      expect(
        contrastRatio(const Color(0xFFFFFFFF), onPage),
        greaterThan(8.0),
        reason: 'white text on a faintly veiled dark page is legible',
      );
    });
  });
}
