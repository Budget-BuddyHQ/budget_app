import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'config/dev_preview_flags.dart';
import 'config/runtime_env.dart';
import 'controllers_that_updates_stats/adventure_state_controller.dart';
import 'controllers_that_updates_stats/app_settings_controller.dart';
import 'controllers_that_updates_stats/daily_plan_controller.dart';
import 'controllers_that_updates_stats/user_stats_controller.dart';
import 'navigation_tools_and_animation/app_tab_index.dart';
import 'screens_minigames_admin_etc/Gameplay/core_bottom_pages/game_canvas.dart';
import 'screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'screens_minigames_admin_etc/Gameplay/minigames_pages/life_board_page.dart';
import 'screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart';
import 'screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart';
import 'screens_minigames_admin_etc/auth/auth_screen.dart';
import 'screens_minigames_admin_etc/loading/temporary_loading_screen.dart';
import 'screens_minigames_admin_etc/onboarding/welcome_screen.dart';
import 'services_backend_and_other_services/app_sound_service.dart';
import 'services_backend_and_other_services/market_data_service.dart';
import 'services_backend_and_other_services/supabase_service.dart';
import 'themes_colors/app_theme.dart';
import 'widgets_custom_lotties/orientation_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations(kAppOrientations);
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      await windowManager.ensureInitialized();
      const options = WindowOptions(
        size: Size(1000, 800),
        minimumSize: Size(450, 400),
        center: true,
      );

      windowManager.waitUntilReadyToShow(options, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (error) {
      debugPrint('Window manager failed: $error');
    }
  }

  // No hardcoded fallback on purpose: real credentials belong only in
  // supabase.env.json (gitignored, see supabase.env.json.example) or in
  // SUPABASE_URL / SUPABASE_ANON_KEY environment variables. If neither is
  // set, SupabaseService.initialize() detects the empty values and runs the
  // app in local-only mode instead of silently using a baked-in key.
  final supabaseUrl = readRuntimeEnv('SUPABASE_URL') ?? '';
  final supabaseAnonKey = readRuntimeEnv('SUPABASE_ANON_KEY') ?? '';
  final profileImageBucket = readRuntimeEnv('SUPABASE_PROFILE_IMAGE_BUCKET');

  await SupabaseService.instance.initialize(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
    profileImageBucket: profileImageBucket,
  );
  await AppSoundService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsController>(
          create: (_) => AppSettingsController()..initialize(),
        ),
        ChangeNotifierProvider<MarketDataService>(
          // Lazily constructed: with no FINNHUB_API_KEY this never makes a
          // network call, so the app runs fine with zero configuration.
          create: (_) => MarketDataService(),
        ),
        ChangeNotifierProvider<UserStatsController>(
          create: (_) =>
              UserStatsController(service: SupabaseService.instance)
                ..initialize(),
        ),
        ChangeNotifierProxyProvider<
          UserStatsController,
          AdventureStateController
        >(
          create: (_) => AdventureStateController(),
          update: (_, userStats, adventure) =>
              (adventure ?? AdventureStateController())
                ..attachUserStats(userStats),
        ),
        // Rebuilds its plan whenever stats change (a lesson finishes, an
        // arcade run is logged, etc.), so the home checklist always reflects
        // reality.
        ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
          create: (context) =>
              DailyPlanController(context.read<UserStatsController>()),
          update: (_, userStats, previous) =>
              previous ?? DailyPlanController(userStats),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Buddy - Financial Literacy Gaming',
      theme: AppTheme.getLightTheme(),
      debugShowCheckedModeBanner: false,
      home: const _AppBootstrapGate(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const AuthScreen(mode: AuthMode.signUp),
        '/login': (context) => const AuthScreen(mode: AuthMode.login),
        '/game': (context) => const DashboardShell(),
        '/dashboard': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.dashboard),
        '/game_hub': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.adventure),
        '/customize': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.customize),
        '/lessons': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.academy),
        '/game-canvas': (context) => const GameCanvas(),
        '/main-gameplay': (context) => const MainGamePage(),
        '/life-board': (context) => const LifeBoardPage(),
        '/minigames': (context) => const MinigamesPage(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}

class _AppBootstrapGate extends StatelessWidget {
  const _AppBootstrapGate();

  @override
  Widget build(BuildContext context) {
    if (kDevSkipAuthGate) {
      return const DashboardShell();
    }

    final service = SupabaseService.instance;
    return StreamBuilder<AuthState>(
      stream: service.authStateChanges(),
      builder: (context, snapshot) {
        final user = service.currentUser;

        if (user == null) {
          if (!service.isSupabaseConnected) {
            return const DashboardShell();
          }
          return const WelcomeScreen();
        }

        return FutureBuilder<bool>(
          key: ValueKey(user.id),
          future: service.isCurrentUserDisabled(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const TemporaryLoadingScreen(
                message: 'Checking account...',
              );
            }

            final isDisabled = snap.data == true;

            if (isDisabled) {
              return const _DisabledScreen();
            }

            return Consumer<UserStatsController>(
              builder: (context, controller, _) {
                if (controller.isLoading) {
                  return const _AdventureSaveLoadingScreen();
                }
                return const DashboardShell();
              },
            );
          },
        );
      },
    );
  }
}

class _AdventureSaveLoadingScreen extends StatelessWidget {
  const _AdventureSaveLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const TemporaryLoadingScreen(
      message: 'Loading your adventure save...',
    );
  }
}

class _DisabledScreen extends StatelessWidget {
  const _DisabledScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your account has been disabled.\nContact support.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await SupabaseService.instance.signOut();
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
