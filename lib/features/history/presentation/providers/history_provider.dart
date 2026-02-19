import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinote_ai/features/summary/data/repositories/clinical_data_repository.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';

final historyProvider = FutureProvider<List<ClinicalSummary>>((ref) async {
  final repository = ref.watch(clinicalRepositoryProvider);
  return repository.getHistory();
});
