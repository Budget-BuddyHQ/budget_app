import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/learning_path_screen.dart';
import '../screens/coin_game.dart';
import 'screens/budget_simulation.dart';
import 'screens/login_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();

  WindowOptions options = const WindowOptions(
    size: Size(1000, 800),
    minimumSize: Size(450, 400),
    center: true,
  );

  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Literacy App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 25, 210, 155),
              Color.fromARGB(255, 96, 170, 36),
              Color.fromARGB(255, 161, 236, 64),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth > 600 ? 48.0 : 24.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 1),

                          // App Icon/Logo - FIXED
                          Center(
                            child: Container(
                              width: constraints.maxWidth > 600 ? 120 : 100,
                              height: constraints.maxWidth > 600 ? 120 : 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color.fromARGB(179, 0, 0, 0),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain, // Changed from cover to contain
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback icon if image doesn't load
                                    return const Center(
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        size: 60,
                                        color: Color.fromARGB(255, 96, 170, 36),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 20 : 12,
                          ),

                          // App Title
                          Text(
                            'Budget Buddy Financial Literacy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: constraints.maxWidth > 600 ? 36 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 10 : 6,
                          ),

                          // Subtitle
                          const Text(
                            'Learn. Play. Grow.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 40 : 20,
                          ),

                          // Feature Cards
                          _buildFeatureCard(
                            icon: Icons.school,
                            title: 'Interactive Lessons',
                            description:
                                'Gamified financial education designed for youth',
                            isCompact: constraints.maxHeight < 700,
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 16 : 10,
                          ),

                          _buildFeatureCard(
                            icon: Icons.lightbulb,
                            title: 'Practical Skills',
                            description:
                                'Real-world money management strategies',
                            isCompact: constraints.maxHeight < 700,
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 16 : 10,
                          ),

                          _buildFeatureCard(
                            icon: Icons.trending_up,
                            title: 'Track Progress',
                            description: 'Watch your financial knowledge grow',
                            isCompact: constraints.maxHeight < 700,
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 40 : 20,
                          ),

                          // Start Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color.fromARGB(
                                255,
                                96,
                                170,
                                36,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: constraints.maxHeight > 700 ? 16 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 700 ? 20 : 12,
                          ),

                          // Login Button
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: constraints.maxHeight > 700 ? 16 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          // Credits
                          const Text(
                            'Developed with ❤️ by the App Team',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: isCompact ? 32 : 40,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 96, 170, 36),
              Color.fromARGB(255, 230, 245, 220),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: constraints.maxWidth > 600 ? 80 : 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome to Budget Buddy!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: constraints.maxWidth > 600 ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth > 600 ? 80 : 20,
                            ),
                            child: const Text(
                              'Your journey to financial literacy starts here. Explore lessons, games, and tools to build practical money skills.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Navigation Buttons
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LearningPathScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Learning'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color.fromARGB(
                                255,
                                96,
                                170,
                                36,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth > 600
                                    ? 48
                                    : 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                          ),

                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CoinCollectorGame(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.code),
                            label: const Text('Mini Game: Coin Collector'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth > 600
                                    ? 48
                                    : 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BudgetSimulationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.sim_card),
                            label: const Text('Budget Simulator'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              backgroundColor: Colors.teal.withOpacity(0.2),
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth > 600
                                    ? 48
                                    : 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// NEW PAGE: Lessons Page
class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Lessons'),
        backgroundColor: const Color.fromARGB(252, 96, 170, 36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(200, 28, 250, 118),
                Colors.lightGreenAccent,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Top header text - FIXED COLOR
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Select one of the following on the list",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(
                        200,
                        100,
                        100,
                        100,
                      ), // FIXED: was (200, 200, 200, 200)
                      fontSize: 18,
                    ),
                  ),
                ),

                // Lesson Cards
                _buildLessonCard(
                  "Lesson 1",
                  "Introduction to Budgeting and Money Management",
                ),
                _buildLessonCard("Lesson 2", "Saving Tips for Beginners"),
                _buildLessonCard(
                  "Lesson 3",
                  "Investing Basics: Start Early for Long-Term Growth", // FIXED: shortened description
                ),

                const SizedBox(height: 30),
                // Game Button - UPDATED to new game
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CoinCollectorGame(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.games),
                    label: const Text('Play Coin Collector Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable lesson card
  Widget _buildLessonCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
