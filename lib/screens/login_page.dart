import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:one_one/screens/name_setup_page.dart';
import 'package:one_one/screens/walkie_talkie_screen.dart';
import 'package:one_one/providers/fcm_provider.dart';

enum UserStatus {
  newUser,
  existsWithoutSetup,
  alreadyRegistered,
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Remove serverClientId as it might be causing the type casting issue
  );
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _setupFCM();
    _checkGoogleSignInConfiguration();
  }

  Future<void> _checkGoogleSignInConfiguration() async {
    try {
      // This will help verify if Google Sign-In is properly configured
      final isAvailable = await _googleSignIn.isSignedIn();
      print("Google Sign-In available: $isAvailable");
    } catch (e) {
      print("Google Sign-In configuration check failed: $e");
    }
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _setupFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = token;
      });
      print("FCM Token: $_fcmToken");

      FirebaseMessaging.onMessage.listen((message) async {
        print("Foreground message: ${message.data}");
        await connectToServer(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        print("Message opened from background");
        await connectToServer(message);
      });
    } catch (e) {
      print("Error setting up FCM: $e");
    }
  }

  Future<User?> _signInWithGoogle() async {
    try {
      print("Starting Google sign-in process...");
      
      // Sign out from previous sessions to avoid conflicts
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      print("Initiating Google sign-in...");
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        print("User cancelled Google sign-in");
        return null;
      }

      print("Getting authentication details...");
      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.accessToken == null || auth.idToken == null) {
        print("Failed to get Google auth tokens");
        print("Access token: ${auth.accessToken != null ? 'Present' : 'Missing'}");
        print("ID token: ${auth.idToken != null ? 'Present' : 'Missing'}");
        return null;
      }
      
      print("Creating Firebase credential...");
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      print("Signing in with Firebase...");
      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User? user = userCred.user;

      if (user != null) {
        print("Successfully signed in as: ${user.displayName}, ${user.email}");
        print("User UID: ${user.uid}");
      } else {
        print("Firebase sign-in returned null user");
      }

      return user;
    } on PlatformException catch (e) {
      print("Platform exception during Google sign-in: ${e.code} - ${e.message}");
      if (e.code == 'sign_in_failed') {
        print("This is likely a configuration issue. Check SHA-1 fingerprints in Firebase Console.");
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.message}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return null;
    } catch (e, stackTrace) {
      print("Google sign-in failed with error: $e");
      print("Error type: ${e.runtimeType}");
      print("Stack trace: $stackTrace");
      
      // Clean up any partial sign-in state
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (cleanupError) {
        print("Error during cleanup: $cleanupError");
      }
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Future<UserStatus> _sendUserDataToBackend(User user) async {
    try {
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('https://api.oneoneapp.in/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'token': idToken ?? '',
        },
        body: jsonEncode({
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'fcmToken': _fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print("User data sent successfully");
        return UserStatus.newUser;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        if (body['user'] != null && body['user']['dob'] != null) {
          print("User already registered");
          return UserStatus.alreadyRegistered;
        } else {
          print("User exists without completing setup");
          return UserStatus.existsWithoutSetup;
        }
      } else {
        print("Unexpected status: ${response.statusCode}");
        return UserStatus.newUser;
      }
    } catch (e) {
      print("Error sending user data: $e");
      return UserStatus.newUser;
    }
  }

  Future<void> _handleLogin() async {
    print("Starting Google Sign-In process...");
    print("Package name: com.example.one_one");
    print("Expected SHA-1: B6:05:F5:3B:6A:A1:E3:4E:03:DA:9F:C7:A8:44:DE:DB:5C:8C:83:A7");
    
    final user = await _signInWithGoogle();
    if (!mounted || user == null) return;

    final status = await _sendUserDataToBackend(user);
    if (!mounted) return;

    switch (status) {
      case UserStatus.alreadyRegistered:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WalkieTalkieScreen()),
        );
        break;
      case UserStatus.existsWithoutSetup:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NameSetupPage()),
        );
        break;
      case UserStatus.newUser:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NameSetupPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF00),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFF00),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icon/logo.png',
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: const Color(0xFFFFFF00),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        child: Image.asset('assets/icon/google.png'),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'By signing in, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
