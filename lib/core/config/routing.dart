import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/screens/home_page.dart';
import 'package:one_one/screens/login_page.dart';
import 'package:one_one/screens/profile_page.dart';
import 'package:one_one/screens/setup/setup_page.dart';
import 'package:one_one/services/user_service.dart';

class AppRouterNotifier extends ChangeNotifier {
  static final AppRouterNotifier _instance = AppRouterNotifier._internal();
  factory AppRouterNotifier() => _instance;
  AppRouterNotifier._internal();

  void refresh() {
    notifyListeners();
  }
}

class AppRouter {
  static final _routerNotifier = AppRouterNotifier();
  
  static GoRouter get routerData => GoRouter(
    initialLocation: '/',
    requestFocus: false,
    refreshListenable: Listenable.merge([
      FirebaseAuthChangeListenable(),
      _routerNotifier,
    ]),
    redirect: (context, state) async {
      final userData = await UserService.getUserData();
      logger.debug("Router redirect check: userData=$userData, path=${state.path}");
      
      if (userData == null) {
        logger.debug("No user data found, redirecting to login");
        return "/login";
      } else if (userData['registrationStatus'] == 'pending' || userData['name'] == null) {
        logger.debug("User registration is pending or no name, redirecting to setup");
        return "/setup";
      } else {
        logger.debug("User data complete, allowing access to requested route");
        return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(
        name: "home",
        path: "/",
        builder: (context, state) {
          return const HomePage();
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
      GoRoute(
        name: "profile",
        path: "/profile",
        builder: (context, state) {
          return const ProfilePage();
        },
      ),
    ],
  );

  static void refreshRouter() {
    _routerNotifier.refresh();
  }
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