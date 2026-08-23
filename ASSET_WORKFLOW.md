# Asset Workflow

Budget Buddy is using a 2D sprite + UI animation pipeline right now.

## Lottie / ambient decoration

- Put `.json` Lottie files in `assets/animations/`
- Register the folder in `pubspec.yaml`
- Reuse them through [`lib/widgets_custom_lotties/ambient_lottie_card.dart`](lib/widgets_custom_lotties/ambient_lottie_card.dart) (`AmbientLottieCard`)
  — note this widget currently renders the app's own pixel sprites (turtle,
  coin, etc.) with a code-driven bob + orbiting motes rather than actual
  Lottie files, since none have been shipped yet; it's Lottie-*ready*, not
  Lottie-*fed*.
- Current placements:
  - [`lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart`](lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart)
  - [`lib/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart`](lib/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart)

## Character skins and sprite art

- Put turtle/villager PNGs in `assets/images/turtles/` or `assets/own_skins/`
  (skin sheets packed by `tool/pack_skin_sheets.ps1`)
- Register new skins in [`lib/models_Like_Skins_and_lessons_templates/avatar_skin.dart`](lib/models_Like_Skins_and_lessons_templates/avatar_skin.dart)
- Broken or missing skin files should stay out of the registry until the image exists locally

## Game map and world art

- The live Adventure map lives flat in `assets/images/maps/` as `map.json` +
  `spritesheet.png` — see [`assets/images/maps/README.md`](assets/images/maps/README.md)
  for the format (Sprite Fusion, not Tiled — though Tiled exports still work
  too) and how to replace it.
- Loaded and rendered via [`bonfire`](https://pub.dev/packages/bonfire) in
  [`lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart`](lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart)
  (`AdventureWorldScreen`) — that's the game canvas; there's no separate
  `lib/game/` folder.
- Raw third-party tile/sprite packs (not yet cut down into what the app
  actually uses) live under `assets/imported/` — kept there rather than
  under `assets/images/` so it's clear which art is source material versus
  what's actually wired in.

## Sound

- Sound settings are stored in [`lib/controllers_that_updates_stats/app_settings_controller.dart`](lib/controllers_that_updates_stats/app_settings_controller.dart)
- `assets/audio/` is currently **empty** — the previous `.wav` set was
  removed 2026-08-22 to make room for a new set the user is assembling.
  [`lib/services_backend_and_other_services/app_sound_service.dart`](lib/services_backend_and_other_services/app_sound_service.dart)
  (`AppSoundService`) is unaffected either way: sound is off by default, and
  every `play()` call already falls back to a `SystemSound` click/alert on a
  missing or failed asset, so this isn't a broken state.
- When new audio lands: add the file to `assets/audio/` (already registered
  in `pubspec.yaml`, no change needed there unless the folder path changes),
  match it to an existing `AppSoundEffect` case in `_assetPaths`, and it
  will play automatically the next time that effect fires — no other wiring
  needed.

## About "models"

- The current project is not using a 3D model pipeline for gameplay art
- It is image/sprite based today, so the easiest path is adding PNG sprite art first
- One exception: `assets/imported/pond_loading_animation_source/pond.glb`
  is a real `.glb`, used for a specific loading-screen animation — that's
  the one place a 3D asset is already in use, not a green light to add more
  without picking a runtime/format for it first
