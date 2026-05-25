import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AmbientLottieCard extends StatelessWidget {
  const AmbientLottieCard({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
    this.height = 180,
    this.width,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = const Color(0x14FFFFFF),
    this.borderColor = const Color(0x24FFFFFF),
  });

  final String assetPath;
  final String semanticLabel;
  final double height;
  final double? width;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Lottie.asset(
          assetPath,
          fit: BoxFit.contain,
          repeat: true,
          frameRate: FrameRate.composition,
        ),
      ),
    );
  }
}
