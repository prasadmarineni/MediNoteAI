class PatientVisit {
  final String id;
  final String patientName;
  final String date;
  final String summary;
  final List<String> symptoms;

  PatientVisit({
    required this.id,
    required this.patientName,
    required this.date,
    required this.summary,
    required this.symptoms,
  });
}

// Mock data
final mockVisits = [
  PatientVisit(
    id: '1',
    patientName: 'John Doe',
    date: 'Oct 24, 2023',
    summary: 'Follow-up for hypertension. BP is stable at 120/80.',
    symptoms: ['Hypertension', 'Follow-up'],
  ),
  PatientVisit(
    id: '2',
    patientName: 'Jane Smith',
    date: 'Oct 23, 2023',
    summary: 'Complaint of severe headache and nausea for 3 days.',
    symptoms: ['Headache', 'Nausea'],
  ),
  PatientVisit(
    id: '3',
    patientName: 'Robert Brown',
    date: 'Oct 22, 2023',
    summary: 'Annual physical examination. All vitals are normal.',
    symptoms: ['Annual Checkup'],
  ),
];
