import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens_minigames_admin_etc/profile/feedback_screen.dart';
import 'ambient_lottie_card.dart';

/// The occasional, dismissible nudge toward [FeedbackScreen] — distinct from
/// the always-available "Send Feedback" row in Profile. Whether/when to show
/// this is decided by the caller (see `AppSettingsController.isFeedbackPromptDue`
/// and `kFeedbackEnabled`); this widget is just the prompt itself.
class FeedbackPromptSheet {
  FeedbackPromptSheet._();

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedbackPromptSheetContent(),
    );
  }
}

class _FeedbackPromptSheetContent extends StatelessWidget {
  const _FeedbackPromptSheetContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2B20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AmbientLottieCard(
                motif: AmbientMotif.turtle,
                semanticLabel: 'A friendly turtle mascot asking for feedback',
                height: 110,
              ),
              const SizedBox(height: 16),
              Text(
                'Got a sec?',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A quick bug report, idea, or "this part is confusing" '
                'helps more than you\'d think.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FeedbackScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2F9E68),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Send Feedback',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
