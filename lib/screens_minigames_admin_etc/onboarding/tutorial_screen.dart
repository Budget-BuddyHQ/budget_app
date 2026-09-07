import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_assets.dart';
import '../../controllers_that_updates_stats/app_settings_controller.dart';
import '../../widgets_custom_lotties/mentor_image.dart';
import '../../models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import '../../services_backend_and_other_services/app_sound_service.dart';
import '../../themes_colors/app_theme.dart';
import '../../widgets_custom_lotties/fitted_label.dart';
import '../../widgets_custom_lotties/idle_hover_icon.dart';

/// The guided tour: Buddy walking a new player through every page in the app.
///
/// **Why a route and not a spotlight overlay.** The obvious version of this
/// highlights real widgets in place with a cut-out mask. That needs a
/// `GlobalKey` on every element it points at, breaks the moment a card moves
/// or a layout reflows at a different width, and this app has already had
/// several rounds of exactly that kind of churn (cards added, tabs moved
/// between the bottom bar and the top strip). A self-contained route says
/// the same things, survives any of that, and can be replayed from Profile
/// without needing the tab it describes to be on screen.
///
/// Returns the tab index the player asked to be dropped on via "Take me
/// there", or null if they finished or skipped normally — see
/// [TutorialScreen.show].
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  /// Pushes the tour and marks it seen on the way out.
  ///
  /// Marking happens here rather than in `dispose` so it covers every exit
  /// — finishing, skipping, and the system back gesture — in one place, and
  /// so it is awaited (a fire-and-forget write in `dispose` can lose the
  /// race against the app being backgrounded straight after).
  ///
  /// Resolves to a tab index when the player used "Take me there", so the
  /// caller can honour it; null otherwise.
  static Future<int?> show(BuildContext context) async {
    final settings = context.read<AppSettingsController>();
    final jumpTo = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => const TutorialScreen(),
        fullscreenDialog: true,
      ),
    );
    await settings.markTutorialSeen();
    return jumpTo;
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _index == kTutorialSteps.length - 1;

  void _go(int next) {
    if (next < 0 || next >= kTutorialSteps.length) return;
    HapticFeedback.lightImpact();
    AppSoundService.play(AppSoundEffect.navigation);
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish({int? jumpTab}) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(jumpTab);
  }

  @override
  Widget build(BuildContext context) {
    final step = kTutorialSteps[_index];

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: Stack(
        children: [
          // The accent wash re-tints as you move between steps, so each
          // feature owns the whole screen rather than just its icon chip.
          AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.65),
                radius: 1.1,
                colors: [
                  step.accent.withValues(alpha: 0.20),
                  AppTheme.deepForest,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              AppAssets.homeTileBackground,
              repeat: ImageRepeat.repeat,
              filterQuality: FilterQuality.none,
              opacity: const AlwaysStoppedAnimation<double>(0.05),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TourHeader(
                  step: _index,
                  total: kTutorialSteps.length,
                  accent: step.accent,
                  onSkip: () => _finish(),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: kTutorialSteps.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _TourPage(step: kTutorialSteps[i]),
                  ),
                ),
                _TourControls(
                  step: step,
                  index: _index,
                  isLast: _isLast,
                  onBack: _index == 0 ? null : () => _go(_index - 1),
                  onNext: _isLast ? () => _finish() : () => _go(_index + 1),
                  onJump: step.jumpTab == null
                      ? null
                      : () => _finish(jumpTab: step.jumpTab),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress pips plus the always-available exit.
///
/// The skip button is a labelled pill rather than a bare "×": a tour that
/// hides its own exit is the reason people distrust tours, and at this size
/// the word costs nothing.
class _TourHeader extends StatelessWidget {
  const _TourHeader({
    required this.step,
    required this.total,
    required this.accent,
    required this.onSkip,
  });

  final int step;
  final int total;
  final Color accent;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    height: 6,
                    width: i == step ? 22 : 6,
                    decoration: BoxDecoration(
                      color: i == step
                          ? accent
                          : Colors.white.withValues(
                              alpha: i < step ? 0.42 : 0.16,
                            ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (i != total - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Skip the tutorial',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSkip();
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One feature, explained: mascot, name, what you do, and why it's here.
class _TourPage extends StatelessWidget {
  const _TourPage({required this.step});

  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: IdleHoverIcon(
              idleAmplitude: 4,
              pulseAmplitude: 0.02,
              period: const Duration(seconds: 4),
              child: MentorImage(
                pose: step.mascot,
                size: 132,
                errorBuilder: (_, _, _) =>
                    Icon(step.icon, size: 96, color: step.accent),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: step.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: step.accent.withValues(alpha: 0.34),
                  ),
                ),
                child: Icon(step.icon, color: step.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedLabel(
                  step.title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.tagline,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (step.whereToFind != null) ...[
            const SizedBox(height: 10),
            _FindItChip(text: step.whereToFind!, accent: step.accent),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            decoration: AppTheme.getPuffyDecoration(
              accent: step.accent,
              fillColor: const Color(0xFF15302A),
              borderRadius: AppTheme.radiusLarge,
              restAlpha: 0.14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < step.bullets.length; i++) ...[
                  if (i != 0) const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: step.accent,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          step.bullets[i],
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            height: 1.38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: step.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, size: 16, color: step.accent),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    step.teaches,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
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

/// "Where do I actually find this" — only rendered for the features whose
/// entry point isn't one of the five bottom tabs.
class _FindItChip extends StatelessWidget {
  const _FindItChip({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.my_location_rounded, size: 13, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back / Take me there / Continue.
///
/// "Take me there" is the reason the tour returns an int: reading about the
/// Market Board and then having to find it yourself is how a tour gets
/// forgotten before it gets used.
class _TourControls extends StatelessWidget {
  const _TourControls({
    required this.step,
    required this.index,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onJump,
  });

  final TutorialStep step;
  final int index;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback? onJump;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onJump != null) ...[
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onJump!();
                },
                icon: Icon(
                  Icons.arrow_outward_rounded,
                  size: 17,
                  color: step.accent,
                ),
                label: Text(
                  'Take me to ${step.title}',
                  style: GoogleFonts.quicksand(
                    color: step.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    side: BorderSide(
                      color: step.accent.withValues(alpha: 0.32),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
          Row(
            children: [
              // Kept mounted but disabled on step one, so the Continue
              // button doesn't jump sideways between the first and second
              // page.
              _BackButton(enabled: onBack != null, onTap: onBack),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryButton(
                  label: isLast ? 'Start playing' : 'Continue',
                  icon: isLast
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  accent: step.accent,
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Previous step',
      child: Opacity(
        opacity: enabled ? 1 : 0.32,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Container(
              height: 52,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white70,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          height: 52,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.puffyShadow(
              accent,
              restAlpha: 0.34,
              blurRadius: 18,
              spreadRadius: -3,
              offset: const Offset(0, 7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedLabel(
                  label,
                  style: GoogleFonts.pixelifySans(
                    color: const Color(0xFF062C21),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: const Color(0xFF062C21), size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
