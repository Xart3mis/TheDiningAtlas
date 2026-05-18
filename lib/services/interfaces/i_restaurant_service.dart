import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant_model.dart';

abstract class IRestaurantService {
  Future<List<RestaurantModel>> fetchFeed({required String cityId, int limit = 20});
  Future<List<RestaurantModel>> fetchNearby({required GeoPoint center, double radiusKm = 0.5});
  Future<List<RestaurantModel>> fetchByCategory({required String category, required String cityId});
  Future<List<RestaurantModel>> search({required String query, required String cityId});
  Future<RestaurantModel> fetchById(String restaurantId);
  Future<String> addRestaurant(RestaurantModel restaurant);
  Future<void> updateRestaurant(RestaurantModel restaurant);
}
