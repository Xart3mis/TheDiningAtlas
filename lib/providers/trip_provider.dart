import 'package:flutter/material.dart';
import '../services/interfaces/i_trip_service.dart';
import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  final ITripService _service;
  TripProvider(this._service);

  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrips(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _trips = await _service.fetchTrips(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot}) async {
    await _service.addSpot(uid: uid, tripId: tripId, dayId: dayId, spot: spot);
    await loadTrips(uid);
  }

  Future<void> createTrip(String uid, TripModel trip) async {
    await _service.createTrip(trip);
    await loadTrips(uid);
  }

  void reset() {
    _trips = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
