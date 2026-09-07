# -*- coding: utf-8 -*-
"""Find text that renders digits in the pixel font.

`tool/check_digit_legibility.py` shows Pixelify Sans has 18 of 45 digit pairs
confusable at reading size -- 8/9 differ by under 4% of their inked pixels.
That is fine for a wordmark and unusable for a number somebody is being asked
to do arithmetic on.

This locates the call sites that matter. A `Text` styled with
`GoogleFonts.pixelifySans` is only a problem if what it renders can contain a
digit, so this looks at the string literal or interpolation attached to each
styled widget and reports the ones that can.

It is a heuristic and says so. Interpolated values (`'$count left'`) are
flagged because they *might* be numeric; a human decides. The alternative --
reading 365 call sites by hand -- is how the ambiguous ones get missed.

USAGE
-----
    python tool/audit_number_fonts.py
    python tool/audit_number_fonts.py --strict   # literals with digits only
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')

# A Text/FittedLabel whose content we can see, followed within a few lines by
# a pixelifySans style. Deliberately loose: this is a net, not a parser.
CONTENT = re.compile(
    r"""(?:Text|FittedLabel)\s*\(\s*(?P<q>['"])(?P<body>(?:\\.|(?!\1).)*)\1""",
    re.S,
)

# The gap that let the worst instances through.
#
# The first version of this audit matched only quoted content, so
# `Text(question.prompt, style: pixelifySans(...))` did not register -- and
# that was the exact widget a tester misread a 5 in, twice over (the Academy
# quiz prompt and the Finance Brawl question). Any Text whose content is a
# bare expression can carry digits at runtime, so a human has to look at it.
VARIABLE = re.compile(
    r"(?:Text|FittedLabel)\s*\(\s*(?P<expr>[A-Za-z_][\w.!\[\]()]*)\s*,"
)

DIGIT = re.compile(r'\d')
INTERP = re.compile(r'\$\{?\w')


def scan(path, strict):
    src = open(path, encoding='utf8').read()
    lines = src.split('\n')
    hits = []

    for m in CONTENT.finditer(src):
        body = m.group('body')
        start = src.count('\n', 0, m.start())

        # Does a pixelifySans style attach to this widget? Look ahead a few
        # lines -- the style argument follows the content in every call in
        # this codebase.
        window = '\n'.join(lines[start:start + 12])
        if 'pixelifySans' not in window:
            continue

        has_digit = bool(DIGIT.search(body))
        has_interp = bool(INTERP.search(body))
        if strict and not has_digit:
            continue
        if not (has_digit or has_interp):
            continue

        hits.append((
            start + 1,
            'LITERAL DIGIT' if has_digit else 'interpolated',
            body.strip()[:64].replace('\n', ' '),
        ))

    for m in VARIABLE.finditer(src):
        start = src.count('\n', 0, m.start())
        window = '\n'.join(lines[start:start + 8])
        if 'pixelifySans' not in window:
            continue
        if strict:
            continue
        hits.append((start + 1, 'variable', m.group('expr')))

    hits.sort()
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--strict', action='store_true')
    args = ap.parse_args()

    total = 0
    literal = 0
    for base, _, files in os.walk(LIB):
        for name in sorted(files):
            if not name.endswith('.dart'):
                continue
            path = os.path.join(base, name)
            hits = scan(path, args.strict)
            if not hits:
                continue
            rel = os.path.relpath(path, ROOT).replace('\\', '/')
            print('\n%s' % rel)
            for line, kind, body in hits:
                mark = '!!' if kind == 'LITERAL DIGIT' else '  '
                print('  %s :%-5d %-14s %s' % (mark, line, kind, body))
                total += 1
                if kind == 'LITERAL DIGIT':
                    literal += 1

    print('\n%d sites render possible digits in the pixel font '
          '(%d with a literal digit)' % (total, literal))
    return 0


if __name__ == '__main__':
    sys.exit(main())
