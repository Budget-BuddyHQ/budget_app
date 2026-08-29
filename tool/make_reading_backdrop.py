# -*- coding: utf-8 -*-
"""Build the soft backdrop the Academy's reading screens sit on.

**The problem.** The lesson, quiz and practice screens paint the village map
behind their text with a translucent scrim over it. Measured against the real
asset, that scrim was already doing its job on paper: white text over the
*brightest* pixel in the map came out at 4.53:1, which clears WCAG AA.

It still read badly, and the numbers say why. Under the 0.74 scrim the
backdrop ranges from 4.53:1 to 12.4:1 depending on which tile a given letter
happens to land on, and the map's detail sits at roughly the scale of a
letterform -- fence posts, tile seams, tree crowns. A contrast ratio describes
one pixel against one background. It cannot describe a background that changes
underneath a word.

**The fix.** Take the structure out rather than turning the lights down.
A Gaussian blur wide enough to erase tile detail leaves the colour and the
sense of place, and the scrim on top then has a nearly flat surface to work
against. Blurring at build time rather than with `ImageFiltered` keeps it free
at runtime -- this is a static image behind a scrolling list, and there is no
reason to re-filter it sixty times a second.

The desaturation is small and does the same job for hue: the map's greens and
water blues are what pull the eye to individual tiles.

Run:  python tool/make_reading_backdrop.py
"""
from __future__ import annotations

import os
import sys

try:
    from PIL import Image, ImageEnhance, ImageFilter
except ImportError:  # pragma: no cover
    sys.exit('pip install pillow')

SOURCE = os.path.join('assets', 'self_made_backgrounds', 'map.png')
TARGET = os.path.join('assets', 'self_made_backgrounds', 'map_soft.png')

# Wide enough to erase a tile seam (the source is 561x400 and its tiles are
# about 16px), narrow enough that the map still reads as a map.
BLUR_RADIUS = 9

# Just enough to stop the water and grass competing for attention.
SATURATION = 0.72


def main() -> None:
    if not os.path.exists(SOURCE):
        sys.exit(f'{SOURCE} is missing')
    image = Image.open(SOURCE).convert('RGB')
    image = image.filter(ImageFilter.GaussianBlur(BLUR_RADIUS))
    image = ImageEnhance.Color(image).enhance(SATURATION)
    image.save(TARGET)
    print(f'{TARGET}  {image.size[0]}x{image.size[1]}  '
          f'({os.path.getsize(TARGET) // 1024}KB)')


if __name__ == '__main__':
    main()
