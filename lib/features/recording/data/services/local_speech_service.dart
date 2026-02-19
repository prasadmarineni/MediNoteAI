import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:medinote_ai/features/recording/data/services/speech_service.dart';

class LocalSpeechService implements SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final _controller = StreamController<TranscriptionResult>.broadcast();
  bool _isAvailable = false;
  final _statusController = StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  @override
  Stream<TranscriptionResult> get transcriptionStream => _controller.stream;

  @override
  Future<void> startListening({Stream<Uint8List>? audioStream}) async {
    // Note: speech_to_text typically uses the device microphone directly via the OS,
    // it doesn't usually accept a raw audio stream from another source (like our RecordingProvider).
    // However, since we are doing a fallback, we can let it control the input for recognition
    // while the RecordingProvider records to file in parallel (if the OS allows dual access).
    // Android often allows shared mic access if configured, or we might need to rely on the OS behavior.

    if (!_isAvailable) {
      _isAvailable = await _speechToText.initialize(
        onError: (e) => debugPrint('Local STT Error: $e'),
        onStatus: (s) => _statusController.add(s),
        debugLogging: true,
      );
    }

    if (_isAvailable) {
      await _speechToText.listen(
        onResult: (result) {
          _controller.add(
            TranscriptionResult(
              text: result.recognizedWords,
              isFinal: result.finalResult,
              speakerId: 'User',
            ),
          );
        },
        listenFor: const Duration(minutes: 20),
        pauseFor: const Duration(seconds: 60),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        onDevice: false, // Use standard recognition for better reliability
      );
    } else {
      debugPrint('Local Speech to Text not available');
    }
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
    await _statusController.close();
  }
}
