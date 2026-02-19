class Patient {
  final String id;
  final String name;
  final String? dob;
  final String? gender;

  Patient({required this.id, required this.name, this.dob, this.gender});
}
