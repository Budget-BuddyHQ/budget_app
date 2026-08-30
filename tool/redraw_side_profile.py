# -*- coding: utf-8 -*-
"""Redraw the side-facing head on every villager sprite sheet.

**What was wrong with the art.** Read back at its true resolution, the
side-facing head is three mistakes stacked on each other:

1. *The crown is drawn flat.* From the front the head is six pixels wide at
   the crown; in profile it is **two**. A head seen from the side is at least
   as deep as it is wide, so reusing the front crown turns it into a spike.
2. *The face is a three-pixel notch, one row proud of the row above it.* That
   step, under the spike, is what reads as a beak.
3. *The head is redrawn differently in every frame.* Frame 0's crown spans
   four columns, frame 2's seven, frame 5's five. A walk cycle bobs a head; it
   does not reshape it. That is the "shifting pixels" in the animation.

**What was wrong with the previous attempts at fixing it**, which matters
more, because there were five of them. They all assumed the sheet was one
clean grid: 14x27 logical pixels at 5x, anchored at (6, 12) in every cell.
Measuring it says otherwise.

* Every frame has *its own* origin. Frames 0 and 4 start at y=12, frames 1, 3,
  5 and 7 at y=10, frames 2 and 6 at y=5 -- and horizontally at x=6, 12 and 2.
  Those are not multiples of the block size, so a fixed grid reads frames 1-7
  at the wrong phase. Coherent enough to *look* at; wrong to *write* to.
* Vertically the sheet is a clean 5px grid within each frame. **Horizontally
  it is not** -- no phase makes the 5px column groups uniform, so the sheet
  was scaled unevenly at some point in its history. Stamping fixed 5x5 blocks
  therefore lands half a block off, which is precisely the "pixels are
  shifted" complaint the redraws were meant to cure.

So this works from each frame's own measured geometry: the vertical grid it
actually has, the coat colour to find where its torso starts, and the raw
x-range of its own neck to centre the head on. The head is rendered at 1:1 and
scaled once, so its own blocks are exactly uniform whatever the sheet around
it does.

Only the head is touched. The neck row and everything under it is left alone,
which is what keeps the men's collars and the women's ponytails attached to
the bodies they were drawn for. The east row is then rebuilt as a per-frame
mirror of the west, which is what it already was in all 38 sheets.

**The guardrail.** Every earlier attempt was written first and looked at
afterwards. This one is dry by default: it writes a magnified before/after to
`build/sprite/` and touches nothing.

    python tool/redraw_side_profile.py             # contact sheet only
    python tool/redraw_side_profile.py --write     # apply
"""
from __future__ import annotations

import glob
import os
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit('pip install pillow')

SRC_DIR = os.path.join('assets', 'self_made_skins')
OUT_DIR = os.path.join('build', 'sprite')

CELL_W, CELL_H = 104, 162
COLS = 8
ROW_STEP = 5          # the vertical grid, which *is* clean within a frame
WEST_ROW, EAST_ROW = 2, 3
CLEAR = (0, 0, 0, 0)

# --------------------------------------------------------------------------
# The drawing
# --------------------------------------------------------------------------
# 'O' outline   'H' hair   'S' skin   'E' eye   '.' transparent
#
# facing west. twelve columns wide, and the SAME twelve columns in every
# frame - a head that changes shape between frames is the whole bug here
HEAD_TALL = [
    '...OOOOOOO..',   # crown: six deep, not two
    '..OHHHHHHHO.',
    '.OHHHHHHHHHO',
    '.OSSHHHHHHHO',   # hairline
    '.OSESHHHHHHO',   # eye
    'OSSSSHHHHHHO',   # nose, one pixel proud of the face
    '.OSSSHHHHHO.',
    '..OOOSSSOOO.',   # jaw, with the neck emerging under the middle
]

# bob frames get a row less because their shoulders sit a row higher. the
# row comes out of the crown and not the face - a row less hair reads
# as the head dipping, where moving the eye every fourth frame would be the
# same flicker this is here to remove.
HEAD_SHORT = [
    '..OOOOOOOOO.',
    '.OHHHHHHHHHO',
    '.OSSHHHHHHHO',
    '.OSESHHHHHHO',
    'OSSSSHHHHHHO',
    '.OSSSHHHHHO.',
    '..OOOSSSOOO.',
]

HEAD_W = 12
# The column of the head design that should sit over the middle of the neck.
NECK_COL = 6
# How wide one logical pixel of the head is drawn. Matches the vertical grid,
# which keeps the head square against the body it sits on.
PIXEL = 5


# --------------------------------------------------------------------------
# Measuring a frame
# --------------------------------------------------------------------------
def frame_box(im, col, row):
    return (col * CELL_W, row * CELL_H, (col + 1) * CELL_W, (row + 1) * CELL_H)


def frame_geometry(im, col, row):
    """This frame's own bounding box and vertical grid origin."""
    cell = im.crop(frame_box(im, col, row))
    bbox = cell.getbbox()
    if bbox is None:
        raise ValueError(f'frame {col} is empty')
    return cell, bbox


def raw_row(cell, bbox, index):
    """Every raw pixel of logical row `index`, left to right."""
    y = bbox[1] + index * ROW_STEP + ROW_STEP // 2
    if y >= bbox[3]:
        return []
    px = cell.load()
    return [px[x, y] for x in range(bbox[0], bbox[2])]


def band_colours(cell, bbox, index):
    """Logical row `index` sampled one pixel per column.

    The 5px step is right vertically and only approximate horizontally -- see
    the module docstring -- but sampling the middle of each band is accurate
    enough to *read* the drawing, which is all this is used for. Anything that
    writes uses raw pixel coordinates instead.
    """
    y = bbox[1] + index * ROW_STEP + ROW_STEP // 2
    if y >= bbox[3]:
        return []
    px = cell.load()
    width = (bbox[2] - bbox[0] + ROW_STEP - 1) // ROW_STEP
    return [
        px[min(bbox[0] + gx * ROW_STEP + ROW_STEP // 2, bbox[2] - 1), y]
        for gx in range(width)
    ]


def shoulder_index(cell, bbox, coat):
    """The logical row where the torso starts -- what the head sits above.

    By colour, not by width: the head is as wide as the shoulders, so a width
    threshold picks the brow instead. And by *one* coat colour, not two -- the
    first version of this read the body and its shadow, and broke on every
    female sheet, because her hair runs down her back and the shadow probe
    landed on hair.
    """
    for index in range(20):
        if coat in band_colours(cell, bbox, index):
            return index
    raise ValueError('no torso found')


def neck_span(cell, bbox, index, skin):
    """The raw x-range of skin in the neck row, which the head must sit on."""
    y = bbox[1] + index * ROW_STEP + ROW_STEP // 2
    px = cell.load()
    xs = [x for x in range(bbox[0], bbox[2]) if px[x, y] == skin]
    if not xs:
        raise ValueError('no neck found')
    return min(xs), max(xs) + 1


def palette_of(im):
    """Outline, hair, skin and coat, read out of this sheet's own art.

    There are only two alpha masks across all 38 sheets, one per gender, and
    both put these roles at the same place in west frame 0 -- so the probes
    are shared, and every sheet still keeps its own colours.
    """
    cell, bbox = frame_geometry(im, 0, WEST_ROW)
    row4 = band_colours(cell, bbox, 4)
    row6 = band_colours(cell, bbox, 6)
    row12 = band_colours(cell, bbox, 12)
    outline, hair, skin = row4[2], row4[6], row6[4]
    coat = row12[3]
    roles = {'O': outline, 'H': hair, 'S': skin, 'E': outline}
    if len({outline, hair, skin, coat}) != 4 or any(
        c[3] == 0 for c in (outline, hair, skin, coat)
    ):
        raise ValueError('palette probes did not land on four distinct colours')
    return roles, coat


# --------------------------------------------------------------------------
# The redraw
# --------------------------------------------------------------------------
def render_head(art, roles):
    """The head design as an image, one pixel per character, then scaled once.

    Scaled as a unit rather than stamped block by block, so the head's own
    columns are exactly even however uneven the sheet around it is.
    """
    small = Image.new('RGBA', (HEAD_W, len(art)), CLEAR)
    for y, line in enumerate(art):
        for x, ch in enumerate(line):
            if ch != '.':
                small.putpixel((x, y), roles[ch])
    return small.resize(
        (HEAD_W * PIXEL, len(art) * PIXEL), Image.NEAREST
    )


def extend_to_hair(head, roles, below, bbox_left, head_left):
    """Reach the head's hair back far enough to meet the body's.

    The women carry a ponytail that starts at the neck row and hangs past the
    shoulders. It is body, not head, so it is left alone -- but on the frames
    where the arm swings forward the new head is narrower than the old one and
    stops short of it, leaving the ponytail floating half a pixel behind the
    skull. So the hair at the back of the head is drawn out to wherever the
    body's hair actually starts. The men have none, and get no extension.
    """
    skip = (roles['O'], roles['S'], (0, 0, 0, 0))
    reach = [
        bbox_left + i
        for i, p in enumerate(below)
        if p[3] and p not in skip
    ]
    if not reach:
        return head
    needed = max(reach) + 1 - head_left
    if needed <= head.width:
        return head

    wider = Image.new('RGBA', (needed, head.height), CLEAR)
    wider.paste(head, (0, 0))
    px = head.load()
    for y in range(head.height):
        edge = px[head.width - 1, y]
        if edge != roles['H']:
            continue
        for x in range(head.width, needed):
            wider.putpixel((x, y), roles['H'])
    return wider


def redraw(im):
    roles, coat = palette_of(im)
    for col in range(COLS):
        cell, bbox = frame_geometry(im, col, WEST_ROW)
        neck = shoulder_index(cell, bbox, coat) - 1
        art = HEAD_TALL if neck >= len(HEAD_TALL) else HEAD_SHORT
        if neck != len(art):
            raise ValueError(f'frame {col}: {len(art)} head rows for {neck}')

        nx0, nx1 = neck_span(cell, bbox, neck, roles['S'])

        # Close the seam before rendering. The head's bottom row is outlined
        # along the back, which is right for the men and wrong for the women:
        # their hair carries on down past the shoulders, and an outline across
        # it reads as the ponytail being cut off.
        below = raw_row(cell, bbox, neck)
        head_left = (nx0 + nx1) // 2 - (NECK_COL * PIXEL + PIXEL // 2)
        art = list(art)
        bottom = list(art[-1])
        for i, ch in enumerate(bottom):
            if ch != 'O':
                continue
            x = head_left + i * PIXEL + PIXEL // 2 - bbox[0]
            if 0 <= x < len(below):
                under = below[x]
                if under[3] and under not in (roles['O'], roles['S']):
                    bottom[i] = 'H'
        art[-1] = ''.join(bottom)

        # Clear everything above the neck row, in raw pixels across the whole
        # cell. The old head is a different shape and reaches places the new
        # one does not, so stamping over the top would leave its outline
        # showing.
        top = bbox[1] + neck * ROW_STEP
        x0, y0, _, _ = frame_box(im, col, WEST_ROW)
        im.paste(Image.new('RGBA', (CELL_W, top), CLEAR), (x0, y0))

        # `top - bbox[1]` is exactly `neck * ROW_STEP`, which is the head's
        # rendered height, so the head lands with its jaw on the neck row.
        head = render_head(art, roles)
        head = extend_to_hair(head, roles, below, bbox[0], head_left)
        im.paste(head, (x0 + head_left, y0 + bbox[1]), head)

    # East is a per-frame mirror of west -- which is what it already was in
    # every sheet. Rebuilt rather than redrawn so the two cannot drift.
    for col in range(COLS):
        box = frame_box(im, col, WEST_ROW)
        frame = im.crop(box).transpose(Image.FLIP_LEFT_RIGHT)
        im.paste(frame, (col * CELL_W, EAST_ROW * CELL_H))
    return im


# --------------------------------------------------------------------------
# Review
# --------------------------------------------------------------------------
def contact_sheet(paths, scale=3):
    strips = []
    for path in paths:
        strips.append(Image.open(path).convert('RGBA'))
        strips.append(redraw(Image.open(path).convert('RGBA')))
    w = COLS * CELL_W
    sheet = Image.new('RGBA', (w * scale, CELL_H * len(strips) * scale),
                      (26, 30, 28, 255))
    for i, im in enumerate(strips):
        strip = im.crop((0, WEST_ROW * CELL_H, w, (WEST_ROW + 1) * CELL_H))
        sheet.alpha_composite(
            strip.resize((w * scale, CELL_H * scale), Image.NEAREST),
            (0, i * CELL_H * scale),
        )
    return sheet


def main() -> None:
    write = '--write' in sys.argv
    files = sorted(glob.glob(os.path.join(SRC_DIR, '*.png')))
    if not files:
        sys.exit(f'no sheets in {SRC_DIR}')
    os.makedirs(OUT_DIR, exist_ok=True)

    sample = [f for f in files if os.path.basename(f) in (
        'villager_male_classic.png', 'villager_female_classic.png')]
    out = os.path.join(OUT_DIR, 'side_profile_review.png')
    contact_sheet(sample).save(out)
    print(f'review: {out}  ({len(sample)} sheets, before over after)')

    if not write:
        print('dry run - look at that file, then re-run with --write')
        return

    for path in files:
        redraw(Image.open(path).convert('RGBA')).save(path)
    print(f'rewrote {len(files)} sheets')


if __name__ == '__main__':
    main()
