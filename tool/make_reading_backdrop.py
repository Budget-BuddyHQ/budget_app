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

# Both town maps get the same treatment. The second one is the 800x800 export
# that could not be made *playable* -- its collision data was never in the PNG
# and three separate heuristics all read the main road as solid -- but there
# was never anything wrong with the art, and a backdrop needs no colliders.
# So it earns its place here instead: see `MapBackdrop.variant`.
PAIRS = (
    (
        os.path.join('assets', 'self_made_backgrounds', 'map.png'),
        os.path.join('assets', 'self_made_backgrounds', 'map_soft.png'),
    ),
    (
        os.path.join('assets', 'images', 'maps', 'map (1).png'),
        os.path.join('assets', 'self_made_backgrounds', 'map_two_soft.png'),
    ),
)

# The second map ships inside a decorative stone frame. Fine in an editor
# preview, wrong as a full-bleed backdrop: `BoxFit.cover` on a portrait phone
# scales an 800x800 square to the screen width, so the left and right runs of
# that frame land right down the edges of the screen and read as a border
# somebody forgot to remove. 16px is past it on every side.
FRAME_INSET = {os.path.join('assets', 'images', 'maps', 'map (1).png'): 16}

# Where the cropped-but-unblurred copy goes for each framed source.
SHARP_OUT = {
    os.path.join('assets', 'images', 'maps', 'map (1).png'): os.path.join(
        'assets', 'self_made_backgrounds', 'map_two.png'
    ),
}

# Wide enough to erase a tile seam (the source is 561x400 and its tiles are
# about 16px), narrow enough that the map still reads as a map.
BLUR_RADIUS = 9

# Just enough to stop the water and grass competing for attention.
SATURATION = 0.72


def main() -> None:
    for source, target in PAIRS:
        if not os.path.exists(source):
            sys.exit(f'{source} is missing')
        image = Image.open(source).convert('RGB')
        inset = FRAME_INSET.get(source, 0)
        if inset:
            w, h = image.size
            image = image.crop((inset, inset, w - inset, h - inset))
            # The cropped-but-sharp copy is an output too, not a by-product:
            # the decorative and hero backdrop styles both want the art
            # unblurred, and they want it without the frame just as much.
            sharp = SHARP_OUT[source]
            image.save(sharp)
            print(f'{sharp}  {image.size[0]}x{image.size[1]}  sharp')
        # The blur is specified against the 561px source, so scale it with the
        # image -- a fixed 9px radius on the 800px export would leave tile
        # seams standing, which is the one thing this is for.
        radius = BLUR_RADIUS * (image.size[0] / 561.0)
        image = image.filter(ImageFilter.GaussianBlur(radius))
        image = ImageEnhance.Color(image).enhance(SATURATION)
        image.save(target)
        print(f'{target}  {image.size[0]}x{image.size[1]}  '
              f'blur {radius:.1f}px  ({os.path.getsize(target) // 1024}KB)')


if __name__ == '__main__':
    main()
