import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../interfaces/i_subscription_service.dart';

class FirestoreSubscriptionService implements ISubscriptionService {
  final FirebaseFirestore _db;

  FirestoreSubscriptionService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(AppConstants.kColUsers).doc(uid);

  DocumentReference<Map<String, dynamic>> _usageDoc(String uid) {
    final now = DateTime.now().toUtc();
    final dayId =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _userDoc(uid).collection(AppConstants.kColDailyUsage).doc(dayId);
  }

  @override
  Future<bool> isPremium(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.data()?['isPremium'] == true;
  }

  @override
  Future<void> upgradeToPremium(String uid) async {
    await _userDoc(uid).set({
      'isPremium': true,
      'premiumUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<int> translationsUsedToday(String uid) async {
    final doc = await _usageDoc(uid).get();
    return (doc.data()?['translationsUsed'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> chatMessagesSentToday(String uid) async {
    final doc = await _usageDoc(uid).get();
    return (doc.data()?['chatMessagesSent'] as num?)?.toInt() ?? 0;
  }
}
