import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/providers/fcm_provider.dart';
import 'package:one_one/services/api_service.dart';
import 'package:one_one/services/user_service.dart';

enum UserAuthStatus {
  newUser,
  existsWithoutSetup,
  alreadyRegistered,
  error
}

class AuthService {
  final ApiService apiService;
  
  AuthService({
    required this.apiService,
  });

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  String? _fcmToken;

  void init() {
    _initializeFirebase();
    _setupFCM();
    _checkGoogleSignInConfiguration();
  }

  Future<void> _checkGoogleSignInConfiguration() async {
    try {
      final isAvailable = _googleSignIn.supportsAuthenticate();
      logger.info("Google Sign-In available: $isAvailable");
    } catch (e) {
      logger.error("Google Sign-In configuration check failed: $e");
    }
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _googleSignIn.initialize(
      clientId: '372494251881-dekm0ari0d01uvqm48fifam7f1pu6dne.apps.googleusercontent.com',
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _setupFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      _fcmToken = token;
      logger.debug("FCM Token: $_fcmToken");

      FirebaseMessaging.onMessage.listen((message) async {
        logger.info("Foreground message: ${message.data}");
        await connectToServer(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        logger.info("Message opened from background");
        await connectToServer(message);
      });
    } catch (e) {
      logger.error("Error setting up FCM: $e");
    }
  }

  Future<User?> _signInWithGoogle() async {
    try {
      logger.info("Starting Google sign-in process...");
      
      logger.info("Sign out from previous sessions to avoid conflicts...");
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      logger.info("Initiating Google sign-in...");
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      logger.info("Getting authentication details...");
      final GoogleSignInAuthentication auth = account.authentication;

      if (auth.idToken == null) {
        logger.error("Failed to get Google ID token");
        return null;
      }

      logger.info("Creating Firebase credential...");
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      logger.info("Signing in with Firebase...");
      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User? user = userCred.user;

      if (user != null) {
        logger.info("Successfully signed in as: ${user.displayName}, ${user.email}");
        logger.info("User UID: ${user.uid}");
      } else {
        logger.warning("Firebase sign-in returned null user");
      }

      return user;
    } on PlatformException catch (e) {
      logger.error("Platform exception during Google sign-in: ${e.code} - ${e.message}");
      if (e.code == 'sign_in_failed') {
        logger.error("This is likely a configuration issue. Check SHA-1 fingerprints in Firebase Console.");
      }
      return null;
    } catch (e, stackTrace) {
      logger.error("Google sign-in failed with error: $e : ${e.runtimeType} : $stackTrace");
      
      logger.info("Cleaning up after failed sign-in...");
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (cleanupError) {
        logger.error("Error during cleanup: $cleanupError");
      }
      return null;
    }
  }

  Future<UserAuthStatus> _sendUserDataToBackend(User user) async {
    try {
      final idToken = await user.getIdToken();

      var response = await apiService.post(
        'auth/signup',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: {
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'fcmToken': _fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.info("User data sent successfully: NEW USER!!");
        return UserAuthStatus.newUser;
      } else if (response.statusCode == 400) {
        final body = response.data;
        if (body != null && body['user'] != null) {
          final userData = {
            'name': body['user']['name'],
            'dob': body['user']['dob'],
            'profilePic': body['user']['profilePic'],
            'timestamp': body['user']['createdAt'],
            'uid': body['user']['uid'],
            'email': body['user']['email'],
            'registrationStatus': body['user']['registrationStatus'],
          };
          UserService.updateUserData(userData);
          // Check registrationStatus field first
          if (body['user']['registrationStatus'] == 'pending') {
            logger.info("User registration is pending, redirecting to setup");
            return UserAuthStatus.existsWithoutSetup;
          } else if (body['user']['dob'] != null) {
            logger.info("User already registered");
            return UserAuthStatus.alreadyRegistered;
          } else {
            logger.info("User exists without completing setup");
            return UserAuthStatus.existsWithoutSetup;
          }
        } else {
          logger.info("User exists but response format unexpected");
          return UserAuthStatus.existsWithoutSetup;
        }
      } else if (response.statusCode == 409) {
        // User already exists
        logger.info("User already exists, checking registration status");
        return await _checkUserRegistrationStatus(user);
      } else if (response.statusCode != null && response.statusCode! >= 500) {
        logger.error("Server error (${response.statusCode}): ${response.data}");
        return UserAuthStatus.error;
      } else {
        logger.warning("Unexpected status: ${response.statusCode}, treating as new user");
        return UserAuthStatus.newUser;
      }
    } catch (e) {
      logger.error("Error sending user data: $e");
      if (e.toString().contains('500') || e.toString().contains('DioException')) {
        return UserAuthStatus.error;
      }
      return UserAuthStatus.newUser;
    }
  }

  Future<UserAuthStatus> _checkUserRegistrationStatus(User user) async {
    try {
      final idToken = await user.getIdToken();
      
      final response = await apiService.get(
        'user/check',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['isRegistered'] == true) {
          if (body['userData'] != null) {
            UserService.updateUserData(body['userData']);
            // Check registrationStatus field
            if (body['userData']['registrationStatus'] == 'pending') {
              return UserAuthStatus.existsWithoutSetup;
            } else if (body['userData']['dob'] != null) {
              return UserAuthStatus.alreadyRegistered;
            } else {
              return UserAuthStatus.existsWithoutSetup;
            }
          } else {
            return UserAuthStatus.alreadyRegistered;
          }
        } else {
          return UserAuthStatus.newUser;
        }
      } else {
        logger.warning("Failed to check user status: ${response.statusCode}");
        return UserAuthStatus.newUser;
      }
    } catch (e) {
      logger.error("Error checking user registration status: $e");
      return UserAuthStatus.newUser;
    }
  }

  Future<UserAuthStatus> startAuthentication() async {
    logger.info("Starting user authentication process...");
    
    final user = await _signInWithGoogle();
    if (user == null) return UserAuthStatus.error;

    final status = await _sendUserDataToBackend(user);
    return status;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      UserService.clearLocalUserData();
      logger.info("User signed out successfully");
    } catch (e) {
      logger.error("Error signing out: $e");
    }
  }
}