import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'config/dev_preview_flags.dart';
import 'config/runtime_env.dart';
import 'controllers_that_updates_stats/app_settings_controller.dart';
import 'controllers_that_updates_stats/daily_plan_controller.dart';
import 'controllers_that_updates_stats/money_habit_controller.dart';
import 'controllers_that_updates_stats/user_stats_controller.dart';
import 'navigation_tools_and_animation/app_tab_index.dart';
import 'screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart';
import 'screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart';
import 'screens_minigames_admin_etc/auth/auth_screen.dart';
import 'screens_minigames_admin_etc/auth/set_new_password_screen.dart';
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
        // Was 450x400. Dragging the window narrower than the declared
        // minimum doesn't reflow the framework's layout — it keeps laying
        // out for the minimum and the surplus is simply clipped, which read
        // as "the Market Board breaks on smaller screens" (content cut off
        // on the right, no overflow error anywhere because nothing actually
        // overflowed). Every screen is layout-tested down to 320x568, so the
        // floor can safely sit below the sizes people actually drag to.
        minimumSize: Size(340, 480),
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
        // Rebuilds its plan whenever stats change (a lesson finishes, an
        // arcade run is logged, etc.), so the home checklist always reflects
        // reality.
        ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
          create: (context) =>
              DailyPlanController(context.read<UserStatsController>()),
          update: (_, userStats, previous) =>
              previous ?? DailyPlanController(userStats),
        ),
        // Same shape as DailyPlanController: derives everything from
        // UserStatsController's spendingHabits, no separate persistence.
        ChangeNotifierProxyProvider<UserStatsController, MoneyHabitController>(
          create: (context) =>
              MoneyHabitController(context.read<UserStatsController>()),
          update: (_, userStats, previous) =>
              previous ?? MoneyHabitController(userStats),
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
        // Arcade and Style are no longer bottom tabs (the bar is five slots
        // with Home centred), so these push the screens directly. Each one
        // keeps its own AppBar back button when `onNavSelected` is null,
        // so there is still a way out.
        '/customize': (context) => const CustomizeScreen(),
        '/lessons': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.academy),
        '/main-gameplay': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.adventure),
        '/minigames': (context) => const MinigamesPage(),
        '/daily': (context) =>
            const DashboardShell(initialIndex: AppTabIndex.daily),
        // /life is intentionally full-screen: it's a game with its own exit,
        // not a tab.
        '/life': (context) => const LifeSimPage(),
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

        // Tapping the emailed reset link signs the player in on a recovery
        // session. Without this branch the gate treated that like a normal
        // sign-in and dropped them straight into the dashboard — so the
        // reset flow could never actually change a password. The screen
        // stays up until `updateUser` fires its own event, which replaces
        // this snapshot and falls through to the dashboard below.
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const SetNewPasswordScreen();
        }

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
    return const TemporaryLoadingScreen(message: 'Loading your progress...');
  }
}

class _DisabledScreen extends StatelessWidget {
  const _DisabledScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
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
