# -*- coding: utf-8 -*-
"""Give the second town real walls, from hand-measured building footprints.

**The problem this solves.** `build_map_two.py` learned which tile ids are
solid from the first map and defaulted every id it had never seen to
walkable, on purpose (an over-strict map is impassable, an over-loose one
lets you through a bush). The cost of that default turned out to be most of
the town: the cafe, the mine, the middle of both big wooden halls, the top
half of the stilt tower, the playground, and the rock border along the
bottom and right edges — which is how a player walked straight off the map.

**Why footprints and not more id-guessing.** A roof tile and a doorstep can
share an id, and so can a wall and a step. Deciding per id is the approach
that already failed. A building's footprint is what a person actually sees,
so the boxes below were read off a tile-gridded render of the map, one
building at a time.

**How the walls are added without changing the art.** A new collider layer,
`collision`, holds one fully transparent tile (id 26) per extra solid cell,
so nothing new is drawn. The handful of cells that were solid and should not
be (the grass notch of the L-shaped house, which blocked its own front door)
are moved from `walls` to `decor`, so they keep their exact appearance and
lose only their hitbox.

Checks run on every rebuild, and fail the script rather than write a map
that breaks the game: every building marker stands on open ground, every
marker, coin and the spawn point are in one connected space, and no NPC's
sprite overlaps a wall anywhere along its patrol.

Run:  python tool/fix_map_two_collision.py
"""
from __future__ import annotations

import json
import os
import re
import sys
from collections import deque

MAP = os.path.join('assets', 'images', 'maps', 'map_two.json')
MODELS = os.path.join(
    'lib', 'models_Like_Skins_and_lessons_templates', 'town_spot_models.dart'
)
SIZE = 50
TRANSPARENT_TILE = '26'
LAYER = 'collision'

# (x0, y0, x1, y1), inclusive, in tiles. Read off a tile-gridded render.
SOLID: list[tuple[str, tuple[int, int, int, int]]] = [
    # The border. Rock and hedge on every side; the bottom two rows and the
    # right edge had no hitbox at all.
    ('top edge', (0, 0, 49, 0)),
    ('bottom rocks', (0, 48, 49, 49)),
    ('left rocks', (0, 0, 1, 49)),
    ('right edge', (49, 0, 49, 49)),
    ('right rocks, north', (48, 1, 48, 24)),
    ('right rocks, south', (48, 39, 48, 47)),
    ('east road post, north', (48, 33, 48, 33)),
    ('east road post, south', (48, 38, 48, 38)),
    # North-west.
    ('tree by the cafe', (5, 1, 7, 3)),
    ('cafe, two wings', (8, 2, 11, 4)),
    ('cafe tower', (10, 1, 11, 1)),
    ('cafe menu boards and table', (12, 3, 13, 4)),
    ('library house', (15, 2, 17, 4)),
    ('fence north of the field', (18, 5, 21, 5)),
    ('fence south of the field', (18, 10, 21, 10)),
    ('big wooden hall', (9, 11, 12, 15)),
    ('crates by the hall', (13, 12, 14, 12)),
    ('signboard by the hall', (15, 12, 15, 13)),
    ('clinic barn', (16, 11, 19, 15)),
    ('tree below the deck', (6, 14, 8, 16)),
    ('housing house', (18, 17, 20, 19)),
    ('rocking toy', (6, 23, 6, 24)),
    ('statue on the west lawn', (6, 25, 6, 27)),
    ('statue south of the road', (30, 39, 30, 40)),
    ('well', (12, 23, 13, 24)),
    ('merry-go-round', (16, 22, 18, 24)),
    ('swings', (24, 18, 26, 20)),
    # North-east.
    ('rock west of the mine', (29, 2, 30, 3)),
    ('mine', (31, 1, 33, 3)),
    ('rock east of the mine', (34, 2, 35, 3)),
    ('sapling by the mine', (37, 2, 38, 3)),
    ('bank, L-shaped hall', (42, 6, 47, 9)),
    ('bank, west wall', (41, 6, 41, 7)),
    ('tree on the green', (29, 11, 31, 12)),
    ('tree on the green, trunk', (30, 13, 30, 13)),
    ('red railing', (27, 13, 28, 14)),
    ('slide', (27, 16, 27, 17)),
    ('stilt tower', (39, 12, 41, 16)),
    ('stilt tower walkway and stairs', (42, 13, 46, 16)),
    ('notice totem', (31, 19, 31, 20)),
    ('gym barn', (32, 18, 35, 22)),
    ('blue tent by the gym', (32, 23, 33, 24)),
    ('blue tent by the tower', (39, 18, 40, 19)),
    ('campus hall', (40, 22, 45, 24)),
    ('campus hall, east wing', (43, 25, 45, 25)),
    # South-west.
    ('tree by the school', (6, 28, 7, 29)),
    ('school house', (9, 28, 12, 32)),
    ('cart and workbench', (13, 30, 14, 32)),
    ('tree east of the school', (15, 29, 17, 31)),
    ('sapling by the school', (4, 31, 5, 32)),
    ('bamboo, west', (4, 40, 4, 42)),
    ('tree, south lawn', (9, 40, 10, 41)),
    ('platform at the top of the steps', (12, 41, 15, 42)),
    ('tree, south lawn east', (18, 40, 19, 41)),
    ('tree and hedge, south', (21, 40, 24, 41)),
    ('tree and hedge, south, trunk', (22, 42, 22, 42)),
    ('tree, far south-west', (6, 43, 8, 45)),
    ('tree, far south', (15, 43, 17, 45)),
    ('tree, bottom', (21, 44, 22, 45)),
    # South-east.
    ('tree north of the road', (36, 25, 37, 25)),
    ('hedge north of the road', (36, 26, 38, 26)),
    ('tree north of the road, trunk', (37, 27, 37, 27)),
    ('sapling, east', (47, 25, 48, 26)),
    ('kiln', (40, 30, 41, 32)),
    ('home', (42, 28, 45, 32)),
    ('bench sign', (33, 31, 34, 31)),
    ('cafe awning', (25, 41, 28, 41)),
    ('rock and bucket', (29, 41, 29, 42)),
    ('desk by the stall', (42, 41, 42, 42)),
    ('tree and hedge, south-east', (43, 41, 45, 43)),
    ('bamboo by the road', (36, 37, 36, 39)),
    ('bamboo, south', (26, 44, 26, 46)),
    ('tree, south-east lawn', (35, 43, 37, 45)),
]

# Solid today and should not be: the grass in the notch of the L-shaped
# campus hall, which sat in front of its own door.
CLEAR: list[tuple[int, int]] = [(40, 25), (41, 25), (42, 25)]

# NPC sprite: 26px tall, 26 * 102/116 wide, anchored top-left at its tile.
NPC_W = 26 * 102 / 116
NPC_H = 26.0


def rect_cells(r):
    x0, y0, x1, y1 = r
    return {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}


def parse_models():
    src = open(MODELS, encoding='utf-8').read()
    spots = {}
    for m in re.finditer(
        r"id: '(spot_\w+)'.*?tileX2: (\d+),\s*tileY2: (\d+)", src, re.S
    ):
        spots[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    npcs = {}
    for block in re.split(r'\n  TownNpc\(', src)[1:]:
        id_ = re.search(r"id: '(npc_\w+)'", block)
        if not id_:
            continue
        x2 = int(re.search(r'tileX2: (\d+)', block).group(1))
        y2 = int(re.search(r'tileY2: (\d+)', block).group(1))
        pt = re.search(r'patrolTiles: (\d+)', block)
        ph = re.search(r'patrolHorizontal: (true|false)', block)
        npcs[id_.group(1)] = (
            x2, y2, int(pt.group(1)) if pt else 0,
            (ph.group(1) == 'true') if ph else True,
        )
    two = src.split('kTownCoinsTwo')[1].split('];')[0]
    coins = [(int(a), int(b)) for a, b in
             re.findall(r'x: (\d+), y: (\d+)', two)]
    return spots, npcs, coins


def npc_cells(x, y, patrol, horizontal):
    """Every tile the sprite touches at any point of its patrol."""
    cells = set()
    for step in range(0, patrol * 16 + 1):
        px = x * 16 + (step if horizontal else 0)
        py = y * 16 + (0 if horizontal else step)
        for cx in range(int(px // 16), int((px + NPC_W - 0.01) // 16) + 1):
            for cy in range(int(py // 16), int((py + NPC_H - 0.01) // 16) + 1):
                cells.add((cx, cy))
    return cells


def flood(start, solid):
    seen = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < SIZE and 0 <= ny < SIZE and (nx, ny) not in solid \
                    and (nx, ny) not in seen:
                seen.add((nx, ny))
                q.append((nx, ny))
    return seen


def main():
    data = json.load(open(MAP, encoding='utf-8'))
    layers = {l['name']: l for l in data['layers']}
    walls, decor = layers['walls'], layers['decor']

    # Move cleared cells out of the collider layer, keeping their art.
    moved = [t for t in walls['tiles'] if (t['x'], t['y']) in set(CLEAR)]
    walls['tiles'] = [t for t in walls['tiles'] if t not in moved]
    decor['tiles'].extend(moved)

    existing = {(t['x'], t['y']) for l in data['layers'] if l.get('collider')
                for t in l['tiles'] if l['name'] != LAYER}
    wanted = set()
    for _, r in SOLID:
        wanted |= rect_cells(r)
    added = sorted(wanted - existing - set(CLEAR))

    data['layers'] = [l for l in data['layers'] if l['name'] != LAYER]
    data['layers'].insert(0, {
        'name': LAYER,
        'collider': True,
        'tiles': [{'id': TRANSPARENT_TILE, 'x': x, 'y': y} for x, y in added],
    })

    solid = existing | set(added)
    spots, npcs, coins = parse_models()
    spawn = (spots['spot_home'][0], spots['spot_home'][1] + 2)
    reach = flood(spawn, solid)

    problems = []
    for sid, cell in spots.items():
        if cell in solid:
            problems.append(f'{sid} at {cell} is inside a wall')
        elif cell not in reach:
            problems.append(f'{sid} at {cell} cannot be reached from spawn')
    for cell in coins:
        if cell in solid or cell not in reach:
            problems.append(f'coin at {cell} is walled in')
    for nid, (x, y, patrol, horiz) in npcs.items():
        hit = npc_cells(x, y, patrol, horiz) & solid
        if hit:
            problems.append(f'{nid} at {(x, y)} overlaps walls at {sorted(hit)}')

    walkable = SIZE * SIZE - len(solid)
    print(f'added {len(added)} invisible wall cells, cleared {len(moved)}; '
          f'{walkable / (SIZE * SIZE):.0%} walkable, '
          f'{len(reach) / walkable:.0%} of it reachable from spawn')
    if problems:
        print('\n'.join(problems))
        if '--force' not in sys.argv:
            print('not written: fix the problems above or pass --force')
            sys.exit(1)

    with open(MAP, 'w', encoding='utf-8') as f:
        json.dump(data, f)
    print('wrote', MAP)


if __name__ == '__main__':
    main()
