import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/notification_model.dart';
import '../interfaces/i_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmNotificationService implements INotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission — non-blocking, users may deny
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications (uses named 'settings:' in v18+)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Listen for foreground messages
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
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'diningatlas_channel',
      'DiningAtlas',
      channelDescription: 'DiningAtlas notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> scheduleGeofenceNotification({
    required String placeId,
    required String placeName,
    required double lat,
    required double lng,
  }) async {
    // Triggered by position stream in LocationProvider
  }

  @override
  Future<void> cancelGeofenceNotification(String placeId) async {
    // Cancel by notification id derived from placeId
  }

  @override
  Future<List<NotificationModel>> fetchNotifications(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(NotificationModel.fromFirestore).toList();
  }
}
