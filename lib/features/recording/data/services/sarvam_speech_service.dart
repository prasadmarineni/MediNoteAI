import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:medinote_ai/features/recording/data/services/speech_service.dart';

/// Speech-to-text service using Sarvam AI's Saaras v3 streaming STT API.
///
/// WebSocket endpoint: wss://api.sarvam.ai/speech-to-text-translate/ws
/// Auth: api-subscription-key header
/// Audio: PCM 16-bit 16kHz mono (pcm_s16le)
///
/// Only the API key is required — no orgId, workspaceId, or appId.
class SarvamSpeechService implements SpeechService {
  final String apiKey;

  static const String _wsUrl =
      'wss://api.sarvam.ai/speech-to-text-translate/ws';

  final _transcriptionController =
      StreamController<TranscriptionResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _audioSub;
  bool _connected = false;
  final StringBuffer _partialBuffer = StringBuffer();

  SarvamSpeechService({required this.apiKey});

  @override
  Stream<TranscriptionResult> get transcriptionStream =>
      _transcriptionController.stream;

  @override
  Stream<String> get statusStream => _statusController.stream;

  @override
  Future<void> startListening({Stream<Uint8List>? audioStream}) async {
    _statusController.add('Connecting to Sarvam AI STT...');

    final uri = Uri.parse(_wsUrl).replace(
      queryParameters: {
        'model': 'saaras:v3',
        'sample_rate': '16000',
        'input_audio_codec': 'pcm_s16le',
        'mode': 'transcribe',
        'vad_signals': 'true',
      },
    );

    _channel = WebSocketChannel.connect(uri, protocols: []);

    // Send auth header via the first message protocol
    // Sarvam accepts the API key as a query param or header-equivalent message
    // For WebSocket we pass it via the URL query or initial JSON config message
    try {
      // Send authentication config message first
      _channel!.sink.add(
        jsonEncode({
          'api-subscription-key': apiKey,
          'model': 'saaras:v3',
          'sample_rate': 16000,
          'input_audio_codec': 'pcm_s16le',
          'mode': 'transcribe',
        }),
      );

      _connected = true;
      _statusController.add('Sarvam AI STT connected ✅');
      debugPrint('SarvamSTT: Connected to Saaras v3');
    } catch (e) {
      throw Exception('Sarvam AI STT connection failed: $e');
    }

    // Listen to server responses (transcription results)
    _channel!.stream.listen(
      (message) {
        _handleResponse(message);
      },
      onError: (e) {
        debugPrint('SarvamSTT: WebSocket error: $e');
        _statusController.add('Sarvam AI error: $e');
        _connected = false;
      },
      onDone: () {
        debugPrint('SarvamSTT: WebSocket closed');
        _statusController.add('disconnected');
        _connected = false;
      },
    );

    // Stream audio data to Sarvam
    if (audioStream != null) {
      _audioSub = audioStream.listen((chunk) {
        if (_connected && _channel != null) {
          _channel!.sink.add(chunk);
        }
      });
    }
  }

  void _handleResponse(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      // Sarvam STT response format:
      // { "transcript": "...", "is_final": true/false }
      // or for VAD: { "event": "speech_start" } / { "event": "speech_end" }
      final transcript = data['transcript'] as String?;
      final isFinal = data['is_final'] as bool? ?? false;
      final event = data['event'] as String?;

      if (event == 'speech_start') {
        _statusController.add('listening...');
        _partialBuffer.clear();
      } else if (event == 'speech_end') {
        _statusController.add('processing...');
      }

      if (transcript != null && transcript.isNotEmpty) {
        if (!isFinal) {
          _partialBuffer.clear();
          _partialBuffer.write(transcript);
        }
        if (!_transcriptionController.isClosed) {
          _transcriptionController.add(
            TranscriptionResult(text: transcript, isFinal: isFinal),
          );
        }
      }
    } catch (e) {
      debugPrint('SarvamSTT: Failed to parse response: $e (raw: $message)');
    }
  }

  @override
  Future<void> stopListening() async {
    // Send flush signal to finalize
    try {
      if (_connected && _channel != null) {
        _channel!.sink.add(jsonEncode({'type': 'flush'}));
      }
    } catch (_) {}

    await _audioSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
    _statusController.add('stopped');
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    if (!_transcriptionController.isClosed) {
      await _transcriptionController.close();
    }
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }

  bool get isConnected => _connected;
}
