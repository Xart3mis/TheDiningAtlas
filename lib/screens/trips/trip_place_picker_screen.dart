import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/trip_model.dart';

class TripPlacePickerScreen extends StatefulWidget {
  final String tripId;
  final String dayId;
  final String uid;

  const TripPlacePickerScreen({
    super.key,
    required this.tripId,
    required this.dayId,
    required this.uid,
  });

  @override
  State<TripPlacePickerScreen> createState() => _TripPlacePickerScreenState();
}

class _TripPlacePickerScreenState extends State<TripPlacePickerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final rp = context.read<RestaurantProvider>();
      if (rp.feed.isEmpty) {
        rp.loadFeed(cityId: rp.currentCityId.isNotEmpty ? rp.currentCityId : 'paris_france');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = context.watch<RestaurantProvider>().feed;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text('Pick a Place',
            style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: restaurants.isEmpty
          ? Center(
              child: Text('No restaurants available.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.warmGrey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: restaurants.length,
              itemBuilder: (_, i) {
                final r = restaurants[i];
                return GestureDetector(
                  onTap: () => _addSpot(context, r),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.lightGrey.withOpacity(0.6)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: r.mediaUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: r.mediaUrls.first,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: r.tileColor),
                                  errorWidget: (_, __, ___) =>
                                      Container(color: r.tileColor),
                                )
                              : StripeTile(
                                  color: r.tileColor,
                                  width: 80,
                                  height: 80,
                                  borderRadius: BorderRadius.zero,
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                    style: GoogleFonts.fraunces(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${r.category} · ${r.neighborhood}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.warmGrey)),
                                const SizedBox(height: 4),
                                StarRating(rating: r.avgRating, size: 11),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.add_circle_outline,
                              color: AppColors.terracotta, size: 22),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addSpot(BuildContext context, RestaurantModel r) async {
    final tripProvider = context.read<TripProvider>();
    final spot = TripSpotModel(
      id: '',
      time: '12:00',
      mealType: 'Meal',
      restaurantId: r.id,
      name: r.name,
      neighborhood: r.neighborhood,
      statusLabel: 'Planned',
      statusColor: Colors.green,
      tileColor: r.tileColor,
    );
    try {
      await tripProvider.addSpot(
        uid: widget.uid,
        tripId: widget.tripId,
        dayId: widget.dayId,
        spot: spot,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${r.name} added to your trip!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add place: $e')));
      }
    }
  }
}
