import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeakingStatusDot extends StatefulWidget {
  final bool isSpeaking;
  final double size;
  final EdgeInsets? margin;
  final Color? activeColor;
  final bool animateWhenInactive;
  final Duration? duration;

  const SpeakingStatusDot({
    super.key,
    this.isSpeaking = true,
    this.size = 12.0,
    this.margin,
    this.activeColor,
    this.animateWhenInactive = false,
    this.duration,
  });

  @override
  State<SpeakingStatusDot> createState() => _SpeakingStatusDotState();
}

class _SpeakingStatusDotState extends State<SpeakingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phaseOffsets;
  late final List<double> _frequencies;
  late final List<double> _amplitudes;
  late final List<double> _exponents;
  late final List<double> _minHeights;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 900),
    );

    final seed = widget.key?.hashCode ?? DateTime.now().microsecondsSinceEpoch;
    final rnd = math.Random(seed);

    // Choose a central phase and make left/right roughly inverted so center peaks
    final centerPhase = rnd.nextDouble() * math.pi * 2;
    final jitter = (rnd.nextDouble() - 0.5) * 0.4; // small jitter so it's not perfectly symmetric
    _phaseOffsets = [
      centerPhase + math.pi + jitter, // left (mostly low when center high)
      centerPhase, // center (dominant)
      centerPhase + math.pi - jitter, // right
    ];

    // Center slower and smoother, sides a bit faster
    _frequencies = [
      1.15 + rnd.nextDouble() * 0.4,
      0.9 + rnd.nextDouble() * 0.2,
      1.15 + rnd.nextDouble() * 0.4,
    ];

    // Center has larger amplitude (taller), sides smaller
    _amplitudes = [
      0.6 + rnd.nextDouble() * 0.4, // left
      1.1 + rnd.nextDouble() * 0.6, // center (bigger)
      0.6 + rnd.nextDouble() * 0.4, // right
    ];

    // Exponents shape the wave: sides keep low most of the time (larger exponent),
    // center stays high more often (smaller exponent)
    _exponents = [
      2.2, // left -> biased low
      0.7, // center -> biased high
      2.2, // right -> biased low
    ];

    // Minimum height factors so sides stay generally lower even at peak
    _minHeights = [
      0.45, // left baseline
      0.65, // center baseline
      0.45, // right baseline
    ];

    if (widget.isSpeaking || widget.animateWhenInactive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpeakingStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSpeaking != widget.isSpeaking || oldWidget.animateWhenInactive != widget.animateWhenInactive) {
      if (widget.isSpeaking || widget.animateWhenInactive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get color => widget.activeColor ?? Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final baseSize = widget.size;
    final smallDotSize = baseSize * 0.6;
    final dotSpacing = smallDotSize * 0.55;

    return Container(
      margin: widget.margin,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : dotSpacing),
                child: SizedBox(
                  width: smallDotSize,
                  height: baseSize,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (!widget.isSpeaking && !widget.animateWhenInactive) {
                        return Center(
                          child: Container(
                            width: smallDotSize,
                            height: smallDotSize * 0.9,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(smallDotSize),
                            ),
                          ),
                        );
                      }

                      final t = _controller.value;
                      final freq = _frequencies[index];
                      final phase = _phaseOffsets[index];
                      final amp = _amplitudes[index];
                      final exponent = _exponents[index];
                      final minH = _minHeights[index];

                      // sine wave 0..1
                      final wave = math.sin(2 * math.pi * freq * t + phase);
                      final normalized = (wave + 1) / 2;

                      final idleAmpScale = widget.isSpeaking ? 1.0 : 0.55;
                      final effectiveAmp = amp * idleAmpScale;
                      final shapedIdle = math.pow(normalized, exponent).toDouble();
                      double heightFactorIdle = minH + shapedIdle * effectiveAmp;
                      const double minHeightFactorClamp = 0.75;
                      if (heightFactorIdle < minHeightFactorClamp) heightFactorIdle = minHeightFactorClamp;

                      return Center(
                        child: Container(
                          width: smallDotSize,
                          height: smallDotSize * heightFactorIdle,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(smallDotSize),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.12),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}