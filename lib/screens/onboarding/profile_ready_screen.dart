import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_names.dart';

class ProfileReadyScreen extends StatelessWidget {
  const ProfileReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final auth = context.read<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Your taste profile is ready!',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ...onboarding.vibes.map(
                  (v) => Chip(label: Text(v.replaceAll('_', ' ')))),
              Chip(label: Text(onboarding.budget)),
              ...onboarding.atmosphere
                  .map((a) => Chip(label: Text(a.replaceAll('_', ' ')))),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onboarding.isLoading
                  ? null
                  : () async {
                      final uid = auth.user?.uid;
                      if (uid == null) return;
                      await onboarding.completeOnboarding(uid);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, RouteNames.kMain);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC17B4E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: onboarding.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text("Let's go!",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
