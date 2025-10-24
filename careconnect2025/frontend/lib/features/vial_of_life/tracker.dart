
class Tracker {
  static final List<String> _meds = [];
  static final List<String> _allergies = [];
  static final List<String> _conditions = [];
  static final List<String> _symptoms = [];

  static String _stamp() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // Call these right after you save
  static void logMedication(String label) {
    _meds.insert(0, "Added medication: $label • ${_stamp()}");
    if (_meds.length > 50) _meds.removeLast();
  }
  static void logAllergy(String label) {
    _allergies.insert(0, "Added allergy: $label • ${_stamp()}");
    if (_allergies.length > 50) _allergies.removeLast();
  }
  static void logCondition(String label) {
    _conditions.insert(0, "Added condition: $label • ${_stamp()}");
    if (_conditions.length > 50) _conditions.removeLast();
  }
  static void logSymptom(String label) {
    _symptoms.insert(0, "Added symptom: $label • ${_stamp()}");
    if (_symptoms.length > 50) _symptoms.removeLast();
  }

  static List<String> get meds => List.unmodifiable(_meds);
  static List<String> get allergies => List.unmodifiable(_allergies);
  static List<String> get conditions => List.unmodifiable(_conditions);
  static List<String> get symptoms => List.unmodifiable(_symptoms);
}
