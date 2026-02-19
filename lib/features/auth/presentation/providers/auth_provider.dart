import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userName;
  final String? email;

  AuthState({required this.status, this.userName, this.email});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.authenticated(String name, String email) =>
      AuthState(status: AuthStatus.authenticated, userName: name, email: email);
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    // Simulated login logic
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'admin@medinote.ai' && password == 'Admin@123') {
      state = AuthState.authenticated('Dr. Prasad Marineni', email);
    } else {
      throw 'Invalid email or password. Hint: admin@medinote.ai / Admin@123';
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthState.initial();
    await Future.delayed(const Duration(seconds: 1));
    state = AuthState.authenticated(
      'Dr. Prasad Marineni',
      'google-user@gmail.com',
    );
  }

  void logout() {
    state = AuthState.unauthenticated();
  }

  void enterDemoMode() {
    state = AuthState.authenticated('Dr. Prasad Marineni', 'demo@medinote.ai');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
