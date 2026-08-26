"""Slices and recolours the Tiny Swords UI pack into Budget Buddy's palette.

WHY THIS EXISTS
---------------
The app kept being described as having no UI, and the cause was structural:
there was nothing to build a game interface *out of*. Every panel was a
`BoxDecoration` rounded rect and every button a `FilledButton`, so the product
read as Material with a pixel font on top.

Meanwhile `assets/imported/Tiny Swords (Free Pack)/UI Elements/` has been
sitting in the repo, referenced by nothing: papers, banners, ribbons, bars,
buttons with real pressed states, and a set of icons. It is far better art
than anything worth generating by hand. Two things stopped it being usable
as-is, and this script fixes both.

**1. It ships as contact sheets, not as nine-slices.** Each file is a 64px
grid with the nine pieces parked at cells 0, 2 and 4 — gaps in between. Flutter
needs the pieces packed adjacently so `centerSlice` can pin the corners and
stretch only the middle. So every sheet is re-packed, and the script prints the
exact `centerSlice` rect for each output.

**2. It is fantasy-medieval.** Teal, wood-brown and parchment, against an app
whose identity is forest green and gold with a turtle carrying a coin. The
recolour maps hue while preserving saturation and value, so the bevels,
shadows and highlights that make the art good all survive — only the colour
family moves.

USAGE
-----
    python tool/build_ui_pack.py            # write assets + preview
    python tool/build_ui_pack.py --preview  # preview only, write nothing

Rerunning is safe: outputs are rewritten from scratch. Never hand-edit the
files under `assets/images/ui_kit/` — edit this script instead.
"""

from __future__ import annotations

import argparse
import colorsys
import os

from PIL import Image

SRC = os.path.join(
    "assets", "imported", "Tiny Swords (Free Pack)", "UI Elements", "UI Elements"
)
OUT = os.path.join("assets", "images", "ui_kit")

# The pack is authored on a 64px grid; pieces occupy whole cells even when the
# art inside a cell has transparent padding for its drop shadow.
CELL = 64


# ---------------------------------------------------------------------------
# Palette targets, in degrees on the colour wheel.
# Kept next to lib/themes_colors/app_theme.dart's values so generated art and
# hand-written Flutter colours cannot drift apart.
# ---------------------------------------------------------------------------
HUE_GREEN = 158 / 360.0   # AppTheme.greenPrimary #4BD2A3
HUE_GOLD = 43 / 360.0     # #E9C46A
HUE_RED = 6 / 360.0       # AppTheme.errorRed #FF8474
HUE_BLUE = 200 / 360.0    # AppTheme.teal #69C6FF


def _hue_of(rgb):
    r, g, b = (c / 255.0 for c in rgb)
    return colorsys.rgb_to_hsv(r, g, b)[0]


def recolor(img: Image.Image, rules) -> Image.Image:
    """Remap hue families, preserving saturation and value.

    Preserving S and V is the whole trick. A flat colour replacement would
    throw away the bevel — the light edge, the shadow edge and the mid tone in
    this pack are the *same* hue at three different values, and it is that
    ramp, not the hue, that makes a rectangle read as a raised panel.

    `rules` is a list of (lo_deg, hi_deg, target_hue, sat_scale). Hue ranges
    are inclusive and may wrap past 360.
    """
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            deg = hh * 360.0
            for lo, hi, target, sat_scale in rules:
                inside = (lo <= deg <= hi) if lo <= hi else (deg >= lo or deg <= hi)
                # Near-greys have a meaningless hue; leave them alone or they
                # flare into colour and the outlines stop reading as outlines.
                if inside and ss > 0.12:
                    nr, ng, nb = colorsys.hsv_to_rgb(
                        target, min(1.0, ss * sat_scale), vv
                    )
                    px[x, y] = (
                        int(nr * 255),
                        int(ng * 255),
                        int(nb * 255),
                        a,
                    )
                    break
    return img


# Teal/cyan trim -> app green. Covers the pack's button faces and wood trim.
TEAL_TO_GREEN = [(150, 220, HUE_GREEN, 1.0)]
# Parchment/tan -> warmer gold, so papers sit with the coin art.
TAN_TO_GOLD = [(20, 60, HUE_GOLD, 1.05)]
# Blue button -> green primary.
BLUE_TO_GREEN = [(170, 260, HUE_GREEN, 1.0)]
# Leave red alone but pull it toward the app's softer error red.
RED_TO_RED = [(330, 20, HUE_RED, 0.95)]


def bands(img: Image.Image, axis: int) -> list[tuple[int, int]]:
    """Find the pieces along one axis, snapped to the 64px authoring grid.

    Detection is on opacity rather than on assuming a 3x3 split, because the
    sheets are not uniform: `RegularPaper` is 320px with pieces one cell wide,
    while `Banner` is 448px with pieces two cells wide. Snapping the detected
    runs outward to cell boundaries recovers the author's intended pieces in
    both cases without hardcoding either.
    """
    alpha = img.convert("RGBA").split()[3]
    w, h = img.size
    px = alpha.load()
    if axis == 0:
        flags = [any(px[x, y] > 8 for y in range(h)) for x in range(w)]
    else:
        flags = [any(px[x, y] > 8 for x in range(w)) for y in range(h)]

    runs, start = [], None
    for i, f in enumerate(flags):
        if f and start is None:
            start = i
        elif not f and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, len(flags) - 1))

    snapped = []
    for lo, hi in runs:
        snapped.append(((lo // CELL) * CELL, ((hi // CELL) + 1) * CELL - 1))
    # Merge anything that collided after snapping.
    merged = []
    for band in snapped:
        if merged and band[0] <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], band[1]))
        else:
            merged.append(band)
    return merged


def repack(img: Image.Image):
    """Re-pack a gapped sheet into a contiguous nine-slice.

    Returns (image, centerSlice-as-LTRB) — the rect is printed so it can be
    pasted straight into `AppAssets`, because a nine-slice asset whose slice
    rect is guessed will smear its bevel and look like a scaling artefact.
    """
    cols = bands(img, 0)
    rows = bands(img, 1)
    if not cols or not rows:
        return img, None

    widths = [c[1] - c[0] + 1 for c in cols]
    heights = [r[1] - r[0] + 1 for r in rows]
    out = Image.new("RGBA", (sum(widths), sum(heights)), (0, 0, 0, 0))

    oy = 0
    for ri, (ry0, ry1) in enumerate(rows):
        ox = 0
        for ci, (cx0, cx1) in enumerate(cols):
            piece = img.crop((cx0, ry0, cx1 + 1, ry1 + 1))
            out.alpha_composite(piece, (ox, oy))
            ox += widths[ci]
        oy += heights[ri]

    if len(cols) < 3 or len(rows) < 3:
        # A 3x1 strip (the bars) has no vertical slice; report horizontal only
        # and let the caller decide.
        left = widths[0] if len(widths) > 1 else 0
        right = left + (widths[1] if len(widths) > 1 else out.width)
        return out, (left, 0, right, out.height)

    left, top = widths[0], heights[0]
    return out, (left, top, left + widths[1], top + heights[1])


# (source, output name, recolour rules, output scale)
#
# **The scale column is not cosmetic — it is a hard rendering limit.**
#
# A nine-slice can never be drawn smaller than its two end caps combined:
# Flutter subtracts the caps from the destination, and a negative remainder
# trips `centerSlice was used with a BoxFit that does not guarantee that the
# image is fully visible`. The pack is authored for a desktop RTS on a 64px
# grid, so a 192px bar has 128px of caps — and the Finance Brawl HUD gives its
# panels about 119px on a phone. That bar was mathematically unable to render
# there, and the layout sweep caught it.
#
# Downscaling is safe for this pack because it is painted, anti-aliased art
# rather than 1:1 pixel art, so LANCZOS keeps it clean.
#
# Buttons go to 0.25 rather than 0.5 because of the *vertical* caps: at 0.5
# the art carried 52px of them, and a 52px-tall button therefore had exactly
# zero stretchable middle and fell back to a plain rounded rect every single
# time. A kit asset that never renders is the same as no kit asset.
def _trim(img: Image.Image, rect):
    """Crop transparent padding, moving the slice rect with it.

    **This is not tidying, it is a correctness fix.** Every sheet in the pack
    carries generous transparent margins, and Flutter fits an `Image` to its
    *file* bounds, not to the art inside them. So a bar whose 64x64 file holds
    24 rows of colour, drawn into a 6px-tall box, painted a ~2px hairline —
    which is exactly what the Finance Brawl progress bar looked like. The
    panels had the same problem less visibly: they rendered inset from their
    own widget and never quite filled it.

    The slice rect has to move by the same offset or it stops describing the
    art and the bevel smears.
    """
    bbox = img.getbbox()
    if bbox is None or bbox == (0, 0, img.width, img.height):
        return img, rect
    out = img.crop(bbox)
    if rect is None:
        return out, None
    l, t, r, b = rect
    dx, dy = bbox[0], bbox[1]
    l, t, r, b = l - dx, t - dy, r - dx, b - dy

    # Clamp back inside the trimmed image. Cropping can move a slice edge
    # outside the art — a 3x1 strip's slice spans the full height, so
    # trimming any blank rows off the top pushes `top` negative, and Flutter
    # asserts on a centerSlice that is not contained by the image. Seen for
    # real on the ribbons (top -7) and the small bar (top -3).
    l = max(0, min(l, out.width - 1))
    t = max(0, min(t, out.height - 1))
    r = max(l + 1, min(r, out.width))
    b = max(t + 1, min(b, out.height))
    return out, (l, t, r, b)


def _downscale(img: Image.Image, rect, scale: float):
    """Shrink a packed nine-slice and its slice rect together.

    Both have to move or the rect stops describing the art — a slice rect that
    is even one pixel off pins the wrong column and the bevel smears.
    """
    w = max(1, int(round(img.width * scale)))
    h = max(1, int(round(img.height * scale)))
    out = img.resize((w, h), Image.LANCZOS)
    if rect is None:
        return out, None
    l, t, r, b = rect
    return out, (
        int(round(l * scale)),
        int(round(t * scale)),
        int(round(r * scale)),
        int(round(b * scale)),
    )


JOBS = [
    ("Papers/RegularPaper.png", "panel_paper", TAN_TO_GOLD, 0.5),
    ("Papers/SpecialPaper.png", "panel_slate", TEAL_TO_GREEN, 0.5),
    ("Banners/Banner.png", "panel_banner", TAN_TO_GOLD, 0.4),
    ("Wood Table/WoodTable.png", "panel_wood", TEAL_TO_GREEN, 0.4),
    ("Buttons/BigBlueButton_Regular.png", "btn_primary", BLUE_TO_GREEN, 0.25),
    ("Buttons/BigBlueButton_Pressed.png", "btn_primary_pressed", BLUE_TO_GREEN, 0.25),
    ("Buttons/BigRedButton_Regular.png", "btn_danger", RED_TO_RED, 0.25),
    ("Buttons/BigRedButton_Pressed.png", "btn_danger_pressed", RED_TO_RED, 0.25),
    ("Bars/BigBar_Base.png", "bar_base", TEAL_TO_GREEN, 0.25),
    ("Bars/SmallBar_Base.png", "bar_base_small", TEAL_TO_GREEN, 0.25),
]

# The pack's bar fill is red — right for a health bar, wrong for the progress
# bars this app needs ("Debts Paid 3/12"), where red would read as danger
# rather than as progress. Emitted in three colours so a caller picks by
# meaning instead of recolouring at every call site.
RED_TO_GREEN = [(330, 30, HUE_GREEN, 1.0)]
RED_TO_GOLD = [(330, 30, HUE_GOLD, 1.0)]

# Bars' fill is a single tileable cell rather than a nine-slice, and the icons
# are standalone — both are copied straight through (recoloured where the pack
# colour fights the app's).
COPIES = [
    ("Bars/BigBar_Fill.png", "bar_fill_green", RED_TO_GREEN),
    ("Bars/BigBar_Fill.png", "bar_fill_gold", RED_TO_GOLD),
    ("Bars/BigBar_Fill.png", "bar_fill_red", None),
    ("Bars/SmallBar_Fill.png", "bar_fill_small_green", RED_TO_GREEN),
    ("Bars/SmallBar_Fill.png", "bar_fill_small_red", None),
    ("Icons/Icon_03.png", "pack_icon_coin", None),
    ("Icons/Icon_06.png", "pack_icon_shield", None),
    ("Icons/Icon_07.png", "pack_icon_arrow_green", None),
    ("Icons/Icon_08.png", "pack_icon_arrow_orange", None),
    ("Icons/Icon_09.png", "pack_icon_x", None),
    ("Icons/Icon_11.png", "pack_icon_info", None),
]


# Ribbons ship five colours stacked in one file, each a 3x1 horizontal slice.
# (source, row index, output name, recolour)
RIBBONS = [
    ("Ribbons/BigRibbons.png", 0, "ribbon_green", TEAL_TO_GREEN, 0.5),
    ("Ribbons/BigRibbons.png", 2, "ribbon_gold", None, 0.5),
    ("Ribbons/BigRibbons.png", 1, "ribbon_red", None, 0.5),
    ("Ribbons/SmallRibbons.png", 0, "ribbon_small_green", TEAL_TO_GREEN, 0.5),
    ("Ribbons/SmallRibbons.png", 4, "ribbon_small_gold", None, 0.5),
]


def extract_ribbon(img: Image.Image, row_index: int):
    """One ribbon out of a stacked sheet, re-packed as a 3x1 nine-slice.

    Ribbons are the cheapest big win in the kit: a section heading drawn on a
    ribbon reads as a game, and the same heading in bold text reads as a
    settings screen. They only work stretched, though — the caps have to stay
    fixed while the middle grows to fit the words.
    """
    rows = bands(img, 1)
    if row_index >= len(rows):
        return None, None
    ry0, ry1 = rows[row_index]
    strip = img.crop((0, ry0, img.width, ry1 + 1))
    return repack(strip)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", action="store_true", help="write nothing")
    args = ap.parse_args()

    if not args.preview:
        os.makedirs(OUT, exist_ok=True)

    results = []
    for rel, name, rules, scale in JOBS:
        src = Image.open(os.path.join(SRC, rel)).convert("RGBA")
        if rules:
            src = recolor(src, rules)
        # Slice at full resolution, *then* scale. Scaling first would move the
        # piece boundaries off the 64px grid and the band detection would find
        # the wrong seams.
        packed, slice_rect = repack(src)
        if scale != 1.0:
            packed, slice_rect = _downscale(packed, slice_rect, scale)
        packed, slice_rect = _trim(packed, slice_rect)
        results.append((name, packed, slice_rect))
        if not args.preview:
            packed.save(os.path.join(OUT, f"{name}.png"))

    for rel, row_index, name, rules, scale in RIBBONS:
        src = Image.open(os.path.join(SRC, rel)).convert("RGBA")
        if rules:
            src = recolor(src, rules)
        packed, slice_rect = extract_ribbon(src, row_index)
        if packed is None:
            continue
        if scale != 1.0:
            packed, slice_rect = _downscale(packed, slice_rect, scale)
        packed, slice_rect = _trim(packed, slice_rect)
        results.append((name, packed, slice_rect))
        if not args.preview:
            packed.save(os.path.join(OUT, f"{name}.png"))

    for rel, name, rules in COPIES:
        src = Image.open(os.path.join(SRC, rel)).convert("RGBA")
        if rules:
            src = recolor(src, rules)
        src, _ = _trim(src, None)
        results.append((name, src, None))
        if not args.preview:
            src.save(os.path.join(OUT, f"{name}.png"))

    print(f"{'name':24} {'size':12} centerSlice (LTRB)")
    for name, img, rect in results:
        r = f"Rect.fromLTRB({rect[0]}, {rect[1]}, {rect[2]}, {rect[3]})" if rect else "-"
        print(f"{name:24} {str(img.size):12} {r}")

    # Slices differ per asset once the art is trimmed, so they cannot share
    # one constant any more. Printed ready to paste into AppAssets rather
    # than left to be re-derived by hand, which is how a rect ends up one
    # pixel off and the bevel smears.
    print()
    print("// --- paste into AppAssets ---")
    for name, img, rect in results:
        if rect is None:
            continue
        camel = "".join(
            w.capitalize() if i else w for i, w in enumerate(name.split("_"))
        )
        print(
            f"  static const Rect kitSlice{camel[0].upper()}{camel[1:]} = "
            f"Rect.fromLTRB({rect[0]}, {rect[1]}, {rect[2]}, {rect[3]});"
        )

    # Contact sheet, so the result is looked at rather than assumed.
    pad, cell = 12, 210
    cols = 5
    rowsn = (len(results) + cols - 1) // cols
    sheet = Image.new(
        "RGBA", (cols * cell + pad, rowsn * cell + pad), (28, 34, 30, 255)
    )
    for i, (name, img, _) in enumerate(results):
        t = img.copy()
        t.thumbnail((cell - pad * 2, cell - pad * 2), Image.NEAREST)
        cx = (i % cols) * cell + pad + (cell - pad * 2 - t.width) // 2
        cy = (i // cols) * cell + pad
        sheet.alpha_composite(t, (cx, cy))
    sheet.save(os.path.join(OUT if not args.preview else ".", "_pack_preview.png"))
    print("\npreview -> _pack_preview.png")


if __name__ == "__main__":
    main()
