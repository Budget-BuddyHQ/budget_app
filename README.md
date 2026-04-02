# Budget Buddy

Budget Buddy is a Flutter app for financial-literacy gameplay with:

- Flutter UI for onboarding, dashboard, budget, investing, profile, and mini-game launch flows
- A local WebView bridge for the React challenge
- Supabase-backed user stats with local cache fallback
- A simplified gameplay shell built around a persistent bottom navigation bar

## Where to start

- App entry: `lib/main.dart`
- Main tab shell: `lib/screens/Gameplay/dashboard_shell.dart`
- Main home hub: `lib/screens/Gameplay/main_game_page.dart`
- Backend/data layer: `lib/services/supabase_service.dart`
- Shared user state: `lib/controllers/user_stats_controller.dart`

## Team handoff docs

The detailed project map lives here:

- `docs/PROJECT_STRUCTURE.md`

That document explains:

- which folders are active vs legacy/reference
- what each active Dart file does
- what is inside the assets folders
- which platform folders are standard Flutter boilerplate
- which files were deleted during cleanup to reduce confusion
