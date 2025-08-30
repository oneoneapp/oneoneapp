import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/theme/theme.dart';
import 'package:one_one/screens/name_setup_page.dart';
import 'package:one_one/screens/walkie_talkie_screen.dart';
import 'package:one_one/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
import 'package:one_one/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalkieTalkieProvider()),
      ],
      child: const WalkieTalkieApp(),
    ),
  );
}

class WalkieTalkieApp extends StatefulWidget {
  const WalkieTalkieApp({super.key});

  @override
  State<WalkieTalkieApp> createState() => _WalkieTalkieAppState();
}

class _WalkieTalkieAppState extends State<WalkieTalkieApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneOne',
      theme: Themes.darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, now fetch user data
            return FutureBuilder<Map<String, dynamic>?>(
              future: UserService.getUserData(), // replace with your actual class/method
              builder: (context, userDataSnapshot) {
                if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userDataSnapshot.hasError) {
                  return const Center(child: Text('Failed to load user data.'));
                }

                final userData = userDataSnapshot.data;

                if (userData != null && userData['name'] != null) {
                  return WalkieTalkieScreen();
                } else {
                  return NameSetupPage();
                }
              },
            );
          }

          // Not logged in
          return LoginPage();
        },
      ),
    );
  }
}