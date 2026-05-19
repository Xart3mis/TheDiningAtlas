import '../../models/notification_model.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<String?> getFcmToken();
  Future<void> showLocalNotification({required String title, required String body});
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng});
  Future<void> cancelGeofenceNotification(String placeId);
  Future<List<NotificationModel>> fetchNotifications(String uid);
  Future<void> seedDemoNotifications(String uid);

  /// Persists a chat notification for [recipientUid] and fires a local
  /// notification when the recipient is on the same device (foreground).
  Future<void> sendChatNotification({
    required String recipientUid,
    required String senderName,
    required String messagePreview,
    required String chatId,
  });
}
