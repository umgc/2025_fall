package com.careconnect.dto;

import com.careconnect.model.QuestionType;

public record QuestionUpsertDTO(
        String prompt,
        QuestionType type,
        boolean required,
        Integer ordinal
) { }