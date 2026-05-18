import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../models/seed_data_model.dart';

class DestinationScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const DestinationScreen({super.key, required this.onNext, required this.onBack});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<SeedDataProvider>().load();
    });
  }

  List<({String code, String name, int venueCount})> _countries(List<SeedCityModel> cities) {
    final seen = <String>{};
    final result = <({String code, String name, int venueCount})>[];
    for (final city in cities) {
      if (seen.add(city.countryCode)) {
        final total = cities
            .where((c) => c.countryCode == city.countryCode)
            .fold(0, (sum, c) => sum + c.venueCount);
        result.add((code: city.countryCode, name: city.country, venueCount: total));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final seedProvider = context.watch<SeedDataProvider>();
    final countries = _countries(seedProvider.cities);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you headed?',
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1A))),
          const SizedBox(height: 8),
          Text('Pick your destination.',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF6B6560))),
          const SizedBox(height: 32),
          Expanded(
            child: seedProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : countries.isEmpty
                    ? Center(
                        child: Text('No destinations available.',
                            style: GoogleFonts.inter(color: const Color(0xFF6B6560))))
                    : ListView.builder(
                        itemCount: countries.length,
                        itemBuilder: (_, i) {
                          final country = countries[i];
                          final selected = provider.countryId == country.code;
                          return GestureDetector(
                            onTap: () => provider.setCountry(country.code, country.name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFC17B4E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected
                                        ? const Color(0xFFC17B4E)
                                        : const Color(0xFFE0D9D0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white.withOpacity(0.25)
                                          : const Color(0xFFC17B4E).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      country.code,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFFC17B4E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      country.name,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF2C2825)),
                                    ),
                                  ),
                                  Text(
                                    '${country.venueCount} places',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: selected
                                            ? Colors.white.withOpacity(0.8)
                                            : const Color(0xFF9B9590)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Row(
            children: [
              TextButton(
                  onPressed: widget.onBack,
                  child: Text('Back',
                      style: GoogleFonts.inter(color: const Color(0xFF6B6560)))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.countryId.isNotEmpty ? widget.onNext : null,
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
