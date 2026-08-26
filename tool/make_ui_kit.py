"""Generates Budget Buddy's pixel-art UI kit into assets/images/ui_kit/.

WHY THIS EXISTS
---------------
The app kept being described as "not having UI", and the reason was visible
the moment the old kit was rendered side by side: `assets/images/ui/` is a
flat green rounded rectangle with a gold stripe, plus four 8x8 icons. Nothing
in it reads as a *game* interface, so every screen fell back to Material
defaults with a pixel font on top.

This produces the missing half: nine-slice frames and buttons with real
bevels, corner studs, pressed states, and a hand-drawn 16x16 icon set — in
the app's own palette, so it sits with the existing turtle/coin art instead
of next to it.

WHY GENERATED RATHER THAN DRAWN BY HAND
---------------------------------------
Bevel geometry is the same four rules on every frame (outline, top-left
highlight, bottom-right shadow, fill). Writing those rules once means a
palette change is a one-line edit and every asset stays consistent, which is
exactly what hand-drawing 40 files cannot promise. The *icons* are hand-drawn
here as ASCII sprite maps, because iconography is judgement, not geometry —
and a sprite map stays editable by anyone who can count squares.

USAGE
-----
    python tool/make_ui_kit.py

Requires Pillow. Rerunning is safe: every file is rewritten from scratch.
"""

from __future__ import annotations

import os

from PIL import Image

OUT = os.path.join("assets", "images", "ui_kit")

# ---------------------------------------------------------------------------
# Palette. Pulled from lib/themes_colors/app_theme.dart so generated art and
# hand-written Flutter colours cannot drift apart.
# ---------------------------------------------------------------------------
INK = (10, 26, 18, 255)          # near-black outline, used on everything
DEEP = (15, 46, 32, 255)         # AppTheme.deepForest
DARK = (27, 70, 51, 255)         # AppTheme.darkForest
PANEL = (38, 79, 61, 255)        # AppTheme.panel
PANEL_HI = (51, 93, 72, 255)     # AppTheme.panelStrong
GREEN = (75, 210, 163, 255)      # AppTheme.greenPrimary
LIME = (183, 247, 215, 255)      # AppTheme.limeAccent
GOLD = (233, 196, 106, 255)
GOLD_HI = (255, 212, 92, 255)
GOLD_LO = (168, 133, 56, 255)
RED = (255, 132, 116, 255)
RED_LO = (176, 78, 68, 255)
BLUE = (105, 198, 255, 255)
BLUE_LO = (58, 122, 168, 255)
CREAM = (247, 255, 251, 255)
GREY = (120, 140, 130, 255)
BROWN = (140, 96, 56, 255)
BROWN_LO = (94, 62, 34, 255)
NONE = (0, 0, 0, 0)


def _shade(color, factor):
    """Darken (<1) or lighten (>1) a colour, keeping it in range."""
    r, g, b, a = color
    return (
        max(0, min(255, int(r * factor))),
        max(0, min(255, int(g * factor))),
        max(0, min(255, int(b * factor))),
        a,
    )


# ---------------------------------------------------------------------------
# Nine-slice frames
# ---------------------------------------------------------------------------
def make_frame(
    size: int,
    fill,
    *,
    outline=INK,
    studs=None,
    header=None,
    inner_pad: int = 3,
) -> Image.Image:
    """A bevelled panel built for `centerSlice` stretching.

    The corners carry all the detail and the middle is deliberately flat, so
    Flutter can stretch the interior to any size without smearing a gradient
    or tiling a pattern. That is the whole reason a nine-slice looks right at
    arbitrary sizes and a plain scaled PNG does not.
    """
    img = Image.new("RGBA", (size, size), NONE)
    px = img.load()

    hi = _shade(fill, 1.35)
    lo = _shade(fill, 0.62)

    for y in range(size):
        for x in range(size):
            edge = x == 0 or y == 0 or x == size - 1 or y == size - 1
            inner = x == 1 or y == 1 or x == size - 2 or y == size - 2
            if edge:
                px[x, y] = outline
            elif inner:
                # Top and left catch the light; bottom and right fall away.
                # This one asymmetry is what makes a flat rectangle read as a
                # raised surface rather than as a coloured box.
                px[x, y] = hi if (x == 1 or y == 1) else lo
            else:
                px[x, y] = fill

    if header is not None:
        for y in range(2, 2 + inner_pad):
            for x in range(2, size - 2):
                px[x, y] = header
        for x in range(2, size - 2):
            px[x, 2 + inner_pad] = _shade(header, 0.55)

    if studs is not None:
        # A 2x2 rivet inset from each corner. Corners are the only part of a
        # nine-slice that never stretches, so detail placed here survives at
        # every size — anywhere else it would smear.
        for cx, cy in ((3, 3), (size - 5, 3), (3, size - 5), (size - 5, size - 5)):
            px[cx, cy] = _shade(studs, 1.25)
            px[cx + 1, cy] = studs
            px[cx, cy + 1] = studs
            px[cx + 1, cy + 1] = _shade(studs, 0.7)

    return img


def make_button(w: int, h: int, base, *, pressed=False, disabled=False):
    """A chunky bevelled button, nine-sliced horizontally."""
    img = Image.new("RGBA", (w, h), NONE)
    px = img.load()

    fill = _shade(base, 0.55) if disabled else base
    if disabled:
        fill = (
            int(fill[0] * 0.5 + GREY[0] * 0.5),
            int(fill[1] * 0.5 + GREY[1] * 0.5),
            int(fill[2] * 0.5 + GREY[2] * 0.5),
            255,
        )
    hi = _shade(fill, 1.4)
    lo = _shade(fill, 0.55)

    for y in range(h):
        for x in range(w):
            if x == 0 or y == 0 or x == w - 1 or y == h - 1:
                px[x, y] = INK
            elif y == 1 and not pressed:
                px[x, y] = hi
            elif y == h - 2:
                px[x, y] = lo
            elif x == 1:
                px[x, y] = hi if not pressed else lo
            elif x == w - 2:
                px[x, y] = lo
            else:
                px[x, y] = fill

    if pressed:
        # Pressed reads as "pushed down into the panel": the highlight moves
        # to the bottom edge and the top goes dark.
        for x in range(2, w - 2):
            px[x, 1] = lo
            px[x, h - 2] = hi
    return img


# ---------------------------------------------------------------------------
# Hand-drawn sprites, as ASCII maps.
#
# Legend: '.' transparent, 'k' ink outline, and the rest are palette letters
# defined in SPRITE_COLORS. Authored at 16x16 so a glyph still reads at 16
# logical pixels on a phone while carrying real detail when scaled up.
# ---------------------------------------------------------------------------
SPRITE_COLORS = {
    ".": NONE,
    "k": INK,
    "g": GOLD,
    "G": GOLD_HI,
    "d": GOLD_LO,
    "n": GREEN,
    "N": LIME,
    "m": _shade(GREEN, 0.6),
    "r": RED,
    "R": _shade(RED, 1.2),
    "q": RED_LO,
    "b": BLUE,
    "B": _shade(BLUE, 1.25),
    "v": BLUE_LO,
    "w": CREAM,
    "s": GREY,
    "o": BROWN,
    "O": BROWN_LO,
    "p": PANEL_HI,
}

SPRITES: dict[str, list[str]] = {
    # A coin, three-quarter lit, with a capped currency bar through it.
    # The app's own logo is a turtle carrying a coin, so this is the most
    # repeated shape in the product and gets the most care. An earlier
    # draft used a hollow ring and read as a target, not as money.
    "icon_coin": [
        "................",
        ".....kkkkkk.....",
        "...kkGGGGGGkk...",
        "..kGGGGGGGGGGk..",
        ".kGGGGGGGGGGGGk.",
        "kGGGGkkkkkkGGGGk",
        "kGGGGGGkkGGGGGGk",
        "kGGGGGGkkGGGGGGk",
        "kGGGGGGkkGGGGGGk",
        "kGGGGGGkkGGGGGGk",
        "kGGGGkkkkkkGGGGk",
        ".kGGGGGGGGGGGGk.",
        "..kGGGGGGGGGGk..",
        "...kkdddddddk...",
        ".....kkkkkk.....",
        "................",
    ],
    # Stacked coins — "savings", as opposed to the single coin's "money".
    "icon_stack": [
        "................",
        "....kkkkkkkk....",
        "...kGGGGGGGGk...",
        "..kGGdddddGGGk..",
        "...kGGGGGGGGk...",
        "....kkkkkkkk....",
        "...kGGGGGGGGk...",
        "..kGGdddddGGGk..",
        "...kGGGGGGGGk...",
        "....kkkkkkkk....",
        "...kGGGGGGGGk...",
        "..kGGdddddGGGk..",
        "..kGGGGGGGGGGk..",
        "...kdddddddk....",
        "....kkkkkkk.....",
        "................",
    ],
    # A piggy bank. Reads as "put it away and leave it there" in a way a
    # generic wallet does not.
    "icon_piggy": [
        "................",
        "...........k....",
        "....kkkk..kNk...",
        "..kkNNNNkkNNk...",
        ".kNNNNNNNNNNkk..",
        "kNNkNNNNNNNNNNk.",
        "kNNNNNNNNNNNNNk.",
        "kNNNNNNNNNNNNkk.",
        "kNNNNNNNNNNNNk..",
        "kNNNNNNNNNNNNk..",
        ".kNNNNNNNNNNk...",
        "..kkNkkkkNkk....",
        "...kNk..kNk.....",
        "...kkk..kkk.....",
        "................",
        "................",
    ],
    # Three ascending bars rather than a polyline: at 16px a line turns to
    # mush, while stepped bars keep their shape all the way down.
    "icon_chart_up": [
        "................",
        "................",
        "................",
        "..........kkkk..",
        "..........kNNk..",
        "..........kNNk..",
        "......kkkkkNNk..",
        "......kNNkkNNk..",
        "......kNNkkNNk..",
        "......kNNkkNNk..",
        "..kkkkkNNkkNNk..",
        "..kNNkkNNkkNNk..",
        "..kNNkkNNkkNNk..",
        "..kNNkkNNkkNNk..",
        "..kkkkkkkkkkkk..",
        "................",
    ],
    "icon_chart_down": [
        "................",
        "................",
        "................",
        "..kkkk..........",
        "..krrk..........",
        "..krrk..........",
        "..krrkkkkk......",
        "..krrkkrrk......",
        "..krrkkrrk......",
        "..krrkkrrk......",
        "..krrkkrrkkkkk..",
        "..krrkkrrkkrrk..",
        "..krrkkrrkkrrk..",
        "..krrkkrrkkrrk..",
        "..kkkkkkkkkkkk..",
        "................",
    ],
    # Heart — health in the Life sim.
    "icon_heart": [
        "................",
        "...kkk....kkk...",
        "..kRRRk..kRRRk..",
        ".kRRRRRkkRRRRRk.",
        "kRRwRRRRRRRRRRRk",
        "kRRwRRRRRRRRRRRk",
        "kRRRRRRRRRRRRRRk",
        ".kRRRRRRRRRRRRk.",
        "..kRRRRRRRRRRk..",
        "...kRRRRRRRRk...",
        "....kRRRRRRk....",
        ".....kRRRRk.....",
        "......kRRk......",
        ".......kk.......",
        "................",
        "................",
    ],
    # Star — XP, ratings, "new".
    "icon_star": [
        "................",
        ".......kk.......",
        "......kGGk......",
        "......kGGk......",
        "..kkkkkGGkkkkk..",
        ".kGGGGGGGGGGGGk.",
        "..kGGGGGGGGGGk..",
        "...kGGGGGGGGk...",
        "....kGGGGGGk....",
        "...kGGGGGGGGk...",
        "..kGGGkkkkGGGk..",
        ".kGGGk....kGGGk.",
        ".kGGk......kGGk.",
        "..kk........kk..",
        "................",
        "................",
    ],
    # Shield with a tick — the emergency fund. The tick has to be drawn as
    # a diagonal pair of runs; an earlier draft's stray pixels read as a
    # question mark, which says roughly the opposite thing.
    "icon_shield": [
        "................",
        "...kkkkkkkkkk...",
        "..kbBBBBBBBBbk..",
        "..kbBBBBBBBBbk..",
        "..kbBBBBBBBwbk..",
        "..kbBBBBBBwwbk..",
        "..kbBwBBBwwBbk..",
        "..kbBwwBwwBBbk..",
        "..kbBBwwwBBBbk..",
        "...kbBwwBBBbk...",
        "...kbBBBBBBbk...",
        "....kbBBBBbk....",
        ".....kbBBbk.....",
        "......kbbk......",
        ".......kk.......",
        "................",
    ],
    # Padlock — a locked lesson, a blocked action.
    "icon_lock": [
        "................",
        ".....kkkkkk.....",
        "....ksssssk.....",
        "...kssk..ksk....",
        "...ksk....ksk...",
        "...ksk....ksk...",
        "..kkkkkkkkkkkk..",
        "..kGGGGGGGGGGk..",
        "..kGGGGkkGGGGk..",
        "..kGGGkddkGGGk..",
        "..kGGGkddkGGGk..",
        "..kGGGGkkGGGGk..",
        "..kGGGGGGGGGGk..",
        "..kkkkkkkkkkkk..",
        "................",
        "................",
    ],
    # An open book with a visible spine and ruled lines. Without the lines
    # the two pages read as two blank rectangles.
    "icon_book": [
        "................",
        "................",
        "..kkkkkkkkkkkk..",
        ".kwwwwwkkwwwwwk.",
        ".kwwwwwkkwwwwwk.",
        ".kwOOwwkkwwOOwk.",
        ".kwwwwwkkwwwwwk.",
        ".kwOOOwkkwOOOwk.",
        ".kwwwwwkkwwwwwk.",
        ".kwOOwwkkwwOOwk.",
        ".kwwwwwkkwwwwwk.",
        ".kOOOOOkkOOOOOk.",
        "..kkkkkkkkkkkk..",
        "................",
        "................",
        "................",
    ],
    # Trophy — leaderboard, achievements.
    "icon_trophy": [
        "................",
        "..kkkkkkkkkkkk..",
        ".kGGGGGGGGGGGGk.",
        "kkGGGGGGGGGGGGkk",
        "kdkGGGGGGGGGGkdk",
        "kdkGGGGGGGGGGkdk",
        "kdkGGGGGGGGGGkdk",
        "kkkGGGGGGGGGGkkk",
        "...kGGGGGGGGk...",
        "....kGGGGGGk....",
        ".....kGGGGk.....",
        "......kGGk......",
        "...kkkkGGkkkk...",
        "..kdddddddddk...",
        "..kkkkkkkkkkk...",
        "................",
    ],
    # Two pixels thick. A one-pixel tick disappears against a busy panel.
    "icon_check": [
        "................",
        ".............kk.",
        "............kNNk",
        "...........kNNk.",
        "..........kNNk..",
        ".........kNNk...",
        "..kk....kNNk....",
        "..kNk..kNNk.....",
        "..kNNkkNNk......",
        "...kNNNNk.......",
        "....kNNk........",
        ".....kk.........",
        "................",
        "................",
        "................",
        "................",
    ],
    "icon_cross": [
        "................",
        "..kk........kk..",
        ".krrk......krrk.",
        "..krrk....krrk..",
        "...krrk..krrk...",
        "....krrkkrrk....",
        ".....krrrrk.....",
        "......krrk......",
        ".....krrrrk.....",
        "....krrkkrrk....",
        "...krrk..krrk...",
        "..krrk....krrk..",
        ".krrk......krrk.",
        "..kk........kk..",
        "................",
        "................",
    ],
}

# Tutorial pointers. Chunky, high-contrast, and drawn with a white core so
# they stay visible over both the dark panels and the bright pixel map.
POINTERS: dict[str, list[str]] = {
    "arrow_down": [
        "......kkkk......",
        "......kGGk......",
        "......kGGk......",
        "......kGGk......",
        "......kGGk......",
        "......kGGk......",
        "..kkkkkGGkkkkk..",
        "..kGGGGGGGGGGk..",
        "...kGGGGGGGGk...",
        "....kGGGGGGk....",
        ".....kGGGGk.....",
        "......kGGk......",
        ".......kk.......",
        "................",
        "................",
        "................",
    ],
    "arrow_up": [
        "................",
        "................",
        "................",
        ".......kk.......",
        "......kGGk......",
        ".....kGGGGk.....",
        "....kGGGGGGk....",
        "...kGGGGGGGGk...",
        "..kGGGGGGGGGGk..",
        "..kkkkkGGkkkkk..",
        "......kGGk......",
        "......kGGk......",
        "......kGGk......",
        "......kGGk......",
        "......kGGk......",
        "......kkkk......",
    ],
    "arrow_right": [
        "................",
        "................",
        ".........kk.....",
        ".........kGk....",
        "..kkkkkkkkGGk...",
        "..kGGGGGGGGGGk..",
        "..kGGGGGGGGGGGk.",
        "..kGGGGGGGGGGGGk",
        "..kGGGGGGGGGGGk.",
        "..kGGGGGGGGGGk..",
        "..kkkkkkkkGGk...",
        ".........kGk....",
        ".........kk.....",
        "................",
        "................",
        "................",
    ],
    "arrow_left": [
        "................",
        "................",
        ".....kk.........",
        "....kGk.........",
        "...kGGkkkkkkkk..",
        "..kGGGGGGGGGGk..",
        ".kGGGGGGGGGGGk..",
        "kGGGGGGGGGGGGk..",
        ".kGGGGGGGGGGGk..",
        "..kGGGGGGGGGGk..",
        "...kGGkkkkkkkk..",
        "....kGk.........",
        ".....kk.........",
        "................",
        "................",
        "................",
    ],
}


def render_sprite(rows: list[str], scale: int = 1) -> Image.Image:
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, h), NONE)
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            px[x, y] = SPRITE_COLORS.get(ch, NONE)
    if scale != 1:
        img = img.resize((w * scale, h * scale), Image.NEAREST)
    return img


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    written: list[str] = []

    def save(img: Image.Image, name: str) -> None:
        path = os.path.join(OUT, name)
        img.save(path)
        written.append(f"{name} {img.size[0]}x{img.size[1]}")

    # Frames and buttons are NOT emitted here any more.
    #
    # They were, and they were fine — but `tool/build_ui_pack.py` produces
    # better ones by slicing and recolouring the Tiny Swords pack that was
    # already sitting in the repo unused, and shipping two competing sets of
    # panels would just be more unused art on top of the unused art this
    # whole effort exists to fix. `make_frame`/`make_button` are kept above
    # because they are still the fastest way to prototype a new surface
    # colour before committing to pack art for it.
    #
    # What this script still owns is the ICON set: the pack has no coin
    # stack, piggy bank, or up/down chart, and those are the concepts a
    # budgeting app needs most.

    # --- icons and pointers --------------------------------------------
    for name, rows in SPRITES.items():
        save(render_sprite(rows), f"{name}.png")
    for name, rows in POINTERS.items():
        save(render_sprite(rows), f"{name}.png")

    # --- contact sheet, for reviewing the kit in one look ----------------
    sheet = Image.new("RGBA", (560, 300), DEEP)
    x, y = 8, 8
    for name in sorted(os.listdir(OUT)):
        if not name.endswith(".png") or name.startswith("_"):
            continue
        tile = Image.open(os.path.join(OUT, name)).convert("RGBA")
        tile = tile.resize((tile.width * 2, tile.height * 2), Image.NEAREST)
        if x + tile.width > 552:
            x = 8
            y += 72
        sheet.alpha_composite(tile, (x, y))
        x += tile.width + 10
    sheet.save(os.path.join(OUT, "_kit_preview.png"))

    print(f"wrote {len(written)} files to {OUT}")
    for line in written:
        print("  ", line)


if __name__ == "__main__":
    main()
