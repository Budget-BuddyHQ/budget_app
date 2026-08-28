# Adventure map

The live map lives here as `map.json` + `spritesheet.png` — this is what
`AdventureWorldScreen`
(`lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart`)
loads at runtime. If `map.json` is missing, the screen shows a "waiting for
your map" placeholder instead of crashing.

`reference/town_preview.png` is just the assembled top-down render of the
current map, kept for visual reference — it's not read by the app.

## Format: Sprite Fusion (not Tiled)

The exported map is **Sprite Fusion** JSON, not Tiled JSON — Bonfire (the
game package this app uses) ships a reader for this format too
(`WorldMapBySpritefusion` + `SpritefusionAssetReader`), so it Just Works
without any conversion. The schema:

```json
{
  "tileSize": 16,
  "mapWidth": 50,
  "mapHeight": 50,
  "layers": [
    { "name": "floor", "tiles": [{ "id": "12", "x": 3, "y": 4 }, ...] },
    ...
  ]
}
```

- `spritesheet.png` **must** be named exactly that and live in this same
  folder — the reader hardcodes the filename.
- Tile `id`s index into the spritesheet left-to-right, top-to-bottom, at
  `tileSize`-px cells (e.g. an 8-column sheet: `row = id ~/ 8`,
  `col = id % 8`).
- Layers stack in listed order; a layer can optionally set `"collider":
  true` to make its tiles solid.

Bonfire's Tiled reader (`WorldMapByTiled` + `TiledAssetReader`) still works
too if you ever export from Tiled instead — just drop a Tiled-exported
`adventure_map.json` (File → Export As → JSON, not Save As; Orthogonal
orientation only) here and swap the reader in
`adventure_world_screen.dart` back.

## How this map is made

`map.json` is **generated** by `tool/make_town_map.py`, not drawn by hand:

```
python tool/make_town_map.py --preview
```

The previous hand-drawn town is kept at `tool/town_v1_source.json` as the
generator's *input*, not as a shipped asset. Nothing in the script draws a
building — it lifts each structure out of that old map as a prefab (the exact
tiles, across the exact layers) and only decides where they stand. So every
building is one somebody actually drew; the layout is the generated part.

The layout is radial: a brick square in the middle, a north-south and an
east-west avenue crossing at it, and the six money-decision buildings placed
around it with short spur lanes joining each door to the nearest avenue.

`reference/town_preview.png` is re-rendered by the same script (`--preview`)
and is not read by the app.

### Editing it

Change `PLACEMENTS`, `PROPS`, `DECOR` or `SPURS` near the top of the script
and re-run. Before writing anything it verifies the map itself — sealed
border, full reachability from spawn, both avenues clear, and every spot /
NPC / coin on a walkable tile — and exits non-zero rather than shipping a
broken town. The tile ids for grass, paths and paving are read off the old
map's own palette, so the art stays consistent.

The spot, NPC, coin and spawn coordinates are duplicated in the script
(`SPOTS`, `NPCS`, `COINS`, `SPAWN`) purely so it can prove they are valid;
the values the app actually uses live in `town_spot_models.dart` and
`kTownSpawnTile`. **If you move a building, update both.**

## Collision

Solid layers are `walls` (the outer ring), `structures`, `Structure Ground`,
`Wall Texturing`, `more Structures` and `structures mre`. `floor`, `terrain`
(paths and paving), `texture` (grass detail) and `inside` (building decor
drawn over the roofs) are walkable.

**The outer ring is copied verbatim from the old map** rather than
re-derived, because it is the one part where "looks about right" is not good
enough — a single gap lets the player walk into the void. `town_map_test.dart`
re-checks it anyway.

`CameraConfig.moveOnlyMapArea` in `adventure_world_screen.dart` is
deliberately left `false`, so standing at the wall still shows a sliver of
empty void past it rather than the camera clamping a tile early — the
collider, not the camera, is what stops the player.

## Building triggers (not wired yet)

Any object/tile layer named for a building/zone (job, school, shop, bank,
home, etc.) could be wired up in code to trigger a Life Sim event when the
player walks into it — Sprite Fusion's `objectsBuilder` mechanism supports
this. The current map's layers (`top_playground`, `playground`,
`structures`, `walls`, `terrain`, `floor`, etc.) aren't named for specific
buildings, so nothing is wired yet. Name a layer for a zone and say which
event it should fire, and it can be added.

## After adding a new file

Register any new subfolder here in `pubspec.yaml` if a tileset image lives
in a nested folder (Flutter does not bundle subfolders recursively), then
do a full restart (not just hot reload) so the asset bundle picks it up.
