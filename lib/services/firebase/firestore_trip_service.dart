import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_trip_service.dart';
import '../../models/trip_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreTripService implements ITripService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _tripsCol(String uid) => _db
      .collection(AppConstants.kColTrips)
      .doc(uid)
      .collection(AppConstants.kColUserTrips);

  @override
  Future<List<TripModel>> fetchTrips(String uid) async {
    final snap = await _tripsCol(uid).orderBy('startDate', descending: true).get();
    final trips = <TripModel>[];

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final daysSnap = await _tripsCol(uid)
          .doc(doc.id)
          .collection(AppConstants.kColDays)
          .orderBy('date')
          .get();

      final days = <TripDayModel>[];
      for (final dayDoc in daysSnap.docs) {
        final dd = dayDoc.data() as Map<String, dynamic>;
        final spotsSnap = await _tripsCol(uid)
            .doc(doc.id)
            .collection(AppConstants.kColDays)
            .doc(dayDoc.id)
            .collection(AppConstants.kColSpots)
            .orderBy('time')
            .get();

        final spots = spotsSnap.docs.map((s) {
          final sd = s.data() as Map<String, dynamic>;
          return TripSpotModel(
            id: s.id,
            time: sd['time'] ?? '',
            mealType: sd['mealType'] ?? '',
            restaurantId: sd['restaurantId'] ?? '',
            name: sd['name'] ?? '',
            neighborhood: sd['neighborhood'] ?? '',
            statusLabel: sd['statusLabel'] ?? '',
          );
        }).toList();

        days.add(TripDayModel(
          id: dayDoc.id,
          date: (dd['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          spots: spots,
        ));
      }

      trips.add(TripModel(
        id: doc.id,
        uid: uid,
        title: d['title'] ?? '',
        cityId: d['cityId'] ?? '',
        startDate: (d['startDate'] as Timestamp).toDate(),
        endDate: (d['endDate'] as Timestamp).toDate(),
        participantUids: List<String>.from(d['participantUids'] ?? []),
        days: days,
      ));
    }
    return trips;
  }

  @override
  Future<String> createTrip(TripModel trip) async {
    final ref = await _tripsCol(trip.uid).add({
      'title': trip.title,
      'cityId': trip.cityId,
      'startDate': Timestamp.fromDate(trip.startDate),
      'endDate': Timestamp.fromDate(trip.endDate),
      'participantUids': trip.participantUids,
    });

    // Seed empty day documents so the day selector has entries
    if (trip.days.isNotEmpty) {
      final batch = _db.batch();
      for (final day in trip.days) {
        final dayRef = _tripsCol(trip.uid)
            .doc(ref.id)
            .collection(AppConstants.kColDays)
            .doc(day.id);
        batch.set(dayRef, {'date': Timestamp.fromDate(day.date)});
      }
      await batch.commit();
    }
    return ref.id;
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    await _tripsCol(trip.uid).doc(trip.id).update({'title': trip.title});
  }

  @override
  Future<void> deleteTrip({required String uid, required String tripId}) async {
    await _tripsCol(uid).doc(tripId).delete();
  }

  @override
  Future<void> addSpot({required String uid, required String tripId, required String dayId, required TripSpotModel spot}) async {
    await _tripsCol(uid).doc(tripId)
        .collection(AppConstants.kColDays).doc(dayId)
        .collection(AppConstants.kColSpots).add({
      'time': spot.time,
      'mealType': spot.mealType,
      'restaurantId': spot.restaurantId,
      'name': spot.name,
      'neighborhood': spot.neighborhood,
      'statusLabel': spot.statusLabel,
    });
  }

  @override
  Future<void> removeSpot({required String uid, required String tripId, required String dayId, required String spotId}) async {
    await _tripsCol(uid).doc(tripId)
        .collection(AppConstants.kColDays).doc(dayId)
        .collection(AppConstants.kColSpots).doc(spotId).delete();
  }
}
