# -*- coding: utf-8 -*-
"""Gives every turtle skin its own set of guide poses.

# Why this exists

Asked for directly: *"Make the turtle skins change it for the guides and
tutorials."*

The guide -- the turtle who runs the tour, the coach marks and the mentor tips
-- was four hardcoded PNGs of the **classic** turtle. A player who had won
Guild Runner (a 1-in-1000 legendary) or Explorer walked the whole app as an
orange turtle and was then taught by a green one. The skin they earned was
visible everywhere except the character who talks to them.

# Why recolouring rather than drawing four new sets

The four turtle skins are the *same sprite* -- pixel for pixel -- with a
different palette and, on two of them, an accessory. That is verifiable rather
than assumed: comparing `classic.png` to each variant position by position,
every base colour maps to exactly one variant colour, and the handful of
pixels that do not fit that mapping are precisely the coin medallion and the
cape.

So the palette map is **measured out of the art**, not typed in. Redraw a
turtle skin and re-run this; the guide follows. Typing sixteen hex values into
a script would be four more places for the art to drift away from itself.

# Why the accessory is transplanted rather than redrawn

The mentor poses are the same body with a different head and arms, so the
belly sits at the same coordinates in all four, and the coin medallion lands
on it exactly.

It is drawn **on top of the pose but clipped to the pose's own silhouette**.
Both halves of that matter, and the first attempt got it wrong. Underneath,
the opaque belly hides the coin entirely -- which is what the first run
produced: a coin-shell guide with no coin, indistinguishable from the classic
one. Unclipped, an accessory pixel can land where that pose has moved a limb
away and hang in mid-air. Clipping to the silhouette gives a coin on the belly
and nothing floating beside a raised arm.

# Why non-turtle skins are not covered

They were not asked for, and a villager or a Goomba has no mentor pose to
recolour -- inventing one would be a different job with a different answer.
Those skins keep the classic turtle guide, which is what they have today.

Run:  python tool/make_mentor_skins.py
"""

import os
from collections import Counter, defaultdict

from PIL import Image

TURTLES = 'assets/images/turtles'
MENTOR = 'assets/own_skins/turtle_mentor'
POSES = ('idle', 'wave', 'thinking', 'worried')

# Skin **id** -> the still used as its art, both from `avatar_skin.dart`.
# `classic_turtle` is the source everything is measured against and is not
# regenerated.
#
# The keys are ids, not filenames, and the two do not always match:
# `explorer_turtle` is drawn by `explorer.png`. Naming the output after the
# file instead of the id shipped art the app could never ask for -- the lookup
# is by equipped skin id, so it fell back to the classic turtle forever and
# looked exactly like the feature not working.
VARIANTS = {
    'coin_shell': 'coin_shell.png',
    'explorer_turtle': 'explorer.png',
    'guild_runner': 'guild_runner.png',
}

# The sweat drop on the worried pose. It is weather, not turtle, and a
# recoloured drop reads as a bruise.
KEEP = {(140, 200, 240, 255)}


def palette_and_accessory(base, variant):
    """Measures how [variant] differs from [base].

    Returns the colour map (the recolour) and an image of everything that map
    cannot explain (the accessory). Splitting them this way means a skin that
    is *only* a recolour produces an empty accessory layer and needs no
    special case.
    """
    bp, vp = base.load(), variant.load()
    counts = defaultdict(Counter)
    for y in range(base.height):
        for x in range(base.width):
            counts[bp[x, y]][vp[x, y]] += 1

    # The mode, because accessory pixels are a minority sharing a base colour
    # with the body they sit on. Taking any single pixel's mapping would let a
    # coin repaint the whole shell.
    palette = {a: c.most_common(1)[0][0] for a, c in counts.items()}

    accessory = Image.new('RGBA', base.size, (0, 0, 0, 0))
    ap = accessory.load()
    for y in range(base.height):
        for x in range(base.width):
            if vp[x, y] != palette[bp[x, y]]:
                ap[x, y] = vp[x, y]
    return palette, accessory


def recolour(pose, palette):
    out = pose.copy()
    op = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = op[x, y]
            if c in KEEP:
                continue
            op[x, y] = palette.get(c, c)
    return out


def dress(art, accessory):
    """Lays [accessory] over [art], clipped to the art's own silhouette."""
    clipped = accessory.copy()
    cp, ap = clipped.load(), art.load()
    for y in range(art.height):
        for x in range(art.width):
            if ap[x, y][3] == 0:
                cp[x, y] = (0, 0, 0, 0)
    out = art.copy()
    out.alpha_composite(clipped)
    return out


def main():
    base = Image.open('%s/classic.png' % TURTLES).convert('RGBA')
    poses = {
        name: Image.open('%s/turtle_mentor_%s.png' % (MENTOR, name)).convert(
            'RGBA'
        )
        for name in POSES
    }

    columns = []
    for skin_id, filename in VARIANTS.items():
        variant = Image.open('%s/%s' % (TURTLES, filename)).convert('RGBA')
        assert variant.size == base.size, '%s is not the same grid' % skin_id

        palette, accessory = palette_and_accessory(base, variant)

        for name, pose in poses.items():
            merged = dress(recolour(pose, palette), accessory)
            path = '%s/turtle_mentor_%s_%s.png' % (MENTOR, name, skin_id)
            merged.save(path)
            print('%-14s %-9s -> %s' % (skin_id, name, path))

        columns.append((skin_id, [
            dress(recolour(poses[n], palette), accessory) for n in POSES
        ]))

    contact = os.environ.get('CONTACT_SHEET')
    if contact:
        cell = 160
        rows = len(columns) + 1
        sheet = Image.new(
            'RGBA', (cell * len(POSES), cell * rows), (26, 30, 26, 255)
        )
        for i, name in enumerate(POSES):
            art = poses[name].resize((cell, cell), Image.NEAREST)
            sheet.paste(art, (i * cell, 0), art)
        for r, (_, arts) in enumerate(columns, start=1):
            for i, art in enumerate(arts):
                art = art.resize((cell, cell), Image.NEAREST)
                sheet.paste(art, (i * cell, r * cell), art)
        sheet.save(contact)
        print('contact sheet -> ' + contact)


if __name__ == '__main__':
    main()
