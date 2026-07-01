import 'package:flutter/material.dart';

class BrandedLoading extends StatelessWidget {
  const BrandedLoading({
    super.key,
    this.message,
    this.compact = false,
    this.assetPath,
  });

  final String? message;
  final bool compact;
  final String? assetPath;

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
            child: CircularProgressIndicator(
              strokeWidth: compact ? 2.5 : 3.0,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF85EFAC),
              ),
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
