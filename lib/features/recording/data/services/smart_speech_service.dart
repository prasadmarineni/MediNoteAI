import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:medinote_ai/features/recording/data/services/speech_service.dart';
import 'package:medinote_ai/features/recording/data/services/sarvam_speech_service.dart';
import 'package:medinote_ai/features/recording/data/services/local_speech_service.dart';

/// A smart speech service that tries Sarvam AI first and falls back
/// to the on-device (mobile) LocalSpeechService on failure.
class SmartSpeechService implements SpeechService {
  final String sarvamApiKey;

  SpeechService? _activeService;
  final _transcriptionController =
      StreamController<TranscriptionResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  StreamSubscription<TranscriptionResult>? _transcriptionSub;
  StreamSubscription<String>? _statusSub;

  SmartSpeechService({required this.sarvamApiKey});

  @override
  Stream<TranscriptionResult> get transcriptionStream =>
      _transcriptionController.stream;

  @override
  Stream<String> get statusStream => _statusController.stream;

  @override
  Future<void> startListening({Stream<Uint8List>? audioStream}) async {
    // Step 1: Try Sarvam AI
    if (sarvamApiKey.isNotEmpty) {
      try {
        debugPrint('SmartSTT: Trying Sarvam AI...');
        _statusController.add('Connecting to Sarvam AI...');

        final sarvam = SarvamSpeechService(apiKey: sarvamApiKey);
        await sarvam.startListening(audioStream: audioStream);

        _activeService = sarvam;
        _statusController.add('Sarvam AI connected ✅');
        debugPrint('SmartSTT: Using Sarvam AI');
        _forwardStreams();
        return;
      } catch (e) {
        debugPrint(
          'SmartSTT: Sarvam AI failed ($e), falling back to local STT',
        );
        _statusController.add('Sarvam AI unavailable, using device STT...');
      }
    }

    // Step 2: Fallback to local mobile STT
    await _startLocalFallback(audioStream: audioStream);
  }

  Future<void> _startLocalFallback({Stream<Uint8List>? audioStream}) async {
    debugPrint('SmartSTT: Starting LocalSpeechService fallback');
    final local = LocalSpeechService();
    await local.startListening(audioStream: audioStream);
    _activeService = local;
    _statusController.add('Using device speech recognition 📱');
    _forwardStreams();
  }

  void _forwardStreams() {
    _transcriptionSub?.cancel();
    _statusSub?.cancel();

    _transcriptionSub = _activeService!.transcriptionStream.listen((result) {
      if (!_transcriptionController.isClosed) {
        _transcriptionController.add(result);
      }
    });

    _statusSub = _activeService!.statusStream.listen((status) {
      if (!_statusController.isClosed) {
        _statusController.add(status);
      }
    });
  }

  @override
  Future<void> stopListening() async {
    await _transcriptionSub?.cancel();
    await _statusSub?.cancel();
    await _activeService?.stopListening();
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _activeService?.dispose();
    _activeService = null;
    if (!_transcriptionController.isClosed) {
      await _transcriptionController.close();
    }
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }

  String get activeServiceName {
    if (_activeService is SarvamSpeechService) return 'Sarvam AI';
    if (_activeService is LocalSpeechService) return 'Device STT';
    return 'None';
  }
}
