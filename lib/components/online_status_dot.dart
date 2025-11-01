import 'package:flutter/material.dart';

class OnlineStatusDot extends StatelessWidget {
  final bool isOnline;
  final double size;
  final EdgeInsets? margin;

  const OnlineStatusDot({
    super.key,
    required this.isOnline,
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
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class OnlineStatusRow extends StatelessWidget {
  final bool isOnline;
  final TextStyle? textStyle;

  const OnlineStatusRow({
    super.key,
    required this.isOnline,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnlineStatusDot(
          isOnline: isOnline,
          size: 8,
        ),
        const SizedBox(width: 6),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: textStyle ??
              TextStyle(
                color: isOnline ? Colors.green : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}