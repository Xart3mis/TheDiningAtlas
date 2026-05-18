import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

class BudgetScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const BudgetScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final options = [
      {r'$': r'Under $15 · Budget'},
      {r'$$': r'$15 – $50 · Mid-range'},
      {r'$$$': r'$50 – $100 · Upscale'},
      {r'$$$$': r'$100+ · Fine Dining'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your budget?",
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick what feels right.',
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: options.map((opt) {
                final key = opt.keys.first;
                final label = opt.values.first;
                final selected = provider.budget == key;
                return GestureDetector(
                  onTap: () => provider.setBudget(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFC17B4E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFFC17B4E)
                              : const Color(0xFFE0D9D0)),
                    ),
                    child: Row(
                      children: [
                        Text(key,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFFC17B4E))),
                        const SizedBox(width: 14),
                        Text(label.split(' · ').last,
                            style: TextStyle(
                                fontSize: 14,
                                color: selected
                                    ? Colors.white70
                                    : const Color(0xFF6B6560))),
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
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B6560)))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC17B4E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Continue',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
