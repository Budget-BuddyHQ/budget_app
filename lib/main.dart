import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'config/runtime_env.dart';
import 'controllers/adventure_state_controller.dart';
import 'controllers/app_settings_controller.dart';
import 'controllers/user_stats_controller.dart';
import 'navigation/app_tab_index.dart';
import 'screens/Gameplay/arcade/bill_dodger.dart';
import 'screens/Gameplay/core/game_canvas.dart';
import 'screens/Gameplay/core/main_game_page.dart';
import 'screens/Gameplay/core/minigames_page.dart';
import 'screens/Gameplay/dashboard/dashboard_shell.dart';
import 'screens/Gameplay/dashboard/leaderboard_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'services/app_sound_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }


    } catch (error) {
      debugPrint('Window manager failed: $error');

  const fallbackSupabaseUrl = 'https://cwqjduingvevagrxbwts.supabase.co';
  const fallbackSupabaseAnonKey =
      'sb_publishable_sALqhgaTDGewkqp_XiNo-g_EO6ziR4l';
  final supabaseUrl = readRuntimeEnv('SUPABASE_URL') ?? fallbackSupabaseUrl;
  final supabaseAnonKey =
      readRuntimeEnv('SUPABASE_ANON_KEY') ?? fallbackSupabaseAnonKey;
  await SupabaseService.instance.initialize(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );
  await AppSoundService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsController>(
          create: (_) => AppSettingsController()..initialize(),
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
        '/minigames': (context) => const MinigamesPage(),
        '/bill-dodger': (context) => const BillDodgerScreen(),
        '/bill_dodger': (context) => const BillDodgerScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}

class _AppBootstrapGate extends StatelessWidget {
  const _AppBootstrapGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      builder: (context, snapshot) {
        }

      },
    );
  }
}

}
