import '../../models/notification_model.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<String?> getFcmToken();
  Future<void> showLocalNotification({required String title, required String body});
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng});
  Future<void> cancelGeofenceNotification(String placeId);
  Future<List<NotificationModel>> fetchNotifications(String uid);
}
