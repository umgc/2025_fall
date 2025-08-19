import 'package:focused_ai_app/models/user_role.dart';

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String platform;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.platform,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.teacher,
      ),
      platform: json['platform'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'platform': platform,
    };
  }
}
