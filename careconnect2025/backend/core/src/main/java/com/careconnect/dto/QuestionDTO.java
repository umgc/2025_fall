package com.careconnect.dto;

import com.careconnect.model.QuestionType;

public record QuestionDTO(
        Long id,
        String prompt,
        QuestionType type,
        boolean required,
        Integer ordinal,
        Boolean active
) { }
