
class Assessment {
  final int id;
  final String name;
  final String type; // "essay" or "quiz"

  Assessment({required this.id, required this.name, required this.type});

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        id: json['id'],
        name: json['name'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
      };
}