# -*- coding: utf-8 -*-
"""Snap every town spot to a doorway instead of a patch of open path.

**The problem.** The markers were hand-placed and several of them drifted:
measured against the collider data, the cafe and the clinic sit *four tiles*
from the nearest solid thing, and the market and library three. On screen that
reads as a coloured circle floating in the middle of a road with no building
anywhere near it, which is what got reported -- "make the store near the
building".

**What counts as a doorway.** A walkable tile touching a *building*, not
merely touching something solid. Trees, fences and bins are all solid too, and
snapping a shop marker to the side of a hedge would be a different wrong
answer rather than a fix. So a solid cell only qualifies if it belongs to a
connected solid cluster of at least [MIN_BUILDING] tiles -- big enough to be
a structure, small enough to include the little market stalls.

**Intent is preserved.** Each spot keeps its author-chosen area; this only
pulls it to the nearest qualifying tile. The person who placed the cafe on the
south side of the square meant it to be there, and a tool that re-optimised
every position from scratch would throw that away to fix a four-tile drift.

Run:  python tool/place_town_spots.py            (prints a report)
      python tool/place_town_spots.py --write    (rewrites the Dart)
"""
from __future__ import annotations

import json
import os
import re
import sys
from collections import deque

MAPS = os.path.join('assets', 'images', 'maps')
DART = os.path.join(
    'lib', 'models_Like_Skins_and_lessons_templates', 'town_spot_models.dart'
)

# A solid cluster this size or bigger is a building. Below it is scenery.
MIN_BUILDING = 6

# How far a marker may be dragged. Past this the tool has stopped adjusting a
# position and started inventing one, so it reports instead.
MAX_SNAP = 6


def load_map(name):
    data = json.load(open(os.path.join(MAPS, name), encoding='utf8'))
    width, height = data['mapWidth'], data['mapHeight']
    solid = {
        (t['x'], t['y'])
        for layer in data['layers'] if layer.get('collider')
        for t in layer['tiles']
    }
    return width, height, solid


def buildings(width, height, solid):
    """Solid cells that belong to a cluster of at least [MIN_BUILDING]."""
    seen = set()
    out = set()
    for start in solid:
        if start in seen:
            continue
        queue = deque([start])
        cluster = {start}
        seen.add(start)
        while queue:
            x, y = queue.popleft()
            for nx, ny in ((x+1, y), (x-1, y), (x, y+1), (x, y-1)):
                if (nx, ny) in solid and (nx, ny) not in seen:
                    seen.add((nx, ny))
                    cluster.add((nx, ny))
                    queue.append((nx, ny))
        if len(cluster) >= MIN_BUILDING:
            out |= cluster
    return out


def doorways(width, height, solid, built):
    """Walkable tiles with a building directly beside them."""
    out = set()
    for y in range(height):
        for x in range(width):
            if (x, y) in solid:
                continue
            if any(
                (x+dx, y+dy) in built
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
            ):
                out.add((x, y))
    return out


def snap(x, y, doors):
    """Nearest doorway to (x, y), or None if none is close enough."""
    if (x, y) in doors:
        return (x, y), 0
    best, best_d = None, None
    for dx, dy in doors:
        d = max(abs(dx - x), abs(dy - y))
        if d > MAX_SNAP:
            continue
        if best_d is None or d < best_d:
            best, best_d = (dx, dy), d
    return best, best_d


def read_spots():
    src = open(DART, encoding='utf8').read()
    return src, re.findall(
        r"id: '(\w+)',\s*\n\s*kind: TownSpotKind\.(\w+),",
        src,
    )


def main() -> None:
    write = '--write' in sys.argv
    src = open(DART, encoding='utf8').read()

    # id -> (tileX, tileY), in file order.
    #
    # `spot_` only, deliberately. The NPCs live in the same file and match the
    # same shape, and the first run of this happily dragged all six of them
    # onto doorsteps -- but a person is not a building entrance. They are
    # meant to be standing about in the open, and pinning them to walls would
    # make the town look like everybody is queueing.
    found = [
        m for m in re.findall(
            r"id: '(\w+)',.*?tileX: (\d+),\s*\n\s*tileY: (\d+),",
            src,
            re.S,
        )
        if m[0].startswith('spot_')
    ]

    width, height, solid = load_map('map.json')
    built = buildings(width, height, solid)
    doors = doorways(width, height, solid, built)
    print(f'map.json: {len(built)} building tiles, {len(doors)} doorways\n')

    print(f'{"spot":14} {"from":>9} {"to":>9}  moved')
    moves = {}
    for sid, sx, sy in found:
        x, y = int(sx), int(sy)
        target, distance = snap(x, y, doors)
        if target is None:
            print(f'{sid:14} {str((x, y)):>9} {"--":>9}  no doorway within '
                  f'{MAX_SNAP} -- left alone')
            continue
        if distance == 0:
            print(f'{sid:14} {str((x, y)):>9} {str(target):>9}  already at a door')
            continue
        moves[sid] = target
        print(f'{sid:14} {str((x, y)):>9} {str(target):>9}  {distance}')

    if not write:
        print('\n(dry run -- pass --write to apply)')
        return

    for sid, (nx, ny) in moves.items():
        pattern = re.compile(
            r"(id: '" + sid + r"',.*?tileX: )\d+(,\s*\n\s*tileY: )\d+",
            re.S,
        )
        src, count = pattern.subn(rf'\g<1>{nx}\g<2>{ny}', src, count=1)
        assert count == 1, sid
    open(DART, 'w', encoding='utf8').write(src)
    print(f'\nwrote {len(moves)} positions to {DART}')


if __name__ == '__main__':
    main()
