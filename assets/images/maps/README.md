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

## Collision

`walls`, `Wall Texturing`, `structures`, `structures mre`, `more
Structures`, and `Structure Ground` are the layers marked `"collider":
true` — every other layer (`floor`, `terrain`, `playground`,
`top_playground`, `inside`) is walkable. **The outer ring (x=0, x=49, y=0,
y=49 — the rock border) is fully solid with zero gaps**, verified directly
against the tile data (not just visually): the player cannot reach open
space beyond the map edge. `CameraConfig.moveOnlyMapArea` in
`adventure_world_screen.dart` is deliberately left `false`, so standing at
the wall still shows a sliver of empty void past it rather than the camera
clamping a tile early — the collider (not the camera) is what stops the
player, same as any open-world map.

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
