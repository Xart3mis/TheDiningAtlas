import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

import '../services/interfaces/i_user_service.dart';
import '../models/user_model.dart';

/// Provides auth state to the entire widget tree via Provider.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final IUserService _userService;

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider(this._userService) {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      notifyListeners();
      if (user != null) {
        try {
          final userModel = await _userService.fetchUser(user.uid);
          if (userModel == null) {
            await _userService.createUser(UserModel(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              photoUrl: user.photoURL ?? '',
              tier: 'Free',
              score: 0,
              isPremium: false,
              onboardingComplete: false,
              chatPrivacy: const ChatPrivacy(mode: 'private'),
              createdAt: DateTime.now(),
            ));
          }
        } catch (e) {
          debugPrint('Failed to sync user profile: $e');
        }
      }
    });
  }

  /// Sign up with email/password.
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email, password);
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email/password.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _error = null;
      return result != null;
    } catch (e) {
      _error = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email.
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordReset(email);
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
