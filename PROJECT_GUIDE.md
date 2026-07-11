# Budget Buddy Project Guide

Budget Buddy is a Flutter app for financial-literacy gameplay. The current build combines a polished onboarding and dashboard experience with Supabase-backed progress, animated minigames, avatar customization, and a persistent gameplay shell.

## What this project is

The app currently includes:

- Flutter UI for onboarding, dashboard, academy lessons, profile, and gameplay entry points
- Provider-based state for player stats, adventure progress, and app settings
- Supabase integration for auth, leaderboard reads, stats sync, and profile image storage
- Local fallback behavior for cached user data and offline-safe startup
- Minigames and challenge screens such as Bill Dodger, Budget Challenge, Subscription Sweep, Stock Market, and the React challenge flow
- A growing game shell that uses a persistent bottom navigation bar and tab-preserving navigation

## Where to start

- `lib/main.dart`
  - App entrypoint. Initializes Flutter, window settings, Supabase, Providers, routes, and the app theme.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart`
  - Top-level shell used by the main routes and tab-based navigation.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/main_navigation.dart`
  - Main tab shell. Contains the persistent `IndexedStack` and keeps each tab alive while switching.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart`
  - Main dashboard/home hub, summary panels, and leaderboard preview.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart`
  - Primary gameplay hub with adventure actions and quick navigation.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart`
  - Arcade/minigame launcher and entry flow for standalone play.
- `lib/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart`
  - Academy progression screen and responsive lesson roadmap.
- `lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart`
  - Skin customization flow, unlock/equip logic, and reward-case presentation.
- `lib/screens_minigames_admin_etc/profile/profile_screen.dart`
  - Profile page, account settings, and avatar upload flow.
- `lib/services_backend_and_other_services/supabase_service.dart`
  - Backend/data service for auth, stats, leaderboard access, storage uploads, and caching.
- `lib/controllers_that_updates_stats/user_stats_controller.dart`
  - Main player state controller for progression, skins, sign-in, and syncing.

## Current project structure

### App entry and shell
- `lib/main.dart` — bootstraps the app, providers, routes, and initial screen gate.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/` — dashboard shell, home screen, leaderboard, and main tab navigation.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/` — gameplay hub, game canvas, and arcade lane pages.
- `lib/navigation_tools_and_animation/` — routing helpers, tab index references, and animation utilities.

### Gameplay and learning
- `lib/screens_minigames_admin_etc/Gameplay/academy/` — lesson screens and learning-path UI.
- `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/` — standalone minigames and challenge experiences.
- `lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart` — avatar and cosmetic progression UI.

### State and services
- `lib/controllers_that_updates_stats/` — `UserStatsController`, `AdventureStateController`, and `AppSettingsController`.
- `lib/services_backend_and_other_services/` — Supabase service, audio service, and local/web challenge helpers.
- `lib/models_Like_Skins_and_lessons_templates/` — lessons, skins, and progression-related data models.

### Shared UI and assets
- `lib/custom_made_widgets/` and `lib/widgets_custom_lotties/` — reusable screen widgets and visual helpers.
- `assets/` — images, animations, audio, fonts, imported map art, and game assets.

## Files to learn first

These are the best starting points for new contributors:

- `lib/main.dart` — full app bootstrap and route registration.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart` — top-level shell for the main app experience.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/main_navigation.dart` — core navigation container and tab preservation.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart` — dashboard layout and summary UI.
- `lib/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart` — learning progression and responsive lesson grid.
- `lib/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart` — lesson detail presentation.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart` — main gameplay hub.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart` — minigame launcher.
- `lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart` — cosmetic unlock/equip flow.
- `lib/screens_minigames_admin_etc/profile/profile_screen.dart` — profile and avatar upload flow.
- `lib/services_backend_and_other_services/supabase_service.dart` — the main backend/data layer.
- `lib/controllers_that_updates_stats/user_stats_controller.dart` — shared player state and sync logic.

## Core app patterns

### Provider + ChangeNotifier
The app uses `Provider` for shared app state. `UserStatsController` is the main state holder and screens typically rebuild through `Consumer`, `context.read()`, or `context.watch()`.

### Responsive UI
`LayoutBuilder` is used heavily so the app can adjust for mobile, tablet, and wider layouts. The academy and dashboard screens are designed to be adaptive rather than fixed-width.

### Persistent tab state
The main navigation shell uses `IndexedStack` so screens stay alive when switching tabs. This is important for preserving scroll and state.

### Async UI patterns
`FutureBuilder` and `StreamBuilder` are used where the interface depends on backend or auth state, especially in startup and profile loading flows.

## Feature notes

### Skins and cosmetics
Source of truth: `lib/models_Like_Skins_and_lessons_templates/avatar_skin.dart`

Current flow:
`CustomizeScreen -> UserStatsController -> SupabaseService -> user_stats table`

Stored fields:
- `spending_habits.equipped_skin`
- `spending_habits.unlocked_skins`

To add a new skin:
1. Place the image in `assets/images/turtles/`.
2. Add a new `AvatarSkin(...)` entry in the avatar skin model file.
3. Re-run `flutter pub get` only if you add a new asset folder rather than a new file in an existing one.
4. Open the customize screen and verify it appears and can be equipped.

### Profile photos
Current flow:
`ProfileScreen -> ImagePicker -> SupabaseService.uploadProfileAvatar(...) -> Supabase Storage -> user_stats.spending_habits.profile_image_url`

This keeps the active avatar available immediately in the loaded user model while the profiles table remains the source for account metadata such as role and disabled state.

### Supabase setup
- `supabase.env.json` exists at the repo root for local development.
- The app also provides fallback values in `lib/main.dart`.
- For production, prefer secure env injection or platform secret storage.

## Development notes

Useful commands:
- `flutter pub get`
- `flutter run`
- `flutter analyze`

When working on UI, keep the visual direction consistent with the emerald/aqua/gold palette and the more polished financial-literacy product feel.

## Best practices for contributors

- Prefer updating existing shared widgets over creating one-off UI.
- Keep state changes flowing through the existing controllers rather than scattering logic across screens.
- Preserve existing route names and tab behavior when making navigation changes.
- Treat imported content in `assets/imported/` and `assets/map_assets_coins/` as first-class game art unless a file is confirmed broken.
- If you add new assets, ensure they are declared correctly in `pubspec.yaml`.
