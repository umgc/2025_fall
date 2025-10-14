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

  VirtualCheckInQuestion copyWith({
    CheckInQuestionType? type,
    bool? required,
    String? text,
  }) {
    return VirtualCheckInQuestion(
      id: id,
      type: type ?? this.type,
      required: required ?? this.required,
      text: text ?? this.text,
    );
  }
}
