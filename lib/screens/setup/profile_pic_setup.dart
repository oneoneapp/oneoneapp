import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_one/screens/setup/setup_step_page.dart';

class ProfilePicSetup extends StatefulWidget {
  final Function() onBack;
  final Function(File) onSubmit;

  const ProfilePicSetup({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<ProfilePicSetup> createState() => ProfilePicSetupState();
}

class ProfilePicSetupState extends State<ProfilePicSetup> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Failed to pick image. Please try again.'),
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
    return SetupStepPage(
      title: "Upload a profile picture",
      step: 3,
      totalSteps: 3,
      onBack: widget.onBack,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[800],
            backgroundImage:_selectedImage != null
              ? FileImage(_selectedImage!)
              : null,
            child: _selectedImage == null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text("Choose from Gallery"),
          ),
        ],
      ),
      onNext: () {
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please pick a image to display"
              )
            )
          );
        } else {
          widget.onSubmit(_selectedImage!);
        }
      },
    );
  }
}