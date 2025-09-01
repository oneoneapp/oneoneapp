import 'package:flutter/material.dart';
import 'package:one_one/screens/setup/setup_step_page.dart';

class NameSetup extends StatelessWidget {
  final Function(String) onSubmit;

  NameSetup({
    super.key,
    required this.onSubmit,
  });

  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SetupStepPage(
      title: "What's your name?",
      step: 1,
      totalSteps: 3,
      showBack: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "Enter your name",
          ),
        ),
      ),
      onNext: () {
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please enter your name"
              )
            )
          );
        } else {
          onSubmit(_nameController.text.trim());
        }
      },
    );
  }
}