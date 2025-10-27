import 'dart:convert';
import 'dart:io';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/core/config/routing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static const String _userRegisteredKey = 'user_registered';
  static const String _userDataKey = 'user_data';

  // Check if user is registered (first check locally, then backend)
  static Future<bool> isUserRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First check local storage
      bool? locallyRegistered = prefs.getBool(_userRegisteredKey);
      
      if (locallyRegistered == true) {
        // User is registered locally, no need to check backend
        return true;
      }

      // If not found locally, check with backend
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      
      final response = await loc<ApiService>().get(
        'user/check',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        bool isRegistered = data['isRegistered'] ?? false;
        
        if (isRegistered) {
          // Also store user data if provided
          if (data['userData'] != null) {
            await _storeUserData(data['userData']);
            // Only mark as registered if registrationStatus is not pending
            if (data['userData']['registrationStatus'] != 'pending') {
              await _storeUserRegistrationStatus(true);
            }
          } else {
            // Store locally for future checks
            await _storeUserRegistrationStatus(true);
          }
        }
        
        return isRegistered;
      } else if (response.statusCode == 404) {
        // User not found in backend
        return false;
      } else {
        throw Exception('Failed to check user registration status');
      }
    } catch (e) {
      logger.info('Error checking user registration: $e');
      // In case of error, return false to be safe
      return false;
    }
  }

  // Store user registration status locally
  static Future<void> _storeUserRegistrationStatus(bool isRegistered) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userRegisteredKey, isRegistered);
  }

  // Store user data locally
  static Future<void> _storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(userData);
      await prefs.setString(_userDataKey, jsonString);
      logger.debug('User data stored successfully');
    } catch (e) {
      logger.error('Error storing user data: $e');
      throw e;
    }
  }

  // Get locally stored user data
  static Future<Map<String, dynamic>?> getLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          return json.decode(userDataString);
        } catch (jsonError) {
          logger.error('Error parsing user data JSON: $jsonError');
          // Clear invalid data
          await prefs.remove(_userDataKey);
          return null;
        }
      }
      return null;
    } catch (e) {
      logger.error('Error getting local user data: $e');
      return null;
    }
  }

  // Submit user data to backend and store locally
  static Future<bool> submitUserData({
    required String name,
    required DateTime dateOfBirth,
    File? profilePicture,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      logger.info('Submitting user data for ${user.email}');

      String? base64Image;
      if (profilePicture != null) {
        List<int> imageBytes = await profilePicture.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final userData = {
        'name': name,
        'dob': dateOfBirth.toIso8601String(),
        'profilePic': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
        'uid': user.uid,
        'email': user.email,
      };

      final response = await loc<ApiService>().post(
        'user/register',
        body: userData,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Store registration status and user data locally
        await _storeUserRegistrationStatus(true);
        await _storeUserData(response.data['user']);
        
        // Refresh the router to pick up the new user data
        AppRouter.refreshRouter();
        
        return true;
      } else {
        throw Exception('Failed to submit user data: ${response.statusCode}');
      }
    } catch (e) {
      logger.info('Error submitting user data: $e');
      return false;
    }
  }

  static Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        
        // Try to update on backend first
        try {
          final response = await loc<ApiService>().put(
            'user/profile',
            body: updatedData,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            logger.debug('Profile updated successfully on backend');
          }
        } catch (e) {
          logger.warning('Failed to update profile on backend, continuing with local update: $e');
        }
      }
      
      // Update local data regardless of backend success
      await _storeUserRegistrationStatus(true);
      await _storeUserData(updatedData);
      
      // Refresh the router to pick up the updated user data
      AppRouter.refreshRouter();
    } catch (e) {
      logger.error('Error updating user data: $e');
      throw e;
    }
  }

  // Clear local user data (for logout or data reset)
  static Future<void> clearLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // await prefs.remove(_userRegisteredKey);
    // await prefs.remove(_userDataKey);
  }

  // Helper method to calculate age
  // static int _calculateAge(DateTime birthDate) {
  //   DateTime today = DateTime.now();
  //   int age = today.year - birthDate.year;
  //   if (today.month < birthDate.month ||
  //       (today.month == birthDate.month && today.day < birthDate.day)) {
  //     age--;
  //   }
  //   return age;
  // }

  // Check if user exists and get their data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      // First try to get from local storage
      final localData = await getLocalUserData();
      if (localData != null) {
        return localData;
      }

      // If not found locally, check backend
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      
      // Try the check endpoint first since profile endpoint returns 404
      final response = await loc<ApiService>().get(
        'user/check',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // If user data is available in the check response
        if (data['user'] != null) {
          // Store the data locally for future use
          await _storeUserData(data['user']);
          // Only mark as registered if registrationStatus is not pending
          if (data['user']['registrationStatus'] != 'pending') {
            await _storeUserRegistrationStatus(true);
          }
          
          return data['user'];
        }
      }
      
      return null;
    } catch (e) {
      logger.info('Error getting user data: $e');
      return null;
    }
  }
}