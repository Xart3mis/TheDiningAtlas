import 'package:flutter/material.dart';

class OnboardingProvider extends ChangeNotifier {
  List<String> _vibes = [];
  String _budget = '\$\$';
  List<String> _atmosphere = [];
  String _cityId = 'tokyo';
  bool _isLoading = false;

  List<String> get vibes => _vibes;
  String get budget => _budget;
  List<String> get atmosphere => _atmosphere;
  String get cityId => _cityId;
  bool get isLoading => _isLoading;

  set vibes(List<String> v) {
    _vibes = v;
    notifyListeners();
  }

  set budget(String v) {
    _budget = v;
    notifyListeners();
  }

  set atmosphere(List<String> v) {
    _atmosphere = v;
    notifyListeners();
  }

  set cityId(String v) {
    _cityId = v;
    notifyListeners();
  }

  Future<void> completeOnboarding(String uid) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    // Joe's UserService will persist this to Firestore
    _isLoading = false;
    notifyListeners();
  }
}
