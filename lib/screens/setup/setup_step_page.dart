import 'package:flutter/material.dart';
import 'package:one_one/core/shared/spacing.dart';

class SetupStepPage extends StatefulWidget {
  final String title;
  final Widget child;
  final int step;
  final int totalSteps;
  final bool showBack;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const SetupStepPage({
    super.key,
    required this.title,
    required this.child,
    required this.step,
    required this.totalSteps,
    this.showBack = true,
    this.onNext,
    this.onBack,
  });

  @override
  State<SetupStepPage> createState() => _SetupStepPageState();
}

class _SetupStepPageState extends State<SetupStepPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500)
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _slideAnim = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextTheme.of(context).headlineMedium
                        // style: const TextStyle(
                        //       color: Colors.white,
                        //       fontSize: 28,
                        //       fontWeight: FontWeight.bold
                        // )
                      ),
                      const SizedBox(height: Spacing.s2),
                      LinearProgressIndicator(
                        value: widget.step / widget.totalSteps,
                        color: ColorScheme.of(context).primary,
                        backgroundColor: ColorScheme.of(context).surfaceBright,
                      )
                    ],
                  ),
                ),

                // Step content
                Expanded(
                  child: Center(
                    child: widget.child
                  )
                ),

                // Nav buttons
                Padding(
                  padding: const EdgeInsets.all(Spacing.s4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.showBack)
                        OutlinedButton(
                          onPressed: widget.onBack,
                          child: const Text("Back"),
                        ),
                      ElevatedButton(
                        onPressed: widget.onNext,
                        child: const Text("Next"),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}