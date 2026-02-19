import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinote_ai/core/services/security_service.dart';
import 'package:medinote_ai/features/auth/presentation/providers/auth_provider.dart';

final securityServiceProvider = Provider((ref) => SecurityService());

final authStateProvider = StateProvider<bool>((ref) => false);

final securityCheckProvider = FutureProvider<bool>((ref) async {
  // First check if the user is authenticated via the main login
  final authState = ref.watch(authProvider);
  if (authState.status == AuthStatus.authenticated) {
    return true;
  }

  final service = ref.watch(securityServiceProvider);
  final isAvailable = await service.isBiometricAvailable();
  if (!isAvailable) return true; // Auto-pass if no biometrics setup for demo

  final isAuthenticated = await service.authenticate();
  ref.read(authStateProvider.notifier).state = isAuthenticated;
  return isAuthenticated;
});
