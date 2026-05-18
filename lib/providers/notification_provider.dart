import 'package:flutter/material.dart';
import '../services/interfaces/i_notification_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationService _service;
  final IUserService _userService;
  NotificationProvider(this._service, this._userService);

  int _badgeCount = 0;
  List<NotificationModel> _notifications = [];

  int get badgeCount => _badgeCount;
  List<NotificationModel> get notifications => _notifications;

  Future<void> initialize() async {
    await _service.initialize();
  }

  Future<String?> getToken() => _service.getFcmToken();

  Future<void> saveToken(String uid) async {
    final token = await _service.getFcmToken();
    if (token != null) {
      await _userService.updateFcmToken(uid, token);
    }
  }

  Future<void> loadNotifications(String uid) async {
    _notifications = await _service.fetchNotifications(uid);
    notifyListeners();
  }

  Future<void> seedDemoNotifications(String uid) async {
    await _service.seedDemoNotifications(uid);
    await loadNotifications(uid);
  }

  void incrementBadge() {
    _badgeCount++;
    notifyListeners();
  }

  void clearBadge() {
    _badgeCount = 0;
    notifyListeners();
  }

  void reset() {
    _notifications = [];
    _badgeCount = 0;
    notifyListeners();
  }
}
