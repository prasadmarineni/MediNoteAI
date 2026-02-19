import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:medinote_ai/features/recording/data/services/speech_service.dart';

class AzureSpeechService implements SpeechService {
  final String subscriptionKey;
  final String region;

  WebSocketChannel? _channel;
  final _controller = StreamController<TranscriptionResult>.broadcast();
  bool _isConnected = false;

  AzureSpeechService({required this.subscriptionKey, required this.region});

  @override
  Stream<TranscriptionResult> get transcriptionStream => _controller.stream;

  @override
  Stream<String> get statusStream => const Stream.empty();

  @override
  Future<void> startListening({Stream<Uint8List>? audioStream}) async {
    if (_isConnected) return;

    final url = Uri.parse(
      'wss://$region.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US',
    );

    debugPrint('Azure Speech connecting to: $url');

    // Connect with headers
    try {
      await _connectWithHeaders(url);
    } catch (e) {
      debugPrint('Error connecting to Azure (rethrowing): $e');
      rethrow;
    }

    _isConnected = true;

    _channel!.stream.listen(
      (message) {
        if (message is String) {
          _handleMessage(message);
        }
      },
      onError: (e) {
        debugPrint('Azure WebSocket Error: $e');
        _isConnected = false;
        _controller.addError(e); // Propagate error to trigger fallback
      },
      onDone: () {
        debugPrint('Azure WebSocket Closed');
        _isConnected = false;
        // If closed unexpectedly (not by stopListening), treat as error
        if (!_controller.isClosed) {
          _controller.addError('Connection closed by server');
        }
      },
    );

    _sendConfiguration();

    // Stream Audio
    if (audioStream != null) {
      audioStream.listen((data) {
        if (_isConnected && _channel != null) {
          _sendAudio(data);
        }
      });
    }
  }

  Future<void> _connectWithHeaders(Uri url) async {
    // This requires Importing dart:io
    // Since we are likely on Mobile/Desktop, we can use IOWebSocketChannel-ish behavior via creating a raw WebSocket first
    // Or use the `connect` method if the package supports headers.
    // `web_socket_channel` `connect` unfortunately doesn't support headers directly in the unified API,
    // but we can use `WebSocket.connect` from dart:io and wrap it.

    try {
      // Dynamic import or check kIsWeb if needed, but assuming mobile/desktop here:
      final ws = await WebSocket.connect(
        url.toString(),
        headers: {
          'Ocp-Apim-Subscription-Key': subscriptionKey,
          'X-ConnectionId': DateTime.now().toIso8601String(),
        },
      );
      _channel = IOWebSocketChannel(ws);
    } catch (e) {
      debugPrint("WebSocket Connection Failed: $e");
      rethrow;
    }
  }

  void _sendConfiguration() {
    final config = {
      "context": {
        "system": {"version": "1.0.0"},
        "os": {
          "platform": "Android", // or dynamic
          "name": "Flutter",
          "version": "1.0.0",
        },
        "device": {
          "manufacturer": "SpeechSDK",
          "model": "SpeechSDK",
          "version": "1.0.0",
        },
      },
      "format": "simple", // or "detailed"
    };

    // Azure expects a text message first for config?
    // Actually the v1 JSON protocol might just start accepting audio,
    // but usually a 'speech.config' message is good practice if using the full SDK protocol.
    // For the simple websocket endpoint, we often just send audio.
    // However, let's stick to sending audio directly as the endpoint v1 often defaults well.
    // Spec: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-to-text-websocket?tabs=languagemodel-default%2Ccommandline#message-flow

    // The protocol requires:
    // 1. Audio messages (binary)
    // 2. Text messages (JSON)
  }

  void _sendAudio(Uint8List data) {
    // Azure expects binary messages for audio.
    _channel?.sink.add(data);
  }

  void _handleMessage(String jsonString) {
    try {
      // Parse JSON
      // Example: {"Path":"speech.phrase","Text":"Hello","Offset":...}
      // We need to import dart:convert;
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final path = data['Path'] as String?;

      if (path == 'speech.phrase') {
        _controller.add(
          TranscriptionResult(
            text: data['DisplayText'] ?? data['Text'] ?? '',
            isFinal: true,
            speakerId: 'User',
          ),
        );
      } else if (path == 'speech.hypothesis') {
        _controller.add(
          TranscriptionResult(
            text: data['Text'] ?? '',
            isFinal: false,
            speakerId: 'User',
          ),
        );
      }
    } catch (e) {
      debugPrint("Error parsing azure msg: $e");
    }
  }

  @override
  Future<void> stopListening() async {
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
  }
}

// Add these imports at the top if missing:
// import 'dart:io';
// import 'package:web_socket_channel/io.dart';
// import 'dart:convert';
// import 'dart:typed_data';
