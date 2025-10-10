import 'dart:ui';

import 'package:flutter/material.dart';

class BgContainer extends StatefulWidget {
  final bool displayMargin;
  final bool isShaking;
  final String imageUrl;

  const BgContainer({
    super.key,
    this.displayMargin = false,
    this.isShaking = false,
    required this.imageUrl
  });

  @override
  State<BgContainer> createState() => _BgContainerState();
}

class _BgContainerState extends State<BgContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  static const Duration duration = Duration(milliseconds: 500);
  static const double angle = 0.05; // in radians (0.05 ≈ 3°);
  static const Duration pause = Duration(milliseconds: 300);
  static const double blurStrength = 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: duration);

    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: angle), weight: 1),
      TweenSequenceItem(tween: Tween(begin: angle, end: -angle), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -angle, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isShaking) _startLoop();
  }

  Future<void> _startLoop() async {
    while (mounted && widget.isShaking) {
      await _controller.forward(from: 0);
      await Future.delayed(pause);
    }
  }

  @override
  void didUpdateWidget(covariant BgContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking && !_controller.isAnimating) {
      _startLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          child: child,
        );
      },
      child: Container(
        margin: widget.displayMargin
          ? const EdgeInsets.only(
            top: 70,
            right: 40,
            left: 40,
            bottom: 40
          )
          : null,
        clipBehavior: widget.displayMargin
          ? Clip.antiAlias
          : Clip.none,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurStrength,
                sigmaY: blurStrength,
              ),
              child: Container(color: Colors.transparent),
            ),
            Container(
              color: ColorScheme.of(context).surfaceTint.withValues(
                alpha: 0.2
              )
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}