import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart'; // Temporarily disabled due to plugin issues
import 'package:one_one/components/custom_image_cropper.dart';
import 'package:one_one/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  String? profileImageUrl;
  File? newProfileImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await UserService.getUserData();
      if (mounted) {
        setState(() {
          userData = data;
          isLoading = false;
          if (data != null) {
            _nameController.text = data['name'] ?? '';
            
            // Safely handle profile image URL
            final profilePic = data['profilePic'];
            if (profilePic != null && profilePic is String && profilePic.isNotEmpty) {
              profileImageUrl = profilePic;
            } else {
              profileImageUrl = null;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Select Image Source',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text('Camera', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
      
      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          imageQuality: 100, // Keep high quality for cropping
        );
        
        if (image != null) {
          // Navigate to custom image cropper
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomImageCropper(
                  imageFile: File(image.path),
                  onCropComplete: (File croppedFile) {
                    setState(() {
                      newProfileImage = croppedFile;
                    });
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image cropped successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (userData == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      String? base64Image;
      if (newProfileImage != null) {
        List<int> imageBytes = await newProfileImage!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final updatedData = Map<String, dynamic>.from(userData!);
      updatedData['name'] = _nameController.text.trim();
      
      if (base64Image != null) {
        updatedData['profilePic'] = base64Image;
      }

      await UserService.updateUserData(updatedData);
      
      if (mounted) {
        setState(() {
          userData = updatedData;
          isEditing = false;
          isSaving = false;
          newProfileImage = null;
          if (base64Image != null) {
            profileImageUrl = base64Image;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ImageProvider? _getImageProviderFromUrl(String url) {
    try {
      if (url.startsWith('http')) {
        return NetworkImage(url);
      } else {
        // Try to decode base64, with better error handling
        String cleanBase64 = url.trim();
        
        // Check if it has data URL prefix and remove it
        if (cleanBase64.startsWith('data:')) {
          final int commaIndex = cleanBase64.indexOf(',');
          if (commaIndex != -1) {
            cleanBase64 = cleanBase64.substring(commaIndex + 1);
          }
        }
        
        // Remove any whitespace characters
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        
        // Validate base64 format
        if (cleanBase64.isNotEmpty && RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(cleanBase64)) {
          // Add padding if necessary
          while (cleanBase64.length % 4 != 0) {
            cleanBase64 += '=';
          }
          
          final bytes = base64Decode(cleanBase64);
          return MemoryImage(bytes);
        } else {
          print('Invalid base64 format for profile image');
          return null;
        }
      }
    } catch (e) {
      print('Error processing image URL: $e');
      return null;
    }
  }

  Widget _buildProfileImage() {
    ImageProvider? imageProvider;
    
    try {
      if (newProfileImage != null) {
        imageProvider = FileImage(newProfileImage!);
      } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        imageProvider = _getImageProviderFromUrl(profileImageUrl!);
      }
    } catch (e) {
      print('Error loading profile image: $e');
      imageProvider = null;
    }

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            image: imageProvider != null
                ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageProvider == null
              ? const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                )
              : null,
        ),
        if (isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAndCropImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'No user data found.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (isEditing)
            IconButton(
              icon: isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.green),
              onPressed: isSaving ? null : _saveChanges,
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  newProfileImage = null;
                  _nameController.text = userData!['name'] ?? '';
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            _buildProfileImage(),
            const SizedBox(height: 40),
            
            // Name Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    )
                  else
                    Text(
                      userData!['name'] ?? 'No name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Unique Code Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unique Code',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userData!['uid']?.substring(0, 8) ?? 'No code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.grey),
                        onPressed: () async {
                          final uniqueCode = userData!['uid']?.substring(0, 8) ?? '';
                          await Clipboard.setData(ClipboardData(text: uniqueCode));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Email Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData!['email'] ?? 'No email',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
