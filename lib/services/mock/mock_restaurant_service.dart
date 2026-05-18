import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../interfaces/i_restaurant_service.dart';
import '../../models/restaurant_model.dart';

final _kSampleRestaurants = [
  RestaurantModel(
    id: 'r1', name: 'Sushi Dai', category: 'Japanese', cityId: 'tokyo',
    neighborhood: 'Tsukiji', geopoint: const GeoPoint(35.6654, 139.7707),
    description: 'Standing sushi counter beloved by locals and chefs alike.',
    tip: 'Arrive before 6am. The wait is worth it.',
    dish: 'Omakase set', mediaUrls: [], contributorId: 'u1',
    status: 'approved', avgRating: 4.9, reviewCount: 312, saveCount: 89,
    priceRange: '\$\$', tileColor: const Color(0xFF4A7C6F), badge: 'Local Legend',
    tagline: 'The sushi Tokyo chefs eat on their days off.',
    createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1),
  ),
  RestaurantModel(
    id: 'r2', name: 'Afuri Ramen', category: 'Japanese', cityId: 'tokyo',
    neighborhood: 'Harajuku', geopoint: const GeoPoint(35.6694, 139.7028),
    description: 'Yuzu-scented shio ramen in a sleek minimalist space.',
    tip: 'Order the yuzu shio. Nothing else matters.',
    dish: 'Yuzu Shio Ramen', mediaUrls: [], contributorId: 'u1',
    status: 'approved', avgRating: 4.7, reviewCount: 198, saveCount: 54,
    priceRange: '\$\$', tileColor: const Color(0xFFC17B4E), badge: null,
    tagline: 'Citrus-bright ramen that reinvented the bowl.',
    createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1),
  ),
];

class MockRestaurantService implements IRestaurantService {
  @override
  Future<List<RestaurantModel>> fetchFeed({required String cityId, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kSampleRestaurants.where((r) => r.cityId == cityId).take(limit).toList();
  }

  @override
  Future<List<RestaurantModel>> fetchNearby({required GeoPoint center, double radiusKm = 0.5}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kSampleRestaurants;
  }

  @override
  Future<List<RestaurantModel>> fetchByCategory({required String category, required String cityId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _kSampleRestaurants.where((r) => r.category == category && r.cityId == cityId).toList();
  }

  @override
  Future<List<RestaurantModel>> search({required String query, required String cityId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    return _kSampleRestaurants.where((r) =>
      r.name.toLowerCase().contains(q) || r.description.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Future<RestaurantModel> fetchById(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _kSampleRestaurants.firstWhere((r) => r.id == restaurantId,
        orElse: () => _kSampleRestaurants.first);
  }

  @override
  Future<String> addRestaurant(RestaurantModel restaurant) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_id_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
