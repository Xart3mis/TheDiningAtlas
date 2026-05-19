import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/errors/app_exception.dart';
import '../models/restaurant_model.dart';
import '../services/interfaces/i_restaurant_service.dart';
import '../services/interfaces/i_user_service.dart';
import 'geofence_provider.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final IUserService _userService;
  final IRestaurantService _restaurantService;
  final GeofenceProvider _geofenceProvider;

  SavedPlacesProvider(
    this._userService,
    this._restaurantService,
    this._geofenceProvider,
  );

  Set<String> _savedIds = {};
  List<RestaurantModel> _savedRestaurants = [];
  Map<String, bool> _reminders = {};
  bool _isLoading = false;
  bool _loaded = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get savedIds => _savedIds;
  List<RestaurantModel> get savedRestaurants => _savedRestaurants;
  bool isSaved(String placeId) => _savedIds.contains(placeId);
  bool reminderEnabled(String placeId) => _reminders[placeId] ?? false;
  int get uniqueCityCount =>
      _savedRestaurants.map((r) => r.cityId).toSet().length;

  // Legacy load used by feed screens — unchanged behaviour.
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

  Future<void> loadSavedRestaurants(String uid) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    // Fetch IDs — fall back to Hive on network failure
    List<String> ids;
    try {
      ids = await _userService.fetchSavedPlaceIds(uid);
      Hive.box<String>('saved_ids').put(uid, jsonEncode(ids));
    } catch (e) {
      final cached = Hive.box<String>('saved_ids').get(uid);
      if (cached != null) {
        _savedIds = Set<String>.from(jsonDecode(cached) as List);
        _isLoading = false;
        notifyListeners();
        return; // IDs visible; no detail fetches while offline
      }
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Kick off reminder flags fetch in parallel with detail fetches
    final flagsFuture = _userService.fetchSavedPlaceFlags(uid);
    _savedIds = ids.toSet();

    final results = <RestaurantModel>[];
    for (final id in ids) {
      try {
        results.add(await _restaurantService.fetchById(id));
      } catch (_) {
        // Skip restaurants that can no longer be found
      }
    }

    try {
      _reminders = await flagsFuture;
    } catch (_) {
      _reminders = {};
    }

    _savedRestaurants = results;
    _loaded = true;
    _geofenceProvider.setWatchList(_savedRestaurants, _reminders);

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _savedIds = {};
    _savedRestaurants = [];
    _reminders = {};
    _isLoading = false;
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  Future<void> toggleSave(
      {required String uid, required RestaurantModel restaurant}) async {
    _error = null;
    final wasSaved = _savedIds.contains(restaurant.id);

    // Optimistic update
    if (wasSaved) {
      _savedIds.remove(restaurant.id);
      _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
      _reminders.remove(restaurant.id);
    } else {
      _savedIds.add(restaurant.id);
      _savedRestaurants.add(restaurant);
      _reminders[restaurant.id] = true; // default reminder on when saving
    }
    _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
    notifyListeners();

    try {
      if (wasSaved) {
        await _userService.unsavePlace(uid: uid, placeId: restaurant.id);
      } else {
        await _userService.savePlace(
            uid: uid, placeId: restaurant.id, reminderEnabled: true);
      }
    } on QuotaException catch (e) {
      // Roll back optimistic update
      if (wasSaved) {
        _savedIds.add(restaurant.id);
        _savedRestaurants.add(restaurant);
        _reminders[restaurant.id] = true;
      } else {
        _savedIds.remove(restaurant.id);
        _savedRestaurants.removeWhere((r) => r.id == restaurant.id);
        _reminders.remove(restaurant.id);
      }
      _error = e.message;
      _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
      notifyListeners();
    }
  }

  Future<void> toggleReminder(String uid, String placeId) async {
    final current = _reminders[placeId] ?? false;
    _reminders[placeId] = !current; // optimistic
    _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
    notifyListeners();
    try {
      await _userService.updateReminderEnabled(uid, placeId, !current);
    } catch (e) {
      _reminders[placeId] = current; // roll back
      _geofenceProvider.setWatchList(_savedRestaurants, _reminders);
      _error = e.toString();
      notifyListeners();
    }
  }
}
