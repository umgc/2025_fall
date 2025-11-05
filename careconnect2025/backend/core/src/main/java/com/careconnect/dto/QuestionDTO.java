package com.careconnect.dto;

// QuestionDTO
public record QuestionDTO(Long id, String prompt, String type, boolean required, boolean active, int ordinal) {}

// CreateCheckInRequest (package-private to allow multiple records in one file)
record CreateCheckInRequest(Long patientId, java.util.List<Long> selectedQuestionIds) {}

// CheckInSummaryDTO (for history card)
record CheckInSummaryDTO(
        Long id, String clinicianName, String type, String status,
        java.time.OffsetDateTime startedAt, Integer durationMinutes,
        String moodLabel, java.time.OffsetDateTime nextCheckIn, String summary) {}

// AnswerUpsertDTO  (send one per answered question)
record AnswerUpsertDTO(Long questionId, String valueText, Boolean valueBoolean, java.math.BigDecimal valueNumber) {}
