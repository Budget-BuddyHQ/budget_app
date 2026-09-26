# Asset & config tooling

Scripts that regenerate build artifacts. **Run under Windows PowerShell 5.1**,
not `pwsh` 7 — 7 doesn't ship `System.Drawing`. Each script prints the exact
command in its header; the short form is:

```
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File tool\<script>.ps1
```

## Villager sprite pipeline

Run in this order after changing the hand-drawn sheets in `assets/own_skins/`:

1. `crop_human_skins.ps1` — slices the raw sheets into per-frame PNGs under
   `assets/images/humans/` (south/north/west + mirrored east).
2. `make_female_bases.ps1` — edits the hair silhouette to create the feminine
   body under `assets/images/humans/female/`. This is a real pixel edit, not a
   recolour.
3. `make_human_variants.ps1` — palette-swaps both bodies into the colour
   variants (emerald_scout, gold_banker, …).
4. `pack_skin_sheets.ps1` — packs everything into the shipped sprite sheets in
   `assets/self_made_skins/` (one 8×4 grid per body+variant).

**Only `assets/self_made_skins/` ships.** The intermediate frames in
`assets/images/humans/` are gitignored build artifacts — don't commit them.
`test/assets_test.dart` fails if a sheet is missing or the wrong size.

## Config / secrets

Runtime config lives in `supabase.env.json` (gitignored). Copy the template and
fill in your own values:

```
cp supabase.env.json.example supabase.env.json
```

| Key | Required? | Notes |
| --- | --- | --- |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | for login/leaderboard | Without them the app runs in local-only mode. |
| `SUPABASE_PROFILE_IMAGE_BUCKET` | optional | Defaults to `profile_pictures`. |
| `FINNHUB_API_KEY` | **optional** | Powers real-stock quotes and symbol search on the Market Board. Leave blank and the board asks for a key instead of a trade list; the rest of the app is unaffected. Free key: https://finnhub.io/register |
| `TWELVE_DATA_API_KEY` | **optional** | Powers chart timeframes (1D/5D/1M/3M/1Y) and candlestick bars on the order ticket. Finnhub moved historical candles to a paid plan, so this comes from Twelve Data instead. Without it the chart falls back to quote-derived prices. Free key (800 req/day): https://twelvedata.com/pricing |

Values can also come from real environment variables of the same name, which
take priority over the JSON file (useful for CI).

**Teammates need no keys to run the app.** Everything degrades gracefully:
missing Supabase → local-only mode; missing Finnhub → live panel hidden. Clone,
`flutter pub get`, `flutter run`.

### Building for a phone (or the web) with your keys baked in

`supabase.env.json` only works on desktop `flutter run` — a filesystem read.
**Android, iOS, and web builds cannot read it at all** (no `Platform.environment`,
no filesystem access on web; both silently return nothing on device, which is
why login/Market Board don't work on a phone build that skips this step).
Those platforms only ever see keys baked in at *compile time* via
`--dart-define`. Bake in the same `supabase.env.json` you already have,
in one shot, with `--dart-define-from-file`:

```
flutter build apk --dart-define-from-file=supabase.env.json
flutter run --dart-define-from-file=supabase.env.json   # debug run on a device/emulator
flutter build web --dart-define-from-file=supabase.env.json
```

No per-key `--dart-define=KEY=value` flags needed — the JSON file's keys
(`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `FINNHUB_API_KEY`, `TWELVE_DATA_API_KEY`)
are read straight out of it. See `lib/config/runtime_env_defines.dart` for how
each key is wired into a real `String.fromEnvironment` constant, and
`docs/ARCHITECTURE.md` §20 for the full root-cause writeup.

## Placing town markers

`place_town_spots.py` and `assign_town_buildings.py` snapped each marker to "a
tile touching any six solid tiles". A tree is nine solid tiles and a rope fence
is nineteen, so they put a cafe beside an oak and a library on the end of a
fence, and the second town's buildings are painted into the ground and are not
solid at all. Do not use them to place markers any more.

The markers are placed by looking:

1. Render the map with every marker drawn in (any script that composites the
   layers of `assets/images/maps/*.json` over `spritesheet.png` will do).
2. Put each marker on the **doorstep** of the building it is for: the walkable
   tile straight below the door, not the door itself (that is solid) and not a
   tile beside a tree, a bush or a fence.
3. Set `tileX/tileY` (first town) and `tileX2/tileY2` (second town) in
   `town_spot_models.dart`, and put the door tile in
   `test/support/town_landmarks.dart`.

`test/town_layout_test.dart` then checks that every marker is walkable and
reachable, one tile from its landmark, that the landmark is not scenery, that no
two markers share a building and that none is within three tiles of another.
The spawn is two tiles south of the house's marker (`townSpawnTile`).
