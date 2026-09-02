# -*- coding: utf-8 -*-
"""Give the side-on walk cycle a second half.

**What is actually wrong with the sprites.** Not the drawing of any one frame.
Every villager sheet has eight columns per row, but the east/west rows contain
only *four distinct poses* — measured across all 38 sheets, column 0 is
pixel-identical to 4, 1 to 3, and 5 to 7. What is there is:

    0 / 4   front-facing contact  (front legs on a profile body)
    1 / 3   passing pose, slim    (~6,740 opaque px, 65px wide)
    2       up pose, slim
    5 / 7   passing pose, BULKY   (~7,820 opaque px, 79.5px wide)
    6       up pose, bulky

So the shipped cycle `[1, 2, 3, 5, 6, 7]` runs slim-pass, slim-up, slim-pass,
fat-pass, fat-up, fat-pass. **The same leg leads the whole way through** —
there is no alternation anywhere in the art — and the body swells 16% halfway
round and shrinks again. That is what "the character is clanking" is, and it
is why redrawing individual frames never fixed it: the frames were not the
problem, the missing half of the cycle was.

**The fix.** A walk's second half is the first half with the legs swapped, not
with a bigger body. So columns 5 and 6 are rebuilt as copies of 1 and 2 with
only the **leg band** mirrored horizontally about its own centre. The torso,
head and arms are untouched and therefore pixel-identical between the halves,
which removes the swell by construction; the legs alternate, which is the
thing that makes it read as walking.

The leg band is found by colour rather than by a hardcoded row: the boots and
trousers are the only saturated dark region below the shirt, and every sheet
is a recolour of the same geometry, so the band is the same everywhere.

Run:  python tool/fix_side_walk_cycle.py            (writes a preview only)
      python tool/fix_side_walk_cycle.py --write    (rewrites the sheets)
"""
from __future__ import annotations

import glob
import os
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    raise SystemExit('pip install pillow')

SHEETS = os.path.join('assets', 'self_made_skins', '*.png')
PREVIEW = os.path.join('build', 'walk_cycle_check.png')

CW, CH = 104, 162
SIDE_ROWS = (2, 3)          # west, east

# Source poses and where their leg-mirrored twins are written.
PAIRS = ((1, 5), (2, 6), (1, 7))

# Where the legs start. Found by colour census: the shirt runs to about y=110
# and the trousers/boots take over from there to the foot.
LEG_TOP = 112


def leg_bounds(cell):
    """Horizontal extent of the leg band, for mirroring about its own centre."""
    px = cell.load()
    left, right = None, None
    for y in range(LEG_TOP, CH):
        for x in range(CW):
            if px[x, y][3] > 10:
                left = x if left is None else min(left, x)
                right = x if right is None else max(right, x)
    return left, right


def mirrored_legs(cell):
    """`cell` with only its leg band flipped horizontally."""
    out = cell.copy()
    left, right = leg_bounds(cell)
    if left is None:
        return out
    band = cell.crop((left, LEG_TOP, right + 1, CH))
    flipped = band.transpose(Image.FLIP_LEFT_RIGHT)
    # Clear the old legs first, or a narrower mirrored band leaves the
    # original's outline standing behind it.
    clear = Image.new('RGBA', (CW, CH - LEG_TOP), (0, 0, 0, 0))
    out.paste(clear, (0, LEG_TOP))
    out.paste(flipped, (left, LEG_TOP), flipped)
    return out


def rebuild(sheet):
    """A copy of `sheet` with columns 5-7 rebuilt on both side rows."""
    out = sheet.copy()
    for row in SIDE_ROWS:
        for source, target in PAIRS:
            cell = sheet.crop(
                (source * CW, row * CH, (source + 1) * CW, (row + 1) * CH)
            )
            fixed = mirrored_legs(cell)
            box = (target * CW, row * CH)
            out.paste(
                Image.new('RGBA', (CW, CH), (0, 0, 0, 0)), box
            )
            out.paste(fixed, box, fixed)
    return out


def main() -> None:
    write = '--write' in sys.argv
    paths = sorted(glob.glob(SHEETS))
    if not paths:
        raise SystemExit(f'no sheets at {SHEETS}')

    # Preview from the first sheet: the old six frames over the new six, so
    # the swell and its absence are visible side by side. Every previous
    # attempt at these sprites failed in a way only looking could catch.
    sample = Image.open(paths[0]).convert('RGBA')
    fixed = rebuild(sample)
    cycle = (1, 2, 3, 5, 6, 7)
    strip = Image.new('RGBA', (CW * len(cycle), CH * 2), (28, 28, 28, 255))
    for i, c in enumerate(cycle):
        strip.paste(sample.crop((c * CW, 2 * CH, (c + 1) * CW, 3 * CH)),
                    (i * CW, 0))
        strip.paste(fixed.crop((c * CW, 2 * CH, (c + 1) * CW, 3 * CH)),
                    (i * CW, CH))
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    strip.convert('RGB').save(PREVIEW)
    print(f'preview -> {PREVIEW}  (old cycle on top, rebuilt underneath)')

    if not write:
        print('\n(dry run — pass --write to rewrite all sheets)')
        return

    for path in paths:
        sheet = Image.open(path).convert('RGBA')
        rebuild(sheet).save(path)
    print(f'\nrewrote {len(paths)} sheets')


if __name__ == '__main__':
    main()
