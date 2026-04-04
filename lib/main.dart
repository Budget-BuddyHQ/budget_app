import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/user_stats_controller.dart';
import 'screens/Gameplay/bill_dodger.dart';
import 'screens/Gameplay/dashboard_shell.dart';
import 'screens/Gameplay/leaderboard_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
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

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );



  await SupabaseService.instance.initialize(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider<UserStatsController>(
      create: (_) => UserStatsController(
        service: SupabaseService.instance,
      )..initialize(),
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
    return FutureBuilder<String?>(
      future: SupabaseService.instance.getActiveSessionUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }
        return snapshot.data == null
            ? const WelcomeScreen()
            : const DashboardShell();
      },
    );
  }
}

