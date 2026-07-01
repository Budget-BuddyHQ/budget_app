# Project context

- Main app entry: lib/main.dart
- Main navigation shell: lib/screens_minigames_admin_etc/Gameplay/dashboard/main_navigation.dart
- Home/dashboard: lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart
- Gameplay hub: lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart
- Minigames hub: lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart
- Academy flow: lib/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart
- Customize screen: lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart
- Profile screen: lib/screens_minigames_admin_etc/profile/profile_screen.dart
- Backend/service layer: lib/services_backend_and_other_services/supabase_service.dart
- Shared state: lib/controllers_that_updates_stats/user_stats_controller.dart
- Skin definitions: lib/models_Like_Skins_and_lessons_templates/avatar_skin.dart
- Current valid skin assets live under assets/images/turtles/
- Only use existing asset files when adding or editing skins; avoid references to removed files.
