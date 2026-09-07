# -*- coding: utf-8 -*-
"""Give every town marker its own building, on both maps.

THE BUG
-------
Reported as: *"make the options actually line up with the house please, I'm
having a cafe in the middle of the road."*

`tool/place_town_spots.py` already snaps every marker to a walkable tile
touching a building, and it works -- measured, all 24 markers sit exactly one
tile from a solid cluster on both maps. So by its own test the placement was
perfect, and the town still looked wrong.

Being next to *a* building is necessary and not sufficient. Nothing stopped
two markers snapping to the SAME building:

    village : 8 of 12 markers shared a building with another
    market  : 9 of 12, with bank + notice board + market stalls all on one

So the clinic and the library were opposite walls of one house. The cafe and
the park were one house. Walking up to a building told you nothing about what
was inside it, because the answer was often "two unrelated things", and a
marker on the far side of a house you have mentally assigned to something else
reads exactly like a marker floating in the road.

The second map made it worse for a reason worth writing down: it has **13
distinct buildings against the village's 23**, so the same greedy snapping
crowds nine markers onto four buildings.

THE FIX
-------
Treat it as an assignment problem rather than twelve independent snaps. Each
marker is matched to a *distinct* building, minimising total displacement from
where it sits today so the town stays recognisable rather than being reshuffled
wholesale.

Greedy by lowest cost, then a 2-opt improvement pass that swaps any pair where
trading buildings shortens the total. With twelve markers this is exact in
practice and takes milliseconds; the Hungarian algorithm would be the textbook
answer and is not worth the extra sixty lines for a problem this size.

USAGE
-----
    python tool/assign_town_buildings.py          # report only
    python tool/assign_town_buildings.py --write  # rewrite the coordinates
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
MAPS = os.path.join(ROOT, 'assets', 'images', 'maps')

NEIGHBOURS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def load_map(name):
    data = json.load(io.open(os.path.join(MAPS, name), encoding='utf8'))
    solid = set()
    for layer in data['layers']:
        if layer.get('collider'):
            for tile in layer['tiles']:
                solid.add((int(tile['x']), int(tile['y'])))
    return data['mapWidth'], data['mapHeight'], solid


def buildings(solid, min_size=6):
    """Connected solid clusters of at least `min_size` tiles.

    The size floor is what separates a building from a tree or a fence post.
    Snapping a shop marker to a hedge is a different wrong answer, not a fix --
    that mistake was made and corrected once already.
    """
    seen, groups = set(), []
    for cell in solid:
        if cell in seen:
            continue
        queue, group = deque([cell]), []
        seen.add(cell)
        while queue:
            cx, cy = queue.popleft()
            group.append((cx, cy))
            for dx, dy in NEIGHBOURS:
                nxt = (cx + dx, cy + dy)
                if nxt in solid and nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        if len(group) >= min_size:
            groups.append(group)
    return groups


def doorsteps(group, solid, width, height):
    """Walkable tiles touching this building -- where a marker may stand."""
    out = set()
    for (bx, by) in group:
        for dx, dy in NEIGHBOURS:
            x, y = bx + dx, by + dy
            if 0 <= x < width and 0 <= y < height and (x, y) not in solid:
                out.add((x, y))
    return sorted(out)


def read_spots():
    src = io.open(MODELS, encoding='utf8').read()
    spots = []
    for m in re.finditer(
            r"id:\s*'(spot_\w+)'.*?tileX:\s*(\d+).*?tileY:\s*(\d+)"
            r".*?tileX2:\s*(\d+).*?tileY2:\s*(\d+)", src, re.S):
        spots.append({
            'id': m.group(1),
            'village': (int(m.group(2)), int(m.group(3))),
            'market': (int(m.group(4)), int(m.group(5))),
        })
    return spots


def assign(spots, key, mapfile):
    width, height, solid = load_map(mapfile)
    groups = buildings(solid)
    doors = [doorsteps(g, solid, width, height) for g in groups]
    usable = [i for i, d in enumerate(doors) if d]

    if len(usable) < len(spots):
        print('  WARNING: %d buildings for %d markers -- some must share'
              % (len(usable), len(spots)))

    def cost(si, gi):
        sx, sy = spots[si][key]
        return min(abs(dx - sx) + abs(dy - sy) for dx, dy in doors[gi])

    # Greedy: take the cheapest marker/building pair still available.
    pairs = sorted(
        ((cost(si, gi), si, gi)
         for si in range(len(spots)) for gi in usable),
        key=lambda t: t[0])

    taken_spot, taken_group, chosen = set(), set(), {}
    for c, si, gi in pairs:
        if si in taken_spot or gi in taken_group:
            continue
        taken_spot.add(si)
        taken_group.add(gi)
        chosen[si] = gi

    # Anything left over (fewer buildings than markers) keeps its position.
    for si in range(len(spots)):
        chosen.setdefault(si, None)

    # 2-opt: swap any pair where trading buildings shortens the total.
    improved = True
    while improved:
        improved = False
        keys = [s for s in chosen if chosen[s] is not None]
        for a in keys:
            for b in keys:
                if a >= b:
                    continue
                ga, gb = chosen[a], chosen[b]
                now = cost(a, ga) + cost(b, gb)
                swapped = cost(a, gb) + cost(b, ga)
                if swapped < now:
                    chosen[a], chosen[b] = gb, ga
                    improved = True

    out = {}
    for si, gi in chosen.items():
        if gi is None:
            out[spots[si]['id']] = spots[si][key]
            continue
        sx, sy = spots[si][key]
        best = min(doors[gi], key=lambda d: abs(d[0] - sx) + abs(d[1] - sy))
        out[spots[si]['id']] = best
    return out, len(usable)


def main():
    write = '--write' in sys.argv
    spots = read_spots()
    print('%d markers\n' % len(spots))

    results = {}
    for label, key, mapfile in (('village', 'village', 'map.json'),
                                ('market', 'market', 'map_two.json')):
        placed, count = assign(spots, key, mapfile)
        results[key] = placed
        moved = sum(1 for s in spots if placed[s['id']] != s[key])
        print('=== %s: %d usable buildings ===' % (label, count))
        for s in spots:
            old, new = s[key], placed[s['id']]
            mark = '' if old == new else '   moved from %s' % (old,)
            print('  %-16s -> %s%s' % (s['id'], new, mark))
        print('  %d of %d moved\n' % (moved, len(spots)))

    if not write:
        print('report only. pass --write to apply.')
        return

    src = io.open(MODELS, encoding='utf8').read()
    for s in spots:
        vx, vy = results['village'][s['id']]
        mx, my = results['market'][s['id']]
        pattern = (r"(id:\s*'%s'.*?tileX:\s*)\d+(,.*?tileY:\s*)\d+"
                   r"(,.*?tileX2:\s*)\d+(,.*?tileY2:\s*)\d+" % s['id'])
        src, n = re.subn(
            pattern,
            lambda m: '%s%d%s%d%s%d%s%d' % (
                m.group(1), vx, m.group(2), vy,
                m.group(3), mx, m.group(4), my),
            src, count=1, flags=re.S)
        if n != 1:
            raise SystemExit('could not rewrite %s' % s['id'])

    io.open(MODELS, 'w', encoding='utf8').write(src)
    print('wrote %s' % MODELS)


if __name__ == '__main__':
    main()
