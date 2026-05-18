import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final seedProvider = context.read<SeedDataProvider>();
      await seedProvider.load();
      if (!mounted) return;
      final restaurantProvider = context.read<RestaurantProvider>();
      if (restaurantProvider.currentCityId.isEmpty &&
          seedProvider.defaultCity != null) {
        seedProvider.loadCityDetails(seedProvider.defaultCity!.id);
        restaurantProvider.loadFeed(cityId: seedProvider.defaultCity!.id);
      } else {
        seedProvider.loadCityDetails(restaurantProvider.currentCityId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final restaurants = _activeFilter == null
        ? restaurantProvider.feed
        : restaurantProvider.feed
            .where((restaurant) => restaurant.category == _activeFilter)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFilters()),
          if (restaurantProvider.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (restaurants.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No recommendations available.')),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _RecommendationCard(restaurant: restaurants[i]),
                childCount: restaurants.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOR YOU',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmGrey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text('Hand-picked for you',
              style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final seedProvider = context.watch<SeedDataProvider>();
    final restaurantProvider = context.watch<RestaurantProvider>();
    final filters = seedProvider
        .categoriesForCity(restaurantProvider.currentCityId)
        .take(8)
        .toList();
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return AtlasPill(
              label: 'All',
              selected: _activeFilter == null,
              onTap: () => setState(() => _activeFilter = null),
            );
          }
          final filter = filters[i - 1];
          return AtlasPill(
            label: filter,
            selected: filter == _activeFilter,
            onTap: () => setState(() => _activeFilter = filter),
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RestaurantModel restaurant;

  const _RecommendationCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        RouteNames.kRestaurantDetail,
        arguments: restaurant,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            StripeTile(
              color: restaurant.tileColor,
              width: 64,
              height: 64,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.category} · ${restaurant.neighborhood}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.warmGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StarRating(
                    rating: restaurant.avgRating,
                    reviewCount: restaurant.reviewCount,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
