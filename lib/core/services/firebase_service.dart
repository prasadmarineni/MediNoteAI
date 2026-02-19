import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // On macOS, Firebase.initializeApp() requires explicit options or plist
        // If they are missing, this will throw.
        await Firebase.initializeApp();
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Firebase initialization failed (Demo Mode bypassing): $e');
      _isInitialized = false;
    }
  }
}
