import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinote_ai/features/summary/domain/models/patient_model.dart';

final selectedPatientProvider = StateProvider<Patient?>((ref) => null);

final patientListProvider = Provider<List<Patient>>((ref) {
  return [
    Patient(id: 'P-101', name: 'John Doe', dob: '1985-05-15', gender: 'Male'),
    Patient(
      id: 'P-102',
      name: 'Jane Smith',
      dob: '1992-08-22',
      gender: 'Female',
    ),
    Patient(
      id: 'P-103',
      name: 'Robert Brown',
      dob: '1978-12-05',
      gender: 'Male',
    ),
    Patient(
      id: 'P-104',
      name: 'Alice Wilson',
      dob: '1995-03-30',
      gender: 'Female',
    ),
  ];
});
