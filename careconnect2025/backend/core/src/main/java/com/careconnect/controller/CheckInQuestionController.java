package com.careconnect.controller;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.service.QuestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping(path = {"/api/checkins", "/v1/api/checkins"}) // <- supports both
public class CheckInQuestionController {

    private final QuestionService questionService;

    public CheckInQuestionController(QuestionService questionService) {
        this.questionService = questionService;
    }

    /**
     * GET /api/checkins/{checkInId}/questions
     * GET /v1/api/checkins/{checkInId}/questions
     */
    @GetMapping("/{checkInId}/questions")
    public ResponseEntity<List<QuestionDTO>> getQuestions(@PathVariable("checkInId") Long checkInId) {
        // Temporary: return active, ordered questions until per-check-in mapping is ready
        List<QuestionDTO> questions = questionService.findActiveOrdered();
        return ResponseEntity.ok(questions);
    }
}
