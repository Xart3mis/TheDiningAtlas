import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';
import 'restaurant_detail_screen.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  String _activeFilter = 'Sushi';
  Restaurant? _selectedRestaurant = sampleRestaurants.first;

  final _cuisineFilters = ['All cuisines', 'Sushi', 'Ramen', 'Kaiseki', '¥'];

  void _onFilterSelect(String f) => setState(() => _activeFilter = f);
  void _onGo() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: Stack(
        children: [
          // Map background
          Positioned.fill(child: CustomPaint(painter: _MapBackgroundPainter())),
          // Price pins
          ..._buildPricePins(),
          // Top search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _buildSearchBar(),
          ),
          // Filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: _buildFilterRow(),
          ),
          // Bottom restaurant card
          if (_selectedRestaurant != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildRestaurantCard(_selectedRestaurant!),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.warmGrey),
                const SizedBox(width: 8),
                Text('"Sushi in Tokyo"', style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
          ),
          child: const Icon(Icons.tune, size: 18, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _cuisineFilters.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == _cuisineFilters.length) {
            return _MapToggle(label: 'map', active: true, onTap: () {});
          }
          final f = _cuisineFilters[i];
          return AtlasPill(
            label: f,
            selected: f == _activeFilter,
            onTap: () => _onFilterSelect(f),
          );
        },
      ),
    );
  }

  List<Widget> _buildPricePins() {
    final pins = [
      (0.15, 0.38, '¥¥', AppColors.terracotta, false),
      (0.62, 0.28, '¥¥¥', AppColors.ink, true),
      (0.38, 0.52, '¥', AppColors.teal, false),
      (0.52, 0.45, null, AppColors.teal, false),
      (0.68, 0.58, '¥¥', AppColors.gold, false),
      (0.2, 0.65, '¥', AppColors.terracotta, false),
    ];
    return pins.map((p) {
      return Positioned(
        left: MediaQuery.of(context).size.width * p.$1,
        top: MediaQuery.of(context).size.height * p.$2,
        child: p.$4 == AppColors.teal && p.$5 == false && p.$3 == null
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.teal, width: 3),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.$5 ? p.$4 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.$5 ? Colors.transparent : p.$4.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Text(
                  p.$3 ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.$5 ? Colors.white : p.$4,
                  ),
                ),
              ),
      );
    }).toList();
  }

  Widget _buildRestaurantCard(Restaurant r) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            StripeTile(color: r.tileColor, width: 56, height: 56, borderRadius: BorderRadius.circular(10)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text('${r.cuisine} · ${r.priceRange} · ${r.neighborhood}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StarRating(rating: r.rating, size: 12),
                      const SizedBox(width: 8),
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal)),
                      const SizedBox(width: 4),
                      Text('Open', style: GoogleFonts.inter(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _onGo,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text('Go', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MapToggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEDE8DC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFD9D4CC).withOpacity(0.5)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // River
    final riverPaint = Paint()
      ..color = const Color(0xFFC8D8D8).withOpacity(0.6)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(size.width * 0.3, size.height * 0.5, size.width * 0.6, size.height * 0.42, size.width, size.height * 0.48);
    canvas.drawPath(path, riverPaint);

    // City blocks
    final blockPaint = Paint()..color = const Color(0xFFD4CFC6).withOpacity(0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.55, size.height * 0.6, 80, 50), const Radius.circular(4)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, size.height * 0.2, 60, 40), const Radius.circular(4)), blockPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
