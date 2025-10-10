import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldBtn extends StatefulWidget {
  final String? image;
  final bool primary;
  final bool? isHolding;
  final Function()? onHold;
  final Function()? onHolding;
  final Function()? onRelease;

  const HoldBtn({
    super.key,
    this.image,
    this.primary = false,
    this.isHolding,
    this.onHold,
    this.onHolding,
    this.onRelease
  });

  @override
  State<HoldBtn> createState() => _HoldBtnState();
}

class _HoldBtnState extends State<HoldBtn> {
  late bool _isHolding;
  late bool _holdLocked;

  @override
  void initState() {
    _isHolding = widget.isHolding ?? false;
    _holdLocked = false;
    super.initState();
  }

  double get size => (_isHolding ? 80 : 70) + (widget.primary ? 20 : 0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_holdLocked)
          Positioned(
            left: 0,
            right: 0,
            bottom: 130,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorScheme.of(context).surfaceBright,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: ColorScheme.of(context).onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Holding',
                    style: TextStyle(
                      color: ColorScheme.of(context).onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            )
          ),
        Container(
          alignment: Alignment.center,
          child: GestureDetector(
            onTapDown: (details) {
              _isHolding = true;
              setState(() {});
              HapticFeedback.mediumImpact();
              widget.onHold?.call();
            },
            onPanUpdate: (details) {
              // Detect upward swipe (negative dy)
              if (details.delta.dy < -5 && !_isHolding) {
                _isHolding = true;
                _holdLocked = true;
                setState(() {});
                HapticFeedback.mediumImpact();
                widget.onHolding?.call();
              }
            },
            onPanEnd: (details) {
              // If user swiped upward, keep holding
              // If not, release
              if (_isHolding) {
                // Do nothing, stays holding
              } else {
                _isHolding = false;
                _holdLocked = false;
                setState(() {});
                widget.onRelease?.call();
              }
            },
            onTapUp: (details) {
              // Release only if not locked in holding
              if (_isHolding && !_holdLocked) {
                _isHolding = false;
                setState(() {});
                widget.onRelease?.call();
              }
            },
            onTapCancel: () {
              if (_isHolding) {
                _isHolding = false;
                setState(() {});
                widget.onRelease?.call();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInBack,
              alignment: Alignment.center,
              transformAlignment: Alignment.center,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorScheme.of(context).onInverseSurface,
                  width: _isHolding ? 8 : 0,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: EdgeInsets.all(_isHolding ? 8 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHolding
                    ? ColorScheme.of(context).onSurfaceVariant
                    : ColorScheme.of(context).onSurfaceVariant.withValues(alpha: 0.9),
                  image: widget.image != null
                    ? DecorationImage(image: NetworkImage(widget.image!))
                    : null,
                ),
              ),
            )
          ),
        ),
      ],
    );
  }
}