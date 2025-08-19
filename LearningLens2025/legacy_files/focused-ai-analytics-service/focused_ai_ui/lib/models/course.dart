
class Course {
  final int id;
  final String fullName;
  final String shortName;
  final String? subject;

  Course({
    required this.id,
    required this.fullName,
    required this.shortName,
    this.subject,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id']?.toString() ?? ''),
        fullName: json['fullName'] ?? json['name'], // fallback to 'name' if 'fullName' is missing
        shortName: json['shortName'] ?? json['name'] ?? 'Unknown',
        subject: json['subject'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'shortName': shortName,
        'subject': subject,
      };
}