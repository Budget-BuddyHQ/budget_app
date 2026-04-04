import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameToast {
  GameToast._();

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData icon = Icons.auto_awesome_rounded,
    Color accent = const Color(0xFF85EFAC),
    Duration duration = const Duration(milliseconds: 2100),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    HapticFeedback.lightImpact();
    _activeEntry?.remove();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _GameToastBanner(
        title: title,
        message: message,
        icon: icon,
        accent: accent,
        duration: duration,
        onDismissed: () {
          if (_activeEntry == entry) {
            _activeEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _GameToastBanner extends StatefulWidget {
  const _GameToastBanner({
    required this.message,
    required this.icon,
    required this.accent,
    required this.duration,
    required this.onDismissed,
    this.title,
  });

  final String? title;
  final String message;
  final IconData icon;
  final Color accent;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_GameToastBanner> createState() => _GameToastBannerState();
}

class _GameToastBannerState extends State<_GameToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(_opacity);

    _controller.forward();
    Future<void>.delayed(widget.duration, () async {
      if (!mounted) {
        return;
      }
      await _controller.reverse();
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slide,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xEE103225),
                          const Color(0xDD173B2D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.accent.withValues(alpha: 0.42),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                        const BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null)
                                Text(
                                  widget.title!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (widget.title != null)
                                const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
