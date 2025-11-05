package com.careconnect.repository;

import com.careconnect.model.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface QuestionRepository extends JpaRepository<Question, Long> {

    // Return all active/inactive questions
    List<Question> findByActive(Boolean active);
    List<Question> findAllByActiveTrueOrderByOrdinalAsc();

    // (Optional niceties)
    List<Question> findAllByActiveTrue();
    List<Question> findAllByActiveFalse();

    List<Question> findAllByOrderByOrdinalAsc();

    List<Question> findAllByActiveFalseOrderByOrdinalAsc();
}

