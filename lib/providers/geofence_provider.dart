import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../models/restaurant_model.dart';
import '../services/interfaces/i_location_service.dart';
import '../services/interfaces/i_notification_service.dart';

class GeofenceProvider extends ChangeNotifier {
  final INotificationService _notificationService;
  final ILocationService _locationService;

  GeofenceProvider(this._notificationService, this._locationService);

  StreamSubscription<GeoPoint>? _subscription;
  List<RestaurantModel> _watchList = const [];
  Map<String, bool> _reminders = const {};
  final Map<String, DateTime> _lastNotified = {};

  /// Subscribes to the position stream. No-op if already started.
  void start() {
    if (_subscription != null) return;
    _subscription = _locationService.positionStream().listen(_onPosition);
  }

  /// Cancels the stream subscription and resets the cooldown map.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _lastNotified.clear();
  }

  /// Replaces the watch list. Safe to call while the stream is running.
  void setWatchList(
      List<RestaurantModel> places, Map<String, bool> reminders) {
    _watchList = List.of(places);
    _reminders = Map.of(reminders);
  }

  void _onPosition(GeoPoint userPos) {
    for (final place in _watchList) {
      if (!(_reminders[place.id] ?? false)) continue;

      final distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        place.geopoint.latitude,
        place.geopoint.longitude,
      );

      if (distance >= AppConstants.kGeofenceRadiusMeters) continue;

      final last = _lastNotified[place.id];
      if (last != null &&
          DateTime.now().difference(last) < const Duration(hours: 1)) {
        continue;
      }

      _lastNotified[place.id] = DateTime.now();
      _notificationService.showLocalNotification(
        title: "You're near ${place.name}",
        body: place.tip.isNotEmpty ? place.tip : place.description,
      );
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
