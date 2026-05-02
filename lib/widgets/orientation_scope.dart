import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationScope extends StatefulWidget {
  const OrientationScope({
    super.key,
    required this.orientations,
    required this.child,
    this.fallbackOrientations = const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ],
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
