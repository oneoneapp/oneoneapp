import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/routing.dart';
import 'package:one_one/core/theme/theme.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:one_one/services/foreground_service.dart';
import 'package:provider/provider.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ForegroundService.initCommunicationPort();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ForegroundService.stopService();
  await setupLocator();
  runApp(
    OneOneApp()
  );
}

class OneOneApp extends StatefulWidget {
  const OneOneApp({super.key});

  @override
  State<OneOneApp> createState() => _OneOneAppState();
}

class _OneOneAppState extends State<OneOneApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ForegroundService.requestPermissions();
      ForegroundService.initService();
    });
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => loc<WalkieTalkieProvider>()),
        ChangeNotifierProvider(create: (_) => loc<HomeProvider>()),
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