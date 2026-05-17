import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kCities = [
  {'id': 'cairo', 'name': 'Cairo', 'flag': '🇪🇬'},
  {'id': 'tokyo', 'name': 'Tokyo', 'flag': '🇯🇵'},
  {'id': 'lisbon', 'name': 'Lisbon', 'flag': '🇵🇹'},
  {'id': 'bangkok', 'name': 'Bangkok', 'flag': '🇹🇭'},
  {'id': 'rome', 'name': 'Rome', 'flag': '🇮🇹'},
  {'id': 'mexico_city', 'name': 'Mexico City', 'flag': '🇲🇽'},
];

class CityScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const CityScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you headed?',
              style: GoogleFonts.fraunces(
                  fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick your city to start exploring.',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: _kCities.map((city) {
                final selected = provider.cityId == city['id'];
                return GestureDetector(
                  onTap: () => provider.cityId = city['id']!,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFC17B4E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFFC17B4E)
                              : const Color(0xFFE0D9D0)),
                    ),
                    child: Row(
                      children: [
                        Text(city['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Text(city['name']!,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : const Color(0xFF2C2825))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: [
              TextButton(
                  onPressed: onBack,
                  child: Text('Back',
                      style: GoogleFonts.inter(color: const Color(0xFF6B6560)))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC17B4E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Continue',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
