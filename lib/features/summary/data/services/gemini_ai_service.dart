import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';
import 'package:medinote_ai/features/summary/domain/services/ai_service_interface.dart';

class GeminiAIService implements IAIService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiAIService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      ),
    );
  }

  @override
  Future<ClinicalSummary> generateSummary(String transcript) async {
    final prompt =
        '''
    You are an expert medical assistant. Based on the following conversation transcript between a doctor and a patient, generate a structured clinical summary in JSON format.
    
    The JSON structure MUST be:
    {
      "soapSubjective": "Subjective notes (Patient's reported symptoms/history)",
      "soapObjective": "Objective notes (Vitals, physical findings)",
      "soapAssessment": "Assessment/Diagnosis",
      "soapPlan": "Treatment plan/Follow-up",
      "entities": [
        {"name": "Symptom Name", "type": "Symptom"},
        {"name": "Medication Name", "type": "Medication"},
        {"name": "Vital Value", "type": "Vital"}
      ],
      "codes": [
        {"code": "ICD Code", "description": "Description", "system": "ICD-10"}
      ]
    }

    Notes on Entity Types: Symptom, Medication, Vital, Allergy, Condition.
    Notes on Codes: Use ICD-10 or SNOMED systems.

    Transcript:
    $transcript
    ''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('Empty response from Gemini');
    }

    final Map<String, dynamic> data = jsonDecode(response.text!);

    return ClinicalSummary(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      patientName: data['patientName'] ?? 'Unknown',
      patientId: data['patientId'] ?? 'P-UNKNOWN',
      visitDate: DateTime.now(),
      soapSubjective: data['soapSubjective'] ?? '',
      soapObjective: data['soapObjective'] ?? '',
      soapAssessment: data['soapAssessment'] ?? '',
      soapPlan: data['soapPlan'] ?? '',
      entities:
          (data['entities'] as List?)
              ?.map(
                (e) => MedicalEntity(
                  name: e['name'] ?? '',
                  type: e['type'] ?? 'Other',
                ),
              )
              .toList() ??
          [],
      codes:
          (data['codes'] as List?)
              ?.map(
                (e) => ClinicalCode(
                  code: e['code'] ?? '',
                  description: e['description'] ?? '',
                  system: e['system'] ?? 'ICD-10',
                ),
              )
              .toList() ??
          [],
    );
  }
}
