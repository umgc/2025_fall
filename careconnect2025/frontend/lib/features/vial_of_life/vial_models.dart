class Profile {
  final String firstName, lastName, id, bloodType, lastUpdated, gender;
  final DateTime dob;
  final List<String> allergiesCritical, allergiesCaution, medications;
  final List<Tag> conditions;
  final List<Contact> contacts;
  final String secureToken;

  const Profile({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dob,
    required this.id,
    required this.bloodType,
    required this.allergiesCritical,
    required this.allergiesCaution,
    required this.medications,
    required this.conditions,
    required this.contacts,
    required this.lastUpdated,
    this.secureToken = 'abc123def456',
  });

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return (a + b).toUpperCase();
  }

  int get age {
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  String qrPayload() {
    final primary = contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contacts.isNotEmpty
          ? contacts.first
          : Contact(name: 'N/A', role: '', phone: ''),
    );

    // keep only digits and leading +
    final tel = primary.phone.replaceAll(RegExp(r'[^+\d]'), '');
    return 'tel:$tel';
  }
  
}


enum TagColor { orange, blue }

class Tag {
  final String label;
  final TagColor color;
  const Tag(this.label, this.color);
}

class Contact {
  final String name, role, phone;
  final bool isPrimary;
  const Contact({
    required this.name,
    required this.role,
    required this.phone,
    this.isPrimary = false,
  });
}
