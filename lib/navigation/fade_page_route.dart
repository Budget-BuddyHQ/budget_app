import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 320),
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
