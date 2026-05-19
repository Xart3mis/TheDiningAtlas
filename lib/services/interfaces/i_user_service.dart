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
  Future<Map<String, bool>> fetchSavedPlaceFlags(String uid);
  Future<void> updateReminderEnabled(String uid, String placeId, bool enabled);
  Future<int> savedPlaceCount(String uid);
  Future<void> updateFcmToken(String uid, String token);
  Future<void> updateCountry(String uid, String countryId);
  Future<void> adjustScore(String uid, int delta);
  Future<List<UserModel>> searchUsers({required String query, required String excludeUid});
}
