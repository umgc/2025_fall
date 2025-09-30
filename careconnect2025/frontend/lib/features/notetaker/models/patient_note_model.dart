class PatientNote {
  final String id;
  final String patientId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientNote({
    required this.id,
    required this.patientId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientNote.fromJson(Map<String, dynamic> json) {
    return PatientNote(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
