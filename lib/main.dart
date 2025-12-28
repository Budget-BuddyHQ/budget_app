import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions options = const WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(600, 400), 
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

                          // App Icon/Logo - FIXED AND CENTERED
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
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback if image doesn't load
                                    return const Icon(
                                      Icons.account_balance_wallet,
                                      size: 60,
                                      color: Color.fromARGB(255, 96, 170, 36),
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
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: isCompact ? 32 : 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                                  builder: (context) => const LessonsPage(),
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

                          // New button to learning page
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DartLearningPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.code),
                            label: const Text('Learn Dart & Flutter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
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

// NEW PAGE: Lessons Page (placeholder)
class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Lessons'),
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Financial lessons coming soon!\n\nThis is where you\'ll learn about:\n• Budgeting\n• Saving\n• Investing\n• Credit\n• And more!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

// NEW PAGE: Dart & Flutter Learning Page
class DartLearningPage extends StatelessWidget {
  const DartLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Dart & Flutter'),
        backgroundColor: const Color.fromARGB(255, 96, 170, 36),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildSectionTitle('Welcome to Dart & Flutter! 🎯'),
            _buildSectionText(
              'Dart is the programming language, and Flutter is the framework (toolkit) for building apps. Let\'s learn together!',
            ),
            const SizedBox(height: 30),

            // Lesson 1: Variables
            _buildLessonCard(
              context,
              lessonNumber: '1',
              title: 'Variables & Data Types',
              description: 'Learn how to store and use different types of data',
              icon: Icons.storage,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VariablesLesson(),
                  ),
                );
              },
            ),

            // Lesson 2: Widgets
            _buildLessonCard(
              context,
              lessonNumber: '2',
              title: 'Widgets & UI',
              description:
                  'Everything in Flutter is a widget - let\'s explore!',
              icon: Icons.widgets,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WidgetsLesson(),
                  ),
                );
              },
            ),

            // Lesson 3: Navigation
            _buildLessonCard(
              context,
              lessonNumber: '3',
              title: 'Navigation',
              description: 'Move between pages like a pro',
              icon: Icons.navigation,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NavigationLesson(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 96, 170, 36),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context, {
    required String lessonNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Lesson Number Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    lessonNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(icon, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// LESSON 1: Variables
class VariablesLesson extends StatelessWidget {
  const VariablesLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson 1: Variables'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('What are Variables? 📦'),
            _buildText(
              'Variables are containers that store data. Think of them as labeled boxes where you put information.',
            ),
            const SizedBox(height: 20),

            _buildTitle('Basic Data Types:'),
            _buildCodeExample('''// String - text
String name = 'John';

// int - whole numbers
int age = 15;

// double - decimal numbers
double price = 9.99;

// bool - true/false
bool isStudent = true;'''),

            const SizedBox(height: 20),
            _buildTitle('Try It Yourself! 💪'),
            _buildText(
              'The code above shows 4 common data types. Each variable has a type, a name, and a value.',
            ),

            const SizedBox(height: 20),
            _buildTitle('Key Points:'),
            _buildBullet('Use descriptive names (age, not x)'),
            _buildBullet('End statements with semicolon ;'),
            _buildBullet('Strings use single or double quotes'),
            _buildBullet('Types must match (can\'t put text in an int)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  Widget _buildCodeExample(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Colors.greenAccent,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

// LESSON 2: Widgets
class WidgetsLesson extends StatelessWidget {
  const WidgetsLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson 2: Widgets'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Everything is a Widget! 🧩'),
            _buildText(
              'In Flutter, EVERYTHING you see is a widget. Buttons, text, images, even layouts - all widgets!',
            ),
            const SizedBox(height: 20),

            _buildTitle('Common Widgets:'),
            _buildWidgetExample('Text', 'Displays text', Icons.text_fields),
            _buildWidgetExample(
              'Container',
              'A box that can hold other widgets',
              Icons.square,
            ),
            _buildWidgetExample(
              'Column',
              'Stacks widgets vertically',
              Icons.view_column,
            ),
            _buildWidgetExample(
              'Row',
              'Stacks widgets horizontally',
              Icons.view_week,
            ),
            _buildWidgetExample(
              'ElevatedButton',
              'A clickable button',
              Icons.smart_button,
            ),

            const SizedBox(height: 20),
            _buildTitle('Example Code:'),
            _buildCodeExample('''Column(
  children: [
    Text('Hello'),
    SizedBox(height: 10),
    ElevatedButton(
      onPressed: () {},
      child: Text('Click Me'),
    ),
  ],
)'''),

            const SizedBox(height: 20),
            _buildTitle('Key Concepts:'),
            _buildBullet('child = ONE widget inside'),
            _buildBullet('children = MANY widgets inside (uses [])'),
            _buildBullet('Widgets are nested (widgets inside widgets)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.purple,
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  Widget _buildWidgetExample(String name, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildCodeExample(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Colors.purpleAccent,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

// LESSON 3: Navigation
class NavigationLesson extends StatelessWidget {
  const NavigationLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson 3: Navigation'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Moving Between Pages 🚀'),
            _buildText(
              'Navigation lets you move from one screen to another, like switching pages in a book.',
            ),
            const SizedBox(height: 20),

            _buildTitle('Navigator.push (Go Forward):'),
            _buildCodeExample('''Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NewPage(),
  ),
);'''),

            const SizedBox(height: 20),
            _buildTitle('Navigator.pop (Go Back):'),
            _buildCodeExample('''Navigator.pop(context);'''),

            const SizedBox(height: 20),
            _buildTitle('Try It Now! 👇'),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DemoPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Go to Demo Page',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildTitle('Key Points:'),
            _buildBullet('context = information about where you are'),
            _buildBullet('MaterialPageRoute = Android-style page transition'),
            _buildBullet('builder = function that creates the new page'),
            _buildBullet('Back button automatically added!'),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  Widget _buildCodeExample(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Colors.lightGreenAccent,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

// Demo page for navigation lesson
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Page'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'You Did It! 🎉',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final Uri url = Uri.parse(
                  'https://www.youtube.com/watch?v=1ukSR1GRtMU&list=PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ&index=1',
                );
                if (!await launchUrl(url)) {
                  throw 'Could not launch $url';
                }
              },
              child: const Text(
                'Copy and paste this link for a guide on guide',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'You successfully navigated to a new page!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Go Back', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
