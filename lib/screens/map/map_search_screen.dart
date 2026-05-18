import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/seed_data_provider.dart';
import '../../core/constants/route_names.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  static const _fallbackPosition = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadNearby());
  }

  Future<void> _loadNearby() async {
    if (!mounted) return;
    final seedProvider = context.read<SeedDataProvider>();
    final locationProvider = context.read<LocationProvider>();
    final restaurantProvider = context.read<RestaurantProvider>();

    await seedProvider.load();
    if (!mounted) return;

    final pos = await locationProvider.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      final geoPoint = GeoPoint(pos.latitude, pos.longitude);
      await restaurantProvider.loadNearby(geoPoint);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } else {
      final city = seedProvider.cityById(restaurantProvider.currentCityId) ??
          seedProvider.defaultCity;
      if (city != null) {
        await seedProvider.loadCityDetails(city.id);
        await restaurantProvider.loadFeed(cityId: city.id);
        _mapController.move(
          LatLng(city.geopoint.latitude, city.geopoint.longitude),
          13,
        );
      }
    }
    if (mounted) _buildMarkers();
  }

  void _buildMarkers() {
    if (!mounted) return;
    final restaurants = context.read<RestaurantProvider>().feed;
    setState(() {
      _markers = restaurants.map((r) {
        return Marker(
          width: 40,
          height: 40,
          point: LatLng(r.geopoint.latitude, r.geopoint.longitude),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.kRestaurantDetail,
              arguments: r,
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.terracotta,
              size: 40,
            ),
          ),
        );
      }).toList();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _fallbackPosition,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dining_atlas',
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ]),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.ink),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _CuisineFilterBar(onChanged: _buildMarkers),
          ),
        ],
      ),
    );
  }
}

class _CuisineFilterBar extends StatefulWidget {
  final VoidCallback onChanged;
  const _CuisineFilterBar({required this.onChanged});

  @override
  State<_CuisineFilterBar> createState() => _CuisineFilterBarState();
}

class _CuisineFilterBarState extends State<_CuisineFilterBar> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    final seedProvider = context.watch<SeedDataProvider>();
    final restaurantProvider = context.watch<RestaurantProvider>();
    final filters = seedProvider
        .categoriesForCity(restaurantProvider.currentCityId)
        .take(8)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['All', ...filters].map((f) {
          final isSelected = _selected == f;
          return GestureDetector(
            onTap: () async {
              setState(() => _selected = f);
              final provider = context.read<RestaurantProvider>();
              if (f == 'All') {
                await provider.loadFeed(cityId: provider.currentCityId);
              } else {
                await provider.loadCategory(f);
              }
              if (!mounted) return;
              widget.onChanged();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.terracotta : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Text(f,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.ink)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
