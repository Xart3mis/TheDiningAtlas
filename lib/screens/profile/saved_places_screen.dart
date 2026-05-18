import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_places_provider.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/route_names.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<SavedPlacesProvider>().loadSavedRestaurants(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = context.watch<SavedPlacesProvider>();
    final restaurants = savedProvider.savedRestaurants;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text('Saved Places',
            style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: savedProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))
          : restaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_border,
                          size: 48, color: AppColors.warmGrey),
                      const SizedBox(height: 12),
                      Text(
                        'No saved places yet.',
                        style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Explore and save places you love.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.warmGrey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  itemCount: restaurants.length,
                  itemBuilder: (_, i) =>
                      _SavedPlaceCard(restaurant: restaurants[i]),
                ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final RestaurantModel restaurant;
  const _SavedPlaceCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
          context, RouteNames.kRestaurantDetail,
          arguments: restaurant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.lightGrey.withOpacity(0.6)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: restaurant.mediaUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.mediaUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: restaurant.tileColor),
                      errorWidget: (_, __, ___) =>
                          Container(color: restaurant.tileColor),
                    )
                  : StripeTile(
                      color: restaurant.tileColor,
                      width: 90,
                      height: 90,
                      borderRadius: BorderRadius.zero,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name,
                        style: GoogleFonts.fraunces(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                        '${restaurant.category} · ${restaurant.neighborhood}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.warmGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    StarRating(rating: restaurant.avgRating, size: 11),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark,
                  color: AppColors.terracotta, size: 20),
              onPressed: () async {
                final uid =
                    context.read<AuthProvider>().user?.uid ?? '';
                await context
                    .read<SavedPlacesProvider>()
                    .toggleSave(uid: uid, restaurant: restaurant);
              },
            ),
          ],
        ),
      ),
    );
  }
}
