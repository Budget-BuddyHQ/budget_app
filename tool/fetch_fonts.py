# -*- coding: utf-8 -*-
"""Bundle the app's two typefaces instead of downloading them at runtime.

**Why this exists.** `google_fonts` fetches a face over HTTP the first time it
is used and caches it on the device. Until that finishes -- and forever, on a
device with no network -- every label in the app renders in the platform
fallback. That is not an edge case: it is the *first* launch, which is what a
store reviewer sees, and it is a child on school wifi with the font CDN
blocked.

The package prefers a bundled asset when it can find one, but only if the file
is named exactly `{Family}-{Variant}.ttf` and the asset manifest covers it.

**Why the files are generated rather than downloaded.** Neither face publishes
static per-weight TTFs any more. The three obvious sources each give something
Flutter cannot use:

* `fonts.googleapis.com/css2` with an old IE user agent returns **EOT** -- it
  has a `.ttf` name in the URL and is not a TrueType file. This was tried
  first, and the tell was that a hand-registered `FontLoader` still measured
  every glyph at exactly one em: the load had silently failed and the test
  font was still in place.
* The same endpoint with a modern user agent returns **WOFF/WOFF2**, which
  Flutter's font loader also does not read.
* `github.com/google/fonts` ships one **variable** TTF per family. Flutter can
  register it, but a variable face registered under a single family name
  renders at its default instance, so every weight in the app would come out
  Regular.

So this downloads the variable font once and cuts static instances out of it
with `fonttools`, which is exactly what the static files used to be.

Run:  python tool/fetch_fonts.py
"""
from __future__ import annotations

import io
import os
import sys
import urllib.request

try:
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer
except ImportError:  # pragma: no cover - a setup problem, not a code path
    sys.exit('pip install fonttools brotli')

OUT_DIR = os.path.join('assets', 'fonts')

# Only the weights google_fonts actually resolves to. Pixelify Sans publishes
# 400-700 upstream, so this app's `fontWeight: w800` and `w900` call sites
# already map onto Bold and need no file of their own -- adding one would ship
# a face nothing can ask for.
FAMILIES = {
    'PixelifySans': {
        'url': 'https://github.com/google/fonts/raw/main/ofl/pixelifysans/PixelifySans%5Bwght%5D.ttf',
        'licence': 'https://raw.githubusercontent.com/google/fonts/main/ofl/pixelifysans/OFL.txt',
        'weights': {'Regular': 400, 'Medium': 500, 'SemiBold': 600, 'Bold': 700},
    },
    'Quicksand': {
        'url': 'https://github.com/google/fonts/raw/main/ofl/quicksand/Quicksand%5Bwght%5D.ttf',
        'licence': 'https://raw.githubusercontent.com/google/fonts/main/ofl/quicksand/OFL.txt',
        'weights': {
            'Light': 300,
            'Regular': 400,
            'Medium': 500,
            'SemiBold': 600,
            'Bold': 700,
        },
    },
}


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={'User-Agent': 'budget-buddy-build'})
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()
    if data[:4] not in (b'\x00\x01\x00\x00', b'true', b'ttcf', b'OTTO'):
        raise SystemExit(
            f'{url} did not return a TrueType file (starts {data[:4]!r}). '
            'See the module docstring: the CSS endpoints hand back EOT and '
            'WOFF, both of which Flutter cannot load.'
        )
    return data


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    for family, spec in FAMILIES.items():
        print(f'{family}: downloading variable font')
        variable = fetch(spec['url'])
        for name, weight in spec['weights'].items():
            font = TTFont(io.BytesIO(variable))
            # overlap=False - the instancer's overlap flag rewrites glyph
            # headers and these faces already have clean outlines
            instancer.instantiateVariableFont(font, {'wght': weight}, inplace=True)
            path = os.path.join(OUT_DIR, f'{family}-{name}.ttf')
            font.save(path)
            print(f'  {path}  ({os.path.getsize(path) // 1024}KB, wght={weight})')
        # OFL says the licence has to travel with the font. shipping the
        # faces without it is the one bit of this thats not optional
        licence = os.path.join(OUT_DIR, f'OFL-{family}.txt')
        request = urllib.request.Request(
            spec['licence'], headers={'User-Agent': 'budget-buddy-build'}
        )
        with urllib.request.urlopen(request, timeout=60) as response:
            with open(licence, 'wb') as handle:
                handle.write(response.read())
        print(f'  {licence}')


if __name__ == '__main__':
    main()
