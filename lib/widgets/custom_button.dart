import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/app_settings_controller.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 58,
    this.style = const CustomButtonStyle.primary(),
    this.prefixIcon,
    this.suffixIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final CustomButtonStyle style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _isDisabled => widget.isLoading || widget.onPressed == null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (_isDisabled) {
      return;
    }
    _controller.forward();
  }

  void _handleTapEnd([Object? _]) {
    if (_controller.isAnimating || _controller.value > 0) {
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (_isDisabled || widget.onPressed == null) {
      return;
    }
    context.read<AppSettingsController>().playTap();
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.style.borderRadius);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: (_) => _handleTapEnd(),
        onTapCancel: _handleTapEnd,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: _isDisabled ? 0.82 : 1,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.style.gradient,
              color: widget.style.gradient == null
                  ? widget.style.backgroundColor
                  : null,
              borderRadius: borderRadius,
              border: widget.style.border,
              boxShadow: widget.style.boxShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isDisabled ? null : _handleTap,
                borderRadius: borderRadius,
                splashColor: widget.style.splashColor,
                highlightColor: Colors.white.withValues(alpha: 0.04),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.prefixIcon != null && !widget.isLoading) ...[
                          widget.prefixIcon!,
                          const SizedBox(width: 10),
                        ],
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.style.textColor,
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.style.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        if (widget.suffixIcon != null && !widget.isLoading) ...[
                          const SizedBox(width: 10),
                          widget.suffixIcon!,
                        ],
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

class CustomButtonStyle {
  const CustomButtonStyle({
    this.gradient,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
    this.borderRadius = 18,
    this.border,
    this.boxShadow,
    this.splashColor = const Color.fromRGBO(255, 255, 255, 0.1),
  });

  final Gradient? gradient;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Color splashColor;

  const CustomButtonStyle.primary({
    this.gradient = const LinearGradient(
      colors: [Color(0xFF76FF03), Color(0xFFA1EC40)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.backgroundColor = Colors.transparent,
    this.textColor = const Color(0xFF1A4D3D),
    this.borderRadius = 18,
    this.border,
    this.boxShadow = const [
      BoxShadow(
        color: Color.fromRGBO(118, 255, 3, 0.24),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
    this.splashColor = const Color.fromRGBO(255, 255, 255, 0.18),
  });

  const CustomButtonStyle.secondary({
    this.gradient,
    this.backgroundColor = const Color(0xFF2D5A4A),
    this.textColor = const Color(0xFF76FF03),
    this.borderRadius = 18,
    this.border = const Border.fromBorderSide(
      BorderSide(color: Color(0xFF76FF03), width: 1.5),
    ),
    this.boxShadow = const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.14),
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
    this.splashColor = const Color.fromRGBO(118, 255, 3, 0.12),
  });

  const CustomButtonStyle.tertiary({
    this.gradient,
    this.backgroundColor = const Color(0xFF1B3329),
    this.textColor = Colors.white,
    this.borderRadius = 18,
    this.border = const Border.fromBorderSide(
      BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08), width: 1),
    ),
    this.boxShadow = const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.12),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
    this.splashColor = const Color.fromRGBO(255, 255, 255, 0.1),
  });

  const CustomButtonStyle.danger({
    this.gradient = const LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFFF8A65)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
    this.borderRadius = 18,
    this.border,
    this.boxShadow = const [
      BoxShadow(
        color: Color.fromRGBO(255, 107, 107, 0.22),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
    this.splashColor = const Color.fromRGBO(255, 255, 255, 0.16),
  });
}
