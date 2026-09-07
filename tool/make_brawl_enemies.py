# -*- coding: utf-8 -*-
"""Draws one sprite per Finance Brawl archetype.

# Why this exists

The Brawl roster grew to ten archetypes -- credit card, payday loan, student
loan, inflation, and the rest -- each with its own health, speed, drain and
lesson. They rendered from **three images**: `brawl_enemy_one`,
`brawl_enemy_two` and `brawl_boss`, picked by a two-branch `isBoss` /
`isEnemyTwo` test.

So the design rule the roster is built on -- *the behaviour is the lesson* --
was working, and the art was quietly undoing it. A payday loan that drains you
four times faster than anything else looked exactly like the credit card next
to it, and a player cannot learn "that one is dangerous" from a thing they
cannot tell apart.

# Why generated rather than hand-drawn

Ten sprites drawn by hand drift: different outline weights, different palettes,
ten separate chances to pick a colour that does not match the health bar. The
colours here are **parsed out of `brawl_enemies.dart`**, so a sprite cannot
disagree with the enemy it belongs to -- change the archetype's colour and
re-run, and the art follows.

The style is copied from the existing sprites rather than invented: a 32x32
logical grid, a two-tone body, a near-black outline and one bright glyph, which
is what `brawl_enemy_one.png` already is (128x128 holding 4px blocks, five
colours).

# Why shapes rather than pixel maps

Every sprite is built from the same handful of primitives and then outlined by
one dilation pass, so the family reads as a family. Hand-mapping 320 rows of
characters would give ten sprites with ten different outline weights, which is
the drift this file exists to avoid.

Run:  python tool/make_brawl_enemies.py
"""

import io
import os
import re

from PIL import Image, ImageDraw

GRID = 32          # logical pixels
SCALE = 8          # exported at 256x256
ROSTER = 'lib/models_Like_Skins_and_lessons_templates/brawl_enemies.dart'
OUT = 'assets/images/finance_brawl_ui/enemies'

OUTLINE = (16, 12, 24, 255)
CLEAR = (0, 0, 0, 0)


# --------------------------------------------------------------------------
# The roster, read from Dart so the art cannot disagree with the game.
# --------------------------------------------------------------------------
def read_roster():
    src = io.open(ROSTER, encoding='utf8').read()
    body = src[src.index('kBrawlEnemies'):]
    out = []
    for chunk in body.split('BrawlEnemy(')[1:]:
        eid = re.search(r"id:\s*'([^']+)'", chunk)
        color = re.search(r'color:\s*Color\(0x([0-9A-Fa-f]{8})\)', chunk)
        if not eid or not color:
            continue
        v = int(color.group(1), 16)
        out.append({
            'id': eid.group(1),
            'rgb': ((v >> 16) & 255, (v >> 8) & 255, v & 255),
            'elite': 'isElite: true' in chunk,
        })
    return out


def shade(rgb, factor):
    return tuple(max(0, min(255, int(c * factor))) for c in rgb)


# --------------------------------------------------------------------------
# Primitives. Every one draws into the same 32x32 image with no outline --
# the outline is a single pass at the end, so it is the same weight everywhere.
# --------------------------------------------------------------------------
def new_layer():
    return Image.new('RGBA', (GRID, GRID), CLEAR)


def rrect(d, box, fill, radius=3):
    d.rounded_rectangle(box, radius=radius, fill=fill)


def glyph(d, art, ox, oy, fill):
    """Stamps a tiny character map. '#' is ink, anything else is skipped."""
    for y, row in enumerate(art):
        for x, ch in enumerate(row):
            if ch == '#':
                d.point((ox + x, oy + y), fill=fill)


DOLLAR = [
    '..#..',
    '.###.',
    '##...',
    '.###.',
    '...##',
    '.###.',
    '..#..',
]
PERCENT = [
    '##..#',
    '##.#.',
    '..#..',
    '.#.##',
    '#..##',
]
PLUS = [
    '..#..',
    '..#..',
    '#####',
    '..#..',
    '..#..',
]
MINUS = ['#####']
ARROW_UP = [
    '..#..',
    '.###.',
    '#####',
    '..#..',
    '..#..',
]
ARROW_DOWN = [
    '..#..',
    '..#..',
    '#####',
    '.###.',
    '..#..',
]
LOOP = [
    '.###.',
    '#...#',
    '#....',
    '#...#',
    '.###.',
]
CRACK = [
    '..#',
    '.#.',
    '#..',
    '.#.',
    '..#',
]


def eyes(d, y, x1, x2, fill=OUTLINE):
    d.rectangle([x1, y, x1 + 1, y + 1], fill=fill)
    d.rectangle([x2, y, x2 + 1, y + 1], fill=fill)


# --------------------------------------------------------------------------
# One builder per archetype. The silhouette is the point: a player has to be
# able to name the thing coming at them from its shape alone, at 30 pixels
# across, while it is moving.
# --------------------------------------------------------------------------
def credit_card(d, c):
    """A card, with a face. The fast, ordinary, relentless one."""
    rrect(d, [4, 9, 28, 25], shade(c, 1.0), radius=3)
    d.rectangle([4, 12, 28, 15], fill=shade(c, 0.55))       # magnetic stripe
    d.rectangle([7, 18, 12, 21], fill=shade(c, 1.35))       # chip
    eyes(d, 19, 17, 23)
    d.rectangle([17, 23, 23, 23], fill=OUTLINE)             # flat angry mouth


def medical_bill(d, c):
    """A sheet of paper with a cross, torn along the bottom."""
    d.polygon([(7, 4), (25, 4), (25, 26), (22, 23), (18, 27),
               (14, 23), (10, 27), (7, 24)], fill=shade(c, 1.0))
    d.rectangle([9, 7, 23, 8], fill=shade(c, 0.6))
    d.rectangle([9, 20, 20, 21], fill=shade(c, 0.6))
    glyph(d, PLUS, 13, 11, shade(c, 0.45))


def subscription_creep(d, c):
    """Tiny, and there are five of them. Kept simple: it renders at 17px."""
    d.ellipse([8, 8, 24, 24], fill=shade(c, 1.0))
    glyph(d, LOOP, 13, 16, shade(c, 0.45))
    eyes(d, 13, 12, 19)


def payday_loan(d, c):
    """A clock with fangs. Small, fast, four times the drain."""
    d.ellipse([6, 6, 26, 26], fill=shade(c, 1.0))
    d.ellipse([9, 9, 23, 23], fill=shade(c, 1.25))
    # Hands wound tight to the top -- a countdown, not an hour.
    d.line([16, 16, 16, 10], fill=OUTLINE, width=1)
    d.line([16, 16, 21, 18], fill=OUTLINE, width=1)
    # No percent badge here. It was drawn clear of the dial, which meant the
    # outline pass gave it its own border and it read as debris stuck to the
    # sprite rather than as a symbol. The dripping fangs already say
    # "this one is eating your money faster than the rest".
    for x in (11, 15, 19):
        d.polygon([(x, 22), (x + 3, 22), (x + 1, 27)], fill=shade(c, 1.35))


def auto_loan(d, c):
    """A car. Big, slow, and you can see it coming."""
    d.rectangle([3, 16, 29, 23], fill=shade(c, 1.0))
    d.polygon([(8, 16), (12, 9), (21, 9), (25, 16)], fill=shade(c, 1.2))
    d.rectangle([12, 11, 20, 15], fill=shade(c, 0.5))       # windscreen
    d.ellipse([5, 21, 12, 28], fill=OUTLINE)
    d.ellipse([20, 21, 27, 28], fill=OUTLINE)
    d.ellipse([7, 23, 10, 26], fill=shade(c, 0.7))
    d.ellipse([22, 23, 25, 26], fill=shade(c, 0.7))
    d.rectangle([3, 17, 5, 19], fill=shade(c, 1.5))         # headlight


def overdraft_fee(d, c):
    """A bank slip with the balance going through the floor."""
    rrect(d, [7, 5, 25, 27], shade(c, 1.0), radius=2)
    d.rectangle([10, 8, 22, 9], fill=shade(c, 0.55))
    d.rectangle([10, 12, 18, 13], fill=shade(c, 0.55))
    d.line([9, 17, 23, 17], fill=shade(c, 0.4))             # the zero line
    glyph(d, ARROW_DOWN, 14, 19, shade(c, 0.35))
    glyph(d, MINUS, 9, 21, shade(c, 0.35))


def student_loan(d, c):
    """A graduation cap on something enormous that will not move."""
    rrect(d, [4, 14, 28, 29], shade(c, 1.0), radius=2)
    d.polygon([(16, 3), (30, 10), (16, 17), (2, 10)], fill=shade(c, 1.25))
    d.rectangle([12, 12, 20, 15], fill=shade(c, 0.75))      # the cap's band
    d.line([29, 10, 29, 18], fill=shade(c, 0.45))           # tassel
    d.rectangle([28, 18, 30, 20], fill=shade(c, 0.45))
    eyes(d, 20, 9, 21)
    d.rectangle([12, 25, 20, 26], fill=OUTLINE)


def subprime_mortgage(d, c):
    """A house with a crack straight through it. The terms, not the size."""
    d.polygon([(16, 3), (30, 14), (2, 14)], fill=shade(c, 1.2))
    d.rectangle([5, 14, 27, 29], fill=shade(c, 1.0))
    d.rectangle([13, 21, 19, 29], fill=shade(c, 0.5))       # door
    d.rectangle([7, 17, 11, 21], fill=shade(c, 0.65))       # windows
    d.rectangle([21, 17, 25, 21], fill=shade(c, 0.65))
    for i, row in enumerate(CRACK * 3):
        if 14 + i > 29:
            break
        for x, ch in enumerate(row):
            if ch == '#':
                d.point((16 + x - 1, 14 + i), fill=OUTLINE)


def inflation(d, c):
    """A balloon carrying a dollar away. You never borrowed it."""
    d.ellipse([6, 3, 26, 23], fill=shade(c, 1.0))
    d.ellipse([10, 6, 17, 13], fill=shade(c, 1.3))          # highlight
    d.polygon([(14, 22), (18, 22), (16, 26)], fill=shade(c, 0.6))
    d.line([16, 26, 16, 30], fill=shade(c, 0.4))
    glyph(d, ARROW_UP, 14, 8, shade(c, 0.4))
    glyph(d, DOLLAR, 14, 14, shade(c, 0.4))


def too_good_offer(d, c):
    """A prize on a hook. It looked like the reward and it was the enemy."""
    d.line([16, 2, 16, 8], fill=shade(c, 0.55))
    d.arc([12, 5, 21, 14], start=0, end=180, fill=shade(c, 0.55))
    rrect(d, [5, 13, 27, 29], shade(c, 1.0), radius=2)
    d.rectangle([14, 13, 18, 29], fill=shade(c, 0.6))       # ribbon
    d.rectangle([5, 18, 27, 21], fill=shade(c, 0.6))
    glyph(d, DOLLAR, 8, 22, shade(c, 0.4))
    glyph(d, PERCENT, 20, 23, shade(c, 0.4))
    # Sparkles, because the whole point is that it looks attractive.
    d.point((9, 15), fill=(255, 255, 255, 255))
    d.point((24, 25), fill=(255, 255, 255, 255))


BUILDERS = {
    'credit_card': credit_card,
    'medical_bill': medical_bill,
    'subscription_creep': subscription_creep,
    'payday_loan': payday_loan,
    'auto_loan': auto_loan,
    'overdraft_fee': overdraft_fee,
    'student_loan': student_loan,
    'subprime_mortgage': subprime_mortgage,
    'inflation': inflation,
    'too_good_offer': too_good_offer,
}


def outline(img):
    """One dilation pass in near-black, behind the art.

    Doing this centrally is the reason ten separately drawn shapes read as one
    roster: nobody gets to pick a different outline weight.
    """
    px = img.load()
    ring = Image.new('RGBA', (GRID, GRID), CLEAR)
    rp = ring.load()
    for y in range(GRID):
        for x in range(GRID):
            if px[x, y][3] != 0:
                continue
            touching = False
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < GRID and 0 <= ny < GRID and px[nx, ny][3]:
                        touching = True
            if touching:
                rp[x, y] = OUTLINE
    return Image.alpha_composite(ring, img)


def elite_glow(img, rgb):
    """A one-pixel bright rim outside the outline, elites only.

    Elites are rarer, tougher and worth more; the game said so in the numbers
    and said nothing on screen. A rim is legible at speed in a way a colour
    shift is not.
    """
    px = img.load()
    ring = Image.new('RGBA', (GRID, GRID), CLEAR)
    rp = ring.load()
    glow = shade(rgb, 1.45) + (255,)
    for y in range(GRID):
        for x in range(GRID):
            if px[x, y][3] != 0:
                continue
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < GRID and 0 <= ny < GRID and px[nx, ny][3]:
                        rp[x, y] = glow
    return Image.alpha_composite(ring, img)


def main():
    roster = read_roster()
    missing = [e['id'] for e in roster if e['id'] not in BUILDERS]
    assert not missing, 'no sprite for archetype(s): %s' % missing

    os.makedirs(OUT, exist_ok=True)
    tile = GRID * 3
    sheet = Image.new('RGBA', (tile * len(roster), tile), (24, 22, 32, 255))

    for i, enemy in enumerate(roster):
        img = new_layer()
        BUILDERS[enemy['id']](ImageDraw.Draw(img), enemy['rgb'])
        img = outline(img)
        if enemy['elite']:
            img = elite_glow(img, enemy['rgb'])

        path = '%s/%s.png' % (OUT, enemy['id'])
        img.resize((GRID * SCALE, GRID * SCALE), Image.NEAREST).save(path)
        print('%-20s %s' % (enemy['id'], path))

        preview = img.resize((tile, tile), Image.NEAREST)
        sheet.paste(preview, (i * tile, 0), preview)

    contact = os.environ.get('CONTACT_SHEET')
    if contact:
        sheet.save(contact)
        print('contact sheet -> ' + contact)


if __name__ == '__main__':
    main()
