import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_one/core/config/routing.dart';
import 'package:one_one/screens/setup/dob_setup.dart';
import 'package:one_one/screens/setup/name_setup.dart';
import 'package:one_one/screens/setup/profile_pic_setup.dart';
import 'package:one_one/services/user_service.dart';

enum SetupStep {
  name,
  dob,
  profilePic;

  SetupStep next() {
    if (index < SetupStep.values.length - 1) {
      return SetupStep.values[index + 1];
    }
    return this;
  }

  SetupStep previous() {
    if (index > 0) {
      return SetupStep.values[index - 1];
    }
    return this;
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late SetupStep _currentStep;
  bool _isUploading = false;

  // Data collected
  String? _name;
  DateTime? _dob;
  File? _profilePic;

  @override
  void initState() {
    _currentStep = SetupStep.name;
    super.initState();
  }

  void _nextStep() {
    setState(() {
      _currentStep = _currentStep.next();
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep = _currentStep.previous();
    });
  }

  Future<void> _submitUserData() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    if (_isUploading) return;
    if (_name == null || _dob == null || _profilePic == null) {
      _showErrorDialog("Form not complete");
      return;
    }
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await UserService.submitUserData(
        name: _name!,
        dateOfBirth: _dob!,
        profilePicture: _profilePic!,
      );
      if (mounted) {
        Navigator.of(context).maybePop();
      }

      if (result == true) {
        // Refresh the router to ensure it picks up the new user data
        AppRouter.refreshRouter();
        
        if (mounted) {
          // Use context.go to navigate to home after successful setup
          context.go("/");
        }
      } else {
        throw Exception('Failed to submit user data');
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorDialog([String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message ?? 'Failed to complete setup. Please check your connection and try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      NameSetup(
        onSubmit: (name) {
          _name = name;
          _nextStep();
        },
      ),
      DobSetup(
        onBack: _prevStep,
        onSubmit: (selectedDate) {
          _dob = selectedDate;
          _nextStep();
        },
      ),
      ProfilePicSetup(
        onBack: _prevStep,
        onSubmit: (pic) async {
          _profilePic = pic;
          await _submitUserData();
        },
      ),
    ];

    return steps[_currentStep.index];
  }
}