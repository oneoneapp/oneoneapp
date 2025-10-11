import 'package:flutter/material.dart';

class CenterSnapScroll extends StatefulWidget {
  final PageController controller;
  final List<Widget> children;

  const CenterSnapScroll({
    super.key,
    required this.controller,
    required this.children
  });

  @override
  State<CenterSnapScroll> createState() => _CenterSnapScrollState();
}

class _CenterSnapScrollState extends State<CenterSnapScroll> {
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    // widget.controller = PageController(
    //   initialPage: _currentPage,
    //   viewportFraction: 0.3
    // );
    widget.controller.addListener(() {
      final newPage = widget.controller.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() => _currentPage = newPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: widget.controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          final bool isActive = index == _currentPage;
          final double scale = isActive ? 1.15 : 0.9;

          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.transparent,
                  width: isActive ? 3 : 0,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: widget.children[index],
            ),
          );
        },
      ),
    );
  }
}