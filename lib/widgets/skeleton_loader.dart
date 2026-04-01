import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const SkeletonLoader({
    Key? key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 14,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animationController.value * 2, 0),
              end: Alignment(-0.5 + _animationController.value * 2, 0),
              colors: const [
                Color(0xFF1B3329),
                Color(0xFF2D5A4A),
                Color(0xFF1B3329),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;

  const SkeletonCard({
    Key? key,
    this.lines = 3,
    this.lineHeight = 12,
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            height: 24,
            borderRadius: 8,
            margin: EdgeInsets.only(bottom: spacing),
          ),
          ...List.generate(
            lines,
            (index) => SkeletonLoader(
              height: lineHeight,
              borderRadius: 6,
              margin: EdgeInsets.only(
                bottom: index < lines - 1 ? spacing : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
