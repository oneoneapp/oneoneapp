import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/shared/spacing.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = loc();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogin(BuildContext context) async {    
    final UserAuthStatus status = await authService.startAuthentication();
    if (!context.mounted) return;

    switch (status) {
      case UserAuthStatus.alreadyRegistered:
        context.goNamed("home");
        break;
      case UserAuthStatus.existsWithoutSetup:
        context.goNamed("setup");
        break;
      case UserAuthStatus.newUser:
        context.goNamed("setup");
        break;
      case UserAuthStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
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
              _Logo(),
              const SizedBox(height: Spacing.s6),
              _WelcomeSection(),
              const SizedBox(height: Spacing.s9),
              _GoogleSignInBtn(
                onTap: () => _handleLogin(context)
              ),
              const SizedBox(height: Spacing.s5),
              _LegalSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: ColorScheme.of(context).primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon/logo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome',
          style: TextTheme.of(context).displaySmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorScheme.of(context).surface,
          ),
        ),
        Text(
          'Sign in to continue',
          style: TextTheme.of(context).headlineSmall!.copyWith(
            fontSize: 16,
            color: ColorScheme.of(context).surface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInBtn extends StatelessWidget {
  final VoidCallback? onTap;

  const _GoogleSignInBtn({
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorScheme.of(context).onPrimary,
          foregroundColor: ColorScheme.of(context).primary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset('assets/icon/google.png'),
            ),
            const SizedBox(width: Spacing.s4),
            const Text(
              'Sign in with Google',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    return Text(
      'By signing in, you agree to our Terms of Service\nand Privacy Policy',
      textAlign: TextAlign.center,
      style: TextTheme.of(context).labelSmall!.copyWith(
        color: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }
}