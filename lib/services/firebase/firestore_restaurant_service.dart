import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_restaurant_service.dart';
import '../../models/restaurant_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreRestaurantService implements IRestaurantService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection(AppConstants.kColRestaurants);

  @override
  Future<List<RestaurantModel>> fetchFeed({required String cityId, int limit = 20}) async {
    final snap = await _col
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .orderBy('avgRating', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  @override
  Future<List<RestaurantModel>> fetchNearby({required GeoPoint center, double radiusKm = 0.5}) async {
    // GeoPoint ordering is (latitude, longitude) — a latitude band query gives a
    // good-enough bounding box for venue-scale radii without needing a geohash field.
    final latDelta = radiusKm / 111.0;
    final snap = await _col
        .where('coordinates',
            isGreaterThanOrEqualTo: GeoPoint(center.latitude - latDelta, -180))
        .where('coordinates',
            isLessThanOrEqualTo: GeoPoint(center.latitude + latDelta, 180))
        .limit(50)
        .get();
    return snap.docs
        .map(RestaurantModel.fromFirestore)
        .where((r) => r.status == 'approved')
        .toList();
  }

  @override
  Future<List<RestaurantModel>> fetchByCategory({required String category, required String cityId}) async {
    final snap = await _col
        .where('category', isEqualTo: category)
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .orderBy('avgRating', descending: true)
        .limit(20)
        .get();
    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  @override
  Future<List<RestaurantModel>> search({required String query, required String cityId}) async {
    // Firestore prefix search — for production use Algolia
    final snap = await _col
        .where('cityId', isEqualTo: cityId)
        .where('status', isEqualTo: 'approved')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query')
        .limit(20)
        .get();
    return snap.docs.map(RestaurantModel.fromFirestore).toList();
  }

  @override
  Future<RestaurantModel> fetchById(String restaurantId) async {
    final doc = await _col.doc(restaurantId).get();
    return RestaurantModel.fromFirestore(doc);
  }

  @override
  Future<String> addRestaurant(RestaurantModel restaurant) async {
    final ref = await _col.add(restaurant.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    await _col.doc(restaurant.id).update(restaurant.toFirestore());
  }
}
