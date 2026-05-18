import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';
import '../models/seed_data_model.dart';
import '../services/firebase/firestore_seed_data_service.dart';

class SeedDataProvider extends ChangeNotifier {
  final FirestoreSeedDataService _service;

  SeedDataProvider(this._service);

  List<SeedCityModel> _cities = [];
  List<SeedCityModel> _passportCities = [];
  final Map<String, List<String>> _categoriesByCity = {};
  final Map<String, List<RestaurantModel>> _restaurantsByCity = {};
  bool _isLoading = false;
  String? _error;

  List<SeedCityModel> get cities => _cities;
  List<RestaurantModel> get restaurants =>
      _restaurantsByCity.values.expand((restaurants) => restaurants).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  SeedCityModel? get defaultCity => _cities.isEmpty ? null : _cities.first;
  List<SeedCityModel> get passportCities => _passportCities;

  Future<void> load() async {
    if (_cities.isNotEmpty || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _cities = await _service.fetchCities();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  SeedCityModel? cityById(String id) {
    for (final city in cities) {
      if (city.id == id) return city;
    }
    return null;
  }

  List<String> categoriesForCity(String cityId) =>
      _categoriesByCity[cityId] ?? const [];

  List<RestaurantModel> restaurantsForCity(String cityId) =>
      _restaurantsByCity[cityId] ?? const [];

  Future<void> loadCityDetails(String cityId) async {
    if (cityId.isEmpty ||
        (_categoriesByCity.containsKey(cityId) &&
            _restaurantsByCity.containsKey(cityId))) {
      return;
    }

    try {
      final categories = await _service.fetchCategoriesForCity(cityId);
      final restaurants = await _service.fetchRestaurantsForCity(cityId);
      _categoriesByCity[cityId] = categories;
      _restaurantsByCity[cityId] = restaurants;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPassportCities(Set<String> restaurantIds) async {
    try {
      _passportCities = await _service.fetchCitiesForRestaurantIds(restaurantIds);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
