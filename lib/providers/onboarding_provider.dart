import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/onboarding_prefs_model.dart';

class OnboardingProvider extends ChangeNotifier {
  final IUserService _userService;
  final IAiService _aiService;
  OnboardingProvider(this._userService, this._aiService);

  List<String> vibes = [];
  String budget = '\$\$';
  List<String> atmosphere = [];
  String cityId = 'tokyo';
  bool _isLoading = false;
  bool _completed = false;

  bool get isLoading => _isLoading;
  bool get completed => _completed;

  Future<void> completeOnboarding(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = OnboardingPrefsModel(
        vibes: vibes, budget: budget, atmosphere: atmosphere,
        cityId: cityId, aiWeights: {},
      );
      final weights = await _aiService.generateTasteWeights(prefs);
      final prefsWithWeights = OnboardingPrefsModel(
        vibes: vibes, budget: budget, atmosphere: atmosphere,
        cityId: cityId, aiWeights: weights,
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
