# Budget Buddy Project Guide

## What each main folder is for

`lib/`
The app code lives here.

`lib/screens/`
The actual pages the user sees.

`lib/screens/Gameplay/dashboard/`
Home dashboard, leaderboard, and main tab shell.

`lib/screens/Gameplay/academy/`
The learning pages, unit list, and lesson detail screens.

`lib/screens/Gameplay/core/`
The bigger gameplay pages like the main gameplay home, game hub, and the Flame game canvas.
This folder also now links out to the new stock-trading side mode from the gameplay shell.

`lib/screens/Gameplay/arcade/`
The quicker minigames and challenge screens.
`stock_market_page.dart` now lives here too as the first market-trading prototype.

`lib/screens/auth/`
Login and sign-up flow.

`lib/screens/profile/`
Profile and account settings.

`lib/controllers/`
App state that changes while the user plays.
`user_stats_controller.dart` handles saved player stats.
`adventure_state_controller.dart` handles the adventure/gameplay session state.

`lib/services/`
Data and platform services.
`supabase_service.dart` is the main cloud/local save layer.

`lib/models/`
Plain data structures like lessons, skins, and progression rules.

`lib/components/` and `lib/widgets/`
Reusable UI pieces used across multiple screens.

`lib/game/`
The Flame game world and game components.

`assets/`
Images, turtle skins, map files, and web-game assets.

`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`
Platform-specific Flutter runner files.

## The files you will care about most

`lib/main.dart`
App startup, providers, routes, and Supabase bootstrapping.

`lib/services/supabase_service.dart`
Where loading, saving, auth helpers, and leaderboard fetches happen.

`lib/models/avatar_skin.dart`
The source of truth for turtle skins.
If you want to add another skin, this is the main file to edit.

`lib/screens/Gameplay/customize_screen.dart`
The skin/case UI the player uses.

`lib/models/lesson_data.dart`
All lesson units and lesson order live here.

`lib/screens/Gameplay/academy/lesson_screen.dart`
The main learning page layout.
This now handles both the wide desktop unit sidebar and the compact "Browse Units" sheet for smaller resolutions.

`lib/screens/Gameplay/academy/lesson_detail_screen.dart`
The content shown when a lesson is opened.

`lib/screens/Gameplay/core/main_game_page.dart`
The main gameplay dashboard.
This is where the session cards, adventure launcher, and the new Market Board entry now live.

`lib/screens/Gameplay/core/minigames_page.dart`
The lighter-weight arcade hub.
The copy here was trimmed down so the page reads more like a game menu and less like a long article.

`lib/screens/Gameplay/arcade/stock_market_page.dart`
The new stock side-mode screen.
It uses local simulated prices right now, buy/sell lot actions, and persistent holdings through `UserStatsController`.

`lib/game/budget_buddy_game.dart`
The Flame game root that loads the world, spawns enemies, and controls encounter flow.

`lib/game/components/player_component.dart`
The top-down player rendering and movement logic.

`lib/game/components/enemy_monster_component.dart`
Roaming enemy behavior and respawn timing.

`lib/game/components/grid_world_component.dart`
The fallback world rendering for the adventure map when the tiled map is still incomplete.

`lib/screens/Gameplay/dashboard/leaderboard_screen.dart`
The full leaderboard page.

## How to add a new skin

1. Put the image into `assets/images/turtles/`.

2. Add a new `AvatarSkin(...)` entry in `lib/models/avatar_skin.dart`.
Use:
- `id`: unique key used in saves
- `name`: label shown in the UI
- `assetPath`: file path in assets
- `rarity`: `common`, `rare`, or `epic`
- `accent`: the color used around the card
- `weight`: how often it can drop from a case

3. Make sure the image folder is already listed in `pubspec.yaml`.
This project already includes `assets/images/turtles/`, so most new turtle files will load automatically.

4. Run the app and open Customize.
If the image path is correct, the new skin should appear in the case/customize flow.

## How skins are saved

The selected skin is stored in the user stats data under:
- `spending_habits.equipped_skin`
- `spending_habits.unlocked_skins`

That means the important path is:
`Customize screen -> UserStatsController -> SupabaseService -> user_stats table`

## Supabase note

There is a `supabase.env.json` file in the repo root.
This app also has a fallback key in `lib/main.dart`.
For local desktop work, the JSON file is fine.
For a real mobile release, prefer secure build-time config such as `--dart-define` instead of depending on a loose root file.

## Future custom profile pictures

This is not fully built yet.
Right now the app supports preset turtle skins, not user-uploaded avatars.

The clean future path would be:
1. Upload image to Supabase Storage
2. Save the public/storage path on the user profile
3. Show that uploaded image in the profile/header/leaderboard UI

## Notes on the latest gameplay pass

`Academy responsiveness`
- Wide layouts use a real scrollable unit sidebar again.
- Smaller layouts now get a `Browse Units` button that opens the same navigation in a bottom sheet.
- The horizontal unit chips also scroll, so longer course lists no longer get cut off.

`Main gameplay`
- The Flame world now has a more dressed fallback map with district markers and a visible route.
- Enemies roam instead of sitting still, and defeated enemies respawn with a delay instead of instantly teleporting.
- The player avatar has a stronger animated silhouette so the world feels closer to an RPG prototype.

`Stock side mode`
- Market Board is currently a local simulation, not a live market API.
- Persistent holdings are stored in `UserStats.holdings` using keys like `stock_BBK`.
- Buy/sell actions are handled in `UserStatsController.buyStockLot(...)` and `sellStockLot(...)`.
- If we later wire in real prices, this screen is the main place to swap the quote source.
