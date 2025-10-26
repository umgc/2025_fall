package com.careconnect.model;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.dto.QuestionUpsertDTO;
import com.careconnect.dto.QuestionMapper;
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
        List<Question> all = (active == null)
                ? repo.findAll()
                : repo.findByActive(active); // <-- add this method to repo; see below
        return all.stream().map(QuestionMapper::toDto).toList();
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
        // default active if null logic is in entity or set here:
        if (q.getActive() == null) q.setActive(Boolean.TRUE);
        q = repo.save(q);
        return QuestionMapper.toDto(q);
    }

    @Override
    public Optional<QuestionDTO> update(Long id, QuestionUpsertDTO body) {
        return repo.findById(id).map(existing -> {
            QuestionMapper.applyUpsert(existing, body);
            return QuestionMapper.toDto(existing);
        });
    }

    @Override
    public Optional<QuestionDTO> setActive(Long id, boolean active) {
        return repo.findById(id).map(existing -> {
            existing.setActive(active);
            return QuestionMapper.toDto(existing);
        });
    }
}
