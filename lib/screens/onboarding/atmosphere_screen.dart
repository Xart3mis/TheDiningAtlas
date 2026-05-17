import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kAtmospheres = [
  {'id': 'quiet', 'label': 'Quiet & intimate'},
  {'id': 'lively', 'label': 'Lively & social'},
  {'id': 'outdoor', 'label': 'Outdoor & scenic'},
  {'id': 'artsy', 'label': 'Artsy & alternative'},
  {'id': 'family', 'label': 'Family-friendly'},
  {'id': 'late_night', 'label': 'Late night'},
];

class AtmosphereScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const AtmosphereScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's the vibe you're after?",
              style: GoogleFonts.fraunces(
                  fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick all that fit you.',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kAtmospheres.map((a) {
              final selected = provider.atmosphere.contains(a['id']);
              return FilterChip(
                label: Text(a['label']!),
                selected: selected,
                onSelected: (_) {
                  final current = List<String>.from(provider.atmosphere);
                  if (selected) {
                    current.remove(a['id']);
                  } else {
                    current.add(a['id']!);
                  }
                  provider.atmosphere = current;
                },
                selectedColor: const Color(0xFFC17B4E),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF2C2825),
                    fontWeight: FontWeight.w500),
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: selected
                        ? const Color(0xFFC17B4E)
                        : const Color(0xFFE0D9D0)),
              );
            }).toList(),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                  onPressed: onBack,
                  child: Text('Back',
                      style: GoogleFonts.inter(color: const Color(0xFF6B6560)))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.atmosphere.isNotEmpty ? onNext : null,
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
