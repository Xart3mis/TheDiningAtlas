import 'package:flutter/material.dart';
import '../services/interfaces/i_user_service.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final IUserService _service;
  UserProvider(this._service);

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _service
          .fetchUser(uid)
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateChatPrivacy(ChatPrivacy privacy) async {
    if (_user == null) return;
    final updated = UserModel(
      uid: _user!.uid, displayName: _user!.displayName, email: _user!.email,
      photoUrl: _user!.photoUrl, tier: _user!.tier, score: _user!.score,
      isPremium: _user!.isPremium, onboardingComplete: _user!.onboardingComplete,
      chatPrivacy: privacy, createdAt: _user!.createdAt,
    );
    await _service.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? username,
  }) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
      username: username,
    );
    await _service.updateUser(updated);
    _user = updated;
    notifyListeners();
  }
}
