import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/interfaces/i_restaurant_service.dart';
import '../models/restaurant_model.dart';

class RestaurantProvider extends ChangeNotifier {
  final IRestaurantService _service;
  RestaurantProvider(this._service);

  List<RestaurantModel> _feed = [];
  List<RestaurantModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _currentCityId = 'tokyo';

  List<RestaurantModel> get feed => _feed;
  List<RestaurantModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCityId => _currentCityId;

  static const _timeout = Duration(seconds: 10);

  Future<void> loadFeed({String? cityId}) async {
    _currentCityId = cityId ?? _currentCityId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _feed = await _service
          .fetchFeed(cityId: _currentCityId)
          .timeout(_timeout, onTimeout: () => []);
    } catch (e) {
      _error = e.toString();
      _feed = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearby(GeoPoint center) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _feed = await _service
          .fetchNearby(center: center)
          .timeout(_timeout, onTimeout: () => []);
    } catch (e) {
      _error = e.toString();
      _feed = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _searchResults = await _service
          .search(query: query, cityId: _currentCityId)
          .timeout(_timeout, onTimeout: () => []);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RestaurantModel?> fetchById(String id) async {
    try {
      return await _service.fetchById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> addRestaurant(RestaurantModel restaurant) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addRestaurant(restaurant);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
