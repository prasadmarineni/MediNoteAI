import 'package:hive/hive.dart';

part 'clinical_summary_hive.g.dart';

@HiveType(typeId: 0)
class ClinicalSummaryHive extends HiveObject {
  @HiveField(0)
  late String cloudId;

  @HiveField(1)
  late String patientName;

  @HiveField(2)
  late String patientId;

  @HiveField(3)
  late DateTime visitDate;

  @HiveField(4)
  late String soapSubjective;

  @HiveField(5)
  late String soapObjective;

  @HiveField(6)
  late String soapAssessment;

  @HiveField(7)
  late String soapPlan;

  @HiveField(8)
  late List<MedicalEntityHive> entities;

  @HiveField(9)
  late List<ClinicalCodeHive> codes;

  @HiveField(10)
  late String audioUrl;

  @HiveField(11)
  late DateTime createdAt;

  @HiveField(12)
  bool isSynced = true;

  @HiveField(13)
  String? id;

  @HiveField(14)
  String? status; // 'draft', 'finalized', 'amended'

  @HiveField(15)
  String? localAudioPath; // path to the recorded WAV file on device

  @HiveField(16)
  String? transcript; // text received from Sarvam AI STT
}

@HiveType(typeId: 1)
class MedicalEntityHive {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String type;
}

@HiveType(typeId: 2)
class ClinicalCodeHive {
  @HiveField(0)
  late String code;

  @HiveField(1)
  late String description;

  @HiveField(2)
  late String system;
}
