import 'package:cloud_firestore/cloud_firestore.dart';

class TripSpotModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String neighborhood;
  final String time;
  final String mealType;

  const TripSpotModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.neighborhood,
    required this.time,
    required this.mealType,
  });
}

class TripDayModel {
  final String id;
  final DateTime date;
  final List<TripSpotModel> spots;

  const TripDayModel({
    required this.id,
    required this.date,
    required this.spots,
  });
}

class TripModel {
  final String id;
  final String uid;
  final String cityId;
  final String title;
  final List<TripDayModel> days;
  final DateTime createdAt;

  const TripModel({
    required this.id,
    required this.uid,
    required this.cityId,
    required this.title,
    required this.days,
    required this.createdAt,
  });
}
