import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Web requires an OAuth clientId — skip lazy init on web to avoid crash at startup
  GoogleSignIn? get _googleSignIn => kIsWeb ? null : GoogleSignIn();

  /// Stream of auth state changes (logged in / logged out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Sign up with email and password.
  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google.
  Future<UserCredential?> signInWithGoogle() async {
    final signIn = _googleSignIn;
    if (signIn == null) return null; // not supported on web without clientId
    final googleUser = await signIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _auth.signOut();
  }
}
