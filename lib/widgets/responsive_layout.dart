import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (size.width >= 1200) {
      return desktop ?? tablet ?? mobile;
    } else if (size.width >= 600) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

class AdaptiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const AdaptiveGridView({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int columns = mobileColumns;

    if (MediaQuery.of(context).size.width >= 1200) {
      columns = desktopColumns;
    } else if (MediaQuery.of(context).size.width >= 600) {
      columns = tabletColumns;
    }

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: children,
    );
  }
}

class FlexiblePadding extends StatelessWidget {
  final Widget child;
  final double mobilePadding;
  final double tabletPadding;
  final double desktopPadding;

  const FlexiblePadding({
    Key? key,
    required this.child,
    this.mobilePadding = 16,
    this.tabletPadding = 24,
    this.desktopPadding = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double padding = mobilePadding;

    if (MediaQuery.of(context).size.width >= 1200) {
      padding = desktopPadding;
    } else if (MediaQuery.of(context).size.width >= 600) {
      padding = tabletPadding;
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}
