import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../models/onboarding_prefs_model.dart';
import '../models/user_model.dart';

class OnboardingProvider extends ChangeNotifier {
  final IUserService _userService;
  final IAiService _aiService;
  OnboardingProvider(this._userService, this._aiService);

  final List<String> _vibes = [];
  String _budget = '\$\$';
  final List<String> _atmosphere = [];
  String _countryId = '';
  String _countryCode = '';
  String _countryName = '';
  bool _isLoading = false;
  bool _completed = false;

  List<String> get vibes => List.unmodifiable(_vibes);
  String get budget => _budget;
  List<String> get atmosphere => List.unmodifiable(_atmosphere);
  String get countryId => _countryId;
  String get countryCode => _countryCode;
  String get countryName => _countryName;
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

  void setCountry(String code, String name) {
    _countryId = name.toLowerCase();
    _countryCode = code;
    _countryName = name;
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
        countryId: _countryId,
        aiWeights: {},
      );
      final weights = await _aiService.generateTasteWeights(prefs);
      final prefsWithWeights = OnboardingPrefsModel(
        vibes: _vibes,
        budget: _budget,
        atmosphere: _atmosphere,
        countryId: _countryId,
        aiWeights: weights,
      );
      await _userService.savePreferences(uid, prefsWithWeights);
      final UserModel? user = await _userService.fetchUser(uid);
      if (user == null) {
        throw StateError('Unable to complete onboarding without user profile');
      }
      final updatedUser = UserModel(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoUrl,
        tier: user.tier,
        score: user.score,
        isPremium: user.isPremium,
        onboardingComplete: true,
        chatPrivacy: user.chatPrivacy,
        createdAt: user.createdAt,
        username: user.username,
        countryCode: user.countryCode,
        onboardingCountryId: _countryId,
      );
      await _userService.updateUser(updatedUser);
      await _userService.markOnboardingComplete(uid);
      _completed = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
