# Adventure map

## `pending_export/`
Your first map export landed here (`map (1).png` + `loading_screen/map.json` +
`loading_screen/spritesheet.png`), but `map.json` is **not Tiled JSON** — it's
a custom `{tileSize, mapWidth, mapHeight, layers}` schema from whatever tool
made it, missing the `orientation`/`tilesets` fields Bonfire's `TiledAssetReader`
needs. It won't load as-is. Re-export from Tiled as JSON (see Format below) and
drop the real `adventure_map.json` directly in this folder, or say the word and
I'll write a small converter for this schema instead.


Drop your exported map here as `adventure_map.json`, plus whatever tileset
image(s) it references, in this same folder. `AdventureWorldScreen`
(`lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart`)
checks for `assets/images/maps/adventure_map.json` at runtime — if it's not
there yet, the screen shows a "waiting for your map" placeholder instead of
crashing; the moment the file exists (and the app is rebuilt), it loads for real.

## Format

Bonfire reads **Tiled JSON**, not the raw `.tmx` XML file — in Tiled, use
**File → Export As → JSON**, not "Save As". A `.tmx` dropped here as-is will
not load.

- Orientation must be **Orthogonal** (Tiled's default) — Bonfire only
  supports that.
- Any object layer named for a building/zone (job, school, shop, bank, home,
  etc.) can be wired up in code to trigger a life-sim event when the player
  walks into it — tell me the layer/object names you used and I'll wire the
  triggers.
- Tile pixel size is read directly from the map file, so a 50x50-**tile**
  grid works at whatever tile pixel size you used (16px, 32px, etc.) with no
  code changes.

## After adding the file

Register any new subfolder here in `pubspec.yaml` if your tileset image
lives in a nested folder (Flutter does not bundle subfolders recursively —
see the `assets:` section), then do a full restart (not just hot reload) so
the asset bundle picks it up.
