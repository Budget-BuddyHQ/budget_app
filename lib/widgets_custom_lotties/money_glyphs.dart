import 'package:flutter/material.dart';

/// Money drawn in the game's own display font, not in a text font.
///
/// **Why a widget instead of a `Text`.** The glyph set in
/// `assets/images/hud_font/` is art, not a `.ttf` — a bold italic cartoon
/// numeral with a white outline and a drop shadow baked in. There is no way
/// to hand that to `TextStyle`. It is also the single best asset in the
/// underwater pack for this app: Budget Buddy puts a currency figure on
/// nearly every screen, and a balance rendered in a real display face is the
/// difference between a game and a spreadsheet with a pixel font.
///
/// The glyphs were packed with a **shared baseline** — cropped to one common
/// vertical band, each keeping its own width — so laying them out is just a
/// row of images at a fixed height. Without that they would each be a
/// different height and the number would bounce.
///
/// Falls back to a styled [Text] for any character it has no glyph for, so a
/// caller passing a comma or a minus sign degrades to something readable
/// rather than dropping it silently.
///
/// # It is not used for balances any more, and here is the number
///
/// Reported as *"the numbers above there is pretty hard to read"*, pointing at
/// the gold figure on the hub. Measured with
/// `tool/check_digit_legibility.py --glyph-dir assets/images/hud_font`:
///
/// > **13 of 45 digit pairs** differ in under 18% of their inked pixels.
/// > 0/8 at 0.090, 3/8 at 0.096, 1/2 at 0.103.
///
/// That is *worse* than the Pixelify Sans digits a tester had already
/// complained about in a quiz question. The cause is the art's own strengths
/// turned against it: a heavy italic weight with a white outline baked in
/// closes every counter, so 0, 3, 6, 8 and 9 collapse into one blob.
///
/// It was never put through that measurement **because it is not a font** —
/// the digit sweep looked at `.ttf` files and this is a folder of PNGs. The
/// tool takes `--glyph-dir` now, and `test/money_glyphs_test.dart` records
/// the score so it cannot quietly come back.
///
/// **Where it may still be used:** short, decorative figures with plenty of
/// context around them — a reward burst, a score flourish. **Not** a balance,
/// a price, a quiz operand, or anything a player has to read exactly. Those
/// use [AppTheme.numeric], which scores 0 of 45. Nothing uses it today; the
/// widget is kept because the art is good and the rule for using it safely is
/// now written down.
class MoneyGlyphs extends StatelessWidget {
  const MoneyGlyphs(
    this.text, {
    super.key,
    this.height = 28,
    this.spacing = 1,
    this.fallbackColor = const Color(0xFFFFD45C),
  });

  /// What to draw. Digits and `$ % . : +` have art; anything else falls back.
  final String text;

  /// Cap height in logical pixels. Widths follow each glyph's own aspect.
  final double height;

  /// Extra space between glyphs. The font is italic, so it already nests
  /// slightly; a large gap makes a number read as separate symbols.
  final double spacing;

  final Color fallbackColor;

  static const Map<String, String> _names = <String, String>{
    r'$': 'dollar',
    '%': 'percent',
    '.': 'dot',
    ':': 'colon',
    '+': 'plus',
  };

  static String? _assetFor(String char) {
    if (char.length != 1) return null;
    final code = char.codeUnitAt(0);
    final isDigit = code >= 0x30 && code <= 0x39;
    final name = isDigit ? char : _names[char];
    return name == null ? null : 'assets/images/hud_font/$name.png';
  }

  /// Whether every character in [value] can be drawn as art.
  ///
  /// Exposed so a caller can decide *before* laying out — a figure that is
  /// half art and half fallback text looks worse than one drawn entirely in
  /// the text font.
  static bool canRender(String value) =>
      value.split('').every((c) => _assetFor(c) != null);

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < chars.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              _glyph(chars[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _glyph(String char) {
    final asset = _assetFor(char);
    if (asset == null) {
      // A space keeps its width; anything else is drawn as text so a stray
      // comma or minus is still legible.
      if (char == ' ') return SizedBox(width: height * 0.28);
      return Text(
        char,
        style: TextStyle(
          color: fallbackColor,
          fontSize: height * 0.9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Image.asset(
      asset,
      height: height,
      // The art is high-resolution and drawn down, so smoothing is right
      // here — unlike the pixel kit, where it would turn the art to mush.
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => SizedBox(width: height * 0.5),
    );
  }
}
