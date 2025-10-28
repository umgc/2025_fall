// lib/features/health/caregiver-patient-list/models/virtual_check_in_question.dart

enum CheckInQuestionType { numerical, yesNo, textInput }

class VirtualCheckInQuestion {
  final String id;
  final CheckInQuestionType type;
  final bool required;
  final String text;

  const VirtualCheckInQuestion({
    required this.id,
    required this.type,
    required this.required,
    required this.text,
  });
}
