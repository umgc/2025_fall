class PatientNote {
  final String id;
  final String patientId;
  final String note;
  final String aiSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientNote({
    required this.id,
    required this.patientId,
    required this.note,
    required this.aiSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientNote.fromJson(Map<String, dynamic> json) {
    return PatientNote(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      aiSummary: json['aiSummary']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'note': note,
      'aiSummary': aiSummary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
