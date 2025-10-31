package com.careconnect.dto;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.dto.QuestionUpsertDTO;
import com.careconnect.model.Question;

public final class QuestionMapper {

    private QuestionMapper() { }

    public static QuestionDTO toDto(Question q) {
        return new QuestionDTO(
                q.getId(),
                q.getPrompt(),
                q.getType().name(),  // Convert QuestionType enum to String
                q.isRequired(),
                q.getOrdinal()
        );
    }

    public static void applyUpsert(Question target, QuestionUpsertDTO src) {
        target.setPrompt(src.prompt());
        target.setType(src.type());
        target.setRequired(src.required());
        target.setOrdinal(src.ordinal());
    }
}
