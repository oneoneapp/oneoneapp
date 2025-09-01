import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/screens/login_page.dart';
import 'package:one_one/screens/setup/setup_page.dart';
import 'package:one_one/screens/walkie_talkie_screen.dart';
import 'package:one_one/services/user_service.dart';

class AppRouter {
  static GoRouter get routerData => GoRouter(
    initialLocation: '/',
    requestFocus: false,
    refreshListenable: FirebaseAuthChangeListenable(),
    redirect: (context, state) async {
      final userData = await UserService.getUserData();
      logger.debug("Router redirect check: userData=$userData}");
      if (userData == null) {
        return "/login";
      } else if (userData['name'] == null) {
        return "/setup";
      } else {
        return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(
        name: "home",
        path: "/",
        builder: (context, state) {
          return const WalkieTalkieScreen();
        },
      ),
      GoRoute(
        name: "login",
        path: "/login",
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        name: "setup",
        path: "/setup",
        builder: (context, state) {
          return const SetupPage();
        },
      ),
    ],
  );
}

class FirebaseAuthChangeListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  FirebaseAuthChangeListenable() {
    _subscription = FirebaseAuth.instance.authStateChanges().asBroadcastStream().listen((_) {
      logger.debug("Auth state changed, notifying listeners...");
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}