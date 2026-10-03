import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_assets.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../themes_colors/app_theme.dart';
import '../../services_backend_and_other_services/supabase_service.dart';
import '../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../widgets_custom_lotties/custom_button.dart';
import '../../widgets_custom_lotties/game_toast.dart';

class _FeedbackCategory {
  const _FeedbackCategory(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

const List<_FeedbackCategory> _categories = [
  _FeedbackCategory('Bug', Icons.bug_report_rounded, Color(0xFFFF8E72)),
  _FeedbackCategory('Idea', Icons.lightbulb_rounded, Color(0xFFF2C66D)),
  _FeedbackCategory('Praise', Icons.favorite_rounded, Color(0xFF9BE870)),
  _FeedbackCategory('Other', Icons.chat_bubble_rounded, Color(0xFF69C6FF)),
];

/// A lightweight way for players to send bug reports, ideas, or praise
/// straight from Profile, without leaving the app.
///
/// Feedback is always saved locally first (see [SupabaseService.submitFeedback])
/// so nothing is lost if the device is offline — it only shows a "sent" state
/// once it's confident the message actually reached the team, otherwise it's
/// honest that it saved locally and will retry.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  int _selectedCategory = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      GameToast.show(
        context,
        title: 'Say a bit more',
        message: 'Add a few words so we know what you mean.',
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFFFF8E72),
      );
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    final stats = context.read<UserStatsController>().stats;
    final user = SupabaseService.instance.currentUser;
    final category = _categories[_selectedCategory].label;

    final sentToServer = await SupabaseService.instance.submitFeedback(
      category: category,
      message: message,
      userId: user?.id ?? stats.id,
      userEmail: user?.email,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    GameToast.show(
      context,
      title: sentToServer ? 'Feedback sent' : 'Saved on this device',
      message: sentToServer
          ? 'Thanks — the team will read this.'
          : 'No connection right now, but it\'s saved and will send later.',
      icon: sentToServer ? Icons.check_circle_rounded : Icons.save_rounded,
      accent: const Color(0xFF9BE870),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.meadowTileBackground,
              repeat: ImageRepeat.repeat,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF111B20).withValues(alpha: 0.72),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Send Feedback',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AmbientLottieCard(
                  motif: AmbientMotif.turtle,
                  semanticLabel: 'A friendly turtle mascot inviting feedback',
                  height: 140,
                ),
                const SizedBox(height: 18),
                Text(
                  'What kind of feedback is this?',
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_categories.length, (index) {
                    final category = _categories[index];
                    final selected = index == _selectedCategory;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? category.accent.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? category.accent.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              color: category.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tell us more',
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 6,
                    minLines: 4,
                    maxLength: 600,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFF9BE870),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      counterStyle: TextStyle(color: Colors.white38),
                      hintText:
                          'A bug you hit, a feature you want, or just how it\'s going.',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: _submitting ? 'Sending...' : 'Send Feedback',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
