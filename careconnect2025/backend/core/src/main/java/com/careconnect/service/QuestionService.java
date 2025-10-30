package com.careconnect.service;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.dto.QuestionUpsertDTO;

import java.util.List;
import java.util.Optional;

public interface QuestionService {
    List<QuestionDTO> listQuestions(Boolean active);
    Optional<QuestionDTO> getOne(Long id);
    QuestionDTO create(QuestionUpsertDTO body);
    Optional<QuestionDTO> update(Long id, QuestionUpsertDTO body);
    Optional<QuestionDTO> setActive(Long id, boolean active);

    // If your controller calls this, declare it too:
    List<QuestionDTO> findActiveOrdered();
}
