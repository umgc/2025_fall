//medication status enum
enum MedicationStatus { upcoming, taken, missed }

MedicationStatus _statusFrom(dynamic v, bool? isActive) {
  // backend uses isActive flag, not explicit "status" field
  if (isActive == true) return MedicationStatus.upcoming; // active meds = upcoming
  return MedicationStatus.missed; // inactive = missed
}

/// Medication model
/// @param name - The name of the medication
/// @param dosage - The dosage of the medication
/// @param frequency - The frequency of the medication
/// @param status - The status of the medication
/// @param nextDose - The next dose of the medication
/// @param deliveryMethod - The delivery method of the medication
class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final MedicationStatus status;
  final String nextDose;
  final String deliveryMethod;

  const Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.status,
    required this.nextDose,
    required this.deliveryMethod,
  });

  Medication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    MedicationStatus? status,
    String? nextDose,
    String? deliveryMethod,
  }) {
    return Medication(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      nextDose: nextDose ?? this.nextDose,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
    );
  }

  // backend MedicationDTO
  factory Medication.fromJson(Map<String, dynamic> j) {
    return Medication(
      name: j['medicationName']?.toString() ?? '',
      dosage: j['dosage']?.toString() ?? '',
      frequency: j['frequency']?.toString() ?? '',
      deliveryMethod: j['route']?.toString() ?? '',
      status: _statusFrom(j['medicationType'], j['isActive']),
      nextDose: '', // backend doesn't provide next dose time yet
    );
  }

  //convert back to JSON for later POST/PUT support
  Map<String, dynamic> toJson() => {
    'medicationName': name,
    'dosage': dosage,
    'frequency': frequency,
    'route': deliveryMethod,
    'isActive': status == MedicationStatus.upcoming,
  };
}

