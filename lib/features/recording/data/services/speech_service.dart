import 'dart:async';
import 'dart:typed_data';

abstract class SpeechService {
  Stream<TranscriptionResult> get transcriptionStream;
  Stream<String> get statusStream;
  Future<void> startListening({Stream<Uint8List>? audioStream});
  Future<void> stopListening();
  Future<void> dispose();
}

class TranscriptionResult {
  final String text;
  final bool isFinal;
  final String? speakerId;

  TranscriptionResult({
    required this.text,
    required this.isFinal,
    this.speakerId,
  });
}
