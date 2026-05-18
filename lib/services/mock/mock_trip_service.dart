import 'package:flutter/material.dart';
import '../interfaces/i_trip_service.dart';
import '../../models/trip_model.dart';

final _kSampleTrip = TripModel(
  id: 't1', uid: 'u1', title: 'Tokyo, April 2026', cityId: 'tokyo',
  startDate: DateTime(2026, 4, 10), endDate: DateTime(2026, 4, 14),
  participantUids: ['u1', 'u2'],
  days: [
    TripDayModel(id: 'd1', date: DateTime(2026, 4, 10), spots: const [
      TripSpotModel(
        id: 's1', time: '8:00 AM', mealType: 'Breakfast', restaurantId: 'r1',
        name: 'Sushi Dai', neighborhood: 'Tsukiji',
        statusLabel: 'Booked', statusColor: Color(0xFF4A7C6F),
        tileColor: Color(0xFF4A7C6F),
      ),
    ]),
  ],
);

class MockTripService implements ITripService {
  @override
  Future<List<TripModel>> fetchTrips(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [_kSampleTrip];
  }

  @override
  Future<String> createTrip(TripModel trip) async => 'mock_trip_id';

  @override
  Future<void> updateTrip(TripModel trip) async {}

  @override
  Future<void> deleteTrip({required String uid, required String tripId}) async {}

  @override
  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot}) async {}

  @override
  Future<void> removeSpot({required String uid, required String tripId, required String dayId, required String spotId}) async {}
}
