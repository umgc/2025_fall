class CareNote {
  final String id;
  final String type;       // "general", "assessment", "medication", "urgent"
  final String author;
  final String? role;      // "RN", "Caregiver"
  final DateTime createdAt;
  final String body;

  CareNote({
    required this.id,
    required this.type,
    required this.author,
    this.role,
    required this.createdAt,
    required this.body,
  });
}



