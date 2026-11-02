import 'package:flutter/material.dart';

import '../themes_colors/app_theme.dart';

/// Keeps the app at phone width on a wide screen.
///
/// **Why.** Budget Buddy is designed for phones, and the Congressional App
/// Challenge judges see it on the website, usually on a laptop. There every
/// card stretched across the whole window, and a layout made for a 400px
/// column looked unfinished at 1,400px. Above [kFrameBreakpoint] the app now
/// sits in a centered column [kFrameWidth] wide, on the page green.
///
/// The column is also what the screens are *told* the width is: the
/// [MediaQuery] inside is narrowed, so a screen sizing itself from the window
/// lays out exactly as it would on a large phone, and dialogs and bottom
/// sheets open inside the column rather than across the window.
const double kFrameWidth = 600;
const double kFrameBreakpoint = 700;

class PhoneWidthFrame extends StatelessWidget {
  const PhoneWidthFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= kFrameBreakpoint) return child;
    return ColoredBox(
      color: AppTheme.deepForest,
      child: Center(
        child: Container(
          width: kFrameWidth,
          decoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: AppTheme.outline, width: 2),
            ),
          ),
          child: ClipRect(
            child: MediaQuery(
              data: media.copyWith(
                size: Size(kFrameWidth - 4, media.size.height),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
