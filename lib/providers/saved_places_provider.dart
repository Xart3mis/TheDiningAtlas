import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_notification_service.dart';
import '../models/restaurant_model.dart';
import '../core/errors/app_exception.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final IUserService _userService;
  final INotificationService _notificationService;
  SavedPlacesProvider(this._userService, this._notificationService);

  Set<String> _savedIds = {};
  String? _error;

  bool get isLoading => false;
  String? get error => _error;
  bool isSaved(String placeId) => _savedIds.contains(placeId);

  Future<void> loadSaved(String uid) async {
    final ids = await _userService.fetchSavedPlaceIds(uid);
    _savedIds = ids.toSet();
    notifyListeners();
  }

  Future<void> toggleSave({required String uid, required RestaurantModel restaurant}) async {
    _error = null;
    try {
      if (_savedIds.contains(restaurant.id)) {
        await _userService.unsavePlace(uid: uid, placeId: restaurant.id);
        await _notificationService.cancelGeofenceNotification(restaurant.id);
        _savedIds.remove(restaurant.id);
      } else {
        await _userService.savePlace(uid: uid, placeId: restaurant.id, reminderEnabled: true);
        await _notificationService.scheduleGeofenceNotification(
          placeId: restaurant.id, placeName: restaurant.name,
          lat: restaurant.geopoint.latitude, lng: restaurant.geopoint.longitude,
        );
        _savedIds.add(restaurant.id);
      }
      notifyListeners();
    } on QuotaException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
