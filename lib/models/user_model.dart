import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String tier; // 'explorer' | 'local' | 'super_local' | 'city_legend'
  final int score;
  final bool isPremium;
  final bool onboardingComplete;
  final ChatPrivacy chatPrivacy;
  final DateTime createdAt;
  final String username;
  final String countryCode; // ISO-2
  final String onboardingCountryId; // e.g. 'japan', 'egypt'

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.tier,
    required this.score,
    required this.isPremium,
    required this.onboardingComplete,
    required this.chatPrivacy,
    required this.createdAt,
    this.username = '',
    this.countryCode = '',
    this.onboardingCountryId = '',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: d['displayName'] ?? '',
      email: d['email'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
      tier: d['tier'] ?? 'explorer',
      score: d['score'] ?? 0,
      isPremium: d['isPremium'] ?? false,
      onboardingComplete: d['onboardingComplete'] ?? false,
      chatPrivacy: ChatPrivacy.fromMap(d['chatPrivacy'] ?? {}),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      username: d['username'] ?? '',
      countryCode: d['countryCode'] ?? '',
      onboardingCountryId: d['onboardingCountryId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'tier': tier,
    'score': score,
    'isPremium': isPremium,
    'onboardingComplete': onboardingComplete,
    'chatPrivacy': chatPrivacy.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
    'username': username,
    'countryCode': countryCode,
    'onboardingCountryId': onboardingCountryId,
  };
}

class ChatPrivacy {
  final String mode; // 'public' | 'private' | 'scheduled'
  final String? scheduleStart; // 'HH:mm'
  final String? scheduleEnd;   // 'HH:mm'
  final List<String> scheduleDays; // ['mon','tue',...]

  const ChatPrivacy({
    required this.mode,
    this.scheduleStart,
    this.scheduleEnd,
    this.scheduleDays = const [],
  });

  factory ChatPrivacy.fromMap(Map<String, dynamic> m) => ChatPrivacy(
    mode: m['mode'] ?? 'public',
    scheduleStart: m['scheduleStart'],
    scheduleEnd: m['scheduleEnd'],
    scheduleDays: List<String>.from(m['scheduleDays'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'mode': mode,
    'scheduleStart': scheduleStart,
    'scheduleEnd': scheduleEnd,
    'scheduleDays': scheduleDays,
  };
}
