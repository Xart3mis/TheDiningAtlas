import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _user = UserModel(
      uid: uid,
      displayName: 'Bedo',
      photoUrl: '',
      tier: 'local',
      score: 128,
      onboardingComplete: true,
      chatPrivacy: const ChatPrivacy(mode: 'public'),
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateChatPrivacy(ChatPrivacy privacy) async {
    if (_user == null) return;
    _user = UserModel(
      uid: _user!.uid,
      displayName: _user!.displayName,
      photoUrl: _user!.photoUrl,
      tier: _user!.tier,
      score: _user!.score,
      onboardingComplete: _user!.onboardingComplete,
      chatPrivacy: privacy,
    );
    notifyListeners();
  }
}
