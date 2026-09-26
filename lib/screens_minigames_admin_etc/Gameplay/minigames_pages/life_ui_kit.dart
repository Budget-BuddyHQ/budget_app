import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../themes_colors/app_theme.dart';

/// The small pieces every Life screen is built from.
///
/// **Why a kit.** The Occupation, Assets, People and Activities screens are four
/// different rooms in the same house. They were each about to invent their own
/// bar, row and chip, and four versions of a progress bar is how a game ends up
/// looking like four games. Everything here follows the rules the rest of the
/// app already keeps: the pixel face for words and never for numbers, the
/// number face for anything with a digit in it, no all-caps, and text that gives
/// way (ellipsis, wrap) before it overflows.

/// Red text that can be read.
///
/// The app's error red is 3.7 to 1 against the panel colour, which is under the
/// 4.5 that body text needs. This is that red lifted just far enough to clear
/// it, so a reason a row is locked is red in spirit and legible in fact.
Color errorInk([Color on = AppTheme.panel]) =>
    AppTheme.legibleOn(AppTheme.errorRed, on);

/// Opens a Life screen as a tall sheet that can be dragged away.
///
/// `useSafeArea` and a visible handle are not optional: a tall sheet without them
/// runs under the status bar with its heading unreadable and no obvious way out,
/// which is a bug this project has already had.
Future<T?> showLifeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// The frame around a Life screen: a heading, a close button, and a body that
/// scrolls.
class LifeSheet extends StatelessWidget {
  const LifeSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  /// Sits beside the close button, for a summary number.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 8, 6),
            child: Row(
              children: [
                // An icon is held to 3 to 1, and the sheet's accents are picked
                // for the town and the tabs, not for this background.
                Icon(
                  icon,
                  color: AppTheme.legibleOn(
                    accent,
                    AppTheme.panelStrong,
                    target: 3.0,
                  ),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.numeric(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A heading inside a screen.
class LifeSection extends StatelessWidget {
  const LifeSection(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.pixelifySans(
                color: AppTheme.textMuted,
                fontSize: 13,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A rounded panel, the background for a block of content.
class LifeCard extends StatelessWidget {
  const LifeCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: (accent ?? Colors.white).withValues(alpha: 0.22),
        ),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: box,
    );
  }
}

/// A labelled progress bar: how close, how well, how much.
///
/// The one bar everything shares, so "Grades", "Performance", a friend's
/// closeness and a stat all read the same way. The number is on the right in
/// the number face, and the colour can be told to follow the value so a low
/// bar reads as low before anybody reads it.
class LifeBar extends StatelessWidget {
  const LifeBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.height = 9,
    this.icon,
    this.caption,
  });

  final String label;

  /// 0 to 100.
  final int value;
  final Color color;

  /// Replaces the percentage on the right, for a bar that says "B" or "Close".
  final String? trailing;
  final double height;
  final IconData? icon;

  /// A small line under the bar.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: AppTheme.legibleOn(color, AppTheme.panel),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              trailing ?? '$v%',
              style: AppTheme.numeric(
                color: AppTheme.legibleOn(color, AppTheme.panel),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: v / 100,
            minHeight: height,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          Text(
            caption!,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

/// A small pill: a requirement, a status, a count.
class LifeChip extends StatelessWidget {
  const LifeChip(this.text, {super.key, this.color, this.icon});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // An opaque fill and an ink measured against that exact fill, as a pair.
    // A see-through tint reads differently over every surface it lands on, and
    // that is the bug this project's contrast audit was written to catch.
    final chip = AppTheme.tintedChip(
      color ?? const Color(0xFF58C7FF),
      alpha: 0.16,
      on: AppTheme.panel,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: chip.ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.numeric(
                color: chip.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row with an icon, two lines of text and something on the right.
class LifeRow extends StatelessWidget {
  const LifeRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accent = const Color(0xFF85EFAC),
    this.disabledReason,
    this.chips = const <Widget>[],
    this.bar,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color accent;

  /// When set the row is greyed out and this is shown in place of the subtitle.
  final String? disabledReason;
  final List<Widget> chips;

  /// A bar under the text, for a row that is about how much.
  final Widget? bar;

  bool get _enabled => disabledReason == null && onTap != null;

  @override
  Widget build(BuildContext context) {
    final locked = disabledReason != null;
    final tile = AppTheme.tintedChip(accent, alpha: 0.16, on: AppTheme.panel);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // No blanket Opacity: it dimmed the reason a row is locked along with the
      // row, and the reason is the one line here that has to stay readable.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: locked ? const Color(0xFF2F5A47) : tile.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: locked ? Colors.white38 : tile.ink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.pixelifySans(
                          color: locked ? Colors.white70 : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (locked || subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          disabledReason ?? subtitle!,
                          style: GoogleFonts.quicksand(
                            color: locked ? errorInk() : AppTheme.textMuted,
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: chips),
                      ],
                      if (bar != null) ...[const SizedBox(height: 8), bar!],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A button. Filled for the thing you came here to do, outlined for the rest.
class LifeButton extends StatelessWidget {
  const LifeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = const Color(0xFF43D07E),
    this.filled = true,
    this.note,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool filled;

  /// A line under the button: what is left, or why it is off.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    final button = filled
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: const Color(0xFF07200F),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
              disabledForegroundColor: Colors.white38,
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(
                color: on ? color.withValues(alpha: 0.7) : Colors.white24,
              ),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
            ),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        if (note != null) ...[
          const SizedBox(height: 3),
          Text(
            note!,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              color: on ? AppTheme.textMuted : errorInk(AppTheme.panelStrong),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// One entry in a [LifeDropdown].
class LifeDropdownItem<T> {
  const LifeDropdownItem({required this.value, required this.label, this.hint});

  final T value;
  final String label;

  /// A short second line shown in the open list.
  final String? hint;
}

/// A real dropdown, styled for a dark sheet.
///
/// **Asked for as:** *"the user can still choose from a dropdown."* Choosing a
/// major, a line of work or a sport is a choice from a list, and a list is what
/// a dropdown is for. It is a plain Material dropdown with the game's colours,
/// so it behaves the way anybody expects a dropdown to.
class LifeDropdown<T> extends StatelessWidget {
  const LifeDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.accent = const Color(0xFF58C7FF),
  });

  final String label;
  final T value;
  final List<LifeDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.panelStrong,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              iconEnabledColor: accent,
              menuMaxHeight: 360,
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              selectedItemBuilder: (context) => [
                for (final item in items)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              items: [
                for (final item in items)
                  DropdownMenuItem<T>(
                    value: item.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.hint != null)
                          Text(
                            item.hint!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A two-column grid of tiles that stays sensible on a narrow phone.
///
/// Built with a `Wrap` and computed widths rather than a `GridView`, because a
/// grid with a fixed aspect ratio is exactly what overflows when a label wraps
/// to a second line at a large text size.
class LifeTileGrid extends StatelessWidget {
  const LifeTileGrid({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 300 ? 2 : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// A big square-ish tile: an icon, a name, a line of detail.
class LifeTile extends StatelessWidget {
  const LifeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    this.subtitle,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback? onTap;

  /// A count in the corner.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.tintedChip(
                      accent,
                      alpha: 0.18,
                      on: AppTheme.panel,
                    ).fill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.tintedChip(
                      accent,
                      alpha: 0.18,
                      on: AppTheme.panel,
                    ).ink,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (badge != null) LifeChip(badge!, color: accent),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A colour for a 0 to 100 value: red when it is low, amber in the middle,
/// green when it is good. Used so a bar reads before its number does.
Color valueColor(int value) {
  if (value >= 70) return const Color(0xFF85EFAC);
  if (value >= 45) return const Color(0xFFF2C66D);
  return const Color(0xFFFF8474);
}

/// Happiness, Health, Smarts and Looks, always on screen.
///
/// **Asked for as:** *"four dynamic meters, Happiness, Health, Smarts and Looks,
/// from 0% to 100%."* Two columns of two, so all four fit in about as much height
/// as the one happiness bar they replace, and so a bar stays readable at 320
/// wide, where a single row of four would leave each one a sliver.
class LifeStatBars extends StatelessWidget {
  const LifeStatBars({
    super.key,
    required this.happiness,
    required this.health,
    required this.smarts,
    required this.looks,
  });

  final int happiness;
  final int health;
  final int smarts;
  final int looks;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBar(
                label: 'Happiness',
                value: happiness,
                color: const Color(0xFFFFD45C),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatBar(
                label: 'Health',
                value: health,
                color: const Color(0xFFFF8474),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _StatBar(
                label: 'Smarts',
                value: smarts,
                color: const Color(0xFF58C7FF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatBar(
                label: 'Looks',
                value: looks,
                color: const Color(0xFFB388FF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$v%',
              style: AppTheme.numeric(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: v / 100,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
