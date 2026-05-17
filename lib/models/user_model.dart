class ChatPrivacy {
  final String mode; // 'public' | 'private' | 'scheduled'

  const ChatPrivacy({required this.mode});

  factory ChatPrivacy.fromMap(Map<String, dynamic> m) =>
      ChatPrivacy(mode: m['mode'] as String? ?? 'public');

  Map<String, dynamic> toMap() => {'mode': mode};
}

class UserModel {
  final String uid;
  final String displayName;
  final String photoUrl;
  final String tier;
  final int score;
  final bool onboardingComplete;
  final ChatPrivacy chatPrivacy;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.tier,
    required this.score,
    required this.onboardingComplete,
    required this.chatPrivacy,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> d) => UserModel(
    uid: uid,
    displayName: d['displayName'] ?? '',
    photoUrl: d['photoUrl'] ?? '',
    tier: d['tier'] ?? 'explorer',
    score: d['score'] ?? 0,
    onboardingComplete: d['onboardingComplete'] as bool? ?? false,
    chatPrivacy: ChatPrivacy.fromMap(
      d['chatPrivacy'] as Map<String, dynamic>? ?? {'mode': 'public'},
    ),
  );

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'photoUrl': photoUrl,
    'tier': tier,
    'score': score,
    'onboardingComplete': onboardingComplete,
    'chatPrivacy': chatPrivacy.toMap(),
  };
}
