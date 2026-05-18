import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/onboarding_prefs_model.dart';

class OnboardingProvider extends ChangeNotifier {
  final IUserService _userService;
  final IAiService _aiService;
  OnboardingProvider(this._userService, this._aiService);

  final List<String> _vibes = [];
  String _budget = '\$\$';
  final List<String> _atmosphere = [];
  String _cityId = '';
  bool _isLoading = false;
  bool _completed = false;

  List<String> get vibes => List.unmodifiable(_vibes);
  String get budget => _budget;
  List<String> get atmosphere => List.unmodifiable(_atmosphere);
  String get cityId => _cityId;
  bool get isLoading => _isLoading;
  bool get completed => _completed;

  void toggleVibe(String id) {
    if (_vibes.contains(id)) {
      _vibes.remove(id);
    } else {
      _vibes.add(id);
    }
    notifyListeners();
  }

  void setBudget(String value) {
    _budget = value;
    notifyListeners();
  }

  void toggleAtmosphere(String id) {
    if (_atmosphere.contains(id)) {
      _atmosphere.remove(id);
    } else {
      _atmosphere.add(id);
    }
    notifyListeners();
  }

  void setCity(String id) {
    _cityId = id;
    notifyListeners();
  }

  Future<void> completeOnboarding(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = OnboardingPrefsModel(
        vibes: _vibes,
        budget: _budget,
        atmosphere: _atmosphere,
        cityId: _cityId,
        aiWeights: {},
      );
      final weights = await _aiService.generateTasteWeights(prefs);
      final prefsWithWeights = OnboardingPrefsModel(
        vibes: _vibes,
        budget: _budget,
        atmosphere: _atmosphere,
        cityId: _cityId,
        aiWeights: weights,
      );
      await _userService.savePreferences(uid, prefsWithWeights);
      await _userService.markOnboardingComplete(uid);
      _completed = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
