package com.careconnect.model;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.dto.QuestionMapper;
import com.careconnect.dto.QuestionUpsertDTO;
import com.careconnect.repository.QuestionRepository;
import com.careconnect.service.QuestionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class QuestionServiceImpl implements QuestionService {

    private final QuestionRepository repo;

    public QuestionServiceImpl(QuestionRepository repo) {
        this.repo = repo;
    }

    @Override
    @Transactional(readOnly = true)
    public List<QuestionDTO> listQuestions(Boolean active) {
        List<Question> src;
        if (active == null) {
            // all questions ordered by ordinal
            src = repo.findAllByOrderByOrdinalAsc();
        } else if (active) {
            // only active, ordered
            src = repo.findAllByActiveTrueOrderByOrdinalAsc();
        } else {
            // only inactive, ordered
            src = repo.findAllByActiveFalseOrderByOrdinalAsc();
        }
        return src.stream().map(QuestionMapper::toDto).toList();
    }

    // #3: used by /v1/api/checkins/{id}/questions
    @Override
    @Transactional(readOnly = true)
    public List<QuestionDTO> findActiveOrdered() {
        return repo.findAllByActiveTrueOrderByOrdinalAsc()
                .stream()
                .map(QuestionMapper::toDto)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<QuestionDTO> getOne(Long id) {
        return repo.findById(id).map(QuestionMapper::toDto);
    }

    @Override
    public QuestionDTO create(QuestionUpsertDTO body) {
        Question q = new Question();
        QuestionMapper.applyUpsert(q, body);
        q.setActive(true);
        q = repo.save(q);
        return QuestionMapper.toDto(q);
    }

    @Override
    public Optional<QuestionDTO> update(Long id, QuestionUpsertDTO body) {
        return repo.findById(id).map(existing -> {
            QuestionMapper.applyUpsert(existing, body);
            existing = repo.save(existing);
            return QuestionMapper.toDto(existing);
        });
    }

    @Override
    public Optional<QuestionDTO> setActive(Long id, boolean active) {
        return repo.findById(id).map(existing -> {
            existing.setActive(active);
            existing = repo.save(existing);
            return QuestionMapper.toDto(existing);
        });
    }
}
