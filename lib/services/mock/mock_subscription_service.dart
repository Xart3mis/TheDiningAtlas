import '../interfaces/i_subscription_service.dart';

class MockSubscriptionService implements ISubscriptionService {
  @override
  Future<bool> isPremium(String uid) async => false;
  @override
  Future<void> upgradeToPremium(String uid) async {}
  @override
  Future<int> translationsUsedToday(String uid) async => 0;
  @override
  Future<int> chatMessagesSentToday(String uid) async => 0;
}
