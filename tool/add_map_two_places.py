# -*- coding: utf-8 -*-
"""Give the second town the same new places the first one got.

WHY THIS EXISTS
---------------
The life sim grew school, a career ladder, a home, cars, pets and a body, and the
town had twelve places to put all of it. `tool/make_town_map.py` adds four to the
first town by composing them from the same prefabs. The second town is not
composed: it was rebuilt from a flat picture (`tool/build_map_two.py`), so there
is nothing to re-run. This lifts the same buildings out of the same source and
stamps them into it.

Every building is a prefab somebody drew; this only decides where it stands. A
building is written to the layers the original used: solid parts into `walls`,
which is the second town's collider layer, and the window and door overlays into
a new top layer called `inside`, because the second town's own layers have
nothing above `walls` and an overlay drawn under the wall it belongs to is
invisible.

IDEMPOTENT. It reads `tool/town_v2_source.json`, the second town as it was before
any of this, and writes `assets/images/maps/map_two.json`. Running it twice gives
the same map, and a placement changed here changes the map rather than adding a
second building beside the first.

USAGE
-----
    python tool/add_map_two_places.py            # report
    python tool/add_map_two_places.py --write    # write the map
"""
from __future__ import annotations

import importlib.util
import json
import os
import shutil
import sys
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS = os.path.join(ROOT, 'assets', 'images', 'maps')
LIVE = os.path.join(MAPS, 'map_two.json')
SOURCE = os.path.join(ROOT, 'tool', 'town_v2_source.json')

# (label, prefab index in make_town_map's list, x, y). Prefab sizes:
#   b04 7x4 pale stone hall   b06 5x5 stacked house   b07 4x6 orange house
#   b11 6x3 cottage and fruit stand
PLACEMENTS = [
    ('campus', 4, 39, 22),
    ('gym', 6, 31, 18),
    ('housing', 11, 17, 17),
    ('pet', 11, 29, 4),
]

SOLID_LAYERS = ('structures', 'structures mre', 'more Structures', 'Structure Ground')
OVERLAY_LAYER = 'inside'


def load_prefabs():
    spec = importlib.util.spec_from_file_location(
        'mtm', os.path.join(ROOT, 'tool', 'make_town_map.py'))
    mtm = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mtm)
    cwd = os.getcwd()
    os.chdir(ROOT)
    try:
        src = mtm.load_source()
        g = mtm.grids(src)
        solid = [L['name'] for L in src['layers'] if L.get('collider')]
        names = [L['name'] for L in src['layers']]
        return mtm.extract_prefabs(
            g, [n for n in solid if n not in ('walls', 'terrain_cliff')], names)
    finally:
        os.chdir(cwd)


def main() -> None:
    write = '--write' in sys.argv
    if not os.path.exists(SOURCE):
        shutil.copyfile(LIVE, SOURCE)
        print(f'kept the untouched second town as {os.path.relpath(SOURCE, ROOT)}')

    data = json.load(open(SOURCE, encoding='utf8'))
    prefabs = load_prefabs()
    layers = {L['name']: L for L in data['layers']}
    walls = layers['walls']

    solid = {(int(t['x']), int(t['y'])) for t in walls['tiles']}

    problems = []
    added_walls, added_inside = [], []
    claimed = set()
    for label, idx, ox, oy in PLACEMENTS:
        pf = prefabs[idx]
        w, h = pf['w'], pf['h']
        for dx in range(-1, w + 1):
            for dy in range(-1, h + 2):   # one row below, for the doorstep
                cell = (ox + dx, oy + dy)
                if cell in solid:
                    problems.append(f'{label}: {cell} is already solid')
                if cell in claimed:
                    problems.append(f'{label}: {cell} overlaps another new building')
        for dx in range(-1, w + 1):
            for dy in range(-1, h + 2):
                claimed.add((ox + dx, oy + dy))
        for name, cells in pf['layers'].items():
            for (dx, dy), tid in cells.items():
                tile = {'id': str(tid), 'x': ox + dx, 'y': oy + dy}
                if name in SOLID_LAYERS:
                    added_walls.append(tile)
                elif name == OVERLAY_LAYER:
                    added_inside.append(tile)

    if problems:
        print('REJECTED:')
        for p in problems[:30]:
            print('  -', p)
        sys.exit(1)

    walls_out = list(walls['tiles']) + added_walls
    new_layers = []
    if added_inside:
        new_layers.append({'name': OVERLAY_LAYER, 'tiles': added_inside})
    for L in data['layers']:
        if L['name'] == 'walls':
            new_layers.append({**L, 'tiles': walls_out})
        else:
            new_layers.append(L)
    out = {**data, 'layers': new_layers}

    # Reachability, the invariant that matters: nothing walkable may be cut off.
    width, height = data['mapWidth'], data['mapHeight']
    blocked = {(int(t['x']), int(t['y'])) for t in walls_out}
    start = next(
        (x, y) for y in range(height) for x in range(width) if (x, y) not in blocked)
    q, reach = deque([start]), {start}
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < width and 0 <= n[1] < height and n not in blocked and n not in reach:
                reach.add(n)
                q.append(n)
    walkable = width * height - len(blocked)
    print(f'{len(PLACEMENTS)} buildings, +{len(added_walls)} solid tiles, '
          f'+{len(added_inside)} overlay tiles; '
          f'{len(reach)} of {walkable} walkable tiles reachable')
    if len(reach) < walkable * 0.995:
        print('REJECTED: the new buildings cut the town in two')
        sys.exit(1)

    if not write:
        print('(report only, pass --write to apply)')
        return
    with open(LIVE, 'w', encoding='utf8') as f:
        json.dump(out, f)
    print('wrote', os.path.relpath(LIVE, ROOT))


if __name__ == '__main__':
    main()
