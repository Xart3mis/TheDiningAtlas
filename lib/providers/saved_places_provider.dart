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
      this._userService, this._notificationService, this._restaurantService);

  Set<String> _savedIds = {};
  List<RestaurantModel> _savedRestaurants = [];
  bool _isLoading = false;
  bool _loaded = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get savedIds => _savedIds;
  List<RestaurantModel> get savedRestaurants => _savedRestaurants;
  bool isSaved(String placeId) => _savedIds.contains(placeId);
  int get uniqueCityCount => _savedRestaurants.map((r) => r.cityId).toSet().length;

  Future<void> loadSaved(String uid) async {
    if (_loaded) return;
    _isLoading = true;
    notifyListeners();
    try {
      final ids = await _userService.fetchSavedPlaceIds(uid);
      _savedIds = ids.toSet();
      _savedRestaurants = await Future.wait(
        ids.map((id) => _restaurantService.fetchById(id)),
      ).then((list) => list.whereType<RestaurantModel>().toList());
      _loaded = true;
    } catch (_) {
      _savedRestaurants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave({required String uid, required RestaurantModel restaurant}) async {
    _error = null;
    final wasSaved = _savedIds.contains(restaurant.id);
    if (wasSaved) {
      _savedIds.remove(restaurant.id);
      _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
    } else {
      _savedIds.add(restaurant.id);
      _savedRestaurants.add(restaurant);
    }
    notifyListeners();
    try {
      if (wasSaved) {
        await _userService.unsavePlace(uid: uid, placeId: restaurant.id);
        await _notificationService.cancelGeofenceNotification(restaurant.id);
      } else {
        await _userService.savePlace(uid: uid, placeId: restaurant.id, reminderEnabled: true);
        await _notificationService.scheduleGeofenceNotification(
          placeId: restaurant.id, placeName: restaurant.name,
          lat: restaurant.geopoint.latitude, lng: restaurant.geopoint.longitude,
        );
      }
    } on QuotaException catch (e) {
      if (wasSaved) {
        _savedIds.add(restaurant.id);
        _savedRestaurants.add(restaurant);
      } else {
        _savedIds.remove(restaurant.id);
        _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
      }
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      if (wasSaved) {
        _savedIds.add(restaurant.id);
        _savedRestaurants.add(restaurant);
      } else {
        _savedIds.remove(restaurant.id);
        _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
      }
      notifyListeners();
      rethrow;
    }
  }
}
