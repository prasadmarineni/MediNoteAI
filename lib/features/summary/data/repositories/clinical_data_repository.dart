import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medinote_ai/core/services/local_database_service.dart';
import 'package:medinote_ai/features/summary/data/models/clinical_summary_hive.dart';
import 'package:medinote_ai/features/summary/domain/models/clinical_summary.dart';
import 'package:medinote_ai/core/services/firebase_service.dart';

class ClinicalDataRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String> uploadAudio(String localPath, String patientId) async {
    if (!FirebaseService.isInitialized) return 'mock_url';
    try {
      final file = File(localPath);
      final fileName =
          'recordings/$patientId/${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref().child(fileName);

      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Firebase Storage upload failed (possibly not enabled): $e');
      return 'mock_url_due_to_storage_disabled';
    }
  }

  Future<void> syncUnsyncedRecords() async {
    if (!FirebaseService.isInitialized) return;

    final box = LocalDatabaseService.summariesBox;
    final unsynced = box.values.where((s) => !s.isSynced).toList();

    if (unsynced.isEmpty) return;

    debugPrint(
      'Found ${unsynced.length} unsynced records. Starting background sync...',
    );

    for (final hiveSummary in unsynced) {
      try {
        final docRef = await _firestore.collection('summaries').add({
          'soapSubjective': hiveSummary.soapSubjective,
          'soapObjective': hiveSummary.soapObjective,
          'soapAssessment': hiveSummary.soapAssessment,
          'soapPlan': hiveSummary.soapPlan,
          'entities': hiveSummary.entities
              .map((e) => {'name': e.name, 'type': e.type})
              .toList(),
          'codes': hiveSummary.codes
              .map(
                (c) => {
                  'code': c.code,
                  'description': c.description,
                  'system': c.system,
                },
              )
              .toList(),
          'patientName': hiveSummary.patientName,
          'patientId': hiveSummary.patientId,
          'audioUrl': hiveSummary.audioUrl,
          'createdAt': hiveSummary.createdAt,
          'id': hiveSummary.id,
          'status': hiveSummary.status,
          'localAudioPath': hiveSummary.localAudioPath,
          'transcript': hiveSummary.transcript,
        });

        hiveSummary.cloudId = docRef.id;
        hiveSummary.isSynced = true;
        await hiveSummary.save();
        debugPrint('Successfully synced record: ${hiveSummary.cloudId}');
      } catch (e) {
        debugPrint('Failed to sync record: $e');
      }
    }
  }

  Future<void> saveSummary(ClinicalSummary summary, String audioUrl) async {
    // 1. Save to Local Cache (Hive) immediately
    final hiveSummary = ClinicalSummaryHive()
      ..cloudId =
          '' // Will be updated after Firestore save
      ..patientName = summary.patientName
      ..patientId = summary.patientId
      ..visitDate = summary.visitDate
      ..soapSubjective = summary.soapSubjective
      ..soapObjective = summary.soapObjective
      ..soapAssessment = summary.soapAssessment
      ..soapPlan = summary.soapPlan
      ..entities = summary.entities
          .map(
            (e) => MedicalEntityHive()
              ..name = e.name
              ..type = e.type,
          )
          .toList()
      ..codes = summary.codes
          .map(
            (c) => ClinicalCodeHive()
              ..code = c.code
              ..description = c.description
              ..system = c.system,
          )
          .toList()
      ..audioUrl = audioUrl
      ..createdAt = DateTime.now()
      ..isSynced = false
      ..id = summary.id
      ..status = summary.status.name
      ..localAudioPath = summary.localAudioPath
      ..transcript = summary.transcript;

    await LocalDatabaseService.summariesBox.add(hiveSummary);

    // 2. Try to sync immediately
    await syncUnsyncedRecords();
  }

  Future<List<ClinicalSummary>> getHistory() async {
    // Check if local database is empty and try to restore from Firestore
    final localSummaries = LocalDatabaseService.summariesBox.values.toList();
    
    if (localSummaries.isEmpty && FirebaseService.isInitialized) {
      debugPrint('Local database empty. Attempting to restore from Firestore...');
      await _restoreFromFirestore();
    }
    
    // Return local cache (Hive is the source of truth for the UI)
    final summaries = LocalDatabaseService.summariesBox.values.toList();

    // Sort by date, most recent first
    summaries.sort((a, b) => b.visitDate.compareTo(a.visitDate));

    return summaries
        .map(
          (h) => ClinicalSummary(
            id: h.id ?? 'LEGACY-${h.visitDate.millisecondsSinceEpoch}',
            patientName: h.patientName,
            patientId: h.patientId,
            visitDate: h.visitDate,
            soapSubjective: h.soapSubjective,
            soapObjective: h.soapObjective,
            soapAssessment: h.soapAssessment,
            soapPlan: h.soapPlan,
            entities: h.entities
                .map((e) => MedicalEntity(name: e.name, type: e.type))
                .toList(),
            codes: h.codes
                .map(
                  (c) => ClinicalCode(
                    code: c.code,
                    description: c.description,
                    system: c.system,
                  ),
                )
                .toList(),
            status: ClinicalStatus.values.firstWhere(
              (s) => s.name == (h.status ?? 'draft'),
              orElse: () => ClinicalStatus.draft,
            ),
            localAudioPath: h.localAudioPath,
            transcript: h.transcript,
          ),
        )
        .toList();
  }

  /// Restore consultations from Firestore to Hive (after app reinstall)
  Future<void> _restoreFromFirestore() async {
    try {
      final querySnapshot = await _firestore
          .collection('summaries')
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit to last 100 consultations
          .get();

      debugPrint('Restoring ${querySnapshot.docs.length} consultations from Firestore');

      final box = LocalDatabaseService.summariesBox;

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          
          final hiveSummary = ClinicalSummaryHive()
            ..cloudId = doc.id
            ..patientName = data['patientName'] ?? ''
            ..patientId = data['patientId'] ?? ''
            ..visitDate = (data['createdAt'] as Timestamp).toDate()
            ..soapSubjective = data['soapSubjective'] ?? ''
            ..soapObjective = data['soapObjective'] ?? ''
            ..soapAssessment = data['soapAssessment'] ?? ''
            ..soapPlan = data['soapPlan'] ?? ''
            ..entities = (data['entities'] as List<dynamic>?)
                    ?.map(
                      (e) => MedicalEntityHive()
                        ..name = e['name']
                        ..type = e['type'],
                    )
                    .toList() ??
                []
            ..codes = (data['codes'] as List<dynamic>?)
                    ?.map(
                      (c) => ClinicalCodeHive()
                        ..code = c['code']
                        ..description = c['description']
                        ..system = c['system'],
                    )
                    .toList() ??
                []
            ..audioUrl = data['audioUrl'] ?? ''
            ..createdAt = (data['createdAt'] as Timestamp).toDate()
            ..isSynced = true
            ..id = data['id'] ?? doc.id
            ..status = data['status'] ?? 'draft'
            ..localAudioPath = data['localAudioPath']
            ..transcript = data['transcript'];

          await box.add(hiveSummary);
        } catch (e) {
          debugPrint('Error restoring document ${doc.id}: $e');
        }
      }

      debugPrint('Successfully restored ${box.length} consultations from Firestore');
    } catch (e) {
      debugPrint('Error restoring from Firestore: $e');
    }
  }

  Future<void> updateSummary(ClinicalSummary summary) async {
    final box = LocalDatabaseService.summariesBox;
    final index = box.values.toList().indexWhere((s) => s.id == summary.id);

    if (index != -1) {
      final hiveSummary = box.getAt(index)!;
      hiveSummary.patientName = summary.patientName;
      hiveSummary.patientId = summary.patientId;
      hiveSummary.soapSubjective = summary.soapSubjective;
      hiveSummary.soapObjective = summary.soapObjective;
      hiveSummary.soapAssessment = summary.soapAssessment;
      hiveSummary.soapPlan = summary.soapPlan;
      hiveSummary.status = summary.status.name;
      hiveSummary.isSynced = false; // Mark for re-sync
      await hiveSummary.save();

      // Attempt background sync
      syncUnsyncedRecords();
    }
  }

  Future<void> clearHistory() async {
    await LocalDatabaseService.summariesBox.clear();
  }
}

final clinicalRepositoryProvider = Provider<ClinicalDataRepository>((ref) {
  return ClinicalDataRepository();
});
