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
| `FINNHUB_API_KEY` | **optional** | Powers the live "Real Market Today" panel. Leave blank and the panel hides itself; the game's simulated market is unaffected. Free key: https://finnhub.io/register |

Values can also come from real environment variables of the same name, which
take priority over the JSON file (useful for CI).

**Teammates need no keys to run the app.** Everything degrades gracefully:
missing Supabase → local-only mode; missing Finnhub → live panel hidden. Clone,
`flutter pub get`, `flutter run`.
