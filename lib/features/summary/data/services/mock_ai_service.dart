import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';
import 'package:medinote_ai/features/summary/domain/services/ai_service_interface.dart';

class MockAIService implements IAIService {
  @override
  Future<ClinicalSummary> generateSummary(String transcript) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Instead of returning hardcoded mockSummary,
    // we use the actual transcript to make it feel real.
    return ClinicalSummary(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      patientName: "Patient", // Overridden by UI
      patientId: "ID",
      visitDate: DateTime.now(),
      soapSubjective: transcript,
      soapObjective: "Review of systems performed based on transcript details.",
      soapAssessment: "Clinical Review Pending (Demo Mode)",
      soapPlan: "Analyze transcript content for further diagnostic evaluation.",
      entities: [],
      codes: [],
    );
  }
}
