import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'tokens.dart';

/// Placeholder shapes with a soft sweep of light, shown while a list loads (visibility of system
/// status: she can see what is coming). The sweep stops when the phone is set to reduce motion.
/// Put [SkeletonBox]es inside it.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, required this.child});

  /// A ready-made list of cards.
  factory SkeletonLoader.list({Key? key, int count = 4, double itemHeight = 88}) => SkeletonLoader(
        key: key,
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              SkeletonBox(height: itemHeight, radius: Corner.medium),
              const SizedBox(height: Space.m - Space.xs),
            ],
          ],
        ),
      );

  final Widget child;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceContainerHigh;
    final light = context.colors.surfaceContainerLowest;
    return Semantics(
      label: context.l10n.loading,
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          if (context.reduceMotion) return child!;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final t = _controller.value;
              return LinearGradient(
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(-0.5 + 3 * t, 0),
                colors: [base, light, base],
                stops: const [0.2, 0.5, 0.8],
              ).createShader(bounds);
            },
            child: child,
          );
        },
      ),
    );
  }
}

/// One grey placeholder shape.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = Corner.small});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
