import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_notification_service.dart';
import '../services/interfaces/i_restaurant_service.dart';
import '../models/restaurant_model.dart';
import '../core/errors/app_exception.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final IUserService _userService;
  final INotificationService _notificationService;
  final IRestaurantService _restaurantService;

  SavedPlacesProvider(
    this._userService,
    this._notificationService,
    this._restaurantService,
  );

  Set<String> _savedIds = {};
  List<RestaurantModel> _savedRestaurants = [];
  bool _loadingRestaurants = false;
  String? _error;

  bool get isLoading => _loadingRestaurants;
  String? get error => _error;
  Set<String> get savedIds => _savedIds;
  List<RestaurantModel> get savedRestaurants => _savedRestaurants;
  bool isSaved(String placeId) => _savedIds.contains(placeId);

  Future<void> loadSaved(String uid) async {
    final ids = await _userService.fetchSavedPlaceIds(uid);
    _savedIds = ids.toSet();
    notifyListeners();
  }

  Future<void> loadSavedRestaurants(String uid) async {
    _loadingRestaurants = true;
    notifyListeners();
    try {
      final ids = await _userService.fetchSavedPlaceIds(uid);
      _savedIds = ids.toSet();
      final results = <RestaurantModel>[];
      for (final id in ids) {
        try {
          final restaurant = await _restaurantService.fetchById(id);
          results.add(restaurant);
        } catch (_) {
          // Skip restaurants that can no longer be found
        }
      }
      _savedRestaurants = results;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingRestaurants = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave(
      {required String uid, required RestaurantModel restaurant}) async {
    _error = null;
    try {
      if (_savedIds.contains(restaurant.id)) {
        await _userService.unsavePlace(uid: uid, placeId: restaurant.id);
        await _notificationService.cancelGeofenceNotification(restaurant.id);
        _savedIds.remove(restaurant.id);
        _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
      } else {
        await _userService.savePlace(
            uid: uid, placeId: restaurant.id, reminderEnabled: true);
        await _notificationService.scheduleGeofenceNotification(
          placeId: restaurant.id,
          placeName: restaurant.name,
          lat: restaurant.geopoint.latitude,
          lng: restaurant.geopoint.longitude,
        );
        _savedIds.add(restaurant.id);
        _savedRestaurants.add(restaurant);
      }
      notifyListeners();
    } on QuotaException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
