import 'package:flutter/material.dart';
import '../services/interfaces/i_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationService _service;
  NotificationProvider(this._service);

  int _badgeCount = 0;
  int get badgeCount => _badgeCount;

  Future<void> initialize() async {
    await _service.initialize();
  }

  Future<String?> getToken() => _service.getFcmToken();

  void incrementBadge() { _badgeCount++; notifyListeners(); }
  void clearBadge() { _badgeCount = 0; notifyListeners(); }
}
