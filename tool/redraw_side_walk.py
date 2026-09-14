# -*- coding: utf-8 -*-
"""Draws the left/right walk cycle from scratch, on every villager sheet.

# Why the earlier fixes did not work

Five scripts edited the side rows in place: narrowing the silhouette,
redrawing the head, clamping the foot dip, mirroring the leg band. Every one
of them patched frames that were never a walk cycle to begin with. Rendered
large, the west row holds three leg poses at most:

  * columns 0 and 4 have *face-on* legs on a profile body (plus a stray hip
    line left by an earlier edit),
  * 1 and 3 are the same pose, 2 has the back foot kicked up,
  * 5-7 are 1-3 with the leg band flipped — which turns the **shoes
    backwards**, so for half the cycle the character walks heel-first.

No frame has the legs apart in a stride. The shipped cycle `[1,2,3,5,6,7]`
therefore shuffled on the spot with the feet flipping direction, which on
screen reads as "the walk animation is not working".

# What this does instead

Keeps the one thing that was fine — the body, head and arm from column 1 —
and draws the legs procedurally for a real eight-frame cycle: heel strike,
weight, passing, push-off, toe-off, lift, swing, reach, with the second leg
half a cycle behind the first. Rules that the old frames broke:

  * **Toes always point the way the character faces.**
  * **The far leg is a darker shade**, so the two legs read as two legs when
    they cross instead of one blob.
  * **The body is identical in every frame** except a one-block dip when both
    feet are planted — the bob that makes a walk look weighted. The head no
    longer changes shape frame to frame.
  * **Feet land on one fixed ground line**, so nothing slides or sinks.

Everything is drawn on the sheet's own 5px block grid, in each sheet's own
trouser colour, and the east row is the west row mirrored — which is what it
already was.

# The guardrail

Every earlier attempt was written first and looked at second. This is dry by
default: it writes a magnified before/after to `build/sprite/` and touches no
asset.

    python tool/redraw_side_walk.py            # preview only
    python tool/redraw_side_walk.py --write    # rewrite rows 2 and 3

Idempotent: the body is read from column 1, which this script writes with no
dip, and everything from the hip down is erased before the legs are drawn.
"""
from __future__ import annotations

import glob
import os
import sys

from PIL import Image, ImageOps

SHEETS = os.path.join('assets', 'self_made_skins', 'villager_*.png')
PREVIEW_DIR = os.path.join('build', 'sprite')

CW, CH = 104, 162
WEST, EAST = 2, 3
BODY_COL = 1

BLOCK = 5
GRID_X, GRID_Y = 12, 10      # where the 5px grid starts inside a cell
HIP_ROW = 21                 # first block row of the legs (y = 115)
GROUND_ROW = 27              # block row a planted shoe sits on (y = 145)
HIP_COL = 5                  # block column of the hip, facing west

OUTLINE = (0x21, 0x28, 0x23, 255)
SHOE_FALLBACK = (0x17, 0x14, 0x0F, 255)

# Where each point of the cycle puts one foot, facing west (forward is -x):
# (foot column offset from the hip, how many blocks the foot is lifted,
#  knee column offset). The second leg runs the same table 4 frames later.
PHASES = (
    (-3, 0, -2),   # 0 heel strike: leg reaching forward, foot planted
    (-2, 0, -1),   # 1 weight onto it
    (0, 0, 0),     # 2 passing: straight under the body
    (2, 0, 1),     # 3 push-off
    (3, 0, 2),     # 4 toe-off: trailing leg
    (3, 2, 1),     # 5 lift: foot comes up behind, knee bends
    # 6 swing: knee leads, foot still *behind* the hip. Straight under it,
    # the lifted shoe sat on top of the planted one and the pair read as a
    # ladder rather than a foot passing a foot.
    (1, 2, -1),
    (-2, 1, -2),   # 7 reach: foot comes down in front
)

# Body dips one block on the frames where both feet are planted far apart.
DIP = (1, 0, 0, 0, 1, 0, 0, 0)


def darker(colour, factor=0.7):
    r, g, b, a = colour
    return (int(r * factor), int(g * factor), int(b * factor), a)


def leg_blocks(phase, dip):
    """Trouser blocks and shoe blocks for one leg, in block coordinates."""
    foot_dx, lift, knee_dx = PHASES[phase % len(PHASES)]
    hip_row = HIP_ROW + dip
    ankle_row = GROUND_ROW - 1 - lift
    knee_row = (hip_row + ankle_row) // 2
    hip = (HIP_COL, hip_row)
    knee = (HIP_COL + knee_dx, knee_row)
    ankle = (HIP_COL + foot_dx, ankle_row)

    trousers = set()

    def segment(a, b):
        (x0, y0), (x1, y1) = a, b
        rows = max(1, y1 - y0)
        for step in range(y1 - y0 + 1):
            x = round(x0 + (x1 - x0) * step / rows)
            y = y0 + step
            trousers.add((x, y))
            trousers.add((x + 1, y))      # two blocks wide

    segment(hip, knee)
    segment(knee, ankle)

    shoe_row = ankle_row + 1
    ax = ankle[0]
    # Toe forward (toward -x), heel under the leg.
    shoe = {(ax - 1, shoe_row), (ax, shoe_row), (ax + 1, shoe_row)}
    return trousers, shoe, hip_row


def paint_block(img, bx, by, colour):
    x, y = GRID_X + bx * BLOCK, GRID_Y + by * BLOCK
    if x < 0 or y < 0 or x + BLOCK > CW or y + BLOCK > CH:
        raise ValueError('block (%d,%d) falls outside the cell' % (bx, by))
    img.paste(colour, (x, y, x + BLOCK, y + BLOCK))


def draw_leg(img, phase, dip, trouser, shoe_colour):
    trousers, shoe, hip_row = leg_blocks(phase, dip)
    filled = trousers | shoe
    outline = set()
    for (x, y) in filled:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in filled and n[1] >= hip_row:
                outline.add(n)
    for bx, by in outline:
        paint_block(img, bx, by, OUTLINE)
    for bx, by in trousers - shoe:
        paint_block(img, bx, by, trouser)
    for bx, by in shoe:
        paint_block(img, bx, by, shoe_colour)


def sample(cell, xy, fallback):
    p = cell.getpixel(xy)
    return p if p[3] == 255 else fallback


def build_west_row(sheet):
    body_cell = sheet.crop(
        (BODY_COL * CW, WEST * CH, (BODY_COL + 1) * CW, (WEST + 1) * CH)
    )
    # The sheet's own colours, read from the source frame's leg and shoe.
    trouser = sample(body_cell, (35, 125), (0x3A, 0x3A, 0x3A, 255))
    shoe = sample(body_cell, (30, 147), SHOE_FALLBACK)

    leg_top_y = GRID_Y + HIP_ROW * BLOCK
    body = body_cell.copy()
    body.paste((0, 0, 0, 0), (0, leg_top_y, CW, CH))

    frames = []
    for t in range(8):
        dip = DIP[t]
        cell = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
        cell.alpha_composite(body, (0, dip * BLOCK))
        near, far = t, t + 4
        draw_leg(cell, far, dip, darker(trouser), darker(shoe, 0.85))
        draw_leg(cell, near, dip, trouser, shoe)
        frames.append(cell)
    return frames


def rewrite(sheet):
    out = sheet.copy()
    west = build_west_row(sheet)
    for col, cell in enumerate(west):
        for row in (WEST, EAST):
            box = (col * CW, row * CH, (col + 1) * CW, (row + 1) * CH)
            out.paste((0, 0, 0, 0), box)
        out.alpha_composite(cell, (col * CW, WEST * CH))
        out.alpha_composite(ImageOps.mirror(cell), (col * CW, EAST * CH))
    return out


def preview(paths):
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    scale = 2
    picks = [p for p in paths if any(
        k in p for k in ('male_classic', 'female_classic', 'aurora_prime'))]
    picks = [p for p in picks if 'female_aurora' not in p]
    rows = []
    for path in picks:
        sheet = Image.open(path).convert('RGBA')
        new = rewrite(sheet)
        for label, src, row, cols in (
            ('before west', sheet, WEST, [1, 2, 3, 5, 6, 7]),
            ('after west', new, WEST, list(range(8))),
            ('after east', new, EAST, list(range(8))),
        ):
            strip = Image.new('RGBA', (CW * 8 * scale, CH * scale), (118, 168, 108, 255))
            for i, col in enumerate(cols):
                cell = src.crop((col * CW, row * CH, (col + 1) * CW, (row + 1) * CH))
                cell = cell.resize((CW * scale, CH * scale), Image.NEAREST)
                strip.alpha_composite(cell, (i * CW * scale, 0))
            # The ground line, so a foot that sinks or floats is obvious.
            ground = (GRID_Y + (GROUND_ROW + 1) * BLOCK) * scale
            strip.paste((200, 60, 60, 255), (0, ground, strip.width, ground + 1))
            rows.append(strip)
    board = Image.new('RGBA', (rows[0].width, sum(r.height + 6 for r in rows)), (30, 60, 40, 255))
    y = 0
    for r in rows:
        board.alpha_composite(r, (0, y))
        y += r.height + 6
    out = os.path.join(PREVIEW_DIR, 'side_walk_preview.png')
    board.save(out)
    print('preview ->', out)

    # Close-up of one sheet, and the same frames at the size the town draws
    # them (34px tall), which is the size that actually has to read as walking.
    sheet = Image.open([p for p in paths if 'male_classic' in p and 'female' not in p][0]).convert('RGBA')
    west = build_west_row(sheet)
    zoom = Image.new('RGBA', (CW * 8 * 4, CH * 4), (118, 168, 108, 255))
    small_h = 34
    small_w = round(CW * small_h / CH)
    tiny = Image.new('RGBA', (small_w * 8 * 3 + 16, small_h * 3), (118, 168, 108, 255))
    for i, cell in enumerate(west):
        zoom.alpha_composite(cell.resize((CW * 4, CH * 4), Image.NEAREST), (i * CW * 4, 0))
        little = cell.resize((small_w, small_h), Image.BILINEAR)
        tiny.alpha_composite(little.resize((small_w * 3, small_h * 3), Image.NEAREST), (i * (small_w * 3 + 2), 0))
    zoom.save(os.path.join(PREVIEW_DIR, 'side_walk_zoom.png'))
    tiny.save(os.path.join(PREVIEW_DIR, 'side_walk_ingame.png'))
    print('zoom and in-game strips written')


def main():
    paths = sorted(glob.glob(SHEETS))
    if not paths:
        sys.exit('no villager sheets found; run from the project root')
    preview(paths)
    if '--write' not in sys.argv:
        print('dry run: no sheet was changed (pass --write to apply)')
        return
    for path in paths:
        sheet = Image.open(path).convert('RGBA')
        if sheet.size != (CW * 8, CH * 4):
            sys.exit('%s is %r, expected %r' % (path, sheet.size, (CW * 8, CH * 4)))
        rewrite(sheet).save(path)
    print('rewrote rows %d and %d of %d sheets' % (WEST, EAST, len(paths)))


if __name__ == '__main__':
    main()
