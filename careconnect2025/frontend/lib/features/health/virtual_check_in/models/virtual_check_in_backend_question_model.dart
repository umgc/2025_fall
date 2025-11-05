import 'package:care_connect_app/features/health/virtual_check_in/models/question_type.dart';


class BackendQuestionDto {
  final int? id;
  final String prompt;
  final BackendQuestionType type;
  final bool required;
  final bool active;
  final int ordinal;

  const BackendQuestionDto({
    this.id,
    required this.prompt,
    required this.type,
    required this.required,
    required this.active,
    required this.ordinal,
  });

  factory BackendQuestionDto.fromJson(Map<String, dynamic> json) {
    return BackendQuestionDto(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num?)?.toInt(),
      prompt: (json['prompt'] ?? '') as String,
      type: BackendQuestionType.fromWire(json['type'] as String?),
      required: (json['required'] as bool?) ?? false,
      active: (json['active'] as bool?) ?? true,
      ordinal: json['ordinal'] is int
          ? json['ordinal'] as int
          : (json['ordinal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'prompt': prompt,
      'type': type.toWire(), // MUST match backend enum string
      'required': required,
      'active': active,
      'ordinal': ordinal,
    };
  }

  BackendQuestionDto copyWith({
    int? id,
    String? prompt,
    BackendQuestionType? type,
    bool? required,
    bool? active,
    int? ordinal,
  }) {
    return BackendQuestionDto(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      required: required ?? this.required,
      active: active ?? this.active,
      ordinal: ordinal ?? this.ordinal,
    );
  }
}
