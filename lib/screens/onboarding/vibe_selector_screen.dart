import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _kVibes = [
  {'id': 'hidden_cafe', 'label': 'Hidden Café', 'emoji': '☕'},
  {'id': 'street_food', 'label': 'Street Food', 'emoji': '🌮'},
  {'id': 'rooftop_bar', 'label': 'Rooftop Bar', 'emoji': '🍸'},
  {'id': 'local_market', 'label': 'Local Market', 'emoji': '🛒'},
  {'id': 'art_gallery', 'label': 'Art Gallery', 'emoji': '🎨'},
  {'id': 'night_life', 'label': 'Nightlife', 'emoji': '🎵'},
  {'id': 'fine_dining', 'label': 'Fine Dining', 'emoji': '🍽️'},
  {'id': 'nature_spot', 'label': 'Nature Spot', 'emoji': '🌿'},
  {'id': 'beach_vibes', 'label': 'Beach Vibes', 'emoji': '🏖️'},
  {'id': 'craft_beer', 'label': 'Craft Beer', 'emoji': '🍺'},
  {'id': 'wellness', 'label': 'Wellness', 'emoji': '🧘'},
  {'id': 'cultural', 'label': 'Cultural', 'emoji': '🎭'},
];

class VibeSelectorScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const VibeSelectorScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your vibe?",
              style: GoogleFonts.fraunces(
                  fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick everything that speaks to you.',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: _kVibes.map((vibe) {
                final selected = provider.vibes.contains(vibe['id']);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => provider.toggleVibe(vibe['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFC17B4E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFFC17B4E)
                                : const Color(0xFFE0D9D0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(vibe['emoji']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(vibe['label']!,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF2C2825)),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: onBack,
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6560),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.vibes.isNotEmpty ? onNext : null,
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
