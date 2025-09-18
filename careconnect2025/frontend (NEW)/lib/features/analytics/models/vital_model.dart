class Vital {
  final DateTime timestamp;
  final double heartRate;
  final double spo2;
  final int systolic;
  final int diastolic;
  final double weight;
  final int? moodValue;
  final int? painValue;
  final int patientId;

  Vital({
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.systolic,
    required this.diastolic,
    required this.weight,
    required this.patientId,
    this.moodValue,
    this.painValue,
  });

  factory Vital.fromJson(Map<String, dynamic> json) {
    double safeDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    DateTime safeDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Vital(
      patientId: safeInt(json['patientId'] ?? json['id']),
      timestamp: safeDate(json['timestamp']),
      heartRate: safeDouble(json['heartRate'], 0.0),
      spo2: safeDouble(json['spo2'], 0.0),
      systolic: safeInt(json['systolic'], 0),
      diastolic: safeInt(json['diastolic'], 0),
      weight: safeDouble(json['weight'], 0.0),
      moodValue: json['moodValue'] == null ? null : safeInt(json['moodValue']),
      painValue: json['painValue'] == null ? null : safeInt(json['painValue']),
    );
  }
}
