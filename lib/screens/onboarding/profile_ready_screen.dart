import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_names.dart';
import '../../theme/app_theme.dart';

const _kVibeLabels = {
  'hidden_cafe':  ('Hidden Café',  '☕'),
  'street_food':  ('Street Food',  '🌮'),
  'rooftop_bar':  ('Rooftop Bar',  '🍸'),
  'local_market': ('Local Market', '🛒'),
  'art_gallery':  ('Art Gallery',  '🎨'),
  'night_life':   ('Nightlife',    '🎵'),
  'fine_dining':  ('Fine Dining',  '🍽️'),
  'nature_spot':  ('Nature Spot',  '🌿'),
  'beach_vibes':  ('Beach Vibes',  '🏖️'),
  'craft_beer':   ('Craft Beer',   '🍺'),
  'wellness':     ('Wellness',     '🧘'),
  'cultural':     ('Cultural',     '🎭'),
};

const _kBudgetLabels = {
  r'$':    r'Under $15',
  r'$$':   r'$15 – $50',
  r'$$$':  r'$50 – $100',
  r'$$$$': r'$100+',
};

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
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text("You're all set!",
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          Text('Your taste profile is ready.',
              style: GoogleFonts.fraunces(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: AppColors.terracotta)),
          const SizedBox(height: 28),

          // Profile summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.lightGrey.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PROFILE',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmGrey,
                        letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: onboarding.vibes.map((id) {
                    final entry = _kVibeLabels[id];
                    final display = entry != null
                        ? '${entry.$2} ${entry.$1}'
                        : id.replaceAll('_', ' ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.terracotta
                                .withOpacity(0.3)),
                      ),
                      child: Text(display,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  '📍 ${onboarding.countryName}  ·  💰 ${_kBudgetLabels[onboarding.budget] ?? onboarding.budget}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.warmGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onboarding.isLoading
                  ? null
                  : () async {
                      final uid = auth.user?.uid;
                      if (uid == null) return;
                      try {
                        await onboarding.completeOnboarding(uid);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Could not save your profile. Please try again.')),
                          );
                        }
                        return;
                      }
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, RouteNames.kMain);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
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
                  : Text('Start Exploring',
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
