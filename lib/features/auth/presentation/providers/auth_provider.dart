import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userName;
  final String? email;
  final String? userId;

  AuthState({
    required this.status,
    this.userName,
    this.email,
    this.userId,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.authenticated(String name, String email, String userId) =>
      AuthState(
        status: AuthStatus.authenticated,
        userName: name,
        email: email,
        userId: userId,
      );
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  // Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      state = AuthState.authenticated(
        user.displayName ?? 'User',
        user.email ?? '',
        user.uid,
      );
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        state = AuthState.authenticated(
          user.displayName ?? 'User',
          user.email ?? email,
          user.uid,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Try to create account if it doesn't exist (for demo purposes)
        try {
          final newUserCredential =
              await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final newUser = newUserCredential.user;
          if (newUser != null) {
            await newUser.updateDisplayName('Dr. Prasad Marineni');
            state = AuthState.authenticated(
              'Dr. Prasad Marineni',
              email,
              newUser.uid,
            );
          }
        } catch (createError) {
          debugPrint('Error creating user: $createError');
          throw 'Invalid email or password. Hint: admin@medinote.ai / Admin@123';
        }
      } else if (e.code == 'wrong-password') {
        throw 'Invalid email or password';
      } else {
        throw e.message ?? 'Authentication failed';
      }
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      // Sign out first to force account picker
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        state = AuthState.authenticated(
          user.displayName ?? googleUser.displayName ?? 'User',
          user.email ?? googleUser.email,
          user.uid,
        );
      }
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      throw 'Google Sign-in failed: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    state = AuthState.unauthenticated();
  }

  void enterDemoMode() {
    state = AuthState.authenticated(
      'Dr. Prasad Marineni',
      'demo@medinote.ai',
      'demo-user-id',
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
