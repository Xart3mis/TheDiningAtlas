import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';

/// The entry gate — checks auth state and routes accordingly.
/// Shows a branded splash while Firebase initialises, then
/// routes to LoginScreen or the main app (MainShell).
class AuthGate extends StatelessWidget {
  final Widget mainApp;

  const AuthGate({super.key, required this.mainApp});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // While Firebase is still determining auth state, show splash
        if (auth.user == null && auth.isLoading) {
          return _SplashView();
        }

        // Authenticated → go to main app
        if (auth.isAuthenticated) {
          return mainApp;
        }

        // Not authenticated → login
        return const LoginScreen();
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The\nDining Atlas',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Experience every city\nthe way locals do.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.terracotta,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
