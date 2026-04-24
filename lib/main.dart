import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

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

  const supabaseUrl = 'https://cwqjduingvevagrxbwts.supabase.co';
  const supabaseAnonKey = 'sb_publishable_sALqhgaTDGewkqp_XiNo-g_EO6ziR4l';

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
        ChangeNotifierProxyProvider<UserStatsController,
            AdventureStateController>(
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

  Future<bool> _isUserDisabled() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) return false;

    try {
      final response = await client
          .from('profiles')
          .select('disabled')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['disabled'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        if (user == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<bool>(
          key: ValueKey(user.id),
          future: _isUserDisabled(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isDisabled = snap.data == true;

            if (isDisabled) {
              return const _DisabledScreen();
            }

            return const DashboardShell();
          },
        );
      },
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
                await Supabase.instance.client.auth.signOut();
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}