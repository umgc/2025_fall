package com.careconnect.repository;

import com.careconnect.model.Question;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface QuestionRepository extends JpaRepository<Question, Long> {

    List<Question> findAllByOrderByOrdinalAscIdAsc();

    List<Question> findByActiveTrueOrderByOrdinalAscIdAsc();

    List<Question> findByActiveOrderByOrdinalAscIdAsc(boolean active);
}
