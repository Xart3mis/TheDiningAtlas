import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/restaurant_model.dart';
import '../../models/seed_data_model.dart';

class FirestoreSeedDataService {
  final FirebaseFirestore _db;

  FirestoreSeedDataService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<SeedCityModel>> fetchCities() async {
    final snap = await _db
        .collection(AppConstants.kColCities)
        .orderBy('country')
        .orderBy('rank')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return SeedCityModel(
        id: doc.id,
        name: data['name'] ?? '',
        country: data['country'] ?? '',
        countryCode: data['countryCode'] ?? '',
        rank: (data['rank'] as num?)?.toInt() ?? 0,
        geopoint: data['geopoint'] ?? const GeoPoint(0, 0),
        venueCount: (data['venueCount'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<String>> fetchCategoriesForCity(String cityId) async {
    if (cityId.isEmpty) return const [];

    final snap = await _db
        .collection(AppConstants.kColRestaurants)
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .get();

    final categories = snap.docs
        .map((doc) => RestaurantModel.fromFirestore(doc).category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  Future<List<RestaurantModel>> fetchRestaurantsForCity(String cityId) async {
    if (cityId.isEmpty) return const [];

    final snap = await _db
        .collection(AppConstants.kColRestaurants)
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .get();

    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  Future<List<SeedCityModel>> fetchCitiesForRestaurantIds(
    Set<String> restaurantIds,
  ) async {
    if (restaurantIds.isEmpty) return const [];

    final cityIds = <String>{};
    final ids = restaurantIds.toList();
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _db
          .collection(AppConstants.kColRestaurants)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final cityId = doc.data()['cityId'] as String?;
        if (cityId != null && cityId.isNotEmpty) cityIds.add(cityId);
      }
    }

    final allCities = await fetchCities();
    return allCities.where((city) => cityIds.contains(city.id)).toList();
  }
}
