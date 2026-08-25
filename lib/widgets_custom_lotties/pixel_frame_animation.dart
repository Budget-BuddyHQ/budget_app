import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// Plays a numbered PNG sequence as an animation, inside the widget tree.
///
/// **Why this exists.** All of this project's character art — the
/// shopkeeper, the taxer, the customer, the worker — ships as one file per
/// frame rather than as a packed sheet, and the only thing that could
/// animate it was Flame, inside the Bonfire canvas. So every screen outside
/// the map showed a single still frame, and the town interiors read as
/// static illustrations of a game rather than as part of one.
///
/// Frames are precached before the timer starts. Without that the first
/// loop stutters visibly while later frames decode, which on a four-frame
/// idle is most of the animation.
class PixelFrameAnimation extends StatefulWidget {
  const PixelFrameAnimation({
    super.key,
    required this.frames,
    this.frameDuration = const Duration(milliseconds: 170),
    this.loop = true,
    this.onComplete,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
  }) : assert(frames.length > 0, 'an animation needs at least one frame');

  final List<String> frames;
  final Duration frameDuration;

  /// When false the sequence plays once and holds on its last frame.
  final bool loop;

  /// Called once a non-looping sequence reaches the end. Never called for
  /// a looping one.
  final VoidCallback? onComplete;

  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  State<PixelFrameAnimation> createState() => _PixelFrameAnimationState();
}

class _PixelFrameAnimationState extends State<PixelFrameAnimation> {
  int _index = 0;
  Timer? _timer;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) _prepare();
  }

  @override
  void didUpdateWidget(PixelFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Swapping the frame list is how a one-shot is triggered — idle frames
    // out, sell frames in. Restart from the top rather than continuing at
    // whatever index the previous list happened to be on, which could be
    // past the end of the new one.
    if (!listEquals(oldWidget.frames, widget.frames)) {
      _timer?.cancel();
      _index = 0;
      _precached = false;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    _precached = true;
    for (final frame in widget.frames) {
      if (!mounted) return;
      // Failures are swallowed: a missing frame should show the
      // errorBuilder for that one image, not abort the whole animation.
      try {
        await precacheImage(AssetImage(frame), context);
      } catch (_) {
        // Intentionally ignored — see above.
      }
    }
    if (!mounted) return;
    _start();
  }

  void _start() {
    _timer?.cancel();
    if (widget.frames.length < 2) {
      // A single frame is a still image. Starting a timer for it would tick
      // forever for no visible reason.
      widget.onComplete?.call();
      return;
    }
    _timer = Timer.periodic(widget.frameDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _index + 1;
      if (next >= widget.frames.length) {
        if (!widget.loop) {
          timer.cancel();
          widget.onComplete?.call();
          return;
        }
        setState(() => _index = 0);
        return;
      }
      setState(() => _index = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      widget.frames[_index.clamp(0, widget.frames.length - 1)],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      // Nearest-neighbour, always. The default smooths pixel art into mush
      // at the scale factors these get drawn at.
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          SizedBox(width: widget.width, height: widget.height),
    );
  }
}
