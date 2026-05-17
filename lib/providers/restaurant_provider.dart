import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';

class RestaurantProvider extends ChangeNotifier {
  List<RestaurantModel> _feed = [];
  bool _isLoading = false;
  String? _error;
  String _currentCityId = 'tokyo';

  List<RestaurantModel> get feed => _feed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCityId => _currentCityId;

  Future<void> loadFeed({required String cityId}) async {
    _currentCityId = cityId;
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _feed = _mockFeed(cityId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNearby(dynamic pos) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _feed = _mockFeed(_currentCityId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchByCategory(String category) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _feed = _mockFeed(_currentCityId)
        .where((r) => category == 'All' || r.category == category)
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRestaurant(RestaurantModel restaurant) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // No-op until Joe wires real service
  }

  List<RestaurantModel> _mockFeed(String cityId) => [
    RestaurantModel(
      id: 'sushi_dai',
      name: 'Sushi Dai',
      category: 'Restaurant',
      cityId: cityId,
      neighborhood: 'Tsukiji',
      geopoint: const GeoPoint(35.6654, 139.7707),
      description: 'An unadorned counter, ten seats, and the chef\'s decisive hand.',
      tip: 'Come before 5am to beat the queue.',
      dish: 'Omakase set',
      mediaUrls: [],
      contributorId: 'local_001',
      status: 'approved',
      avgRating: 4.9,
      reviewCount: 312,
      saveCount: 1024,
      priceRange: '\$\$\$',
      tileColor: const Color(0xFF7090A0),
      tagline: 'The best sushi counter in Tokyo.',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    RestaurantModel(
      id: 'afuri_ramen',
      name: 'Afuri Ramen',
      category: 'Restaurant',
      cityId: cityId,
      neighborhood: 'Ebisu',
      geopoint: const GeoPoint(35.6472, 139.7100),
      description: 'Yuzu-forward broth, impossibly light.',
      tip: 'Order the yuzu shio ramen.',
      dish: 'Yuzu Shio Ramen',
      mediaUrls: [],
      contributorId: 'local_002',
      status: 'approved',
      avgRating: 4.7,
      reviewCount: 204,
      saveCount: 850,
      priceRange: '\$\$',
      tileColor: const Color(0xFFB8962E),
      tagline: 'The bowl that made Ebisu famous.',
      createdAt: DateTime(2025, 2, 1),
      updatedAt: DateTime(2025, 2, 1),
    ),
  ];
}
