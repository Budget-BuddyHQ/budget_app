import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/widgets/pop_navbar.dart';

import '../../constants/app_assets.dart';
import '../../widgets_custom_lotties/mentor_image.dart';
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
  /// **This used to be a guess that called itself exact.** It assumed the bar
  /// spanned the full screen width, was 72px tall, and sat flush against the
  /// bottom. The real bar is 80-106px depending on the viewport, inset 14px
  /// each side, and lifted 6-12px off the bottom — so the spotlight was the
  /// wrong size *and* offset on both axes, and drew its box next to the tab it
  /// was pointing at rather than around it.
  ///
  /// The numbers now come from [PopNavBar], which is the widget that owns
  /// them, so there is nothing left here to drift out of step.
  static Rect navTabRect(BuildContext context, int index, {int tabCount = 5}) {
    final media = MediaQuery.of(context);
    return PopNavBar.tabRect(
      media.size,
      media.padding,
      index,
      tabCount: tabCount,
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
    // even-odd on a path holding both the screen and the cutout is what
    // makes the hole see-through. drawing the scrim as four rects round the
    // target leaves visible seams at the corners, tried it
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
    // registered widget wins. a step that only names a tab falls back to the
    // bar's own geometry. both measured, neither hardcoded
    final registered = TutorialTargets.rectFor(_step.id);
    setState(() {
      _hole =
          registered ??
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

  // ---------------------------------------------------------------------
  // Placement, derived from the viewport
  // ---------------------------------------------------------------------
  //
  // **every number below is a fraction of the window, clamped.** the card
  // used to sit at fixed insets (14px from each edge, 48px gap from the
  // spotlight, 460px cap) and fixed pixels mean the card ends up a different
  // *proportion* of the screen on every device — fine on a phone, a thin
  // strip lost in the middle of a 1440px window, squashed on a 320px one.
  // sizing off the viewport makes it the same thing everywhere
  //
  // The clamps are what stop proportion becoming absurd at the extremes: 2%
  // of 1440 is a 29px margin (fine) and 2% of 320 is 6px (too tight), so
  // each fraction has a floor and a ceiling in real pixels.

  /// Side margin: 2.5% of the width, never below 12 or above 40.
  static double _sideInset(Size screen) =>
      (screen.width * 0.025).clamp(12.0, 40.0);

  /// How wide the card may be: 42% of the window, floored at a readable
  /// measure and capped before a line of copy gets too long to scan.
  ///
  /// The fraction is 42% rather than a third because of where the floor sits.
  /// At 34%, a 375px phone and an 834px tablet both landed on the 300px floor
  /// and got an identical card — a "proportional" size that was in practice
  /// fixed across most of the range it was supposed to cover. 42% clears the
  /// floor from tablet width up, so the ramp is real: ~300 on a phone, ~350 on
  /// a tablet, 520 on a desktop.
  static double _cardMaxWidth(Size screen) => (screen.width * 0.42).clamp(
    math.min(300.0, screen.width - 2 * _sideInset(screen)),
    520.0,
  );

  /// The gap between the spotlight and the card: 5% of the height, so the two
  /// stay visually linked on a short window and do not crowd on a tall one.
  static double _spotlightGap(Size screen) =>
      (screen.height * 0.05).clamp(20.0, 72.0);

  /// The breathing room the card keeps from the top and bottom edges.
  static double _screenEdge(Size screen) =>
      (screen.height * 0.02).clamp(10.0, 28.0);

  /// How large the card's contents should be, 0.78 to 1.0.
  ///
  /// Driven by the shorter screen edge because that is what a card competes
  /// for: on a landscape phone the width is generous and the height is not,
  /// and a card sized off width alone covers the app.
  static double _cardScale(Size screen) {
    final shortest = math.min(screen.width, screen.height);
    if (shortest >= 700) return 1.0;
    if (shortest <= 320) return 0.78;
    // Linear between the two, so there is no step where the layout jumps.
    return 0.78 + (shortest - 320) / (700 - 320) * 0.22;
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
              // Sits in the gap the card left, rather than at a fixed 10px:
              // on a tall window that gap is 72px and a 10px offset put the
              // arrow nowhere near the middle of it.
              top: showBelow
                  ? hole.bottom + _spotlightGap(screen) * 0.28
                  : hole.top - _spotlightGap(screen) * 0.62,
              child: IgnorePointer(
                child: PixelKitIcon(
                  showBelow ? AppAssets.kitArrowUp : AppAssets.kitArrowDown,
                  size: 32,
                ),
              ),
            ),
          // Anchored to the spotlight, not to the screen edge.
          //
          // Pinning the card to the top or the bottom works on a phone, where
          // those are a few hundred pixels from anything. On a desktop window
          // it put the explanation in the top-left while the arrow pointed at
          // something 700px lower, and the two stopped reading as one
          // instruction — which is the whole job of a coach mark.
          //
          // Positioned from the card's *measured* height — see
          // [_CardPlacement]. The width is capped and the card centred rather
          // than stretched edge to edge: `left: 14, right: 14` reads fine on a
          // phone and becomes a 930px banner across a desktop window, three
          // words of copy stranded in a field of panel, covering a quarter of
          // the app it is meant to be pointing at. A tour card is a speech
          // bubble; it should be the size of the speech.
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _CardPlacement(
                hole: hole,
                showBelow: showBelow,
                gap: _spotlightGap(screen),
                edge: _screenEdge(screen),
                inset: _sideInset(screen),
                maxWidth: _cardMaxWidth(screen),
                padding: media.padding,
                reserveBottom:
                    PopNavBar.barHeight(screen) + PopNavBar.bottomGap(screen),
              ),
              child: _CoachCard(
                step: _step,
                index: _index,
                total: widget.steps.length,
                // Everything inside scales with the *shorter* screen edge, so
                // a 320px phone gets a smaller mascot and smaller type instead
                // of a card that eats half the viewport, and a landscape phone
                // (short but wide) gets the same treatment.
                scale: _cardScale(screen),
                onNext: _next,
                onBack: _index == 0 ? null : _back,
                onSkip: widget.onFinished,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Places the coach card against the spotlight using its **real** height.
///
/// **Why this is a layout delegate and not a `Positioned`.** It used to be
/// one, with the card's height guessed as `190 * scale`. That number is a
/// constant standing in for something that varies: the height depends on how
/// the title and body wrap, whether a Back button is present, and the text
/// scale the reader has set. Whenever the real card was taller than the
/// guess, the maths that was supposed to keep it clear of the spotlight
/// placed it *over* the spotlight, and the clamp that was supposed to keep it
/// on screen let it run off the bottom.
///
/// A delegate is handed the child's measured size before it has to answer
/// where the child goes, so the estimate disappears. One layout pass, no
/// second frame, no flicker.
///
/// It also lets the card **flip sides** when it genuinely does not fit, which
/// an estimate could not decide: preferring below and finding no room, it
/// tries above rather than clamping into the spotlight.
class _CardPlacement extends SingleChildLayoutDelegate {
  const _CardPlacement({
    required this.hole,
    required this.showBelow,
    required this.gap,
    required this.edge,
    required this.inset,
    required this.maxWidth,
    required this.padding,
    required this.reserveBottom,
  });

  /// The spotlight, or null when this step points at nothing on screen.
  final Rect? hole;
  final bool showBelow;
  final double gap;
  final double edge;
  final double inset;
  final double maxWidth;
  final EdgeInsets padding;

  /// Height at the bottom of the screen the card may never enter.
  ///
  /// The bottom bar, always — not only on the steps that point at it. Every
  /// step avoids its *own* target, which is not the same thing: step six
  /// spotlights something further up the screen, placed itself neatly clear
  /// of that, and clipped the nav bar by four pixels on the way. The bar is
  /// on screen for the whole tour and half the steps talk about it, so it is
  /// a no-go band rather than an obstacle that appears and disappears.
  final double reserveBottom;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final usable = math.max(
      0.0,
      constraints.maxHeight -
          padding.top -
          padding.bottom -
          reserveBottom -
          2 * edge,
    );

    // **The card is capped to the room beside the spotlight, not to the
    // screen.**
    //
    // It used to be free to grow to the full height and `getPositionForChild`
    // then had to put it somewhere; when neither side had room, the fallback
    // dropped it straight on top of the thing it was describing. On a short
    // landscape phone that is exactly what happened — the bottom bar is 80px
    // tall and the card wanted 358 of the 390 available, so there was no
    // "above" to place it in.
    //
    // Capping first means the position is always achievable. A card that has
    // to be shorter is a card with a scrollbar; a card in the wrong place is
    // a tutorial pointing at itself.
    final target = hole;
    if (target == null) {
      return BoxConstraints(
        maxWidth: math.min(maxWidth, constraints.maxWidth - 2 * inset),
        maxHeight: usable,
      );
    }

    final top = padding.top + edge;
    final floor = constraints.maxHeight - padding.bottom - reserveBottom - edge;
    final spaceAbove = target.top - gap - top;
    final spaceBelow = floor - (target.bottom + gap);

    // A floor, because a hole covering nearly the whole screen would
    // otherwise squeeze the card to nothing. At that point some overlap is
    // unavoidable and a readable card is the better trade.
    const minimum = 140.0;
    final available = math.max(spaceAbove, spaceBelow);

    return BoxConstraints(
      maxWidth: math.min(maxWidth, constraints.maxWidth - 2 * inset),
      maxHeight: math.min(usable, math.max(minimum, available)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = (size.width - childSize.width) / 2;
    final top = padding.top + edge;
    final bottom =
        size.height - padding.bottom - reserveBottom - edge - childSize.height;
    final lowest = math.max(top, bottom);

    final target = hole;
    if (target == null) {
      // Nothing to point at, so the card sits where it is most readable:
      // just off centre, high enough to leave the app visible under it.
      return Offset(
        left,
        ((size.height - childSize.height) / 2).clamp(top, lowest),
      );
    }

    final below = target.bottom + gap;
    final above = target.top - gap - childSize.height;
    // The preferred side first, then the other one, then whatever fits.
    final wanted = showBelow
        ? (below <= lowest ? below : (above >= top ? above : below))
        : (above >= top ? above : (below <= lowest ? below : above));
    return Offset(left, wanted.clamp(top, lowest));
  }

  @override
  bool shouldRelayout(_CardPlacement old) =>
      old.hole != hole ||
      old.showBelow != showBelow ||
      old.gap != gap ||
      old.edge != edge ||
      old.inset != inset ||
      old.maxWidth != maxWidth ||
      old.padding != padding ||
      old.reserveBottom != reserveBottom;
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
    this.scale = 1.0,
  });

  final TutorialStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  /// 0.78 on the smallest phones, 1.0 from tablet size up. See
  /// `_CoachMarkOverlayState._cardScale`.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return PixelFrame(
      style: PixelFrameStyle.slate,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        16 * scale,
        16 * scale,
        14 * scale,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 0,
                maxHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Buddy, in the pose the step asks for, wearing the skin the
                      // player has equipped. The mentor is what makes the tour feel
                      // like being shown around rather than being read a manual —
                      // and being shown around by the turtle you picked is better
                      // still. See [MentorImage].
                      MentorImage(
                        pose: step.mascot,
                        size: 64 * scale,
                        errorBuilder: (_, _, _) => SizedBox(width: 64 * scale),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                color: step.accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 17 * scale,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.tagline,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.35,
                                fontSize: 12.5 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
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
                              fontSize: 12 * scale,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 14 * scale),
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
                            height: 42 * scale,
                            onPressed: onNext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
