// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:one_one/screens/login_page.dart';

// class ProfilePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Profile')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 50,
//               // Use stored profile picture
//             ),
//             SizedBox(height: 20),
//             Text('Name: [Stored Name]'),
//             Text('DOB: [Stored DOB]'),
//             SizedBox(height: 20),
//             ElevatedButton(
//               child: Text('Sign Out'),
//               onPressed: () async {
//                 await FirebaseAuth.instance.signOut();
//                 Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(builder: (context) => LoginPage()),
//                   (route) => false,
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }