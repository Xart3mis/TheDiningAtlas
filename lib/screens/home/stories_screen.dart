import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seedProvider = context.watch<SeedDataProvider>();
    final restaurantProvider = context.watch<RestaurantProvider>();
    if (seedProvider.cities.isEmpty && !seedProvider.isLoading) {
      final seed = context.read<SeedDataProvider>();
      final restaurants = context.read<RestaurantProvider>();
      Future.microtask(() async {
        await seed.load();
        final defaultCity = seed.defaultCity;
        if (defaultCity != null && restaurants.currentCityId.isEmpty) {
          seed.loadCityDetails(defaultCity.id);
          restaurants.loadFeed(cityId: defaultCity.id);
        } else {
          seed.loadCityDetails(restaurants.currentCityId);
        }
      });
    }

    final storyRestaurant = restaurantProvider.feed.isNotEmpty
        ? restaurantProvider.feed.first
        : seedProvider.restaurants.isNotEmpty
            ? seedProvider.restaurants.first
            : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF6B4A2A), Color(0xFF1A0D00)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _TabItem(
                          label: 'Following', selected: false, onTap: () {}),
                      const SizedBox(width: 24),
                      _TabItem(label: 'For You', selected: true, onTap: () {}),
                      const SizedBox(width: 24),
                      _TabItem(label: 'Near Me', selected: false, onTap: () {}),
                      const Spacer(),
                      const Icon(Icons.search, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 32),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const StripeTile(
                    color: AppColors.terracotta,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storyRestaurant?.name ?? 'Loading',
                            style: GoogleFonts.fraunces(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        Text(_storySubtitle(storyRestaurant),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.warmGrey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: storyRestaurant == null
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              RouteNames.kRestaurantDetail,
                              arguments: storyRestaurant,
                            ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('View',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _storySubtitle(RestaurantModel? restaurant) {
    if (restaurant == null) return '';
    return '${restaurant.neighborhood} · ${restaurant.category}';
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : Colors.white54)),
          const SizedBox(height: 3),
          if (selected)
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(1)),
            ),
        ],
      ),
    );
  }
}
