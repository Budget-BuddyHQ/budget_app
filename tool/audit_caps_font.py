# -*- coding: utf-8 -*-
"""Find text set in ALL CAPS in Pixelify Sans.

WHY
---
Reported as *"that E is pretty hard to read"*.

The obvious guess was that Pixelify's lowercase was the problem -- it is a
pixel face with a small x-height, and 'e' looks like a blob next to a capital
L. `tool/check_digit_legibility.py --chars ...` says otherwise, and the guess
was wrong in the useful direction:

    Pixelify lowercase    3 of 325 pairs confusable
    Pixelify CAPITALS    10-23 of 325, at every size tried
    Quicksand lowercase   2 of 325
    Quicksand CAPITALS    0-1 of 325

Three of Pixelify's confusable capital pairs contain an E: **E/S, B/E, E/G**.
So the reader was right about the letter and the fix is not the one that
looked obvious. Setting headings in caps -- which was the first idea -- would
have made it measurably worse.

The rule that falls out: **Pixelify Sans is fine in mixed case and should not
be used for all-caps text.** That keeps the pixel look on every title the app
is recognised by and takes it off the small shouty labels, which is where it
was doing damage and adding nothing.

This script finds the second kind so the sweep can be complete rather than
"the ones I happened to notice" -- the same mistake `tool/audit_number_fonts.py`
records making with quoted-only matching.

USAGE
-----
    python tool/audit_caps_font.py
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')

# A string literal, single or double quoted, optionally raw.
LITERAL = re.compile(r"""r?(['"])((?:\\.|(?!\1).)*)\1""")

# How far above a literal to look for the font call. A `Text(...)` and its
# `style:` are usually within a few lines; anything further apart is a
# different widget and a false positive.
WINDOW = 6


def is_shouting(text):
    """All-caps, and long enough for that to be a decision rather than an 'I'.

    Two letters minimum so `$`, `OK` and single initials do not flood the
    report. A string with no lowercase but at least three cased characters is
    somebody choosing to shout.
    """
    letters = [c for c in text if c.isalpha()]
    if len(letters) < 3:
        return False
    return all(c.isupper() for c in letters)


def scan(path):
    src = io.open(path, encoding='utf8', errors='replace').read()
    lines = src.replace('\r\n', '\n').split('\n')
    hits = []

    for i, line in enumerate(lines):
        if 'pixelifySans' not in line:
            continue
        # Look backwards: the literal is the widget's text, the style comes
        # after it. Also look forward a little for `style:` before `child:`.
        for j in range(max(0, i - WINDOW), min(len(lines), i + 2)):
            if j == i:
                continue
            for match in LITERAL.finditer(lines[j]):
                text = match.group(2)
                if is_shouting(text):
                    hits.append((j + 1, text.strip()))

        # `.toUpperCase()` is the other way to shout, and it hides the string
        # from the literal scan entirely.
        for j in range(max(0, i - WINDOW), min(len(lines), i + 2)):
            if 'toUpperCase()' in lines[j]:
                hits.append((j + 1, lines[j].strip()))

    return hits


def main():
    total = 0
    for base, _, files in os.walk(LIB):
        for name in sorted(files):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(base, name)
            hits = scan(path)
            if not hits:
                continue
            rel = os.path.relpath(path, ROOT).replace('\\', '/')
            print(rel)
            seen = set()
            for line, text in hits:
                key = (line, text)
                if key in seen:
                    continue
                seen.add(key)
                print('  %4d  %s' % (line, text[:88]))
                total += 1
            print('')

    print('%d all-caps site(s) in Pixelify Sans' % total)
    return 0


if __name__ == '__main__':
    sys.exit(main())
