abstract class ISubscriptionService {
  Future<bool> isPremium(String uid);
  Future<void> upgradeToPremium(String uid);
  Future<int> translationsUsedToday(String uid);
  Future<int> chatMessagesSentToday(String uid);
}
