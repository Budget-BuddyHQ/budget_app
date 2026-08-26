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
