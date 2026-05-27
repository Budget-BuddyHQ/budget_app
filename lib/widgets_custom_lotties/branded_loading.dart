import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BrandedLoading extends StatelessWidget {
  const BrandedLoading({
    super.key,
    this.message,
    this.compact = false,
    this.assetPath = dotsAsset,
  });

  static const String dotsAsset =
      'assets/animations/12c4e8c6-bd8a-426e-aba9-55bd62c7688f.json';
  static const String successAsset =
      'assets/animations/62c35559-ef30-401e-a52e-2ba5c16b743c.json';

  final String? message;
  final bool compact;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 88.0;
    final label = message;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              assetPath,
              fit: BoxFit.contain,
              repeat: true,
              frameRate: FrameRate.composition,
            ),
          ),
          if (label != null && label.trim().isNotEmpty) ...[
            SizedBox(width: compact ? 8 : 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.84),
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    if (compact) {
      return content;
    }

    return Center(child: content);
  }
}
