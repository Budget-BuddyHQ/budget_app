import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:lottie/lottie.dart';

class TemporaryLoadingScreen extends StatefulWidget {
  const TemporaryLoadingScreen({
    super.key,
    this.message = 'LOADING ADVENTURE...',
    this.activeTabIndex = -1,
    this.onNavSelected,
    this.compact = false,
    this.animationAssetPath = 'assets/animations/02_Manny_Run_Fill.json',
    this.animationSize = 140,
    this.showProgressIndicator = true,
  });

  final String message;
  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;
  final bool compact;
  final String animationAssetPath;
  final double animationSize;
  final bool showProgressIndicator;

  @override
  State<TemporaryLoadingScreen> createState() => _TemporaryLoadingScreenState();
}

class _TemporaryLoadingScreenState extends State<TemporaryLoadingScreen> {
  final Flutter3DController _pondController = Flutter3DController();

  @override
  void initState() {
    super.initState();
    _pondController.onModelLoaded.addListener(() {
      if (_pondController.onModelLoaded.value) {
        _pondController.playAnimation();
        _pondController.startRotation(rotationSpeed: 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          // =========================================================
          // LAYER 1: Full-Screen Map
          // =========================================================
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return OverflowBox(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxHeight * 2.0,
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight,
                  child: Image.asset(
                    'assets/self_made_backgrounds/map.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.none,
                  ),
                );
              },
            ),
          ),

          // High-contrast tint overlay
          Positioned.fill(
            child: Container(color: const Color(0xFF0D1F1A).withOpacity(0.80)),
          ),

          // =========================================================
          // LAYER 2: Locked UI Canvas (No Scrolling)
          // =========================================================
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Fixed Header Text at the very top
                  const SizedBox(height: 28),
                  _buildLoadingText(),

                  // 2. Flexible Middle Space (Swaps dynamically)
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeLayout(screenSize)
                        : _buildPortraitLayout(screenSize),
                  ),

                  // 3. Full-Screen Width Loading Line at the bottom
                  if (widget.showProgressIndicator)
                    const SizedBox(
                      width: double.infinity, // Spans entire screen width
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        color: Color(0xFF00E676),
                        minHeight: 4, // Thickness of the line
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PORTRAIT MODE (Stacked vertically in the middle)
  // =========================================================
  Widget _buildPortraitLayout(Size screenSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTurtleAnimation(),
        _buildPondViewer(screenSize.width * 0.85),
      ],
    );
  }

  // =========================================================
  // LANDSCAPE MODE (Side-by-side in the middle)
  // =========================================================
  Widget _buildLandscapeLayout(Size screenSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTurtleAnimation(),
        _buildPondViewer(screenSize.width * 0.45),
      ],
    );
  }

  // =========================================================
  // EXTRACTED UI COMPONENTS
  // =========================================================
  Widget _buildTurtleAnimation() {
    return SizedBox(
      width: widget.animationSize * 2.5,
      height: widget.animationSize * 2.5,
      child: Lottie.asset(
        widget.animationAssetPath,
        fit: BoxFit.contain,
        animate: true,
        repeat: true,
        filterQuality: FilterQuality.none,
      ),
    );
  }

  Widget _buildLoadingText() {
    return Text(
      widget.message.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'PressStart2P',
        color: Color(0xFF00E676),
        fontSize: 13,
        height: 1.6,
        letterSpacing: 1.2,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(2, 2)),
          Shadow(color: Colors.black54, offset: Offset(4, 4)),
        ],
      ),
    );
  }

  Widget _buildPondViewer(double width) {
    return SizedBox(
      width: width,
      height: 260,
      child: Flutter3DViewer(
        controller: _pondController,
        src: 'assets/imported/pond_loading_animation_source/pond.glb',
      ),
    );
  }
}
