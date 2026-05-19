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

  @override
  Future<void> sendChatNotification({
    required String recipientUid,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    // Persist to Firestore so the inbox badge + notification list update
    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientUid)
        .collection('notifications')
        .add({
      'title': senderName,
      'body': messagePreview,
      'type': 'chat',
      'relatedId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Local notification is intentionally omitted here — this method runs on
    // the sender's device. The recipient receives the notification via FCM,
    // which triggers the onMessage listener on their device.
  }

  @override
  Future<void> seedDemoNotifications(String uid) async {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded

    final now = DateTime.now();
    final demos = [
      {
        'title': 'New review on your spot!',
        'body': 'Someone left a 5-star review on Café Marais.',
        'type': 'new_review',
        'relatedId': '',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
        'read': false,
      },
      {
        'title': 'You\'re near a saved place!',
        'body': 'La Brasserie du Coin is 200m away. Good time to visit?',
        'type': 'nearby_saved',
        'relatedId': '',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'read': false,
      },
      {
        'title': 'Someone wants to chat',
        'body': 'A local has a question about your recommendation.',
        'type': 'chat',
        'relatedId': '',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'read': true,
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (final n in demos) {
      final docId = 'seed_${n['type']}';
      batch.set(col.doc(docId), n);
    }
    await batch.commit();
  }
}
