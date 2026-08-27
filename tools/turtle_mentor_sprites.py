"""Draws Buddy, the mentor turtle, in the four poses the tutorial uses.

WHY THIS WAS REDRAWN
--------------------
The previous sprites had the head **completely detached from the body** — a
band of empty pixels between the chin and the shell — with arms floating
beside the torso and a head roughly as wide as the whole shell. The result
read as a mask hovering over a table rather than as a character, which is why
the mentor kept being singled out as the art that did not look right.

Three rules fix it, and they are the reason this file draws from shapes
rather than from a sprite map:

1. **The head overlaps the shell.** Its lower arc is drawn *into* the shell's
   top, so there is no seam to fall apart. Detachment is not a spacing bug
   you can nudge away; the shapes have to intersect.
2. **The head is smaller than the shell.** A head as wide as the body is a
   bobblehead at any size.
3. **Limbs attach.** Arms and feet are drawn before the shell and overlap it,
   so the shell's outline reads as the thing they are attached to.

Curves also cannot be hand-placed reliably: a turtle is a dome, a circle and
four stubs, and counting the same arc across a 64-column grid gives a
different answer every time. Ellipses at 1:1, scaled up nearest-neighbour,
keep every pixel a clean block while getting the proportions right by
construction.

USAGE
-----
    python tools/turtle_mentor_sprites.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

OUT = os.path.join("assets", "own_skins", "turtle_mentor")

SRC = 64
SCALE = 10

INK = (24, 46, 32, 255)
SHELL = (86, 150, 74, 255)
SHELL_DARK = (58, 110, 52, 255)
SKIN = (140, 208, 106, 255)
SKIN_DARK = (104, 172, 80, 255)
PLASTRON = (232, 240, 206, 255)
PLASTRON_LINE = (186, 204, 156, 255)
BLUSH = (244, 158, 168, 255)
WHITE = (255, 255, 255, 255)
WATER = (140, 200, 240, 255)
NONE = (0, 0, 0, 0)

# Geometry, in source pixels. Named so a pose can move one part without
# guessing where the others are.
SHELL_BOX = (10, 30, 54, 56)
PLASTRON_BOX = (21, 37, 43, 52)
HEAD_C, HEAD_R = (32, 21), 15
FOOT_BOXES = ((14, 50, 26, 61), (38, 50, 50, 61))


def _ellipse(d, box, fill, outline_w=2):
    x0, y0, x1, y1 = box
    if outline_w:
        d.ellipse(
            (x0 - outline_w, y0 - outline_w, x1 + outline_w, y1 + outline_w),
            fill=INK,
        )
    d.ellipse(box, fill=fill)


def _rounded(d, box, fill, radius=4, outline_w=2):
    x0, y0, x1, y1 = box
    if outline_w:
        d.rounded_rectangle(
            (x0 - outline_w, y0 - outline_w, x1 + outline_w, y1 + outline_w),
            radius=radius + outline_w,
            fill=INK,
        )
    d.rounded_rectangle(box, radius=radius, fill=fill)


def _arm(d, cx, cy, pal, r=7):
    """One stubby arm, drawn as a ball. Overlaps the shell so it attaches."""
    _ellipse(d, (cx - r, cy - r, cx + r, cy + r), pal.skin)
    d.ellipse((cx - r, cy, cx + r, cy + r), fill=pal.skin_dark)


def _face(d, pose: str):
    hx, hy = HEAD_C

    # Eyes. Big and simple; a mentor reads as friendly mostly through these.
    for side in (-1, 1):
        ex = hx + side * 6
        if pose == "thinking":
            # Looking up and to one side, so the pose reads as thought rather
            # than as a blank stare with an arm raised.
            ey = hy - 2
        else:
            ey = hy
        if pose == "wave":
            # Happy closed eyes: an arc instead of a disc.
            d.arc((ex - 5, ey - 5, ex + 5, ey + 3), 200, 340, fill=INK, width=3)
            continue
        d.ellipse((ex - 5, ey - 6, ex + 5, ey + 5), fill=INK)
        d.ellipse((ex - 4, ey - 5, ex + 4, ey + 4), fill=WHITE)
        pupil_dx = 1 if pose == "thinking" else 0
        d.ellipse(
            (ex - 3 + pupil_dx, ey - 4, ex + 2 + pupil_dx, ey + 2), fill=INK
        )
        d.ellipse((ex - 2 + pupil_dx, ey - 3, ex, ey - 1), fill=WHITE)

    # Blush, always — it is most of what makes the character warm.
    for side in (-1, 1):
        bx = hx + side * 11
        d.ellipse((bx - 3, hy + 5, bx + 3, hy + 9), fill=BLUSH)

    # Mouth changes with the pose; everything else is shared.
    my = hy + 8
    if pose == "worried":
        d.line(
            [(hx - 4, my + 1), (hx - 1, my - 1), (hx + 2, my + 1),
             (hx + 5, my - 1)],
            fill=INK,
            width=2,
        )
    elif pose == "thinking":
        d.line([(hx - 2, my), (hx + 4, my)], fill=INK, width=2)
    else:
        d.arc((hx - 6, my - 5, hx + 6, my + 4), 20, 160, fill=INK, width=2)


class Palette:
    """One turtle's colours.

    Exists so the four *skins* can reuse this drawing rather than having their
    own. A separate side-view construction was tried for them and kept coming
    out as a bean with a head: the front-facing mentor build already reads as
    a turtle, so the skins are palette swaps of it plus an accessory. One
    drawing, one style, four characters.
    """

    def __init__(self, shell, shell_dark, skin, skin_dark, plastron=None):
        self.shell = shell
        self.shell_dark = shell_dark
        self.skin = skin
        self.skin_dark = skin_dark
        self.plastron = plastron or PLASTRON


DEFAULT = None  # filled in below, once Palette exists


def render(pose: str, pal=None, coin: bool = False) -> Image.Image:
    pal = pal or DEFAULT
    img = Image.new("RGBA", (SRC, SRC), NONE)
    d = ImageDraw.Draw(img)

    # Feet first: they are drawn before the shell so its outline sits over
    # the hip joint, but they extend *below* it so they are still visible.
    # An earlier version tucked them entirely inside the shell's footprint
    # and the turtle looked like it was resting on the floor.
    for box in FOOT_BOXES:
        _rounded(d, box, pal.skin, radius=4)

    # Shell, then the plastron plates on it.
    _ellipse(d, SHELL_BOX, pal.shell)
    sx0, sy0, sx1, sy1 = SHELL_BOX
    d.ellipse((sx0 + 2, sy0 + 2, sx1 - 2, sy0 + 12), fill=pal.shell_dark)

    _rounded(d, PLASTRON_BOX, pal.plastron, radius=5, outline_w=2)
    px0, py0, px1, py1 = PLASTRON_BOX
    for i in range(1, 3):
        y = py0 + (py1 - py0) * i / 3
        d.line([(px0 + 1, y), (px1 - 1, y)], fill=PLASTRON_LINE, width=1)
    d.line(
        [((px0 + px1) / 2, py0 + 1), ((px0 + px1) / 2, py1 - 1)],
        fill=PLASTRON_LINE,
        width=1,
    )

    # Arms *after* the shell, overlapping its edge.
    #
    # Drawing them first buried them: the shell is an opaque ellipse, so an
    # arm tucked behind it simply disappeared, and the wave pose showed a
    # floating ball with no limb. Overlapping the edge from in front reads as
    # attached and stays visible.
    if pose == "wave":
        d.line([(50, 44), (57, 25)], fill=INK, width=9)
        d.line([(50, 44), (57, 25)], fill=pal.skin, width=5)
        _arm(d, 58, 20, pal, r=7)
        _arm(d, 10, 44, pal)
    elif pose == "thinking":
        d.line([(48, 46), (41, 34)], fill=INK, width=9)
        d.line([(48, 46), (41, 34)], fill=pal.skin, width=5)
        _arm(d, 40, 32, pal, r=6)
        _arm(d, 10, 44, pal)
    else:
        _arm(d, 10, 44, pal)
        _arm(d, 54, 44, pal)

    # Head last and overlapping the shell — this is the fix for the detached
    # head. Its lower arc lands inside the shell's top edge, so there is no
    # gap for a seam to open in.
    hx, hy = HEAD_C
    _ellipse(d, (hx - HEAD_R, hy - HEAD_R, hx + HEAD_R, hy + HEAD_R), pal.skin)
    d.ellipse(
        (hx - HEAD_R, hy + 3, hx + HEAD_R, hy + HEAD_R), fill=pal.skin_dark
    )

    if coin:
        # The app's logo is a turtle carrying a coin, so the coin skins match
        # the brand mark rather than just tinting the shell yellow.
        d.ellipse((25, 33, 39, 47), fill=INK)
        d.ellipse((26, 34, 38, 46), fill=(196, 150, 52, 255))
        d.ellipse((27, 35, 37, 45), fill=(255, 212, 92, 255))
        d.rectangle((31, 36, 33, 44), fill=INK)

    _face(d, pose)

    if pose == "worried":
        # A sweat bead, which is the whole reason this pose exists.
        d.ellipse((49, 8, 55, 17), fill=INK)
        d.ellipse((50, 9, 54, 16), fill=WATER)
        d.ellipse((51, 11, 52, 13), fill=WHITE)

    return img.resize((SRC * SCALE, SRC * SCALE), Image.NEAREST)


DEFAULT = Palette(SHELL, SHELL_DARK, SKIN, SKIN_DARK)

POSES = ["idle", "wave", "thinking", "worried"]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    tiles = []
    for pose in POSES:
        img = render(pose)
        path = os.path.join(OUT, f"turtle_mentor_{pose}.png")
        img.save(path)
        tiles.append(img)
        print(f"wrote {path} ({img.size[0]}x{img.size[1]})")

    sheet = Image.new(
        "RGBA",
        (sum(t.width for t in tiles) + 50, tiles[0].height + 20),
        (36, 44, 40, 255),
    )
    x = 10
    for t in tiles:
        sheet.alpha_composite(t, (x, 10))
        x += t.width + 10
    sheet.save(os.path.join(OUT, "_mentor_preview.png"))
    print("preview -> _mentor_preview.png")


if __name__ == "__main__":
    main()
