import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';

class CityGuideScreen extends StatelessWidget {
  final CityGuide guide;
  const CityGuideScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildCuratedGuides()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Stack(
      children: [
        // Hero stripe tile
        StripeTile(
          color: guide.heroColor,
          width: double.infinity,
          height: 260,
          borderRadius: BorderRadius.zero,
        ),
        // Gradient overlay
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
            ),
          ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
        ),
        // Text overlay
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${guide.season.toUpperCase()} · GUIDE',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(guide.city,
                  style: GoogleFonts.fraunces(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
              const SizedBox(height: 6),
              Text(guide.tagline,
                  style: GoogleFonts.fraunces(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.9), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatItem(value: '${guide.spots}', label: 'SPOTS'),
          const SizedBox(width: 24),
          _StatItem(value: '${guide.reviewers}', label: 'REVIEWERS'),
          const SizedBox(width: 24),
          _StatItem(value: '${guide.stories}', label: 'STORIES'),
        ],
      ),
    );
  }

  Widget _buildCuratedGuides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: const SectionLabel('Curated Guides'),
        ),
        ...guide.guides.map((g) => _GuideRow(guide: g, onTap: () {})),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2)),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  final CuratedGuide guide;
  final VoidCallback onTap;
  const _GuideRow({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            StripeTile(
              color: guide.tileColor,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.title,
                      style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('${guide.count} restaurants',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.warmGrey),
          ],
        ),
      ),
    );
  }
}
