# Asset Workflow

Budget Buddy is using a 2D sprite + UI animation pipeline right now.

## Lottie animations

- Put `.json` Lottie files in `assets/animations/`
- Register the folder in `pubspec.yaml`
- Reuse them through [`lib/widgets/ambient_lottie_card.dart`](lib/widgets/ambient_lottie_card.dart)
- Current placements:
  - [`lib/screens/Gameplay/dashboard/home_screen.dart`](lib/screens/Gameplay/dashboard/home_screen.dart)
  - [`lib/screens/Gameplay/academy/lesson_screen.dart`](lib/screens/Gameplay/academy/lesson_screen.dart)

## Character skins and sprite art

- Put turtle PNGs in `assets/images/turtles/`
- Register new skins in [`lib/models/avatar_skin.dart`](lib/models/avatar_skin.dart)
- Broken or missing skin files should stay out of the registry until the image exists locally

## Game map and world art

- Keep tiled map files in `assets/map/`
- Gameplay/world rendering is wired from the Flame side under `lib/game/`

## Sound

- Sound settings are stored in [`lib/controllers/app_settings_controller.dart`](lib/controllers/app_settings_controller.dart)
- Right now the app uses built-in system click/alert sounds, so there is no separate audio asset folder yet
- If you want custom audio next, a safe next step is `assets/audio/` plus extending the same controller

## About “models”

- The current project is not using a 3D model pipeline
- It is image/sprite based today, so the easiest path is adding PNG sprite art first
- If you want real 3D later, we would need to choose a Flutter-compatible runtime and asset format before downloading `.glb`/`.gltf` files
