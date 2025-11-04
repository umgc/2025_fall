package com.careconnect.controller;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.dto.QuestionUpsertDTO;
import com.careconnect.service.QuestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for managing Question entities.
 *
 * Matches frontend routes:
 *   GET  /api/questions
 *   GET  /api/questions/{id}
 *   POST /api/questions
 *   PUT  /api/questions/{id}
 *   PATCH /api/questions/{id}/active
 *
 * Also supports /v1/api/... for backward compatibility.
 */
@RestController
@RequestMapping(path = {"/api/questions", "/v1/api/questions"}) // supports both
public class QuestionController {

    private final QuestionService questions;

    public QuestionController(QuestionService questions) {
        this.questions = questions;
    }

    /** GET /api/questions?active=true|false */
    @GetMapping
    public List<QuestionDTO> list(@RequestParam(required = false) Boolean active) {
        return questions.listQuestions(active);
    }

    /** GET /api/questions/{id} */
    @GetMapping("/{id}")
    public ResponseEntity<QuestionDTO> one(@PathVariable Long id) {
        return questions.getOne(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /** POST /api/questions */
    @PostMapping
    public ResponseEntity<QuestionDTO> create(@RequestBody QuestionUpsertDTO body) {
        QuestionDTO created = questions.create(body);
        return ResponseEntity.ok(created);
    }

    /** PUT /api/questions/{id} */
    @PutMapping("/{id}")
    public ResponseEntity<QuestionDTO> update(@PathVariable Long id,
                                              @RequestBody QuestionUpsertDTO body) {
        return questions.update(id, body)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /** PATCH /api/questions/{id}/active?active=true|false */
    @PatchMapping("/{id}/active")
    public ResponseEntity<QuestionDTO> setActive(@PathVariable Long id,
                                                 @RequestParam boolean active) {
        return questions.setActive(id, active)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
