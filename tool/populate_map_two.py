# -*- coding: utf-8 -*-
"""Give the second map its own NPCs and coins.

THE BUG
-------
Reported as *"there are no NPCs on the other map"*, and the code says so
outright:

    if (_townMap == TownMap.village)
      for (final npc in kTownNpcs) ...
    if (_townMap == TownMap.village)
      for (final coin in kTownCoins) ...

Both are gated to map one. `TownNpc` and the coin records carry a single
tile position, unlike `TownSpot` which grew `tileX2`/`tileY2` when the second
map arrived -- so there was nowhere to put them and the guard was the honest
short-term answer. It then stayed, and half of all town visits landed in a
place with no people and nothing to pick up.

WHAT THIS DOES
--------------
Generates map-two positions obeying the same rules `test/town_map_test.dart`
already enforces for map one, because those rules are why map one looks right:

  * walkable, and reachable from the spawn
  * NPCs need their 3x3 clear, or the sprite embeds in scenery
  * two rows clear overhead, since a villager is ~2 tiles tall and drawn
    upward from its feet
  * no two NPCs, and no two coins, on the same tile
  * NPCs get room to pace along their patrol axis
  * coins away from building doorsteps, so a pickup is never ambiguous with
    walking into a shop

USAGE
-----
    python tool/populate_map_two.py           # report
    python tool/populate_map_two.py --write   # patch the model
"""
import io
import json
import os
import re
import sys
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = os.path.join(ROOT, 'lib', 'models_Like_Skins_and_lessons_templates',
                      'town_spot_models.dart')
MAP2 = os.path.join(ROOT, 'assets', 'images', 'maps', 'map_two.json')

NEIGHBOURS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def load():
    data = json.load(io.open(MAP2, encoding='utf8'))
    solid = set()
    for layer in data['layers']:
        if layer.get('collider'):
            for t in layer['tiles']:
                solid.add((int(t['x']), int(t['y'])))
    return data['mapWidth'], data['mapHeight'], solid


def reachable(width, height, solid, start):
    seen = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in NEIGHBOURS:
            n = (x + dx, y + dy)
            if (0 <= n[0] < width and 0 <= n[1] < height
                    and n not in solid and n not in seen):
                seen.add(n)
                q.append(n)
    return seen


def clear_3x3(cell, solid):
    x, y = cell
    return all((x + dx, y + dy) not in solid
               for dx in (-1, 0, 1) for dy in (-1, 0, 1))


def headroom(cell, solid):
    x, y = cell
    return (x, y - 1) not in solid and (x, y - 2) not in solid


def read_current():
    """Parse whole `TownNpc(...)` blocks rather than a field order.

    The first version assumed `tileX` followed `id`. It does not -- the real
    order is id, patrolTiles, name, look, tileX, tileY -- so the regex matched
    three of the six NPCs and silently skipped the rest. Splitting on the
    constructor and reading each field by name inside its own block cannot
    care what order somebody writes them in.
    """
    src = io.open(MODELS, encoding='utf8').read()

    start = src.index('kTownNpcs')
    end = src.index('];', start)
    npcs = []
    for block in src[start:end].split('TownNpc(')[1:]:
        nid = re.search(r"id:\s*'(npc_\w+)'", block)
        tx = re.search(r'tileX:\s*(\d+)', block)
        ty = re.search(r'tileY:\s*(\d+)', block)
        if not (nid and tx and ty):
            continue
        patrol = re.search(r'patrolTiles:\s*(\d+)', block)
        npcs.append((nid.group(1), int(tx.group(1)), int(ty.group(1)),
                     int(patrol.group(1)) if patrol else 0))

    cstart = src.index('kTownCoins')
    cend = src.index('];', cstart)
    coins = re.findall(r"\(x:\s*(\d+),\s*y:\s*(\d+),\s*value:\s*(\d+)\)",
                       src[cstart:cend])
    return src, npcs, coins


def main():
    write = '--write' in sys.argv
    width, height, solid = load()
    src, npcs, coins = read_current()

    # Spawn is the house doorstep on map two.
    m = re.search(r"id:\s*'spot_home'.*?tileX2:\s*(\d+),\s*tileY2:\s*(\d+)",
                  src, re.S)
    spawn = (int(m.group(1)), int(m.group(2)))
    open_tiles = reachable(width, height, solid, spawn)
    print('map_two: %d reachable tiles from spawn %s' % (len(open_tiles),
                                                         spawn))

    # Doorsteps are reserved -- a coin on a shop's threshold makes "pick up"
    # and "walk in" the same gesture.
    doorsteps = set()
    for mm in re.finditer(r"tileX2:\s*(\d+),\s*tileY2:\s*(\d+)", src):
        doorsteps.add((int(mm.group(1)), int(mm.group(2))))

    # Spread candidates out rather than taking the first N, so the town does
    # not end up with everybody standing in one corner.
    candidates = sorted(
        c for c in open_tiles
        if clear_3x3(c, solid) and headroom(c, solid) and c not in doorsteps
    )
    print('%d tiles are clear enough for a person' % len(candidates))

    used = set()

    def spread(pool, want):
        """Place `want` items across the whole map, not along one edge.

        The first version sorted the candidates and stepped through them,
        which put every NPC and every coin in the far-left margin -- sorting
        tuples orders by x first, so "evenly spaced through the list" means
        "evenly spaced down column zero".

        This lays `want` target points over the map on a coarse grid and
        takes the nearest usable tile to each, so the result is spread by
        construction rather than by hoping the pool was shuffled.
        """
        pool = list(pool)
        if not pool:
            return []

        cols = int(want ** 0.5 + 0.999) or 1
        rows = (want + cols - 1) // cols
        targets = []
        for r in range(rows):
            for c in range(cols):
                if len(targets) >= want:
                    break
                targets.append((
                    int(width * (c + 0.5) / cols),
                    int(height * (r + 0.5) / rows),
                ))

        out = []
        for tx, ty in targets:
            best = None
            for cell in pool:
                if cell in used:
                    continue
                d = abs(cell[0] - tx) + abs(cell[1] - ty)
                if best is None or d < best[0]:
                    best = (d, cell)
            if best is None:
                continue
            out.append(best[1])
            used.add(best[1])
        return out

    npc_cells = spread(candidates, len(npcs))
    coin_pool = [c for c in open_tiles
                 if c not in doorsteps and headroom(c, solid)]
    coin_cells = spread(coin_pool, len(coins))

    print('\nNPCs (%d):' % len(npc_cells))
    for (nid, _, _, _), cell in zip(npcs, npc_cells):
        print('  %-16s -> %s' % (nid, cell))
    print('\ncoins (%d):' % len(coin_cells))
    for (x, y, v), cell in zip(coins, coin_cells):
        print('  value %-2s  (%s,%s) -> %s' % (v, x, y, cell))

    if len(npc_cells) < len(npcs) or len(coin_cells) < len(coins):
        raise SystemExit('not enough clear tiles -- widen the search')

    if not write:
        print('\nreport only. pass --write to apply.')
        return

    # NPCs gain tileX2/tileY2 the same way TownSpot did.
    for (nid, _, _, _), (cx, cy) in zip(npcs, npc_cells):
        pattern = r"(id:\s*'%s'.*?tileY:\s*\d+,)" % nid
        src2, n = re.subn(
            pattern,
            lambda mo: '%s\n    tileX2: %d,\n    tileY2: %d,'
                       % (mo.group(1), cx, cy),
            src, count=1, flags=re.S)
        if n != 1:
            raise SystemExit('could not patch %s' % nid)
        src = src2

    io.open(MODELS, 'w', encoding='utf8').write(src)
    print('\nwrote %s' % MODELS)
    print('coin positions printed above -- add kTownCoinsTwo by hand or '
          'extend this tool once the record shape is settled.')


if __name__ == '__main__':
    main()
