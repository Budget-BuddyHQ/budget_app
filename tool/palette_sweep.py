"""Moves the app off its one-note dark-green palette.

Reported by testers as "the color scheme looks AI": green panels on green
backgrounds, mint and teal accents, every surface a slightly different shade
of the same hue. The reference the user gave was real game apps such as
Prodigy and Duolingo, which use neutral slate surfaces with a few bold,
purposeful colours on top.

This maps the hard-coded surface greens to slate equivalents of the same
lightness, and the mint/teal accents to a leaf green. It is a fixed table,
old hex -> new hex, so the diff is reviewable and the run is repeatable.

Deliberately NOT touched: the background art the user wants kept (the reef,
the village map and its dimming scrims, town and building drawings).

    python tool/palette_sweep.py          # dry run, prints counts
    python tool/palette_sweep.py --write  # applies it
"""

import pathlib
import re
import sys

# Surfaces, darkest to lightest. Slate keeps a hint of blue-green so it still
# sits well over the green backdrops.
MAPPING = {
    # page / deepest
    '0A1D17': '131F24', '071711': '111B20', '0B1410': '0F181C',
    '10241E': '151F25', '0F2A20': '18252B', '0F2A21': '18252B',
    '091914': '111B20', '0C2018': '141F24',
    # cards
    '103225': '1C2B32', '12352C': '202F36', '133026': '1E2C33',
    '133628': '202F36', '15302A': '1E2C33', '15372A': '202F36',
    '15382A': '1B2A31', '16362B': '1E2D34', '132A21': '1C2A31',
    '122F26': '1D2B32', '0F2B22': '1A272E', '122D24': '1C2A31',
    # raised cards
    '173B2E': '243440', '15392D': '233340', '163729': '22323B',
    '164A3B': '27394A', '173B2F': '243440', '1B4536': '2A3C45',
    '1E3320': '23342B', '21402C': '263A44', '10382D': '1F3140',
    '1C5C48': '2B4256', '1A4133': '263743',
    # second pass: one-off cards, borders and wells
    '0B2D1A': '172328', '0D2B20': '18252B', '0B2419': '152126',
    '1E4D3D': '2A3C45', '12251C': '17232A', '3C5147': '3A4A53',
    '0F2E1E': '131F24', '0E2A20': '18252B', '0E2A1F': '18252B',
    '103224': '1C2B32', '10291F': '18252B', '12321F': '1C2A31',
    '1E3E33': '263743', '303C38': '35424A', '1A4D3D': '2B4256',
    '173B2D': '243440', '14432B': '22383F', '16321F': '1E2C33',
    '13332A': '1E2C33', '133626': '202F36', '2A4A3D': '33444E',
    '143428': '1F2D34', '0C2A1A': '18252B', '2C5A4A': '37464F',
    # the primary button's ledge, re-cut from the new green
    '18493A': '2C5A17',
    # accents: mint/teal -> leaf green
    '4BD2A3': '6CD34A', '85EFAC': '9BE870', '9EF0D0': 'B8F28C',
    '7BE1BB': '8FDB6A', '2F9E68': '3F8F1F',
}

# The background art stays as it is.
SKIP = {
    'reef_scene.dart', 'map_backdrop.dart', 'vivid_backdrop.dart',
    'adventure_world_screen.dart', 'town_interior_screen.dart',
}

PATTERN = re.compile(r'0x[Ff][Ff](' + '|'.join(MAPPING) + r')\b', re.IGNORECASE)


def main() -> None:
    write = '--write' in sys.argv
    total = 0
    for path in sorted(pathlib.Path('lib').rglob('*.dart')):
        if path.name in SKIP:
            continue
        # Bytes, not read_text: read_text rewrites CRLF and would turn a
        # colour change into a whole-file diff.
        text = path.read_bytes().decode('utf-8')
        new, n = PATTERN.subn(
            lambda m: '0xFF' + MAPPING[m.group(1).upper()], text)
        if n:
            total += n
            print(f'{n:4} {path}')
            if write:
                path.write_bytes(new.encode('utf-8'))
    print(f'{total} replacements{"" if write else " (dry run)"}')


if __name__ == '__main__':
    main()
