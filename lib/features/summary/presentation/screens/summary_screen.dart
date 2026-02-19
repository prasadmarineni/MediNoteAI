import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medinote_ai/features/summary/data/repositories/clinical_data_repository.dart';
import 'package:medinote_ai/features/history/presentation/providers/history_provider.dart';
import 'package:medinote_ai/features/settings/presentation/providers/preferences_provider.dart';
import 'package:medinote_ai/features/summary/data/services/pdf_service.dart';
import 'package:go_router/go_router.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';
import 'package:medinote_ai/features/summary/data/services/tts_service.dart';
import 'package:audioplayers/audioplayers.dart';

final summaryProvider = StateProvider<ClinicalSummary?>((ref) => null);

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _isEditing = false;
  late TextEditingController _subjectiveController;
  late TextEditingController _objectiveController;
  late TextEditingController _assessmentController;
  late TextEditingController _planController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isSpeaking = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _subjectiveController = TextEditingController();
    _objectiveController = TextEditingController();
    _assessmentController = TextEditingController();
    _planController = TextEditingController();

    // Listen to audio player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initControllers(ClinicalSummary summary) {
    if (!_isEditing) {
      _subjectiveController.text = summary.soapSubjective;
      _objectiveController.text = summary.soapObjective;
      _assessmentController.text = summary.soapAssessment;
      _planController.text = summary.soapPlan;
    }
  }

  Future<void> _saveChanges(ClinicalSummary summary) async {
    final updatedSummary = summary.copyWith(
      soapSubjective: _subjectiveController.text,
      soapObjective: _objectiveController.text,
      soapAssessment: _assessmentController.text,
      soapPlan: _planController.text,
      status: ClinicalStatus.finalized,
    );

    await ref.read(clinicalRepositoryProvider).updateSummary(updatedSummary);
    ref.read(summaryProvider.notifier).state = updatedSummary;
    ref.invalidate(historyProvider);

    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary updated and finalized')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(summaryProvider);

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clinical Insights')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text('No clinical summary selected'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    _initControllers(summary);
    final ttsService = ref.watch(ttsServiceProvider);
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinical Insights'),
            Text(
              summary.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: summary.status == ClinicalStatus.finalized
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              onPressed: () {
                if (_isSpeaking) {
                  ttsService.stop();
                  setState(() => _isSpeaking = false);
                } else {
                  final textToSpeak =
                      'Subjective: ${summary.soapSubjective}. Objective: ${summary.soapObjective}. Assessment: ${summary.soapAssessment}. Plan: ${summary.soapPlan}';
                  ttsService.speak(
                    textToSpeak,
                    rate: prefs.ttsRate,
                    pitch: prefs.ttsPitch,
                  );
                  setState(() => _isSpeaking = true);
                }
              },
              icon: Icon(
                _isSpeaking ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
              ),
              tooltip: _isSpeaking ? 'Stop Reading' : 'Read Summary',
            ),
            IconButton(
              onPressed: () => PDFService().generateAndPrintSummary(summary),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
            ),
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit SOAP Notes',
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => _saveChanges(summary),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _buildBody(context, summary),
      floatingActionButton: _isEditing
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Home'),
            ),
    );
  }

  Widget _buildBody(BuildContext context, ClinicalSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPatientHeader(context, summary),
        // Audio Player Section
        if (summary.localAudioPath != null) ...[
          _buildAudioPlayerSection(context, summary),
          const SizedBox(height: 24),
        ],
        // Transcript Section
        if (summary.transcript != null && summary.transcript!.isNotEmpty) ...[
          _buildTranscriptSection(context, summary),
          const SizedBox(height: 24),
        ],
        const SizedBox(height: 24),
        _buildSOAPSection(context, summary),
        const SizedBox(height: 24),
        _buildEntitiesSection(context, summary),
        const SizedBox(height: 24),
        _buildCodingSection(context, summary),
        const SizedBox(height: 100),
      ],
    );
  }

  Future<void> _playPauseAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Verify file exists before playing
        final file = File(audioPath);
        if (!file.existsSync()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio file not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (_position == _duration && _duration != Duration.zero) {
          // If audio finished, restart from beginning
          await _audioPlayer.seek(Duration.zero);
        }
        
        // Use setSourceDeviceFile for better compatibility
        await _audioPlayer.setSourceDeviceFile(audioPath);
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _buildAudioPlayerSection(BuildContext context, ClinicalSummary summary) {
    final audioFile = File(summary.localAudioPath!);
    final audioExists = audioFile.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Recorded Consultation'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: audioExists
              ? Column(
                  children: [
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () => _playPauseAudio(summary.localAudioPath!),
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Slider(
                                value: _position.inSeconds.toDouble(),
                                max: _duration.inSeconds.toDouble().clamp(1.0, double.infinity),
                                onChanged: (value) {
                                  _seekAudio(Duration(seconds: value.toInt()));
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audio file not found. It may have been deleted.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTranscriptSection(BuildContext context, ClinicalSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Conversation Transcript'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generated by Sarvam AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.transcript!,
                style: const TextStyle(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientHeader(BuildContext context, ClinicalSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'ID: ${summary.patientId} • ${DateFormat('dd MMM yyyy').format(summary.visitDate)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOAPSection(BuildContext context, ClinicalSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'SOAP Notes'),
        const SizedBox(height: 12),
        _buildSOAPItem(context, 'Subjective', _subjectiveController),
        _buildSOAPItem(context, 'Objective', _objectiveController),
        _buildSOAPItem(context, 'Assessment', _assessmentController),
        _buildSOAPItem(context, 'Plan', _planController),
      ],
    );
  }

  Widget _buildEntitiesSection(BuildContext context, ClinicalSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Extracted Entities'),
        const SizedBox(height: 12),
        if (summary.entities.isEmpty)
          const Text(
            'No clinical entities identified.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.entities
                .map((e) => _buildEntityChip(context, e))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildCodingSection(BuildContext context, ClinicalSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Clinical Coding'),
        const SizedBox(height: 12),
        if (summary.codes.isEmpty)
          const Text(
            'No clinical codes (ICD/SNOMED) identified.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          ...summary.codes.map((c) => _buildCodeTile(context, c)).toList(),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSOAPItem(
    BuildContext context,
    String title,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            TextFormField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(height: 1.5),
            )
          else
            Text(controller.text, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEntityChip(BuildContext context, MedicalEntity entity) {
    Color chipColor;
    switch (entity.type.toLowerCase()) {
      case 'symptom':
        chipColor = Colors.orange;
        break;
      case 'medication':
        chipColor = Colors.green;
        break;
      case 'vital':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline_rounded, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            entity.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeTile(BuildContext context, ClinicalCode code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(code.description, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            code.system,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
