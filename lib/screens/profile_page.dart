import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: FutureBuilder(
        future: UserService.getUserData(),
        builder: (context, asyncSnapshot) {
          final userData = asyncSnapshot.data;
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (userData == null) {
            return Center(child: Text('No user data found.'));
          }
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: MemoryImage(base64Decode(userData['profilePic'])),
                ),
                SizedBox(height: 20),
                Text(userData['name']),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Sign Out'),
                  onPressed: () async {
                    await loc<AuthService>().signOut();
                    if (context.mounted) {
                      context.goNamed("login");
                    }
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}