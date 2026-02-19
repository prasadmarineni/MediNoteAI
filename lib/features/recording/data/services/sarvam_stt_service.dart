import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends a recorded audio file to Sarvam AI's Speech-to-Text REST API.
///
/// Endpoint: POST https://api.sarvam.ai/speech-to-text-translate
/// Auth: api-subscription-key header
/// Model: saaras:v2.5 (supports longer audio for batch processing)
///
/// Only requires an API key — no orgId, workspaceId, or appId.
/// Automatically adds WAV headers if the file is raw PCM (no RIFF header).
class SarvamSTTService {
  final String apiKey;

  static const String _endpoint =
      'https://api.sarvam.ai/speech-to-text-translate';

  // PCM parameters must match what RecordingProvider records:
  // 16-bit, 16kHz, mono (pcm16bits encoder)
  static const int _sampleRate = 16000;
  static const int _numChannels = 1;
  static const int _bitsPerSample = 16;

  SarvamSTTService({required this.apiKey});

  /// Transcribes a recorded audio file using Sarvam AI.
  ///
  /// [audioFilePath] — path to the WAV/PCM file recorded on device.
  /// Returns the transcribed text string.
  Future<String> transcribeFile(String audioFilePath) async {
    debugPrint('SarvamSTT: Transcribing file: $audioFilePath');

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $audioFilePath');
    }

    final rawBytes = await file.readAsBytes();
    debugPrint(
      'SarvamSTT: File size: ${(rawBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
    );

    // Check if the file already has a proper WAV (RIFF) header.
    // The record package's pcm16bits encoder writes raw PCM — no header.
    // We must prepend a WAV header so Sarvam can parse it correctly.
    final Uint8List wavBytes = _ensureWavHeader(rawBytes);

    debugPrint(
      'SarvamSTT: WAV bytes to send: ${(wavBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
    );

    // Build multipart request
    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.headers['api-subscription-key'] = apiKey;

    // Must send with .wav filename so Sarvam detects format correctly
    request.files.add(
      http.MultipartFile.fromBytes('file', wavBytes, filename: 'recording.wav'),
    );

    // Model and parameters
    request.fields['model'] = 'saaras:v2.5';
    request.fields['language_code'] = 'auto'; // Auto-detect language
    request.fields['enable_code_switching'] = 'true'; // Enable code switching
    request.fields['with_timestamps'] = 'false';
    request.fields['with_disfluencies'] = 'false';

    debugPrint('SarvamSTT: Sending to Sarvam AI (model: saaras:v2.5)...');
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
      onTimeout: () =>
          throw Exception('Sarvam AI STT timed out after 120 seconds'),
    );

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('SarvamSTT: Response status: ${response.statusCode}');
    debugPrint('SarvamSTT: Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Sarvam AI STT error ${response.statusCode}: ${response.body}',
      );
    }

    // Parse response: { "transcript": "...", "language_code": "en-IN" }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final transcript =
        json['transcript'] as String? ?? json['text'] as String? ?? '';

    if (transcript.isEmpty) {
      throw Exception('Sarvam AI returned empty transcript');
    }

    debugPrint(
      'SarvamSTT: ✅ Got transcript (${transcript.length} chars): '
      '${transcript.substring(0, transcript.length.clamp(0, 120))}...',
    );
    return transcript;
  }

  /// Returns [bytes] with a valid WAV (RIFF) header prepended if missing.
  Uint8List _ensureWavHeader(Uint8List bytes) {
    // Check for existing RIFF header (bytes 0-3 == "RIFF")
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46) {
      debugPrint('SarvamSTT: File already has WAV header, sending as-is');
      return bytes;
    }

    debugPrint('SarvamSTT: Raw PCM detected — prepending WAV header');
    final pcmData = bytes;
    final dataLength = pcmData.lengthInBytes;
    final byteRate = _sampleRate * _numChannels * (_bitsPerSample ~/ 8);
    final blockAlign = _numChannels * (_bitsPerSample ~/ 8);

    final header = ByteData(44);

    // RIFF chunk
    _setFourCC(header, 0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little); // total file size - 8
    _setFourCC(header, 8, 'WAVE');

    // fmt sub-chunk
    _setFourCC(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 1, Endian.little); // PCM format = 1
    header.setUint16(22, _numChannels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);

    // data sub-chunk
    _setFourCC(header, 36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    // Combine header + PCM data
    final wav = Uint8List(44 + dataLength);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataLength, pcmData);
    return wav;
  }

  void _setFourCC(ByteData bd, int offset, String fourCC) {
    for (int i = 0; i < 4; i++) {
      bd.setUint8(offset + i, fourCC.codeUnitAt(i));
    }
  }
}
