"""Composes the Adventure town's `map.json` from the buildings of the old one.

WHY GENERATE A MAP RATHER THAN DRAW ONE
---------------------------------------
The previous town was hand-made in Sprite Fusion and looked it — but it was
also *one* layout, and re-drawing it by hand to get a different one means
opening an external editor and re-exporting. This composes a new town from
the same art instead, which means the layout is a few lines of Python and
the result is reproducible.

The trick that makes it look hand-made anyway: **nothing here draws a
building**. Every structure is lifted wholesale out of the previous map as a
prefab — the exact tiles, in the exact arrangement, across the exact layers
the original used. So each building is a building somebody actually drew;
this file only decides where they stand and what runs between them.

WHAT IS DIFFERENT ABOUT THE NEW LAYOUT
--------------------------------------
The old town was a scatter of buildings around one long horizontal road,
with most of the interest crowded into the north. This is radial: a cobbled
market square in the middle, two avenues crossing at it, and the six
money-decision buildings arranged around the square so every one of them is
a short walk from the centre rather than a hike across the map.

INVARIANTS THIS MUST PRESERVE
-----------------------------
`test/town_map_test.dart` runs against whatever this writes:

  * the outer ring is fully solid, so the player cannot walk off the map
    (the ring is copied verbatim from the old map rather than re-derived);
  * every walkable tile is reachable from the spawn — no stranded pockets;
  * every spot, NPC and coin sits on a walkable tile, and NPCs need two
    clear rows above them so the sprite does not clip into scenery.

This script checks all of those itself before writing, so a bad layout fails
here rather than in the test run.

USAGE
-----
    python tool/make_town_map.py            # write assets/images/maps/map.json
    python tool/make_town_map.py --preview  # also re-render the reference PNG
"""

from __future__ import annotations

import json
import os
import sys
from collections import deque

MAPS = os.path.join("assets", "images", "maps")
# The previous hand-drawn town, kept as the prefab source. It lives in
# `tool/` rather than beside the map because it is a build input, not a
# shipped asset — and because reading the file this script also *writes*
# would make a second run extract prefabs out of its own output.
SRC_MAP = os.path.join("tool", "town_v1_source.json")
OUT_MAP = os.path.join(MAPS, "map.json")
PREVIEW = os.path.join(MAPS, "reference", "town_preview.png")

W = H = 50
TS = 16

# Ground / path / decor tile ids, read off the old map's own palette.
GRASS = 63
PATH = 91
# One tile, laid solid. The first pass used the muddy cobble (494-497) and
# read as churned earth; alternating 511/512 then read as *speckle*, because
# 512 is nearly the path's own colour, so the checker showed up as scattered
# dots rather than as paving. A single brick tile is what looks laid.
PLAZA = (511,)
GRASS_DECOR = (79, 80, 82, 86, 108, 114, 115, 116)

# Layer order is *top-first* — the last entry is what gets drawn underneath
# everything else. That is how the original export is ordered (its 2,500-tile
# `floor` layer is listed last), and the reader honours it.
LAYER_ORDER = [
    "inside",
    "more Structures",
    "structures mre",
    "structures",
    "Structure Ground",
    "Wall Texturing",
    "walls",
    "terrain",
    "texture",
    "floor",
]
COLLIDERS = {
    "more Structures",
    "structures mre",
    "structures",
    "Structure Ground",
    "Wall Texturing",
    "walls",
}


# --------------------------------------------------------------------------
# Reading the old map
# --------------------------------------------------------------------------

def load_source():
    with open(SRC_MAP, encoding="utf-8") as f:
        return json.load(f)


def grids(src):
    return {
        L["name"]: {(int(t["x"]), int(t["y"])): int(t["id"]) for t in L["tiles"]}
        for L in src["layers"]
    }


def extract_prefabs(g, solid_layers, all_layers):
    """Every free-standing structure in the old map, as a placeable stamp.

    Grouped over *solid* tiles only and 4-connected: grouping 8-way merged a
    row of shops and the plaza beside them into one 17x14 blob, which is not
    a building you can place anywhere.
    """
    occ = set()
    for n in solid_layers:
        occ |= set(g.get(n, {}))
    occ = {(x, y) for x, y in occ if 2 <= x <= W - 3 and 2 <= y <= H - 3}

    seen, comps = set(), []
    for cell in sorted(occ):
        if cell in seen:
            continue
        stack, comp = [cell], []
        seen.add(cell)
        while stack:
            x, y = stack.pop()
            comp.append((x, y))
            for nb in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if nb in occ and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
        comps.append(comp)
    comps.sort(key=len, reverse=True)

    out = []
    for comp in comps:
        if len(comp) < 4:
            continue
        xs = [p[0] for p in comp]
        ys = [p[1] for p in comp]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
        layers = {}
        for n in all_layers:
            cells = {
                (x - x0, y - y0): t
                for (x, y), t in g.get(n, {}).items()
                if x0 <= x <= x1 and y0 <= y <= y1
            }
            if cells:
                layers[n] = cells
        out.append(
            {
                "w": x1 - x0 + 1,
                "h": y1 - y0 + 1,
                "layers": layers,
                "solid": {(p[0] - x0, p[1] - y0) for p in comp},
            }
        )
    return out


# --------------------------------------------------------------------------
# The layout
# --------------------------------------------------------------------------
#
# Prefabs are addressed by their index in the size-sorted list above, which
# is stable for a given source map. Each entry says which building goes
# where; the comment is what it looks like, so a reader does not have to
# open the spritesheet to follow this.
PLACEMENTS = [
    ("market", 0, 6, 7),     # b00 11x6 — stalls and the big barn
    ("bank", 4, 34, 8),      # b04  7x4 — pale stone hall with a dark doorway
    ("notice", 5, 30, 15),   # b05  6x8 — the tall signboard
    ("school", 2, 7, 30),    # b02  7x6 — shopfront with shelves
    ("job", 1, 33, 30),      # b01  8x6 — the timber mill/tower
    # Sits *beside* the south avenue rather than on it. The first pass put
    # this at x22 with a 4-wide footprint, which planted the house squarely
    # across the road — reachability still passed, because you could walk
    # round it on grass, which is exactly why "the tests are green" is not
    # the same as "the map is right".
    ("home", 7, 28, 39),     # b07  4x6 — orange house, clear front door
]

# Smaller set pieces. These are what stop the town reading as six buildings
# marooned in a field: a stall and a cottage give the square neighbours, and
# the fence runs imply fields nobody had to draw.
PROPS = [
    (10, 18, 17),  # b10 3x5 — awninged food stall, north-west of the square
    (11, 13, 43),  # b11 6x3 — cottage and fruit stand, southern lane
    (3, 14, 27),   # b03 8x5 — long bench under an awning
    (9, 8, 19),    # b09 15x1 — fence run, west field
    (9, 8, 38),    # b09 15x1 — fence run, south field
]

# Trees, planted in groves. Scattering them on an even grid is what made the
# first pass look procedural — real planting clumps.
DECOR = [
    # north-west grove
    (13, 3, 3), (14, 6, 4), (21, 4, 8), (12, 2, 12),
    # north-east grove
    (13, 44, 4), (12, 41, 3), (21, 46, 8), (14, 45, 12),
    # south-west grove
    (13, 3, 43), (12, 6, 45), (21, 2, 40),
    # south-east grove
    (13, 45, 43), (21, 42, 46), (14, 44, 39),
    # singles breaking up the open middle
    (13, 19, 8), (21, 20, 13), (14, 31, 8), (13, 43, 20),
    (21, 17, 36), (13, 21, 45), (14, 38, 18), (21, 30, 36),
    # the mid-height bands either side of the square, which read as
    # bald grass once everything else had somewhere to be
    (13, 6, 15), (21, 15, 20), (14, 8, 34), (13, 40, 15),
    (21, 44, 32), (14, 20, 34), (13, 34, 44), (21, 12, 12),
    # NB: anything placed here must clear the avenues — a 3-tall
    # tree at y21 reaches y23 and stands in the road. The check in
    # `verify` catches it now; it was found by the Dart test first.
]

# Short paths joining each door to the nearest avenue, as
# (fixed axis, x-or-y, from, to). Without these the buildings float: the
# avenues went past them rather than to them.
SPURS = [
    ("v", 13, 13, 22),   # market → horizontal avenue
    ("v", 37, 12, 22),   # bank   → horizontal avenue
    ("v", 11, 26, 29),   # school → horizontal avenue
    ("v", 36, 26, 29),   # job    → horizontal avenue
    ("h", 41, 27, 27),   # home   → vertical avenue
]

# Avenues. Three tiles wide so two characters can pass and the square reads
# as a junction rather than a corridor.
V_AVENUE = range(24, 27)
H_AVENUE = range(23, 26)
# Tightened from 11x9. A square that wide was a brown field with buildings
# around it rather than a plaza.
PLAZA_BOX = (21, 21, 29, 27)  # x0, y0, x1, y1 inclusive


def compose(prefabs, border):
    layers = {n: {} for n in LAYER_ORDER}

    # Ground.
    for x in range(W):
        for y in range(H):
            layers["floor"][(x, y)] = GRASS

    # Grass decoration, deterministic so reruns are identical.
    for i in range(W * H):
        x, y = i % W, i // W
        if (x * 7 + y * 13) % 5 == 0:
            layers["texture"][(x, y)] = GRASS_DECOR[(x + y) % len(GRASS_DECOR)]

    # Avenues, then the square on top of them.
    for y in range(3, H - 3):
        for x in V_AVENUE:
            layers["terrain"][(x, y)] = PATH
    for x in range(3, W - 3):
        for y in H_AVENUE:
            layers["terrain"][(x, y)] = PATH
    for axis, fixed, a, b in SPURS:
        for v in range(a, b + 1):
            if axis == "v":
                layers["terrain"][(fixed, v)] = PATH
                layers["terrain"][(fixed + 1, v)] = PATH
            else:
                layers["terrain"][(v, fixed)] = PATH
                layers["terrain"][(v, fixed + 1)] = PATH

    px0, py0, px1, py1 = PLAZA_BOX
    for x in range(px0, px1 + 1):
        for y in range(py0, py1 + 1):
            layers["terrain"][(x, y)] = PLAZA[(x + y) % len(PLAZA)]

    # Buildings and decor.
    def stamp(pf, ox, oy):
        for name, cells in pf["layers"].items():
            target = name if name in layers else "structures"
            for (dx, dy), tid in cells.items():
                layers[target][(ox + dx, oy + dy)] = tid

    spots = {}
    for label, idx, ox, oy in PLACEMENTS:
        pf = prefabs[idx]
        stamp(pf, ox, oy)
        spots[label] = (pf, ox, oy)
    for idx, ox, oy in PROPS + DECOR:
        stamp(prefabs[idx], ox, oy)

    # The border ring, copied rather than invented — it is the one part of
    # the map where "looks about right" is not good enough, because a single
    # gap lets the player walk into the void.
    for (x, y), tid in border.items():
        layers["walls"][(x, y)] = tid

    return layers, spots


# --------------------------------------------------------------------------
# Verification
# --------------------------------------------------------------------------

def solid_set(layers):
    out = set()
    for name in COLLIDERS:
        out |= set(layers[name])
    return out


def reachable(start, solid):
    seen = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        for nb in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if not (0 <= nb[0] < W and 0 <= nb[1] < H):
                continue
            if nb in seen or nb in solid:
                continue
            seen.add(nb)
            q.append(nb)
    return seen


def verify(layers, spawn, spots, npcs, coins):
    solid = solid_set(layers)
    problems = []

    for x in range(W):
        for y in (0, H - 1):
            if (x, y) not in solid:
                problems.append(f"border gap at {x},{y}")
    for y in range(H):
        for x in (0, W - 1):
            if (x, y) not in solid:
                problems.append(f"border gap at {x},{y}")

    if spawn in solid:
        problems.append(f"spawn {spawn} is inside something solid")
        return problems

    seen = reachable(spawn, solid)
    walkable = {
        (x, y) for x in range(W) for y in range(H) if (x, y) not in solid
    }
    stranded = walkable - seen
    if stranded:
        problems.append(
            f"{len(stranded)} walkable tiles unreachable from spawn, "
            f"e.g. {sorted(stranded)[:6]}"
        )

    for name, (x, y) in spots.items():
        if (x, y) in solid:
            problems.append(f"spot {name} at {x},{y} is solid")
        elif (x, y) not in seen:
            problems.append(f"spot {name} at {x},{y} is unreachable")
    for name, (x, y) in npcs.items():
        if (x, y) in solid or (x, y) not in seen:
            problems.append(f"npc {name} at {x},{y} is solid/unreachable")
        # Two clear rows overhead, matching the sprite's height.
        for dy in (1, 2):
            if (x, y - dy) in solid:
                problems.append(f"npc {name} clips scenery at {x},{y - dy}")
    for x in V_AVENUE:
        for y in range(3, H - 3):
            if (x, y) in solid:
                problems.append(f"solid tile on the N-S avenue at {x},{y}")
    for y in H_AVENUE:
        for x in range(3, W - 3):
            if (x, y) in solid:
                problems.append(f"solid tile on the E-W avenue at {x},{y}")

    seen_tiles = set()
    for x, y, _v in coins:
        if (x, y) in solid or (x, y) not in seen:
            problems.append(f"coin {x},{y} is solid/unreachable")
        if (x, y) in seen_tiles:
            problems.append(f"two coins share {x},{y}")
        seen_tiles.add((x, y))
    return problems


# --------------------------------------------------------------------------
# Placements that the Dart side must agree with
# --------------------------------------------------------------------------
#
# These are the numbers `town_spot_models.dart` and `adventure_world_screen`
# carry. They live here too so this script can prove they are valid before
# anyone edits Dart, and they are printed at the end for copying across.
# On the avenue, one tile from the front gate. `town_map_test.dart` requires
# the spawn to be within two tiles of `spot_home` (you start at your door,
# not across town) *and* to have two clear rows overhead, because the
# villager sprite is two tiles tall and drawn upward from its feet. Those
# two rules together rule out standing directly south of the house — the
# house itself would be the thing overhead.
SPAWN = (26, 42)
SPOTS = {
    "spot_store": (11, 14),
    "spot_bank": (37, 13),
    "spot_notice": (32, 24),
    "spot_school": (10, 37),
    "spot_job": (36, 37),
    "spot_home": (27, 42),
}
NPCS = {
    "npc_shopper": (14, 16),
    "npc_taxer": (34, 16),
    "npc_saver": (22, 24),
    "npc_neighbour": (28, 27),
    "npc_student": (13, 27),
    "npc_worker": (33, 27),
}
COINS = [
    (25, 8, 3), (25, 17, 3), (8, 24, 3), (41, 24, 5),
    (25, 31, 5), (18, 24, 3), (25, 44, 5),
]


def render_preview(layers):
    try:
        from PIL import Image
    except ImportError:
        print("  (Pillow not installed — skipping preview)")
        return
    sheet = Image.open(os.path.join(MAPS, "spritesheet.png")).convert("RGBA")
    cols = sheet.size[0] // TS
    img = Image.new("RGBA", (W * TS, H * TS), (0, 0, 0, 0))
    for name in reversed(LAYER_ORDER):  # bottom-up
        for (x, y), tid in layers[name].items():
            r, c = divmod(tid, cols)
            img.alpha_composite(
                sheet.crop((c * TS, r * TS, c * TS + TS, r * TS + TS)),
                (x * TS, y * TS),
            )
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    img.save(PREVIEW)
    print(f"  preview -> {PREVIEW}")


def main() -> None:
    src = load_source()
    g = grids(src)
    solid_layers = [
        L["name"] for L in src["layers"] if L.get("collider")
    ]
    all_layers = [L["name"] for L in src["layers"]]
    prefabs = extract_prefabs(
        g,
        [n for n in solid_layers if n != "walls" and n != "terrain_cliff"],
        all_layers,
    )
    print(f"{len(prefabs)} prefabs lifted from the old map")

    border = {
        (x, y): t
        for (x, y), t in g["walls"].items()
        if x in (0, W - 1) or y in (0, H - 1)
    }
    print(f"border ring: {len(border)} tiles copied")

    layers, _ = compose(prefabs, border)

    problems = verify(layers, SPAWN, SPOTS, NPCS, COINS)
    if problems:
        print("\nLAYOUT REJECTED:")
        for p in problems[:25]:
            print("  -", p)
        sys.exit(1)
    print("layout verified: sealed, fully reachable, all placements valid")

    out = {
        "tileSize": TS,
        "mapWidth": W,
        "mapHeight": H,
        "layers": [
            {
                "name": name,
                **({"collider": True} if name in COLLIDERS else {}),
                "tiles": [
                    {"id": str(tid), "x": x, "y": y}
                    for (x, y), tid in sorted(layers[name].items())
                ],
            }
            for name in LAYER_ORDER
            if layers[name]
        ],
    }
    with open(OUT_MAP, "w", encoding="utf-8") as f:
        json.dump(out, f)
    total = sum(len(layers[n]) for n in layers)
    print(f"wrote {OUT_MAP} ({total} tiles)")

    if "--preview" in sys.argv:
        render_preview(layers)


if __name__ == "__main__":
    main()
