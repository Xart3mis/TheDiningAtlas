import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final Set<String> _savedIds = {};

  Set<String> get savedIds => _savedIds;

  bool isSaved(String restaurantId) => _savedIds.contains(restaurantId);

  Future<void> loadSaved(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // No-op until Joe wires real service
    notifyListeners();
  }

  Future<void> toggleSave({required String uid, required RestaurantModel restaurant}) async {
    if (_savedIds.contains(restaurant.id)) {
      _savedIds.remove(restaurant.id);
    } else {
      _savedIds.add(restaurant.id);
    }
    notifyListeners();
  }
}
