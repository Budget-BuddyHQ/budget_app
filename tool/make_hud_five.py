"""Rebuilds the missing `5`, then packs the HUD money font for Flutter.

WHY THIS EXISTS
---------------
`assets/map_assets_coins/underwater_UI_svgs/` holds a bold italic cartoon
number set — 0-9 plus `$`, `%`, `.`, `:` and `+` — which is by far the best
thing in that folder for a money app: it is a display font for currency, and
Budget Buddy shows currency on nearly every screen.

It is missing the digit **5**. Not corrupt, not misnamed — absent. Every other
glyph converted from SVG cleanly; that one did not survive. A number font
without a 5 is unusable for money (no price, balance or percentage can be
trusted to avoid it), so the glyph has to be reconstructed before the font can
be used at all.

HOW THE 5 IS MADE
-----------------
By **vertically flipping the 2**, then shearing the italic back.

That is not a hack, it is how the two letterforms relate: a 2 is a bowl on top
over a flat bar at the bottom; a 5 is a flat bar on top over a bowl at the
bottom. Flipping swaps them exactly, and because it reuses the real glyph, the
stroke weight, the white outline and the drop shadow all match the rest of the
set automatically — which is precisely what hand-drawing a replacement would
have struggled to do.

Flipping also negates the italic, so the 5 would lean the wrong way. The
correction is measured rather than guessed: the font's slant is read off the
`1` (a single stroke, so its centre line *is* the slant), and twice that is
sheared back — once to undo the flip's negation, once to restore the original
lean.

Alternatives that were tried and looked wrong, for the record:
  * 7's top bar + 6's bowl, at several cut heights — reads as an 8 or a 3,
    because the 7's "bar" is a diagonal, not a flat top.
  * 7's top + 3's bottom — same problem.
  * 9 mirrored horizontally, 2 rotated 180 — read as an 'e' and a 'z'.

USAGE
-----
    python tool/make_hud_five.py

Idempotent. Writes `hud_number_5.png` beside the other glyphs, then emits a
trimmed, baseline-aligned copy of the whole set into `assets/images/hud_font/`
for `MoneyGlyphs` to draw.
"""

from __future__ import annotations

import os
import statistics

from PIL import Image

HUD = os.path.join("assets", "map_assets_coins", "underwater_UI_svgs")


def measure_slant(path: str) -> float:
    """Italic slant, in x-pixels per y-pixel, read off the `1`.

    The `1` is a single stroke, so the horizontal centre of each row *is* the
    slant line. Averaging a band at the top and a band at the bottom rather
    than using two single rows keeps a stray antialiased pixel from tilting
    the answer.
    """
    img = Image.open(path).convert("RGBA")
    px = img.load()
    rows = []
    for y in range(img.height):
        xs = [x for x in range(img.width) if px[x, y][3] > 60]
        if xs:
            rows.append((y, (min(xs) + max(xs)) / 2))
    if len(rows) < 24:
        return 0.0
    top, bottom = rows[:12], rows[-12:]
    cx_top = statistics.mean(c for _, c in top)
    cx_bottom = statistics.mean(c for _, c in bottom)
    y_top = statistics.mean(y for y, _ in top)
    y_bottom = statistics.mean(y for y, _ in bottom)
    if y_bottom == y_top:
        return 0.0
    return (cx_top - cx_bottom) / (y_bottom - y_top)


def shear(img: Image.Image, k: float) -> Image.Image:
    """Slant `img` about its vertical centre. Negative k leans right."""
    w, h = img.size
    return img.transform(
        (w, h),
        Image.AFFINE,
        (1, k, -k * h / 2, 0, 1, 0),
        resample=Image.BICUBIC,
    )


GLYPHS = {
    **{str(d): f"hud_number_{d}" for d in range(10)},
    "$": "hud_dollar",
    "%": "hud_percent",
    ".": "hud_dot",
    ":": "hud_colon",
    "+": "hud_plus",
}

FONT_OUT = os.path.join("assets", "images", "hud_font")

# Filenames a widget can build by character. '$' and '%' are not safe in a
# path on every platform, so the atlas uses words.
SAFE_NAME = {
    "$": "dollar",
    "%": "percent",
    ".": "dot",
    ":": "colon",
    "+": "plus",
}


def pack_font() -> None:
    """Trim every glyph to one shared baseline and write the atlas.

    The source glyphs are 128x128 with different amounts of blank space
    around each character, so laying them out raw would make every digit a
    different height and bounce the baseline. Cropping them all to the
    *union* vertical extent fixes the baseline while letting each keep its
    own width — which is what makes a `1` narrow and a `%` wide, as they
    should be.
    """
    os.makedirs(FONT_OUT, exist_ok=True)

    loaded = {}
    for char, stem in GLYPHS.items():
        path = os.path.join(HUD, f"{stem}.png")
        if not os.path.exists(path):
            print(f"  ! missing {stem}.png, skipping {char!r}")
            continue
        loaded[char] = Image.open(path).convert("RGBA")

    # One vertical band for all of them, so digits sit on a common baseline.
    tops, bottoms = [], []
    for img in loaded.values():
        bbox = img.getbbox()
        if bbox:
            tops.append(bbox[1])
            bottoms.append(bbox[3])
    if not tops:
        return
    top, bottom = min(tops), max(bottoms)

    written = 0
    for char, img in loaded.items():
        bbox = img.getbbox()
        if bbox is None:
            continue
        # Horizontal trim is per glyph (real widths), vertical is shared.
        cropped = img.crop((bbox[0], top, bbox[2], bottom))
        name = SAFE_NAME.get(char, char)
        cropped.save(os.path.join(FONT_OUT, f"{name}.png"))
        written += 1
    print(f"packed {written} glyphs into {FONT_OUT} (band y={top}..{bottom})")


def main() -> None:
    two_path = os.path.join(HUD, "hud_number_2.png")
    one_path = os.path.join(HUD, "hud_number_1.png")
    out_path = os.path.join(HUD, "hud_number_5.png")

    slant = measure_slant(one_path)
    two = Image.open(two_path).convert("RGBA")

    # Flip swaps bowl and bar, and negates the slant; shearing by twice the
    # measured slant undoes the negation and restores the lean in one step.
    five = shear(two.transpose(Image.FLIP_TOP_BOTTOM), -2 * slant)
    five.save(out_path)

    print(f"measured italic slant from the 1: k={slant:.3f}")
    print(f"wrote {out_path} ({five.size[0]}x{five.size[1]})")
    pack_font()


if __name__ == "__main__":
    main()
