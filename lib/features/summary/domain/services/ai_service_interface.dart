import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';

abstract class IAIService {
  Future<ClinicalSummary> generateSummary(String transcript);
}
