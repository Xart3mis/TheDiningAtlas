import '../interfaces/i_user_service.dart';
import '../../models/user_model.dart';
import '../../models/onboarding_prefs_model.dart';

class MockUserService implements IUserService {
  final _savedPlaces = <String, Set<String>>{};

  @override
  Future<UserModel?> fetchUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return UserModel(
      uid: uid, displayName: 'Bedo', email: 'bedo@example.com',
      photoUrl: '', tier: 'local', score: 150, isPremium: false,
      onboardingComplete: true,
      chatPrivacy: const ChatPrivacy(mode: 'public'),
      createdAt: DateTime(2024, 1, 1),
    );
  }

  @override
  Future<void> createUser(UserModel user) async {}

  @override
  Future<void> updateUser(UserModel user) async {}

  @override
  Future<OnboardingPrefsModel?> fetchPreferences(String uid) async => null;

  @override
  Future<void> savePreferences(String uid, OnboardingPrefsModel prefs) async {}

  @override
  Future<void> markOnboardingComplete(String uid) async {}

  @override
  Future<List<String>> fetchSavedPlaceIds(String uid) async {
    return (_savedPlaces[uid] ?? {}).toList();
  }

  @override
  Future<void> savePlace({required String uid, required String placeId, required bool reminderEnabled}) async {
    _savedPlaces.putIfAbsent(uid, () => {}).add(placeId);
  }

  @override
  Future<void> unsavePlace({required String uid, required String placeId}) async {
    _savedPlaces[uid]?.remove(placeId);
  }

  @override
  Future<int> savedPlaceCount(String uid) async {
    return _savedPlaces[uid]?.length ?? 0;
  }
}
