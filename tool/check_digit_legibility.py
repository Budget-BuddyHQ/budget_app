# -*- coding: utf-8 -*-
"""Measure how confusable a font's digits are.

WHY THIS EXISTS
---------------
A tester reported that "5 looks like an 8". It was not a matter of taste: a
quiz question reading *"you get $1 each time, after 5 days, how much have you
earned?"* was read as **8** days, so the tester looked for $8, and the four
options were $1 / $3 / $5 / $10. There was no answer to the question they had
been shown. In a financial literacy app, the font had corrupted the one digit
the question was about.

Rendered and inspected, Pixelify Sans's 5 has a **closed top counter** -- rows
3 to 9 of the glyph are pixel-identical to the 8's. So is the 6's. The digits
share one skeleton and differ by a couple of pixel columns, which survive at
poster size and close up at reading size.

WHAT THIS MEASURES
------------------
For every pair of digits: rasterise both at a realistic reading size, align
them on their bounding boxes, and compute the fraction of pixels that differ.
Two glyphs that differ in under ~18% of their inked area are, in practice, the
same shape wearing a different label.

This is deliberately a measurement rather than an opinion. "Looks a bit
similar" cannot be reviewed, cannot be regression-tested, and cannot settle an
argument about whether a font is good enough for numbers a child is being
asked to do arithmetic on.

USAGE
-----
    python tool/check_digit_legibility.py
    python tool/check_digit_legibility.py --font assets/fonts/Quicksand-Bold.ttf
"""
import argparse
import itertools
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Below this, two digits are treated as confusable.
#
# Calibrated against the fonts actually in this repo rather than picked from
# the air: every Quicksand pair scores well above it, and the Pixelify pairs
# a human reported as unreadable score below it.
THRESHOLD = 0.18

# The size real body text renders at. Measuring at 96px would flatter every
# font -- the complaint is about reading, not about posters.
SIZE = 22


def bitmap(font, ch, box=(64, 64)):
    """One digit, cropped to its ink and normalised to a common box."""
    im = Image.new('L', box, 0)
    ImageDraw.Draw(im).text((8, 4), ch, font=font, fill=255)
    bounds = im.getbbox()
    if bounds is None:
        return None
    im = im.crop(bounds).resize((32, 48), Image.NEAREST)
    return im.point(lambda v: 255 if v > 110 else 0)


def difference(a, b):
    """Fraction of inked pixels that disagree.

    Normalised by the union rather than by the whole box, so a pair of thin
    glyphs is not flattered by the empty space around them.
    """
    pa, pb = a.load(), b.load()
    differ = union = 0
    for y in range(48):
        for x in range(32):
            on_a, on_b = pa[x, y] > 0, pb[x, y] > 0
            if on_a or on_b:
                union += 1
                if on_a != on_b:
                    differ += 1
    return differ / union if union else 0.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--font', default='assets/fonts/PixelifySans-Bold.ttf')
    ap.add_argument('--size', type=int, default=SIZE)
    args = ap.parse_args()

    path = os.path.join(ROOT, args.font)
    font = ImageFont.truetype(path, args.size)
    glyphs = {c: bitmap(font, c) for c in '0123456789'}

    print('%s  at %dpx\n' % (os.path.basename(path), args.size))

    scored = []
    for a, b in itertools.combinations('0123456789', 2):
        scored.append((difference(glyphs[a], glyphs[b]), a, b))
    scored.sort()

    bad = [s for s in scored if s[0] < THRESHOLD]

    print('closest pairs:')
    for score, a, b in scored[:8]:
        flag = '  <-- CONFUSABLE' if score < THRESHOLD else ''
        print('  %s / %s   %.3f%s' % (a, b, score, flag))

    print('\n%d of %d pairs below %.2f' % (len(bad), len(scored), THRESHOLD))
    if bad:
        print('confusable: ' + ', '.join('%s/%s' % (a, b) for _, a, b in bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
