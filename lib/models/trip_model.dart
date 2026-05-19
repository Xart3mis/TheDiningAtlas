import 'package:flutter/material.dart';

class TripModel {
  final String id;
  final String uid;
  final String title;
  final String cityId;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participantUids;
  final List<TripDayModel> days;

  const TripModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.cityId,
    required this.startDate,
    required this.endDate,
    required this.participantUids,
    required this.days,
  });
}

class TripDayModel {
  final String id;
  final DateTime date;
  final List<TripSpotModel> spots;

  const TripDayModel({required this.id, required this.date, required this.spots});
}

class TripSpotModel {
  final String id;
  final String time;
  final String mealType;
  final String restaurantId;
  final String name;
  final String neighborhood;
  final String statusLabel;
  final Color statusColor;
  final Color tileColor;
  final String? imageUrl;

  const TripSpotModel({
    required this.id,
    required this.time,
    required this.mealType,
    required this.restaurantId,
    required this.name,
    required this.neighborhood,
    required this.statusLabel,
    this.statusColor = Colors.green,
    this.tileColor = const Color(0xFF2E5B52),
    this.imageUrl,
  });
}
