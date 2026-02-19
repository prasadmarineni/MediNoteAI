import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medinote_ai/features/history/presentation/providers/history_provider.dart';

class ClinicalTimelineView extends ConsumerWidget {
  final String? patientId; // If null, shows all global visits for demo

  const ClinicalTimelineView({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No timeline data available'),
            ),
          );
        }

        // Show only the 5 most recent for timeline
        final displaySummaries = summaries.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displaySummaries.length,
          itemBuilder: (context, index) {
            final summary = displaySummaries[index];
            final isLast = index == displaySummaries.length - 1;

            return _buildTimelineItem(
              context,
              date: summary.visitDate,
              title: summary.soapAssessment.isEmpty
                  ? 'Clinical Note'
                  : summary.soapAssessment,
              content: summary.soapPlan,
              symptoms: summary.entities
                  .where((e) => e.type == 'Symptom')
                  .map((e) => e.name)
                  .toList(),
              isLast: isLast,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required DateTime date,
    required String title,
    required String content,
    required List<String> symptoms,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Left Side: Date & Dot
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  DateFormat('dd MMM').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('yyyy').format(date),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Center: Line & Node
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Right Side: Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (symptoms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      children: symptoms
                          .take(3)
                          .map((s) => _buildMiniChip(context, s))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
