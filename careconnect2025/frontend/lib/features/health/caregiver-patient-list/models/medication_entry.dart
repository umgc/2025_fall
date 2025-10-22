enum MedicationStatus { active, paused, discontinued }

class MedicationEntry {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startedOn;
  final DateTime lastTakenAt;
  final int compliancePct;         // 0–100
  final MedicationStatus status;   // enum instead of string
  final bool isCritical;

  MedicationEntry({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startedOn,
    required this.lastTakenAt,
    required this.compliancePct,
    required this.status,
    this.isCritical = false,
  });

  // small helpers
  bool get isActive => status == MedicationStatus.active;
  bool get isPaused => status == MedicationStatus.paused;
  bool get isDiscontinued => status == MedicationStatus.discontinued;

  String get statusLabel {
    switch (status) {
      case MedicationStatus.active: return 'active';
      case MedicationStatus.paused: return 'paused';
      case MedicationStatus.discontinued: return 'discontinued';
    }
  }


  int get complianceClamped => compliancePct.clamp(0, 100);


  MedicationEntry copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startedOn,
    DateTime? lastTakenAt,
    int? compliancePct,
    MedicationStatus? status,
    bool? isCritical,
  }) {
    return MedicationEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startedOn: startedOn ?? this.startedOn,
      lastTakenAt: lastTakenAt ?? this.lastTakenAt,
      compliancePct: compliancePct ?? this.compliancePct,
      status: status ?? this.status,
      isCritical: isCritical ?? this.isCritical,
    );
  }
}
