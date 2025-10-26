package com.careconnect.controller;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.dto.QuestionUpsertDTO;
import com.careconnect.service.QuestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/questions")
public class QuestionController {

    private final QuestionService questions;

    public QuestionController(QuestionService questions) {
        this.questions = questions;
    }

    @GetMapping
    public List<QuestionDTO> list(@RequestParam(required = false) Boolean active) {
        return questions.listQuestions(active);
    }

    @GetMapping("/{id}")
    public ResponseEntity<QuestionDTO> one(@PathVariable Long id) {
        return questions.getOne(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<QuestionDTO> create(@RequestBody QuestionUpsertDTO body) {
        QuestionDTO created = questions.create(body);
        return ResponseEntity.ok(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<QuestionDTO> update(@PathVariable Long id,
                                              @RequestBody QuestionUpsertDTO body) {
        return questions.update(id, body)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/active")
    public ResponseEntity<QuestionDTO> setActive(@PathVariable Long id,
                                                 @RequestParam boolean active) {
        return questions.setActive(id, active)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
