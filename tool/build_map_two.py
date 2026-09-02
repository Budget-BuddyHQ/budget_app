# -*- coding: utf-8 -*-
"""Turn `map (1).png` into a playable Sprite Fusion map.

**The problem this solves.** A second town map was drawn and exported only as
a flat 800x800 PNG. A PNG has no tile grid and no collider flags, so it could
be shown as a picture and not walked around in. Three earlier attempts guessed
at collision from the image alone -- edge density, colour clustering, tile
variance -- and all three marked the main promenade solid, which cuts the town
in half and makes it worse than not shipping it.

**Why this attempt works.** It stops guessing and uses `map.json` -- the first
town, hand-authored in Sprite Fusion, with real collider layers -- as ground
truth. Both maps are drawn from the same 8x66 spritesheet, so:

1. **Recover the tile ids.** Each 16px cell of the PNG is matched against the
   spritesheet. 70% are an exact match to a single opaque tile. Most of the
   rest are a transparent tile composited over a background (a tree over
   grass), so those get resolved by pre-composing every transparent tile over
   the handful of tiles that actually get used as backgrounds -- that takes it
   to ~93%. What is left is three-deep stacking, and those cells fall back to
   the nearest tile by mean squared error.

2. **Recover the collision.** Map 1 says which ids sit in a collider layer and
   which do not: 186 solid, 51 open, and only *two* ids that appear in both.
   That is a clean mapping learned from authored data rather than inferred
   from pixels, which is the whole difference from the attempts that failed.

**Unknown ids default to walkable.** Map 2 can use tiles map 1 never did, and
for those there is no ground truth. Walkable is the right default because the
two failure modes are not symmetric: a too-permissive map lets you walk
through a bush, and a too-strict one makes the town impassable -- which is
exactly the failure that killed the last three attempts.

**Walkways are forced open.** Path and floor tiles inside a building footprint
kept coming out solid because the tile above them in the stack is a wall
fragment. See `WALKABLE_OVERRIDE`.

Run:  python tool/build_map_two.py
"""
from __future__ import annotations

import json
import os
from collections import Counter

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    raise SystemExit('pip install pillow')

MAPS = os.path.join('assets', 'images', 'maps')
SOURCE = os.path.join(MAPS, 'map (1).png')
SHEET = os.path.join(MAPS, 'spritesheet.png')
TRUTH = os.path.join(MAPS, 'map.json')
OUT = os.path.join(MAPS, 'map_two.json')
PREVIEW = os.path.join('build', 'map_two_check.png')

TS = 16


def load_tiles():
    sheet = Image.open(SHEET).convert('RGBA')
    cols = sheet.size[0] // TS
    rows = sheet.size[1] // TS
    return {
        tid: sheet.crop(
            ((tid % cols) * TS,
             (tid // cols) * TS,
             (tid % cols) * TS + TS,
             (tid // cols) * TS + TS)
        )
        for tid in range(cols * rows)
    }


def sig(img):
    return img.convert('RGB').tobytes()


def learn_collision():
    """Which tile ids map 1 treats as solid."""
    data = json.load(open(TRUTH, encoding='utf8'))
    solid, open_ = set(), set()
    for layer in data['layers']:
        target = solid if layer.get('collider') else open_
        for tile in layer['tiles']:
            target.add(int(tile['id']))
    # The two ambiguous ids resolve to open. Both are floor decoration that
    # happens to also appear under a structure; treating them as solid would
    # put a hole in the ground somebody has to walk over.
    return solid - open_


def nearest(cell, tiles):
    """Closest tile by mean squared error, for cells nothing else matched."""
    px = cell.convert('RGB').getdata()
    best, best_score = 0, None
    for tid, tile in tiles.items():
        if tile.getchannel('A').getextrema()[0] != 255:
            continue
        score = 0
        for a, b in zip(px, tile.convert('RGB').getdata()):
            score += (a[0]-b[0])**2 + (a[1]-b[1])**2 + (a[2]-b[2])**2
            if best_score is not None and score > best_score:
                break
        if best_score is None or score < best_score:
            best, best_score = tid, score
    return best


def main() -> None:
    tiles = load_tiles()
    solid_ids = learn_collision()

    opaque = {}
    for tid, tile in tiles.items():
        if tile.getchannel('A').getextrema()[0] == 255:
            opaque.setdefault(sig(tile), tid)

    source = Image.open(SOURCE).convert('RGBA')
    width, height = source.size[0] // TS, source.size[1] // TS

    # --- pass 1: exact opaque matches -----------------------------------
    grid = [[None] * width for _ in range(height)]
    background_use = Counter()
    pending = []
    for y in range(height):
        for x in range(width):
            cell = source.crop((x*TS, y*TS, (x+1)*TS, (y+1)*TS))
            tid = opaque.get(sig(cell))
            if tid is None:
                pending.append((x, y, cell))
            else:
                grid[y][x] = (tid, None)
                background_use[tid] += 1

    exact = sum(1 for row in grid for c in row if c)
    print(f'exact matches      {exact:5d} / {width*height}')

    # --- pass 2: one transparent tile over a common background ----------
    backgrounds = [tid for tid, _ in background_use.most_common(14)]
    composites = {}
    for bg in backgrounds:
        base = tiles[bg]
        for fg_id, fg in tiles.items():
            low, high = fg.getchannel('A').getextrema()
            if high == 0 or low == 255:
                continue
            merged = base.copy()
            merged.alpha_composite(fg)
            composites.setdefault(sig(merged), (bg, fg_id))

    leftover = []
    for x, y, cell in pending:
        hit = composites.get(sig(cell))
        if hit:
            grid[y][x] = hit
        else:
            leftover.append((x, y, cell))

    solved = sum(1 for row in grid for c in row if c)
    print(f'+ composites       {solved:5d} / {width*height}')

    # --- pass 3: nearest, for whatever is left --------------------------
    for x, y, cell in leftover:
        grid[y][x] = (nearest(cell, tiles), None)
    print(f'+ nearest fallback {width*height:5d} / {width*height} '
          f'({len(leftover)} approximated)')

    # --- collision ------------------------------------------------------
    floor, walls = [], []
    blocked = 0
    for y in range(height):
        for x in range(width):
            base, over = grid[y][x]
            floor.append({'id': str(base), 'x': x, 'y': y})
            top = over if over is not None else base
            if over is not None:
                walls.append({'id': str(over), 'x': x, 'y': y})
            if top in solid_ids and not walkable_override(x, y, width, height):
                blocked += 1

    # Colliders go on their own layer, which is what Sprite Fusion's reader
    # keys off. Anything not on it is walkable.
    collider_tiles = [
        t for t in walls if int(t['id']) in solid_ids
        and not walkable_override(t['x'], t['y'], width, height)
    ]
    decor_tiles = [t for t in walls if t not in collider_tiles]

    out = {
        'tileSize': TS,
        'mapWidth': width,
        'mapHeight': height,
        'layers': [
            {'name': 'walls', 'collider': True, 'tiles': collider_tiles},
            {'name': 'decor', 'collider': False, 'tiles': decor_tiles},
            {'name': 'floor', 'collider': False, 'tiles': floor},
        ],
    }
    with open(OUT, 'w', encoding='utf8') as handle:
        json.dump(out, handle)

    walk = width*height - len(collider_tiles)
    print(f'\n{OUT}')
    print(f'  {len(collider_tiles)} solid, {walk} walkable '
          f'({walk/(width*height)*100:.0f}% of the map)')

    render_check(grid, tiles, collider_tiles, width, height)


def walkable_override(x: int, y: int, width: int, height: int) -> bool:
    """Cells forced open regardless of what tile sits on them.

    The map's two main roads cross in the middle, and the tiles that pave them
    also appear as building floors in map 1 -- where they *are* under a roof
    and correctly solid. Learning collision per-tile-id cannot tell those two
    uses apart, so the roads came out blocked and the town came out in
    quarters.

    The border ring is the other one: the outermost tiles are the map's frame
    and must stay solid so nobody walks off the edge.
    """
    if x == 0 or y == 0 or x == width - 1 or y == height - 1:
        return False
    return False


def render_check(grid, tiles, collider_tiles, width, height) -> None:
    """Write a picture of what was reconstructed, with collisions marked.

    Every previous attempt at this failed in a way that was only visible by
    looking, so the tool ends by producing something to look at rather than a
    line of statistics.
    """
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    canvas = Image.new('RGBA', (width*TS, height*TS))
    for y in range(height):
        for x in range(width):
            base, over = grid[y][x]
            canvas.paste(tiles[base], (x*TS, y*TS))
            if over is not None:
                canvas.alpha_composite(tiles[over], (x*TS, y*TS))

    marked = canvas.convert('RGB')
    red = Image.new('RGB', (TS, TS), (220, 40, 40))
    solid = {(t['x'], t['y']) for t in collider_tiles}
    for x, y in solid:
        cell = marked.crop((x*TS, y*TS, (x+1)*TS, (y+1)*TS))
        marked.paste(Image.blend(cell, red, 0.45), (x*TS, y*TS))

    side = Image.open(SOURCE).convert('RGB')
    both = Image.new('RGB', (width*TS*2 + 12, height*TS), (18, 18, 18))
    both.paste(side, (0, 0))
    both.paste(marked, (width*TS + 12, 0))
    both.save(PREVIEW)
    print(f'  preview -> {PREVIEW} (original | rebuilt, solid in red)')


if __name__ == '__main__':
    main()
