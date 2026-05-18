import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const features = [
      ('Unlimited saves', Icons.bookmark),
      ('Full AI recommendations', Icons.auto_awesome),
      ('Unlimited translations', Icons.translate),
      ('Unlimited chat messages', Icons.chat),
      ('No ads', Icons.block),
      ('Offline city cache', Icons.wifi_off),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2C2825),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('DiningAtlas Premium',
                  style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Experience cities like a true local.',
                  style: GoogleFonts.fraunces(
                      color: const Color(0xFFCCC5B9),
                      fontSize: 16,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 40),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(f.$2, color: const Color(0xFFC17B4E), size: 20),
                        const SizedBox(width: 16),
                        Text(f.$1,
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  )),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFC17B4E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('Monthly',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 14)),
                    Text('EGP 49 / month',
                        style: GoogleFonts.fraunces(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Payment integration coming soon!'))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Upgrade Now',
                            style: GoogleFonts.inter(
                                color: const Color(0xFFC17B4E),
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
