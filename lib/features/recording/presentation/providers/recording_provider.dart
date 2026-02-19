import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecordingStatus { initial, recording, paused, stopped, error }

class RecordingState {
  final RecordingStatus status;
  final Duration duration;
  final String? path;
  final String? errorMessage;

  RecordingState({
    required this.status,
    required this.duration,
    this.path,
    this.errorMessage,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    Duration? duration,
    String? path,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;

  RecordingNotifier()
    : super(
        RecordingState(
          status: RecordingStatus.initial,
          duration: Duration.zero,
        ),
      );

  Future<void> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Microphone permission denied',
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Record directly to WAV file (not streaming to file sink)
      // The 'record' package will handle WAV header creation
      const config = RecordConfig(
        encoder: AudioEncoder.wav, // Use WAV encoder for proper file format
        sampleRate: 16000,
        numChannels: 1,
      );

      // Start recording directly to file (not streaming)
      await _recorder.start(config, path: path);

      state = state.copyWith(status: RecordingStatus.recording, path: path);
      _startTimer();
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    _handleStop();
  }

  void _handleStop() {
    _stopTimer();
    if (state.status == RecordingStatus.recording ||
        state.status == RecordingStatus.paused) {
      state = state.copyWith(status: RecordingStatus.stopped);
    }
  }

  Future<void> pauseRecording() async {
    // Note: Pause might not be fully supported in valid stream capture for file consistency,
    // but we can request the recorder to pause.
    try {
      await _recorder.pause();
      _stopTimer();
      state = state.copyWith(status: RecordingStatus.paused);
    } catch (e) {
      // Ignore if not supported
    }
  }

  Future<void> resumeRecording() async {
    await _recorder.resume();
    _startTimer();
    state = state.copyWith(status: RecordingStatus.recording);
  }

  void forceStartTimer() {
    state = state.copyWith(status: RecordingStatus.recording);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        duration: state.duration + const Duration(seconds: 1),
      );
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

final recordingProvider =
    StateNotifierProvider.autoDispose<RecordingNotifier, RecordingState>((ref) {
      return RecordingNotifier();
    });
