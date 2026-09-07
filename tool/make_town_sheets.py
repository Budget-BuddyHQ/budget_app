# -*- coding: utf-8 -*-
"""Builds town walk sheets for the skins that are not villagers.

# The bug this fixes

`adventure_world_screen.dart` picks the player's sprite like this:

    final playerSheet = equippedSkin.isHuman
        ? equippedSkin.sheetAsset(body)
        : AppAssets.villagerSheet(null, female: body.isFemale);

Read the second branch. **Every non-villager skin walks the town as the
default blue villager.** All four turtles -- including Guild Runner, the
1-in-1,000 legendary -- and the Mushroom Goomba. A player could win the
rarest item in the game, see it on their profile, in the customise grid and
now in Finance Brawl, then walk into town and be a stranger.

It never threw and never logged. The fallback is a real sheet that loads
perfectly; it is just the wrong character.

# Why the town could not simply draw the still

The town is Bonfire. The player is a `SimpleDirectionAnimation` built out of
one packed sheet -- rows are facings, columns are frames -- and everything
downstream (`_loadRowAnimation`, `kSideWalkFrames`, the 104x162 cell size, the
aspect ratio the component is sized by) assumes that shape. Handing it a
single 640x640 still means rewriting the player, the loaders and the size
maths for one case.

So the still is packed *into* that shape instead, and not a line of the town
changes.

# Where four facings come from one picture

The turtles are drawn front-on, once. The Goomba has real north and south
walk frames and uses them.

  * **South** is the still, with a waddle: a two-pixel bob, and a squash on
    the down-beat so the weight reads. Column 0 is left neutral because it is
    also the idle pose.
  * **North** is the still with its face removed and the belly plate
    recoloured to shell. That is a real back view, not a cheat -- a turtle's
    head is a round blob, so a faceless one is exactly what you see from
    behind, and from behind you would see shell where the belly was.
  * **West/East** are the front view again.

**That last one was tried the other way first and it was worse.** Narrowing
the sprite to 85% and sliding the face toward the direction of travel *sounds*
like a three-quarter turn. Rendered, the eyes end up half off the side of the
head with the mouth still centred, which does not read as a turn -- it reads
as a broken sprite. A round mascot facing the camera while it walks sideways
is a convention older than pixel art and costs nothing; a turtle with its face
falling off is a bug report.

Direction is already legible from the fact that the character is *moving*.
The sprite does not have to say it twice.

# Why generated rather than drawn

Five skins x four facings x eight frames is 160 cells. Drawn by hand they
would drift; generated, a new turtle skin costs one line in `SKINS` and the
walk cycle is identical to every other turtle's, which is what makes them
read as the same species.

Run:  python tool/make_town_sheets.py
"""

import os

from PIL import Image

OUT_DIR = 'assets/self_made_skins'

# Villager grid, from `AppAssets`. The town's loaders assume all of this.
CELL_W, CELL_H = 104, 162
COLUMNS, ROWS = 8, 4
# Row order: south, north, west, east.
NORTH_FRAMES = 7  # the villager sheets leave the last north cell empty

# Palette of the classic turtle, which every turtle skin is a recolour of.
# Read off the art rather than typed from a design doc -- see
# `tool/make_mentor_skins.py`, which measures the same mapping.
CLASSIC = 'assets/images/turtles/classic.png'
EYE_WHITE = (255, 255, 255, 255)
BLUSH = (244, 158, 168, 255)
HEAD_LIGHT = (140, 208, 106, 255)
BELLY_CREAM = (232, 240, 206, 255)
BELLY_LINE = (186, 204, 156, 255)
SHELL_DARK = (58, 110, 52, 255)
SHELL_SHADOW = (86, 150, 74, 255)

# The face, in source pixels. Comfortably inside the head silhouette, checked
# by rendering it -- a box that clipped the outline would give the back view a
# bite out of its skull.
FACE_BOX = (190, 145, 460, 350)

# skin id -> how to build it.
SKINS = {
    'classic_turtle': {'still': 'assets/images/turtles/classic.png'},
    'coin_shell': {'still': 'assets/images/turtles/coin_shell.png'},
    'explorer_turtle': {'still': 'assets/images/turtles/explorer.png'},
    'guild_runner': {'still': 'assets/images/turtles/guild_runner.png'},
    'mushroom_goomba': {
        # This one has real frames already. Synthesising a back view for a
        # character that has one drawn would be strictly worse.
        'south': [
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'walkingframe1.png',
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'walking frame2.png',
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'walkingframe3.png',
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'walkingframe4.png',
        ],
        'north': [
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'northwalking1.png',
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'northwalking2.png',
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'northwalking3.png',
            'assets/own_skins/mushroom_goomba/walking_animation/'
            'northwalking4.png',
        ],
    },
}

# One step per column. Column 0 is flat because it doubles as the idle pose.
BOB = (0, 1, 2, 1, 0, 1, 2, 1)


def palette_map(variant_path):
    """How this skin recolours the classic turtle, measured per pixel."""
    from collections import Counter, defaultdict

    base = Image.open(CLASSIC).convert('RGBA')
    variant = Image.open(variant_path).convert('RGBA')
    if variant.size != base.size:
        return None
    bp, vp = base.load(), variant.load()
    counts = defaultdict(Counter)
    for y in range(base.height):
        for x in range(base.width):
            counts[bp[x, y]][vp[x, y]] += 1
    return {a: c.most_common(1)[0][0] for a, c in counts.items()}


def back_view(front, palette):
    """The still, seen from behind.

    Face off, belly plate turned to shell. The blush is cleared everywhere
    rather than only inside the face box -- it reaches past the box at the
    cheeks, and two pink dots on the back of a head is the one artefact that
    reads as a mistake rather than a style.
    """
    out = front.copy()
    op = out.load()
    light = palette.get(HEAD_LIGHT, HEAD_LIGHT) if palette else HEAD_LIGHT
    dark = palette.get(SHELL_DARK, SHELL_DARK) if palette else SHELL_DARK
    shadow = (
        palette.get(SHELL_SHADOW, SHELL_SHADOW) if palette else SHELL_SHADOW
    )
    cream = palette.get(BELLY_CREAM, BELLY_CREAM) if palette else BELLY_CREAM
    line = palette.get(BELLY_LINE, BELLY_LINE) if palette else BELLY_LINE
    blush = palette.get(BLUSH, BLUSH) if palette else BLUSH

    x0, y0, x1, y1 = FACE_BOX
    for y in range(out.height):
        for x in range(out.width):
            c = op[x, y]
            if c[3] == 0:
                continue
            if x0 <= x < x1 and y0 <= y < y1:
                op[x, y] = light
            elif c == blush:
                op[x, y] = light
            elif c == cream:
                op[x, y] = dark
            elif c == line:
                op[x, y] = shadow
    return out


def side_view(front, palette, facing):
    """The side facings, which are the front view.

    Kept as a function rather than inlined so the reason survives: this is a
    decision, not an omission. See the module docstring -- the shifted-face
    version was built, rendered and thrown away.
    """
    del palette, facing
    return front


def place(sheet, art, column, row, lift):
    """Draws one frame into its cell, standing on the cell's floor."""
    box = art.getbbox()
    if box is None:
        return
    cropped = art.crop(box)

    # Fit the width, leave the height alone: a turtle is shorter than a
    # villager and should render shorter than one.
    target_w = 96
    scale = target_w / cropped.width
    target_h = max(1, int(round(cropped.height * scale)))

    # Squash on the down-beat, stretch at the top of the bob. Two pixels of
    # each, which is all that is visible at the 22px the town draws.
    squash = 2 if lift == 0 else (-2 if lift == 2 else 0)
    frame = cropped.resize(
        (target_w + squash, max(1, target_h - squash)), Image.NEAREST
    )

    x = column * CELL_W + (CELL_W - frame.width) // 2
    # 6px of floor gap so the feet are not flush against the cell edge, which
    # is what the villager sheets do.
    y = row * CELL_H + (CELL_H - 6 - frame.height) - lift
    sheet.alpha_composite(frame, (x, max(row * CELL_H, y)))


def build(skin_id, spec):
    palette = (
        palette_map(spec['still'])
        if 'still' in spec and spec['still'] != CLASSIC
        else ({} if 'still' in spec else None)
    )

    if 'still' in spec:
        front = Image.open(spec['still']).convert('RGBA')
        souths = [front] * COLUMNS
        norths = [back_view(front, palette)] * NORTH_FRAMES
        wests = [side_view(front, palette, 'west')] * COLUMNS
        easts = [side_view(front, palette, 'east')] * COLUMNS
    else:
        south = [Image.open(p).convert('RGBA') for p in spec['south']]
        north = [Image.open(p).convert('RGBA') for p in spec['north']]
        souths = [south[i % len(south)] for i in range(COLUMNS)]
        norths = [north[i % len(north)] for i in range(NORTH_FRAMES)]
        wests = [
            side_view(souths[i], None, 'west') for i in range(COLUMNS)
        ]
        easts = [
            side_view(souths[i], None, 'east') for i in range(COLUMNS)
        ]

    sheet = Image.new(
        'RGBA', (CELL_W * COLUMNS, CELL_H * ROWS), (0, 0, 0, 0)
    )
    for i, art in enumerate(souths):
        place(sheet, art, i, 0, BOB[i])
    for i, art in enumerate(norths):
        place(sheet, art, i, 1, BOB[i])
    for i, art in enumerate(wests):
        place(sheet, art, i, 2, BOB[i])
    for i, art in enumerate(easts):
        place(sheet, art, i, 3, BOB[i])

    path = '%s/town_%s.png' % (OUT_DIR, skin_id)
    sheet.save(path)
    return path, sheet


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    sheets = []
    for skin_id, spec in SKINS.items():
        path, sheet = build(skin_id, spec)
        print('%-18s -> %s' % (skin_id, path))
        sheets.append((skin_id, sheet))

    contact = os.environ.get('CONTACT_SHEET')
    if contact:
        w = CELL_W * COLUMNS
        board = Image.new(
            'RGBA', (w, CELL_H * ROWS * len(sheets)), (26, 30, 26, 255)
        )
        for i, (_, sheet) in enumerate(sheets):
            board.alpha_composite(sheet, (0, i * CELL_H * ROWS))
        board.save(contact)
        print('contact sheet -> ' + contact)


if __name__ == '__main__':
    main()
