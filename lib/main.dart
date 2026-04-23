import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'config/runtime_env.dart';
import 'controllers/adventure_state_controller.dart';
import 'controllers/user_stats_controller.dart';
import 'screens/Gameplay/arcade/bill_dodger.dart';
import 'screens/Gameplay/core/game_canvas.dart';
import 'screens/Gameplay/core/main_game_page.dart';
import 'screens/Gameplay/core/minigames_page.dart';
import 'screens/Gameplay/dashboard/dashboard_shell.dart';
import 'screens/Gameplay/dashboard/leaderboard_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.windows) {
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
  final supabaseUrl = readRuntimeEnv('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = readRuntimeEnv('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint(
      'Supabase credentials were not found in dart-defines or supabase.env.json. The app will fall back to local cached data.',
    );
  }

  await SupabaseService.instance.initialize(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatsController>(
          create: (_) => UserStatsController(
            service: SupabaseService.instance,
          )..initialize(),
        ),
        ChangeNotifierProxyProvider<UserStatsController, AdventureStateController>(
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
        '/dashboard': (context) => const DashboardShell(initialIndex: 0),
        '/game_hub': (context) => const DashboardShell(initialIndex: 1),
        '/customize': (context) => const DashboardShell(initialIndex: 2),
        '/lessons': (context) => const DashboardShell(initialIndex: 3),
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
    final service = SupabaseService.instance;
    return StreamBuilder<AuthState>(
      stream: service.authStateChanges(),
      builder: (context, snapshot) {
        final hasSession =
            snapshot.data?.session != null || service.currentUser != null;
        final controller = context.watch<UserStatsController>();

        if (hasSession && controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return hasSession ? const DashboardShell() : const WelcomeScreen();
      },
    );
  }
}

