import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/privacy_policy.dart';
import '../../widgets_custom_lotties/game_toast.dart';

/// A one-time acknowledgment shown before a player enters guest mode.
///
/// Deliberately lighter than the full sign-up `_TermsCard` -- a guest is not
/// handing over an email address or a password, so a single "Continue"
/// button rather than a required checkbox is enough here. It only shows
/// once per device: a returning guest never sees the welcome screen again
/// (see `_AppBootstrapGate`), so there is nothing extra to persist beyond
/// the existing privacy-acceptance record `continueAsGuest` already writes.
class GuestTermsSheet {
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GuestTermsSheetContent(),
    );
  }
}

class _GuestTermsSheetContent extends StatelessWidget {
  const _GuestTermsSheetContent();

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      // See the identical comment in auth_screen.dart's _openPrivacyPolicy:
      // web always opens external links via `window.open` in a new tab
      // regardless of `mode`, and desktop browsers block that unless it is
      // perfectly synchronous with the click -- mobile is lenient about it,
      // which is why this worked on phone but not on desktop with a mouse.
      // `_self` navigates the current tab instead, which is never blocked.
      webOnlyWindowName: '_self',
    );
    if (!opened && context.mounted) {
      GameToast.show(
        context,
        title: 'Could not open the policy',
        message: kPrivacyPolicyUrl,
        icon: Icons.link_off_rounded,
        accent: const Color(0xFFFFC36B),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2C33),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Playing as a guest',
                style: GoogleFonts.pixelifySans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your progress is saved on this device only -- no email, no '
                'password. You can create an account any time from Profile '
                'to keep it if you get a new device.',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _openPrivacyPolicy(context),
                child: Text(
                  'Read the Budget Buddy Privacy Policy ($kPrivacyPolicyDate)',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9BE870),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3CCB74),
                    foregroundColor: const Color(0xFF131F24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
