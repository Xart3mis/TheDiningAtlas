import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';
import 'city_guide_screen.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  String _selectedCity = 'Tokyo';
  final _cities = ['Tokyo', 'Lisbon', 'Mexico City', 'Bangkok', 'Rome'];

  void _onCityTap(String city) {
    setState(() => _selectedCity = city);
  }

  void _onSearch() {}
  void _onSeeAll() {}
  void _onQuickFilter(String filter) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildMapCard()),
          SliverToBoxAdapter(child: _buildCityChips()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildQuickFilters()),
          SliverToBoxAdapter(child: _buildEditorsPicks()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.language_outlined, size: 22, color: AppColors.ink),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(fontSize: 17, color: AppColors.ink, fontWeight: FontWeight.w600),
                  children: [
                    const TextSpan(text: 'The '),
                    TextSpan(
                      text: 'Dining',
                      style: GoogleFonts.fraunces(fontStyle: FontStyle.italic, color: AppColors.ink),
                    ),
                    const TextSpan(text: ' Atlas'),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: const StripeTile(
              color: AppColors.terracotta,
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CityGuideScreen(guide: tokyoGuide)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Map illustration
            CustomPaint(size: const Size(double.infinity, 200), painter: _MapPainter()),
            // Bottom overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.vertical(top: Radius.zero),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPLORING',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 1.2),
                        ),
                        Text(
                          'Tokyo, Japan',
                          style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text('1284 spots', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AtlasPill(
          label: _cities[i],
          selected: _cities[i] == _selectedCity,
          onTap: () => _onCityTap(_cities[i]),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AtlasSearchBar(
        hint: 'Ramen, kaiseki, late-night…',
        onTap: _onSearch,
        showVoice: true,
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = ['Tonight', 'Nearby', 'Cheap eats', 'Michelin'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AtlasPill(
          label: filters[i],
          selected: i == 0,
          onTap: () => _onQuickFilter(filters[i]),
        ),
      ),
    );
  }

  Widget _buildEditorsPicks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel("Editor's Picks · Tokyo"),
              GestureDetector(
                onTap: _onSeeAll,
                child: Text('See all', style: GoogleFonts.inter(fontSize: 13, color: AppColors.terracotta, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            scrollDirection: Axis.horizontal,
            itemCount: sampleRestaurants.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _EditorPickCard(restaurant: sampleRestaurants[i]),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EditorPickCard extends StatelessWidget {
  final Restaurant restaurant;
  const _EditorPickCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StripeTile(
              color: restaurant.tileColor,
              width: 160,
              height: 72,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: GoogleFonts.fraunces(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.cuisine} · ${restaurant.neighborhood}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.warmGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StarRating(rating: restaurant.rating, size: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple map illustration painter
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.parchment;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final regionPaint = Paint()..color = AppColors.lightGrey.withValues(alpha: 0.6);
    final outlinePaint = Paint()
      ..color = AppColors.warmGrey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw blob-like city regions
    final blobs = [
      Offset(size.width * 0.22, size.height * 0.35),
      Offset(size.width * 0.48, size.height * 0.4),
      Offset(size.width * 0.72, size.height * 0.32),
    ];
    for (final b in blobs) {
      canvas.drawCircle(b, 36, regionPaint);
      canvas.drawCircle(b, 36, outlinePaint);
    }

    // Dots for restaurants
    final dotPaint = Paint()..color = AppColors.ink;
    final dots = [
      Offset(size.width * 0.18, size.height * 0.42),
      Offset(size.width * 0.44, size.height * 0.48),
      Offset(size.width * 0.52, size.height * 0.35),
      Offset(size.width * 0.70, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.5),
    ];
    for (final d in dots) {
      canvas.drawCircle(d, 3, dotPaint);
    }
    // Highlight dot in terracotta
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.5), 4, Paint()..color = AppColors.terracotta);
  }

  @override
  bool shouldRepaint(_) => false;
}
