# Budget Buddy Project Guide

## Project shape

`lib/main.dart`
Bootstraps Flutter, Supabase, Provider state, routes, and the main app theme.

`lib/screens/`
Screen-level UI. The most important subfolders are:

`lib/screens/Gameplay/dashboard/`
The professional app shell: dashboard, leaderboard, and shared tab navigation.

`lib/screens/Gameplay/core/`
The adventure lane and arcade hub entry points.

`lib/screens/Gameplay/academy/`
The learning experience: unit browser, lesson grid, and lesson detail flow.

`lib/screens/profile/`
Account settings, profile presentation, and profile photo upload entry point.

`lib/controllers/`
Provider-backed state objects.
`user_stats_controller.dart` is the main player profile and progression controller.
`adventure_state_controller.dart` owns the active gameplay session state.

`lib/services/`
I/O and persistence code.
`supabase_service.dart` handles auth, local caching, leaderboard reads, and profile photo upload/storage work.

`lib/models/`
Data definitions such as skins, lessons, and progression rules.

`lib/components/` and `lib/widgets/`
Reusable UI building blocks like the responsive lesson cards, bottom nav, and buttons.

`lib/game/`
The Flame-based adventure code.

`assets/`
Images, turtle skins, animations, map files, and audio.

## Files to learn first

`lib/screens/Gameplay/dashboard/main_navigation.dart`
The tab shell. If you want to change how the main app switches sections, start here.

`lib/widgets/custom_bottom_nav.dart`
The shared professional bottom nav. It now keeps labels visible even on tighter widths.

`lib/screens/Gameplay/academy/lesson_screen.dart`
The academy layout controller. It decides whether the page behaves like a mobile list, tablet layout, or desktop sidebar layout.

`lib/components/unit_row_item.dart`
The responsive lesson grid. This is where the lesson cards switch between 2, 3, and 4 columns.

`lib/screens/Gameplay/core/minigames_page.dart`
The arcade hub. Small screens now use content-sized cards instead of a cramped fixed-height grid.

`lib/screens/profile/profile_screen.dart`
The current profile page, including the upload button for user profile photos.

`lib/services/supabase_service.dart`
The data layer for stats, leaderboard, auth, and profile avatar upload to Supabase Storage.

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
It gives you the current available width so you can decide between stacked mobile UI and wider desktop/tablet UI.
The academy page and bottom nav both depend on it heavily.

`FutureBuilder`
Used when UI depends on async work such as loading profile metadata from Supabase.
The profile page uses it to check things like admin status and remote avatar data.

`IndexedStack`
The main tab shell uses `IndexedStack` so each tab stays alive when you switch away from it.
That is helpful for keeping scroll position and screen state.

## How skins work

Source of truth:
`lib/models/avatar_skin.dart`

Save path:
`Customize screen -> UserStatsController -> SupabaseService -> user_stats table`

Stored fields:
- `spending_habits.equipped_skin`
- `spending_habits.unlocked_skins`

To add a new skin:
1. Put the image in `assets/images/turtles/`.
2. Add a new `AvatarSkin(...)` entry in `lib/models/avatar_skin.dart`.
3. Re-run `flutter pub get` only if you added a new asset folder, not just a new file in the existing folder.
4. Open Customize and verify the card appears and can be equipped.

## How profile photos work

Current flow:
`ProfileScreen -> ImagePicker -> SupabaseService.uploadProfileAvatar(...) -> Supabase Storage bucket -> profiles.avatar_url + spending_habits.profile_image_url`

Why both places exist:
- `profiles.avatar_url` is the clean account-level location for cross-screen profile metadata
- `spending_habits.profile_image_url` keeps the active avatar available inside the already-loaded `UserStats` model, so UI can update immediately

If you expand this later:
1. Add image cropping before upload.
2. Add delete/replace support in Storage.
3. Show avatars in leaderboard rows and more dashboard surfaces.

## Supabase notes

`supabase.env.json` exists in the repo root for local work.
There is also a fallback configuration in `lib/main.dart`.

For a real release:
1. Prefer `--dart-define` or platform secret storage.
2. Create the `profile-images` storage bucket in Supabase.
3. Add storage policies so authenticated users can upload only their own avatar paths.

## Recent UI direction

The app is moving from a prototype feel to a more polished financial literacy product.
The current direction is:
- cleaner emerald/aqua/gold palette
- denser layouts on small screens
- clearer typography hierarchy
- less empty whitespace
- shared component styling through `custom_button.dart`, `custom_bottom_nav.dart`, and `app_theme.dart`
