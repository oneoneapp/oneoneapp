import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/routing.dart';
import 'package:one_one/core/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupLocator();
  runApp(
    OneOneApp()
  );
}

class OneOneApp extends StatelessWidget {
  const OneOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalkieTalkieProvider()),
      ],
      child: MaterialApp.router(
        title: 'OneOne',
        debugShowCheckedModeBanner: false,
        theme: Themes.darkTheme,
        routerConfig: AppRouter.routerData,
      ),
    );
  }
}