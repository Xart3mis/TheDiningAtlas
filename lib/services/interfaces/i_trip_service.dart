import '../../models/trip_model.dart';

abstract class ITripService {
  Future<List<TripModel>> fetchTrips(String uid);
  Future<String> createTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> deleteTrip({required String uid, required String tripId});
  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot});
  Future<void> removeSpot({required String uid, required String tripId, required String dayId, required String spotId});
}
