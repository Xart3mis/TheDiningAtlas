import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  List<TripModel> _trips = [];
  bool _isLoading = false;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;

  Future<void> loadTrips(String uid) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _trips = [
      TripModel(
        id: 'trip_1',
        uid: uid,
        cityId: 'tokyo',
        title: 'Tokyo April 2026',
        days: [
          TripDayModel(
            id: 'day_1',
            date: DateTime(2026, 4, 12),
            spots: [
              const TripSpotModel(
                id: 's1',
                restaurantId: 'sushi_dai',
                restaurantName: 'Sushi Dai',
                neighborhood: 'Tsukiji',
                time: '08:30',
                mealType: 'MORNING',
              ),
              const TripSpotModel(
                id: 's2',
                restaurantId: 'afuri_ramen',
                restaurantName: 'Afuri Ramen',
                neighborhood: 'Ebisu',
                time: '13:00',
                mealType: 'LUNCH',
              ),
            ],
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    ];
    _isLoading = false;
    notifyListeners();
  }
}
