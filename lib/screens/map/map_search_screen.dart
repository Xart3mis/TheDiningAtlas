import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/route_names.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  static const _defaultPosition = LatLng(35.6762, 139.6503);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadNearby());
  }

  Future<void> _loadNearby() async {
    if (!mounted) return;
    final locationProvider = context.read<LocationProvider>();
    final restaurantProvider = context.read<RestaurantProvider>();

    final pos = await locationProvider.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      // Convert geolocator Position to Firestore GeoPoint
      final geoPoint = GeoPoint(pos.latitude, pos.longitude);
      await restaurantProvider.loadNearby(geoPoint);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
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
              initialCenter: _defaultPosition,
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
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.ink),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _CuisineFilterBar(),
          ),
        ],
      ),
    );
  }
}

class _CuisineFilterBar extends StatelessWidget {
  const _CuisineFilterBar();

  static const _filters = ['All', 'Japanese', 'Cafe', 'Street Food', 'Bar'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((f) {
          return GestureDetector(
            onTap: () {
              final provider = context.read<RestaurantProvider>();
              if (f == 'All') {
                provider.loadFeed(cityId: provider.currentCityId);
              } else {
                // Use search as a proxy for category filtering
                provider.search(f);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Text(f,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.ink)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
