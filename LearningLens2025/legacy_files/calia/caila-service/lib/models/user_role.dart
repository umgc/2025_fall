enum UserRole {
  teacher,
  student,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'Admin';
    }
  }
}