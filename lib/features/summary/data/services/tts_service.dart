import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(
    String text, {
    double rate = 0.5,
    double pitch = 1.0,
    String language = 'en-US',
  }) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setPitch(pitch);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});
