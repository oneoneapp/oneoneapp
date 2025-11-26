import 'package:flutter/material.dart';

class OnlineStatusDot extends StatelessWidget {
  final bool isOnline;
  final double size;
  final EdgeInsets? margin;

  const OnlineStatusDot({
    super.key,
    this.isOnline = true,
    this.size = 12.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey[600],
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}