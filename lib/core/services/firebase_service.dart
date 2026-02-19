import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:medinote_ai/firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Initialize Firebase with the medinoteai-2 project configuration
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
        debugPrint('✅ Firebase initialized successfully with project: medinoteai-2');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      _isInitialized = false;
    }
  }
}
