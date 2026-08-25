import 'package:flutter/material.dart';

/// A single-line label that **shrinks to fit instead of truncating**.
///
/// The app had 46 separate `Text(maxLines: 1, overflow: TextOverflow
/// .ellipsis)` call sites, and on a real phone a lot of them were firing:
/// "Explore the Town" became "Explore th…", "Pick a money habit" became
/// "Pick a money ha…", "Current Objective" became "Curren…". An ellipsis is
/// a reasonable default for *user data* of unknown length (a username, a
/// company name) but it is the wrong answer for UI chrome the app wrote
/// itself, where the string is known, short, and load-bearing — a label
/// that says "Curren…" has failed at the one thing it exists to do.
///
/// Scaling the whole line down keeps the full phrase at every width. On the
/// sizes this app actually runs at the shrink is a point or two of font
/// size and reads as intentional, where the truncation read as a bug.
///
/// **Use this for app-authored labels. Keep the ellipsis for arbitrary
/// user/remote strings** — a 60-character company name scaled to fit would
/// become unreadably small, and there truncating really is the lesser
/// evil. [minScale] guards that case: below it, this falls back to
/// ellipsis rather than shrinking into illegibility.
class FittedLabel extends StatelessWidget {
  const FittedLabel(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.alignment = Alignment.centerLeft,
    this.minScale = 0.62,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Where the (possibly narrower) scaled line sits in the space it is
  /// given. Left by default because most labels here head a column.
  final AlignmentGeometry alignment;

  /// How far the text may shrink before truncation is the better trade.
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final effective = style ?? DefaultTextStyle.of(context).style;
    final fontSize = effective.fontSize ?? 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Unbounded width (inside a scrolling Row, say) means there is
        // nothing to fit *to* — the text can simply take the space it
        // wants, and FittedBox would have no meaningful scale to compute.
        if (!constraints.hasBoundedWidth) {
          return Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: textAlign,
            style: effective,
          );
        }

        final painter = TextPainter(
          text: TextSpan(text: text, style: effective),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();

        final needed = painter.width;
        final available = constraints.maxWidth;
        if (needed <= available || needed == 0) {
          return Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: textAlign,
            style: effective,
          );
        }

        final scale = available / needed;
        if (scale < minScale) {
          // Too long to shrink gracefully — almost always a remote string
          // rather than one of ours. Truncate instead of going unreadable.
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: effective,
          );
        }

        return Align(
          alignment: alignment,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: textAlign,
            style: effective.copyWith(fontSize: fontSize * scale),
          ),
        );
      },
    );
  }
}
