enum LMSPlatform {
  google,
  moodle;

  String get displayName {
    switch (this) {
      case LMSPlatform.google:
        return 'Google Classroom';
      case LMSPlatform.moodle:
        return 'Moodle';
    }
  }

  String get platformKey {
    switch (this) {
      case LMSPlatform.google:
        return 'google';
      case LMSPlatform.moodle:
        return 'moodle';
    }
  }
}