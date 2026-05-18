import 'package:cloud_firestore/cloud_firestore.dart';

class SeedCityModel {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final int rank;
  final GeoPoint geopoint;
  final int venueCount;

  const SeedCityModel({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.rank,
    required this.geopoint,
    required this.venueCount,
  });

  String get displayName => '$name, $country';
}
