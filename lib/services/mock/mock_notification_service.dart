import '../interfaces/i_notification_service.dart';

class MockNotificationService implements INotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> getFcmToken() async => 'mock_fcm_token';
  @override
  Future<void> showLocalNotification({required String title, required String body}) async {}
  @override
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng}) async {}
  @override
  Future<void> cancelGeofenceNotification(String placeId) async {}
}
