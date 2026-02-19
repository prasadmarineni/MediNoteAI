import 'package:hive_flutter/hive_flutter.dart';
import 'package:medinote_ai/features/summary/data/models/clinical_summary_hive.dart';

class LocalDatabaseService {
  static const String summariesBoxName = 'summaries';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ClinicalSummaryHiveAdapter());
    Hive.registerAdapter(MedicalEntityHiveAdapter());
    Hive.registerAdapter(ClinicalCodeHiveAdapter());

    // Open Boxes
    await Hive.openBox<ClinicalSummaryHive>(summariesBoxName);
  }

  static Box<ClinicalSummaryHive> get summariesBox =>
      Hive.box<ClinicalSummaryHive>(summariesBoxName);
}
