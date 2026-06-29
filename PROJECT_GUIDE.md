# Budget Buddy Project Guide

Budget Buddy is a Flutter app for financial-literacy gameplay with:

- Flutter UI for onboarding, dashboard, budget, investing, profile, and mini-game launch flows
- Supabase-backed user stats, auth, leaderboard, avatar storage, and local cache fallback
- A gameplay shell built around a persistent bottom navigation bar and `IndexedStack`
- Responsive layouts using `LayoutBuilder`, adaptive lesson grids, and preserved tab state

## Where to start

- `lib/main.dart`
  - App entrypoint. Initializes Flutter, Supabase, Provider state, routes, and app theming.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/main_navigation.dart`
  - Main tab shell. Contains the `IndexedStack` and keeps each tab alive when switching.
- `lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart`
  - Dashboard/home hub content, summary cards, and leaderboard preview.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart`
  - Main gameplay hub screen. Handles adventure actions, scouting, recovery, and quick navigation.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/game_canvas.dart`
  - Current adventure placeholder screen. This is where the future Flame/Bonfire game will launch.
- `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart`
  - Arcade/minigame launcher and standalone game entrypoint.
- `lib/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart`
  - Academy progression controller. Builds the responsive lesson grid and study roadmap.
- `lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart`
  - Skin and customization flow. Equips avatar skins, opens reward case logic, and updates cosmetics.
- `lib/screens_minigames_admin_etc/profile/profile_screen.dart`
  - Profile page and account settings, including profile photo upload.
- `lib/services_backend_and_other_services/supabase_service.dart`
  - Backend/data service. Manages auth, user stats, leaderboard reads, storage uploads, and local cache.
- `lib/controllers_that_updates_stats/user_stats_controller.dart`
  - Shared user state. Manages player stats, progression, skin equip, sign-in, and sync logic.

## Quick work zones for new contributors

- UI + screens: `lib/screens_minigames_admin_etc/`
- App state / controllers: `lib/controllers_that_updates_stats/`
- Backend + Supabase + storage: `lib/services_backend_and_other_services/`
- Data models, skins, lessons: `lib/models_Like_Skins_and_lessons_templates/`
- Shared widgets: `lib/custom_made_widgets/`, `lib/widgets_custom_lotties/`
- Adventure placeholder / future Flame game: `lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/game_canvas.dart`
- Navigation and routing helpers: `lib/navigation_tools_and_animation/`
- Assets and media: `assets/`

## Project shape

`lib/main.dart`
Bootstraps Flutter, Supabase, Provider state, routes, and the main app theme.

`lib/screens_minigames_admin_etc/`
Contains the app shell, feature tabs, profile, auth, onboarding, and gameplay screens.

`lib/screens_minigames_admin_etc/Gameplay/dashboard/`
Dashboard tab UI plus the home screen, leaderboard preview, and the main tab shell entrypoint.

`lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/`
Adventure and arcade lane pages for the main gameplay shell.

`lib/screens_minigames_admin_etc/Gameplay/academy/`
Learning experience: progression grid, lesson detail flow, and study roadmap.

`lib/screens_minigames_admin_etc/Gameplay/minigames_pages/`
Standalone minigames and arcade experiences.

`lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart`
Skin equip/customize screen, case rolling, and reward presentation.

`lib/screens_minigames_admin_etc/profile/`
Account settings, profile presentation, and profile photo upload.

`lib/controllers_that_updates_stats/`
Provider-backed state objects.
`user_stats_controller.dart` is the main player profile and progression controller.
`adventure_state_controller.dart` owns the active gameplay session state.
`app_settings_controller.dart` handles sound and app preferences.

`lib/services_backend_and_other_services/`
I/O and persistence code.
`supabase_service.dart` handles auth, local caching, leaderboard reads, and profile avatar upload/storage work.
`app_sound_service.dart` handles audio initialization and effects.

`lib/models_Like_Skins_and_lessons_templates/`
Data definitions such as skins, lessons, progression units, and avatar metadata.

`lib/custom_made_widgets/`
Reusable custom widgets such as `UnitRowItem` and other lesson UI components.

`lib/widgets_custom_lotties/`
Shared decorative widgets, custom buttons, toast helpers, and navigation bars.

`lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/game_canvas.dart`
Current adventure placeholder screen for the future Flame/Bonfire game launch.

`lib/navigation_tools_and_animation/`
Navigation helpers, page transitions, route utilities, and tab index definitions.

`assets/`
Images, turtle skins, animations, map files, and audio.

## Files to learn first

`lib/screens_minigames_admin_etc/Gameplay/dashboard/main_navigation.dart`
The tab shell and app navigation entrypoint. This is where the main `IndexedStack` lives.

`lib/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart`
Wraps `MainNavigation` and provides the top-level shell used by `/dashboard`, `/game_hub`, `/customize`, and `/lessons` routes.

`lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart`
Dashboard home and summary panels for the main player hub.

`lib/widgets_custom_lotties/custom_bottom_nav.dart`
The shared professional bottom nav used by the app shell.

`lib/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart`
The academy progression controller. Builds the responsive lesson grid and study roadmap.

`lib/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart`
The lesson detail layout. Decides whether academy content is shown as mobile cards, tablet split view, or desktop sidebar.

`lib/custom_made_widgets/unit_row_item.dart`
The responsive lesson grid. This is where the lesson cards switch between 2, 3, and 4 columns based on width.

`lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart`
Primary gameplay hub screen with actionable adventure controls and quick transitions.

`lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart`
The arcade hub and minigame entry flow.

`lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart`
The skin customization tab and case roll UI.

`lib/screens_minigames_admin_etc/profile/profile_screen.dart`
The current profile page and user avatar upload flow.

`lib/services_backend_and_other_services/supabase_service.dart`
The data layer for stats, leaderboard, auth, profile avatar upload, and Supabase storage interaction.

## Flutter concepts used in this repo

`StatelessWidget` vs `StatefulWidget`
Use `StatelessWidget` when the UI only depends on incoming data.
Use `StatefulWidget` when the screen has its own temporary UI state such as loading flags, selected indexes, or upload progress.

`Provider` + `ChangeNotifier`
This app uses Provider for app-wide state.
`UserStatsController` extends `ChangeNotifier`, and screens rebuild through `Consumer` or `context.read()` / `context.watch()`.

`BuildContext`
`BuildContext` is how a widget finds inherited data above it, like theme values, navigation, or Provider state.
Examples in this app:
- `context.read<UserStatsController>()` for commands
- `Navigator.of(context)` for routing
- `Theme.of(context)` for shared styling

`LayoutBuilder`
This is the main responsive tool in the app.
It gives you the current available width so you can decide between stacked mobile UI and wider tablet/desktop UI.
The academy page, dashboard, and bottom nav all depend on it heavily.

`FutureBuilder`
Used when UI depends on async work such as loading profile metadata from Supabase.
The profile page uses it to check things like admin status and remote avatar data.

`IndexedStack`
The main tab shell uses `IndexedStack` so each tab stays alive when you switch away from it.
That helps keep scroll and state preserved.

## How skins work

Source of truth:
`lib/models_Like_Skins_and_lessons_templates/avatar_skin.dart`

Save path:
`Customize screen -> UserStatsController -> SupabaseService -> user_stats table`

Stored fields:
- `spending_habits.equipped_skin`
- `spending_habits.unlocked_skins`

To add a new skin:
1. Put the image in `assets/images/turtles/`.
2. Add a new `AvatarSkin(...)` entry in `lib/models_Like_Skins_and_lessons_templates/avatar_skin.dart`.
3. Re-run `flutter pub get` only if you added a new asset folder, not just a new file in the existing folder.
4. Open Customize and verify the card appears and can be equipped.

## How profile photos work

Current flow:
`ProfileScreen -> ImagePicker -> SupabaseService.uploadProfileAvatar(...) -> Supabase Storage bucket -> user_stats.spending_habits.profile_image_url`

Why this location exists:
- `spending_habits.profile_image_url` keeps the active avatar available inside the already-loaded `UserStats` model, so UI can update immediately
- The `profiles` table is still used for account metadata such as `role` and `disabled`, but it does not need an `avatar_url` column

If you expand this later:
1. Add image cropping before upload.
2. Add delete/replace support in Storage.
3. Show avatars in leaderboard rows and more dashboard surfaces.

## Supabase notes

`supabase.env.json` exists in the repo root for local work.
There is also a fallback configuration in `lib/main.dart`.

For a real release:
1. Prefer `--dart-define` or platform secret storage.
2. Create the `profile_pictures` storage bucket in Supabase, or set `SUPABASE_PROFILE_IMAGE_BUCKET` to a different bucket name.
3. Add storage policies so authenticated users can upload only their own avatar paths.

## Recent UI direction

The app is moving from a prototype feel to a more polished financial literacy product.
The current direction is:
- cleaner emerald/aqua/gold palette
- denser layouts on small screens
- clearer typography hierarchy
- less empty whitespace
- shared component styling through `custom_button.dart`, `custom_bottom_nav.dart`, and `app_theme.dart`
