enum ClinicalStatus { draft, finalized, amended }

class ClinicalSummary {
  final String id;
  final String patientName;
  final String patientId;
  final DateTime visitDate;
  final String soapSubjective;
  final String soapObjective;
  final String soapAssessment;
  final String soapPlan;
  final List<MedicalEntity> entities;
  final List<ClinicalCode> codes;
  final ClinicalStatus status;
  final String? localAudioPath; // path to the recorded WAV file on device
  final String? transcript; // text from Sarvam AI STT

  ClinicalSummary({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.visitDate,
    required this.soapSubjective,
    required this.soapObjective,
    required this.soapAssessment,
    required this.soapPlan,
    required this.entities,
    required this.codes,
    this.status = ClinicalStatus.draft,
    this.localAudioPath,
    this.transcript,
  });

  ClinicalSummary copyWith({
    String? patientName,
    String? patientId,
    DateTime? visitDate,
    String? soapSubjective,
    String? soapObjective,
    String? soapAssessment,
    String? soapPlan,
    List<MedicalEntity>? entities,
    List<ClinicalCode>? codes,
    ClinicalStatus? status,
    String? localAudioPath,
    String? transcript,
  }) {
    return ClinicalSummary(
      id: this.id,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      visitDate: visitDate ?? this.visitDate,
      soapSubjective: soapSubjective ?? this.soapSubjective,
      soapObjective: soapObjective ?? this.soapObjective,
      soapAssessment: soapAssessment ?? this.soapAssessment,
      soapPlan: soapPlan ?? this.soapPlan,
      entities: entities ?? this.entities,
      codes: codes ?? this.codes,
      status: status ?? this.status,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      transcript: transcript ?? this.transcript,
    );
  }
}

class MedicalEntity {
  final String name;
  final String type; // Symptom, Medication, Allergy, etc.

  MedicalEntity({required this.name, required this.type});
}

class ClinicalCode {
  final String code;
  final String description;
  final String system; // ICD-10, SNOMED

  ClinicalCode({
    required this.code,
    required this.description,
    required this.system,
  });
}
