// lib/screens/get_started_page.dart
import 'dart:ui';
import 'package:budget_app/screens/goals_setup_page.dart';
import 'package:flutter/material.dart';
import 'get_started_notifications_page.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  bool _showParentEmail = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();

  DateTime? _selectedBirthday;

  static const Color deepForest = Color(0xFF1B3329);
  static const Color limeAccent = Color(0xFF76FF03);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentEmailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;

    final now = DateTime.now();
    int age = now.year - birthday.year;

    if (
      now.month < birthday.month ||
      (now.month == birthday.month && now.day < birthday.day)
    ) {
      age--;
    }

    return age;
  }
  
  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 13, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: limeAccent,
              surface: Color(0xFF1F3A2F),
              onSurface: Colors.white, // ✅ fixes main text color
            ),

            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1B3329),
            ),

            inputDecorationTheme: InputDecorationTheme(
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: limeAccent.withValues(alpha: 0.6)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: limeAccent),
              ),
            ),

            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
  final age = _calculateAge(picked);

  setState(() {
    _selectedBirthday = picked;
    _showParentEmail = age != null && age < 13;
  });
}
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  void _handleContinue() {
    final nickname = _nameController.text.trim();
    final parentEmail = _parentEmailController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what we should call you.')),
      );
      return;
    }

    if (_selectedBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your birthday.')),
      );
      return;
    }

    final age = _calculateAge(_selectedBirthday);
    if (age == null || age < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid birthday.')),
      );
      return;
    }

    if (_showParentEmail) {
      if (parentEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a parent/guardian email.'),
          ),
        );
        return;
      }

      if (!_isValidEmail(parentEmail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid parent/guardian email.'),
          ),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GetStartedNotificationsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curve, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(_selectedBirthday);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, Color(0xFF2E4A3D), Color(0xFF0F2018)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedItem(
                      0,
                      Center(
                        child: Container(
                          height: 92,
                          width: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: limeAccent.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: limeAccent.withValues(alpha: 0.18),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: limeAccent,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      1,
                      const Text(
                        'Get Started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildAnimatedItem(
                      2,
                      Text(
                        'Let’s personalize your Budget Buddy experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildAnimatedItem(
                      3,
                      _buildSectionLabel('What should we call you?'),
                    ),
                    const SizedBox(height: 10),

                    _buildAnimatedItem(
                      4,
                      _buildGlassTextField(
                        controller: _nameController,
                        label: 'Enter your name or nickname',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      5,
                      _buildSectionLabel('Enter your birthday'),
                    ),
                    const SizedBox(height: 10),

                    _buildAnimatedItem(
                      6,
                      _buildDateField(),
                    ),

                    if (_selectedBirthday != null) ...[
                      const SizedBox(height: 10),
                      _buildAnimatedItem(
                        7,
                        Text(
                          age == null
                              ? ''
                              : 'Age detected: $age ${age == 1 ? "year" : "years"} old',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    if (_showParentEmail) ...[
  const SizedBox(height: 24),
  _buildAnimatedItem(
    8,
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: limeAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        'Since you are under 13, please enter a parent or guardian email below.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    ),
  ),
  const SizedBox(height: 14),
  _buildAnimatedItem(
    9,
    _buildGlassTextField(
      key: const ValueKey('parent_email'),
      controller: _parentEmailController,
      label: 'Parent/Guardian Email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
    ),
  ),
],

                    const SizedBox(height: 32),

                    _buildAnimatedItem(
                      10,
                      ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeAccent,
                          foregroundColor: deepForest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: limeAccent.withValues(alpha: 0.45),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDateField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickBirthday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedBirthday == null
                          ? 'Select your birthday'
                          : _formatDate(_selectedBirthday!),
                      style: TextStyle(
                        color: _selectedBirthday == null
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_month, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(index * 0.08, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassTextField({
  Key? key,
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            key: key,
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}