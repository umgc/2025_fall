import 'package:care_connect_app/features/health/virtual_check_in/domain/entities/virtual_check_in_question.dart';
import 'package:care_connect_app/features/health/virtual_check_in/data/dto/virtual_check_in_backend_question_dto.dart';



CheckInQuestionType mapTypeToUi(BackendQuestionType t) {
  switch (t) {
    case BackendQuestionType.NUMBER:
      return CheckInQuestionType.numerical;
    case BackendQuestionType.YES_NO:
    case BackendQuestionType.TRUE_FALSE: // treat as yes/no for now
      return CheckInQuestionType.yesNo;
    case BackendQuestionType.TEXT:
      return CheckInQuestionType.textInput;
  }
  throw StateError('Unhandled BackendQuestionType: $t');
}

VirtualCheckInQuestion toUiQuestion(BackendQuestionDto dto) {
  return VirtualCheckInQuestion(
    id: dto.id.toString(),
    type: mapTypeToUi(dto.type),
    required: dto.required,
    text: dto.prompt,
  );
}
