// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_summary_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClinicalSummaryHiveAdapter extends TypeAdapter<ClinicalSummaryHive> {
  @override
  final int typeId = 0;

  @override
  ClinicalSummaryHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClinicalSummaryHive()
      ..cloudId = fields[0] as String
      ..patientName = fields[1] as String
      ..patientId = fields[2] as String
      ..visitDate = fields[3] as DateTime
      ..soapSubjective = fields[4] as String
      ..soapObjective = fields[5] as String
      ..soapAssessment = fields[6] as String
      ..soapPlan = fields[7] as String
      ..entities = (fields[8] as List).cast<MedicalEntityHive>()
      ..codes = (fields[9] as List).cast<ClinicalCodeHive>()
      ..audioUrl = fields[10] as String
      ..createdAt = fields[11] as DateTime
      ..isSynced = fields[12] as bool
      ..id = fields[13] as String?
      ..status = fields[14] as String?
      ..localAudioPath = fields[15] as String?
      ..transcript = fields[16] as String?;
  }

  @override
  void write(BinaryWriter writer, ClinicalSummaryHive obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.cloudId)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.visitDate)
      ..writeByte(4)
      ..write(obj.soapSubjective)
      ..writeByte(5)
      ..write(obj.soapObjective)
      ..writeByte(6)
      ..write(obj.soapAssessment)
      ..writeByte(7)
      ..write(obj.soapPlan)
      ..writeByte(8)
      ..write(obj.entities)
      ..writeByte(9)
      ..write(obj.codes)
      ..writeByte(10)
      ..write(obj.audioUrl)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.id)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.localAudioPath)
      ..writeByte(16)
      ..write(obj.transcript);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalSummaryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicalEntityHiveAdapter extends TypeAdapter<MedicalEntityHive> {
  @override
  final int typeId = 1;

  @override
  MedicalEntityHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicalEntityHive()
      ..name = fields[0] as String
      ..type = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, MedicalEntityHive obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalEntityHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClinicalCodeHiveAdapter extends TypeAdapter<ClinicalCodeHive> {
  @override
  final int typeId = 2;

  @override
  ClinicalCodeHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClinicalCodeHive()
      ..code = fields[0] as String
      ..description = fields[1] as String
      ..system = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, ClinicalCodeHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.system);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalCodeHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
