import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Orientations the app supports everywhere outside of screens that
/// deliberately lock themselves (the Bonfire world, for example).
///
/// Every page is expected to lay out in both portrait and landscape, so this
/// is the default the app starts in and the state any locking screen restores
/// on the way out.
const List<DeviceOrientation> kAppOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

class OrientationScope extends StatefulWidget {
  const OrientationScope({
    super.key,
    required this.orientations,
    required this.child,
    this.fallbackOrientations = kAppOrientations,
  });

  final List<DeviceOrientation> orientations;
  final List<DeviceOrientation> fallbackOrientations;
  final Widget child;

  @override
  State<OrientationScope> createState() => _OrientationScopeState();
}

class _OrientationScopeState extends State<OrientationScope> {
  @override
  void initState() {
    super.initState();
    _applyOrientations(widget.orientations);
  }

  @override
  void didUpdateWidget(covariant OrientationScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.orientations, widget.orientations)) {
      _applyOrientations(widget.orientations);
    }
  }

  @override
  void dispose() {
    _applyOrientations(widget.fallbackOrientations);
    super.dispose();
  }

  Future<void> _applyOrientations(List<DeviceOrientation> orientations) async {
    if (kIsWeb) {
      return;
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return;
    }

    await SystemChrome.setPreferredOrientations(orientations);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
