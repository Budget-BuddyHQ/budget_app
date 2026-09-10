# -*- coding: utf-8 -*-
"""Pop-up animation frames for Leak Patrol.

# Why

The game was reported as unfinished, and the screenshot showed why: every
hole drew **the same single static frame** of the Mushroom Goomba
(`AppAssets.goombaWalk`, frame one of its walk cycle). Nothing rose, nothing
reacted to a tap, and nine holes held nine identical pictures. A whack-a-mole
where nothing moves is a list of buttons.

# The three frames, and why three

  * **rise** — stretched tall and narrowed. Played as the thing comes up out
    of the hole, so it reads as arriving rather than appearing.
  * **idle** — the neutral pose, held while it is tappable.
  * **hit** — squashed wide and flat and flashed white. Played for the moment
    of the tap.

The impact burst is drawn by the widget, not baked in here. It was baked in
first, and two things were wrong with that: the spikes landed on the cell
corners and got clipped, and — more importantly — a baked burst can only be
one colour. Drawn live it is **green for a leak you caught and red for a
charge you should have left alone**, which turns the most-looked-at frame in
the game into the feedback the player actually needs.

Squash-and-stretch is doing the work here rather than new drawing. It is the
oldest trick in animation for exactly this reason: a shape that stretches on
the way up and flattens on impact reads as having weight and being *hit*,
from two derived frames per creature.

# Why four creatures, and why the sprite must not mean anything

The one rule of this game is **tap the leaks, leave the real charges**, and
the player has to *read the label* to tell them apart. So the artwork must
carry no information about which is which.

That rules out the obvious idea — leaks as one creature, legitimate charges
as another — which would look great and would delete the entire lesson,
because you could then win with the sound off and your eyes half closed.

The sprite is therefore chosen by a hash of the item id: stable per item (so
the same charge always looks the same, which is fair), varied across the
board, and carrying nothing. `test/leak_patrol_test.dart` asserts every
creature is used by both leaks and legitimate charges, so this cannot drift
into a tell.

The four are the Goomba plus the three Finance Brawl debt sprites, which
already exist, already read at this size, and already belong to the same
world.

Run:  python tool/make_leak_sprites.py
"""

import os

from PIL import Image

OUT = 'assets/images/leak_patrol'
CELL = 128          # exported size
BODY = 104          # the creature's height inside the cell, idle

SOURCES = {
    'goomba': 'assets/own_skins/mushroom_goomba/walking_animation/'
              'walkingframe1.png',
    'red': 'assets/images/finance_brawl_ui/brawl_enemy_one.png',
    'violet': 'assets/images/finance_brawl_ui/brawl_enemy_two.png',
    'shadow': 'assets/images/finance_brawl_ui/brawl_boss.png',
}


def trimmed(path):
    """The source with its transparent margin removed.

    The four sources are packed differently — the Goomba fills its frame, the
    boss sits inside a wide one. Without this, "the same height" would render
    as four visibly different sizes.
    """
    art = Image.open(path).convert('RGBA')
    box = art.getbbox()
    return art.crop(box) if box else art


def framed(art, width, height, lift=0):
    """Bottom-aligns [art] at the given size inside a square cell.

    Bottom-aligned because these come out of holes: whatever the frame does
    to the height, the feet stay on the ground, so the animation reads as
    rising rather than as growing from the middle.
    """
    cell = Image.new('RGBA', (CELL, CELL), (0, 0, 0, 0))
    scaled = art.resize((max(1, width), max(1, height)), Image.NEAREST)
    cell.alpha_composite(
        scaled, ((CELL - scaled.width) // 2, CELL - scaled.height - lift)
    )
    return cell


def flash(cell, strength=0.45):
    """Whitens the art without touching its silhouette.

    Compositing a white rectangle would fill the whole cell. This lightens
    only the pixels that are already there, which is what "flash" means for a
    sprite with a shape.
    """
    out = cell.copy()
    px = out.load()
    for y in range(CELL):
        for x in range(CELL):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (
                int(r + (255 - r) * strength),
                int(g + (255 - g) * strength),
                int(b + (255 - b) * strength),
                a,
            )
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    made = []

    for name, path in SOURCES.items():
        art = trimmed(path)
        ratio = art.width / art.height

        idle_h = BODY
        idle_w = int(round(idle_h * ratio))

        # Rise: taller and narrower, and lifted clear of the floor so the
        # sprite is visibly on its way up rather than standing still.
        rise = framed(
            art, int(idle_w * 0.90), int(idle_h * 1.14), lift=int(CELL * 0.05)
        )
        idle = framed(art, idle_w, idle_h)
        # Hit: wide and flat. The proportions are exaggerated deliberately —
        # this frame is on screen for about a tenth of a second, and a subtle
        # squash at that duration is indistinguishable from no squash.
        hit = flash(framed(art, int(idle_w * 1.18), int(idle_h * 0.70)))

        for frame, image in (('rise', rise), ('idle', idle), ('hit', hit)):
            target = '%s/%s_%s.png' % (OUT, name, frame)
            image.save(target)
            made.append(target)
        print('%-8s rise / idle / hit' % name)

    contact = os.environ.get('CONTACT_SHEET')
    if contact:
        sheet = Image.new(
            'RGBA', (CELL * 3, CELL * len(SOURCES)), (26, 40, 32, 255)
        )
        for row, name in enumerate(SOURCES):
            for col, frame in enumerate(('rise', 'idle', 'hit')):
                art = Image.open('%s/%s_%s.png' % (OUT, name, frame))
                sheet.alpha_composite(art, (col * CELL, row * CELL))
        sheet.save(contact)
        print('contact sheet -> ' + contact)

    print('%d frames' % len(made))


if __name__ == '__main__':
    main()
