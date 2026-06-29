# Game Canvas Integration Outline

This outline describes the files needed to integrate Bonfire into the existing `game_canvas.dart` screen.

## Install Bonfire
1. Open `pubspec.yaml`
2. Add `bonfire: ^0.43.0` under `dependencies`
3. Run `flutter pub get`

## Files

### `lib/game_canvas/game_canvas.dart`
- Main Bonfire integration screen.
- Loads the current user stats from `UserStatsController`.
- Uses `BonfireWidget` with `WorldMapByTiled`.
- Adds standard Flutter HUD overlays via `Stack`.
- Passes equipped skin, level, and gold into a player component.

### `lib/game_canvas/player/player.dart`
- Defines `AdventurePlayer` extending `SimplePlayer`.
- Provides sprite animation setup from a `SpriteSheet`.
- Accepts `AvatarSkin skin`, `int gold`, and `int level`.
- Loads the player animation based on the equipped skin string.

### `lib/game_canvas/maps/starter_village.tmx`
- Tiled map file for the starter village.
- Uses a simple grass floor and collision layer.
- Placed in `assets/map/` or `assets/tiled/`.

### `lib/game_canvas/maps/tiles.png`
- Tile set image referenced by the `.tmx` file.
- Used for map floor and walls.

### `lib/game_canvas/skins/`
- Store sprite sheets for each skin.
- Example:
  - `classic_turtle_spritesheet.png`
  - `guild_runner_spritesheet.png`

### `lib/game_canvas/README.md`
- Integration guide for the game canvas.
- Explains where to place new Tiled assets.
- Notes on skin swapping logic.

## Skin swapping logic
- Use `equipped_skin` from `UserStatsController`.
- In the player constructor, choose the correct `SpriteSheet` path:
  - `Classic Turtle` => `assets/images/turtles/classic_turtle_spritesheet.png`
  - `Guild Runner` => `assets/images/turtles/guild_runner_spritesheet.png`
- Load the correct `SpriteAnimation` from the chosen sheet.

## HUD
- Build HUD widgets with standard Flutter.
- Place them over `BonfireWidget` using `Stack`.
- Example items:
  - gold counter
  - level display
  - back button

## Notes
- Bonfire includes Flame, so no separate Flame dependency is required.
- `.tmx` map files require Tiled.
- Keep the new files under `lib/game_canvas/` to separate them from existing app UI.
