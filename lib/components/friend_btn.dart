import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_one/components/online_status_dot.dart';
import 'package:one_one/components/speaking_status_dot.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/core/shared/spacing.dart';
import 'package:one_one/models/friend.dart';

class FriendBtn extends StatefulWidget {
  final Friend friend;
  final bool enabled;
  final bool? isHolding;
  final Function()? onHold;
  final Function()? onHolding;
  final Function()? onRelease;

  const FriendBtn({
    super.key,
    required this.friend,
    this.isHolding,
    this.enabled = true,
    this.onHold,
    this.onHolding,
    this.onRelease
  });

  @override
  State<FriendBtn> createState() => _FriendBtnState();
}

class _FriendBtnState extends State<FriendBtn> {
  late Timer? releaseFuncTimer;
  
  late bool _isHolding;
  late bool _holdLocked;

  @override
  void initState() {
    releaseFuncTimer = null;
    _isHolding = widget.isHolding ?? false;
    _holdLocked = false;
    super.initState();
  }

  double get size => (_isHolding ? 80 : 70);

  void release() {
    releaseFuncTimer?.cancel();
    releaseFuncTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isHolding) {
        _isHolding = false;
        widget.onRelease?.call();
        setState(() {});
      }
    });
  }

  void onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    logger.debug("[hold btn] Tap down");
    if (!_isHolding && !_holdLocked) {
      _isHolding = true;
      setState(() {});
      HapticFeedback.mediumImpact();
      widget.onHold?.call();
    }
  }

  void onTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    logger.debug("[hold btn] Tap Up");
    if (!_holdLocked) {
      release();
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    logger.debug("[hold btn] Pan update");
    final dy = details.delta.dy;
    if (dy < -1.0 && !_holdLocked) {
      releaseFuncTimer?.cancel();
      _isHolding = true;
      _holdLocked = true;
      setState(() {});
      HapticFeedback.mediumImpact();
      widget.onHolding?.call();
    } else if (dy > 1.0 && _holdLocked) {
      logger.debug("Releasing hold via downward swipe");
      _holdLocked = false;
      setState(() {});
      release();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (_holdLocked)
          Positioned(
            bottom: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6
              ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: ColorScheme.of(context).onSurfaceVariant
                  ),
                  const SizedBox(width: Spacing.s1),
                  Text(
                    'Holding',
                    style: TextTheme.of(context).labelMedium
                  ),
                ],
              )
            )
          ),
        Container(
          alignment: Alignment.center,
          child: GestureDetector(
            onTapDown: onTapDown,
            onPanUpdate: onPanUpdate,
            onTapUp: onTapUp,
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
                  image: widget.friend.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.friend.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
              ),
            )
          ),
        ),
        if (widget.friend.socketData?.isOnline ?? false)
          Positioned(
            bottom: 18,
            right: 10,
            child: OnlineStatusDot(
              size: 20,
            ),
          ),
        if (widget.friend.socketData?.speaking ?? false)
          Positioned(
            top: 14,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(Spacing.s1),
              decoration: BoxDecoration(
                color: ColorScheme.of(context).primary,
                borderRadius: BorderRadius.circular(Spacing.s2),
              ),
              child: SpeakingStatusDot(
                size: 12
              ),
            ),
          ),
      ],
    );
  }
}