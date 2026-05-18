import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_user_service.dart';
import '../../models/user_model.dart';
import '../../models/onboarding_prefs_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class FirestoreUserService implements IUserService {
  final _db = FirebaseFirestore.instance;

  DocumentReference _userDoc(String uid) =>
      _db.collection(AppConstants.kColUsers).doc(uid);

  @override
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _userDoc(user.uid).set(user.toFirestore());
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _userDoc(user.uid).update({
      ...user.toFirestore(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<OnboardingPrefsModel?> fetchPreferences(String uid) async {
    final doc = await _userDoc(uid).collection(AppConstants.kDocPreferences).doc('prefs').get();
    if (!doc.exists) return null;
    return OnboardingPrefsModel.fromFirestore(doc);
  }

  @override
  Future<void> savePreferences(String uid, OnboardingPrefsModel prefs) async {
    await _userDoc(uid)
        .collection(AppConstants.kDocPreferences)
        .doc('prefs')
        .set(prefs.toFirestore());
  }

  @override
  Future<void> markOnboardingComplete(String uid) async {
    await _userDoc(uid).update({'onboardingComplete': true});
  }

  @override
  Future<List<String>> fetchSavedPlaceIds(String uid) async {
    final snap = await _userDoc(uid).collection(AppConstants.kColSavedPlaces).get();
    return snap.docs.map((d) => d.id).toList();
  }

  @override
  Future<void> savePlace({required String uid, required String placeId, required bool reminderEnabled}) async {
    final count = await savedPlaceCount(uid);
    final userDoc = await fetchUser(uid);
    if (count >= AppConstants.kMaxSavedFree && !(userDoc?.isPremium ?? false)) {
      throw const QuotaException('Save limit reached. Upgrade to premium for unlimited saves.');
    }
    await _userDoc(uid)
        .collection(AppConstants.kColSavedPlaces)
        .doc(placeId)
        .set({'reminderEnabled': reminderEnabled, 'savedAt': FieldValue.serverTimestamp()});
    await _db.collection(AppConstants.kColRestaurants).doc(placeId).update({
      'saveCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> unsavePlace({required String uid, required String placeId}) async {
    await _userDoc(uid).collection(AppConstants.kColSavedPlaces).doc(placeId).delete();
    await _db.collection(AppConstants.kColRestaurants).doc(placeId).update({
      'saveCount': FieldValue.increment(-1),
    });
  }

  @override
  Future<int> savedPlaceCount(String uid) async {
    final snap = await _userDoc(uid).collection(AppConstants.kColSavedPlaces).count().get();
    return snap.count ?? 0;
  }
}
