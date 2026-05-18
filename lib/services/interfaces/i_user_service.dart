import '../../models/user_model.dart';
import '../../models/onboarding_prefs_model.dart';

abstract class IUserService {
  Future<UserModel?> fetchUser(String uid);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<OnboardingPrefsModel?> fetchPreferences(String uid);
  Future<void> savePreferences(String uid, OnboardingPrefsModel prefs);
  Future<void> markOnboardingComplete(String uid);
  Future<List<String>> fetchSavedPlaceIds(String uid);
  Future<void> savePlace({required String uid, required String placeId, required bool reminderEnabled});
  Future<void> unsavePlace({required String uid, required String placeId});
  Future<int> savedPlaceCount(String uid);
}
