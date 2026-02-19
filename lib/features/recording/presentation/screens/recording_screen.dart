import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medinote_ai/features/recording/presentation/providers/recording_provider.dart';
import 'package:medinote_ai/features/summary/data/repositories/clinical_data_repository.dart';
import 'package:medinote_ai/features/summary/presentation/providers/ai_service_provider.dart';
import 'package:medinote_ai/features/summary/presentation/screens/summary_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinote_ai/features/history/presentation/providers/history_provider.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';
import 'package:medinote_ai/features/recording/data/services/sarvam_stt_service.dart';
import 'package:medinote_ai/features/settings/presentation/providers/preferences_provider.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final String patientName;
  final String? patientId;

  const RecordingScreen({super.key, required this.patientName, this.patientId});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startSpeechStream();
  }

  void _startSpeechStream() async {
    // Always record to a WAV file. After stop, the file will be sent to
    // Sarvam AI REST API for batch transcription.
    debugPrint('Starting Session: File Recording Mode (Sarvam AI batch STT)');

    try {
      await ref
          .read(recordingProvider.notifier)
          .startRecording();
    } catch (e) {
      debugPrint('Recording error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to start microphone: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _handleClose(context, ref),
        ),
        title: const Text('Live Consultation'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildTimer(context, recordingState.duration),
            const SizedBox(height: 60),
            _buildWaveform(
              context,
              recordingState.status == RecordingStatus.recording,
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildTranscriptionPreview(context)),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            _buildControls(context, ref, recordingState),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(BuildContext context, Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return Column(
      children: [
        Text(
          '$minutes:$seconds',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 500.ms)
                .fadeOut(duration: 500.ms),
            const SizedBox(width: 8),
            Text(
              'REC',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveform(BuildContext context, bool isRecording) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          return Container(
                width: 4,
                height: isRecording ? (20 + (index % 5) * 10) : 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scaleY(
                begin: 0.5,
                end: 1.5,
                duration: (300 + index * 50).ms,
                curve: Curves.easeInOut,
              );
        }),
      ),
    );
  }

  Widget _buildTranscriptionPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording in progress...\\n\\nTranscription will be generated by AI after you finish recording.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    RecordingState state,
  ) {
    final status = state.status;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume
        _buildCircularButton(
          context,
          icon: status == RecordingStatus.paused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          onPressed: () {
            if (status == RecordingStatus.recording) {
              ref.read(recordingProvider.notifier).pauseRecording();
            } else if (status == RecordingStatus.paused) {
              ref.read(recordingProvider.notifier).resumeRecording();
            }
          },
          label: status == RecordingStatus.paused ? 'Resume' : 'Pause',
        ),
        const SizedBox(width: 32),
        // Stop & Finish
        _buildCircularButton(
          context,
          icon: Icons.stop_rounded,
          onPressed: () async {
            // Confirm before stopping
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Finish Recording?'),
                content: const Text(
                  'The recording will be sent to Sarvam AI for transcription and then to AI for clinical summary generation.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continue Recording'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Finish'),
                  ),
                ],
              ),
            );
            if (confirm != true) return;

            // Await the stop with a timeout to prevent hanging the UI
            try {
              // We use a short timeout to ensure the button feels responsive even if recorder fails
              await ref
                  .read(recordingProvider.notifier)
                  .stopRecording()
                  .timeout(
                    const Duration(seconds: 1),
                    onTimeout: () => debugPrint('Stop Recording timed out'),
                  );
            } catch (e) {
              debugPrint('Error during stop operations: $e');
            }

            if (mounted) {
              _showProcessingSummary(context, ref, state);
            }
          },
          label: 'Finish',
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildCircularButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: isPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: isPrimary
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.all(20),
          ),
          icon: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    final status = ref.read(recordingProvider).status;
    if (status != RecordingStatus.initial) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard recording?'),
          content: const Text(
            'Are you sure you want to discard this clinical recording? All current progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(recordingProvider.notifier).stopRecording();
                Navigator.pop(context); // Close dialog
                context.pop(); // Close screen
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  void _showProcessingSummary(
    BuildContext context,
    WidgetRef ref,
    RecordingState state,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Processing Consultation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Transcribing with Sarvam AI, then generating clinical summary...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ).whenComplete(() {
      // Optional: Logic if sheet is closed by other means
    });

    // Execute processing logic once
    _processRecording(context, ref, state);
  }

  Future<void> _processRecording(
    BuildContext context,
    WidgetRef ref,
    RecordingState state,
  ) async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final repository = ref.read(clinicalRepositoryProvider);
      final prefs = ref.read(preferencesProvider);

      // 1. Transcribe the recorded audio file via Sarvam AI REST API
      String transcript = '';
      if (state.path != null) {
        debugPrint(
          '_processRecording: Sending to Sarvam AI STT: ${state.path}',
        );
        final sarvamSTT = SarvamSTTService(apiKey: prefs.sarvamApiKey);
        transcript = await sarvamSTT
            .transcribeFile(state.path!)
            .timeout(
              const Duration(minutes: 3),
              onTimeout: () =>
                  throw 'Sarvam AI STT timed out. Please check your internet and try again.',
            );
      } else {
        throw 'No audio file was recorded';
      }

      // Validate transcript
      if (transcript.isEmpty) {
        throw 'No transcription captured. Please try again.';
      }

      debugPrint('Transcript length: ${transcript.length} chars');
      final aiSummary = await aiService
          .generateSummary(transcript)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw 'AI service timed out. Please check your connection or try again.',
          );

      // Override with actual patient details
      final summary = ClinicalSummary(
        id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
        patientName: widget.patientName,
        patientId: widget.patientId ?? 'P-UNKNOWN',
        visitDate: DateTime.now(),
        soapSubjective: aiSummary.soapSubjective,
        soapObjective: aiSummary.soapObjective,
        soapAssessment: aiSummary.soapAssessment,
        soapPlan: aiSummary.soapPlan,
        entities: aiSummary.entities,
        codes: aiSummary.codes,
        localAudioPath: state.path, // save device path for retry STT
        transcript: transcript, // save Sarvam AI transcript
      );

      // 3. Persist
      String audioUrl = 'mock_url';
      try {
        if (state.path != null) {
          audioUrl = await repository.uploadAudio(state.path!, 'P-UNKNOWN');
        }
      } catch (e) {
        debugPrint('Upload failed (continuing with mock URL): $e');
      }

      await repository.saveSummary(summary, audioUrl);
      ref.invalidate(historyProvider); // Ensure dashboard is updated

      // 4. Update Summary Provider and Navigate
      ref.read(summaryProvider.notifier).state = summary;

      if (context.mounted) {
        Navigator.pop(context); // Close sheet
        context.go('/summary');
      }
    } catch (e) {
      debugPrint('Error in _processRecording: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close sheet so user isn't stuck
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
