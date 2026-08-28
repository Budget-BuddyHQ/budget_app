import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import '../../widgets_custom_lotties/pixel_kit.dart';

/// Registry of things the tutorial can point at.
///
/// **Why a registry rather than coordinates.** A coach mark has to sit over
/// the *real* widget, and where that widget is depends on the screen size,
/// the text scale, the safe area and whatever the player has scrolled to.
/// Hardcoded rectangles are right on exactly one device and wrong everywhere
/// else — which is the failure mode that makes tutorials point at empty space.
///
/// Screens call [register] with a stable id and a `GlobalKey` attached to the
/// widget they want highlighted. The overlay asks for the key's current
/// geometry at the moment it draws, so it tracks reality.
class TutorialTargets {
  TutorialTargets._();

  static final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  /// Associates [id] with [key]. Safe to call repeatedly — a rebuild that
  /// hands over the same key is normal, and a screen re-registering after a
  /// hot reload should win rather than be ignored.
  static void register(String id, GlobalKey key) => _keys[id] = key;

  static void unregister(String id) => _keys.remove(id);

  /// The on-screen rect of one bottom-nav tab.
  ///
  /// Derived from layout rather than from a `GlobalKey`, because
  /// `MainNavigation` keeps all seven screens alive in an `IndexedStack` and
  /// each renders its own bottom bar — so a key per tab ends up attached to
  /// seven widgets at once, which Flutter refuses ("Multiple widgets used the
  /// same GlobalKey") and which took out every Dashboard test when it was
  /// tried.
  ///
  /// This is exact rather than a guess: the bar spans the full width, the tabs
  /// divide it evenly, and its height is a constant the bar itself defines.
  static Rect navTabRect(
    BuildContext context,
    int index, {
    int tabCount = 5,
    double barHeight = 72,
  }) {
    final media = MediaQuery.of(context);
    final width = media.size.width / tabCount;
    final bottom = media.size.height - media.padding.bottom;
    return Rect.fromLTWH(
      width * index,
      bottom - barHeight,
      width,
      barHeight,
    );
  }

  /// Where [id] currently is on screen, or null when that widget is not
  /// mounted right now.
  ///
  /// Null is an ordinary answer, not an error: a step can name a target that
  /// lives on a tab the player has not opened yet, and the overlay handles
  /// that by centring its card instead of pointing at nothing.
  static Rect? rectFor(String id) {
    final context = _keys[id]?.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }
}

/// Punches a hole in a dim scrim so one widget stays lit.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.radius});

  final Rect? hole;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xE6081A12);
    final full = Offset.zero & size;
    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    // Even-odd on a path containing both the screen and the cutout is what
    // makes the hole transparent; drawing the scrim in four rectangles around
    // the target would leave visible seams at the corners.
    final path = Path()
      ..addRect(full)
      ..addRRect(
        RRect.fromRectAndRadius(hole!.inflate(6), Radius.circular(radius)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);

    canvas.drawRRect(
      RRect.fromRectAndRadius(hole!.inflate(6), Radius.circular(radius)),
      Paint()
        ..color = const Color(0xFF85EFAC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.hole != hole || old.radius != radius;
}

/// The in-app guided tour: a spotlight on real UI, not a separate screen.
///
/// **Why this replaced a full-screen deck.** The previous tour was seven
/// pages of description shown before the app appeared — which teaches the
/// *idea* of a feature and never its location. A player who read it still had
/// to find everything afterwards. Pointing at the live widget means the thing
/// being explained is the thing on screen, and the player has already been
/// where it is by the time the tour ends.
///
/// Steps that name a tab switch to it first, so the target is mounted before
/// the spotlight looks for it.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
    required this.onWantTab,
  });

  final List<TutorialStep> steps;

  /// Called once, when the tour ends or is skipped.
  final VoidCallback onFinished;

  /// Asks the host to switch tabs. Awaited so the target has a frame to
  /// mount before the spotlight tries to measure it.
  final Future<void> Function(int tabIndex) onWantTab;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  int _index = 0;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleOnStep());
  }

  TutorialStep get _step => widget.steps[_index];

  /// Moves to the step's tab, waits for it to lay out, then measures.
  ///
  /// The wait is the important part: switching tabs and measuring in the same
  /// frame reads the *old* screen's geometry, so the spotlight would land on
  /// whatever happened to be in that position before.
  Future<void> _settleOnStep() async {
    final tab = _step.jumpTab;
    if (tab != null) {
      await widget.onWantTab(tab);
    }
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    // A registered widget wins; a step that only names a tab falls back to
    // the bar's own geometry. Both are measured, neither is hardcoded.
    final registered = TutorialTargets.rectFor(_step.id);
    setState(() {
      _hole = registered ??
          (tab != null && tab < 5
              ? TutorialTargets.navTabRect(context, tab)
              : null);
    });
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _hole = null;
    });
    _settleOnStep();
  }

  void _back() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _hole = null;
    });
    _settleOnStep();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final hole = _hole;

    // Put the card on whichever side of the target has more room, so it never
    // covers the thing it is describing.
    final targetBottom = hole?.bottom ?? screen.height / 2;
    final showBelow = targetBottom < screen.height * 0.52;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // The scrim swallows taps, so a half-guided player cannot press a
          // button the tour has not explained yet.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(hole: hole, radius: 16),
              ),
            ),
          ),
          if (hole != null)
            Positioned(
              left: (hole.center.dx - 16).clamp(8.0, screen.width - 40),
              top: showBelow ? hole.bottom + 10 : hole.top - 40,
              child: IgnorePointer(
                child: PixelKitIcon(
                  showBelow ? AppAssets.kitArrowUp : AppAssets.kitArrowDown,
                  size: 32,
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            top: showBelow ? null : media.padding.top + 16,
            bottom: showBelow ? media.padding.bottom + 20 : null,
            child: _CoachCard(
              step: _step,
              index: _index,
              total: widget.steps.length,
              onNext: _next,
              onBack: _index == 0 ? null : _back,
              onSkip: widget.onFinished,
            ),
          ),
        ],
      ),
    );
  }
}

/// A text button that takes only the room its label needs.
///
/// Material's defaults — a 64px minimum width, 16px of horizontal padding and
/// a 48px tap target — are right for a screen's primary actions and far too
/// generous for two secondary words sharing a row with a counter and a
/// primary button on a phone.
ButtonStyle _compactText(Color colour) => TextButton.styleFrom(
  foregroundColor: colour,
  padding: const EdgeInsets.symmetric(horizontal: 8),
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final TutorialStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return PixelFrame(
      style: PixelFrameStyle.slate,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buddy, in the pose the step asks for. The mentor is what
              // makes the tour feel like being shown around rather than
              // being read a manual.
              Image.asset(
                step.mascot.asset,
                width: 64,
                height: 64,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => const SizedBox(width: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        color: step.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.tagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.35,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // One bullet, not all of them. The full-screen version listed three
          // per step and nobody reads three bullets standing in front of the
          // thing they describe.
          if (step.bullets.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelKitIcon(AppAssets.kitIconCheck, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.bullets.first,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Flexible, and the first thing to give way. On a 393px phone
              // with the Back button showing, a default-padded TextButton
              // pair plus a 116px Next overflowed this row by 39px — Material
              // buttons carry a 64px minimum and a 48px tap target on top of
              // their padding, so four ordinary-looking children came to
              // 372px inside 333. The counter is also the least important
              // thing here, which is why it is the one that shrinks.
              Flexible(
                child: Text(
                  '${index + 1} / $total',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (onBack != null)
                TextButton(
                  onPressed: onBack,
                  style: _compactText(Colors.white60),
                  child: const Text('Back'),
                ),
              TextButton(
                onPressed: onSkip,
                style: _compactText(Colors.white38),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 6),
              // Up to 104px, less when the row is cramped. A fixed width here
              // still overflowed a 320px phone by 0.8px on the last step —
              // and a rigid primary button is the wrong thing to hold fixed
              // when the alternative is a red overflow banner across it.
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 104),
                  child: PixelButton(
                    label: index == total - 1 ? 'Done' : 'Next',
                    height: 42,
                    onPressed: onNext,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
