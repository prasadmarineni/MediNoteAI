import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medinote_ai/features/summary/data/repositories/clinical_data_repository.dart';
import 'package:intl/intl.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';
import 'package:medinote_ai/features/summary/presentation/screens/summary_screen.dart';
import 'package:medinote_ai/features/history/presentation/providers/history_provider.dart';
import 'package:medinote_ai/core/providers/security_provider.dart';
import 'package:medinote_ai/features/recording/data/services/sarvam_stt_service.dart';
import 'package:medinote_ai/features/summary/presentation/providers/ai_service_provider.dart';
import 'package:medinote_ai/features/settings/presentation/providers/preferences_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final securityAsync = ref.watch(securityCheckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient History'),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All History?'),
                  content: const Text(
                    'This will permanently delete all clinical records from your local device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(clinicalRepositoryProvider).clearHistory();
                ref.invalidate(historyProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History Cleared')),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by assessment...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: securityAsync.when(
        data: (isAuthenticated) {
          if (!isAuthenticated) {
            return _buildLockedState();
          }
          final historyAsync = ref.watch(historyProvider);
          return historyAsync.when(
            data: (summaries) {
              final filteredSummaries = summaries.where((s) {
                final assessment = s.soapAssessment.toLowerCase();
                final patient = s.patientName.toLowerCase();
                final query = _searchQuery.toLowerCase();
                return assessment.contains(query) || patient.contains(query);
              }).toList();

              if (filteredSummaries.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSummaries.length,
                itemBuilder: (context, index) {
                  final summary = filteredSummaries[index];
                  return _buildHistoryCard(context, summary);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildLockedState(),
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_person_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Authentication Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Please authenticate to view clinical records.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(securityCheckProvider),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Unlock with Biometrics'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No history found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Your past clinical notes will appear here.'),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ClinicalSummary summary) {
    final dateStr = DateFormat('dd MMM yyyy').format(summary.visitDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            summary.patientName.isNotEmpty
                ? summary.patientName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                summary.patientName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: summary.status == ClinicalStatus.finalized
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                summary.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: summary.status == ClinicalStatus.finalized
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'ID: ${summary.patientId} • $dateStr',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              summary.soapAssessment.isEmpty
                  ? 'View details for assessment and plan.'
                  : summary.soapAssessment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          ref.read(summaryProvider.notifier).state = summary;
          context.push('/summary');
        },
      ),
    );
  }
}
