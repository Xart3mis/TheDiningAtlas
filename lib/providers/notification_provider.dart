import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Joe will wire firebase_messaging here
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<String?> getToken() async {
    // Joe will call FirebaseMessaging.instance.getToken()
    return null;
  }
}
