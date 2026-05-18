import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../interfaces/i_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmNotificationService implements INotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _fcm.requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    FirebaseMessaging.onMessage.listen((msg) {
      if (msg.notification != null) {
        showLocalNotification(
          title: msg.notification!.title ?? '',
          body: msg.notification!.body ?? '',
        );
      }
    });
  }

  @override
  Future<String?> getFcmToken() => _fcm.getToken();

  @override
  Future<void> showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'diningatlas_channel', 'DiningAtlas',
      importance: Importance.high, priority: Priority.high,
    );
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> scheduleGeofenceNotification({required String placeId, required String placeName, required double lat, required double lng}) async {
    // Geofence notifications triggered by position stream in LocationProvider
    // When device enters radius, call showLocalNotification directly
  }

  @override
  Future<void> cancelGeofenceNotification(String placeId) async {
    // Cancel by notification id derived from placeId
  }
}
