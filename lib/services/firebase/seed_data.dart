import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/app_constants.dart';

Future<void> seedRestaurants() async {
  final db = FirebaseFirestore.instance;
  final col = db.collection(AppConstants.kColRestaurants);

  final restaurants = [
    RestaurantModel(
      id: '', name: 'Sushi Dai', category: 'Japanese', cityId: 'tokyo',
      neighborhood: 'Tsukiji', geopoint: const GeoPoint(35.6654, 139.7707),
      description: 'Standing sushi counter beloved by locals and chefs alike.',
      tip: 'Arrive before 6am.', dish: 'Omakase set', mediaUrls: [],
      contributorId: 'system', status: 'approved', avgRating: 4.9,
      reviewCount: 0, saveCount: 0, priceRange: '\$\$',
      tileColor: const Color(0xFF4A7C6F), badge: 'Local Legend',
      tagline: 'The sushi Tokyo chefs eat on their days off.',
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ),
  ];

  for (final r in restaurants) {
    await col.add(r.toFirestore());
  }
}
