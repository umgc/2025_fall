package com.careconnect.controller;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.service.QuestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller that exposes check-in specific question endpoints.
 *
 * Matches frontend routes:
 *   GET /v1/api/checkins/{checkInId}/questions
 *
 * If a check-in-specific question list is not yet implemented,
 * this controller currently returns all active questions in order
 * via the QuestionService.
 */
@RestController
@RequestMapping("/v1/api/checkins")
public class CheckInQuestionController {

    private final QuestionService questionService;

    public CheckInQuestionController(QuestionService questionService) {
        this.questionService = questionService;
    }

    /**
     * GET /v1/api/checkins/{checkInId}/questions
     *
     * Retrieves the list of questions associated with a given check-in.
     * Currently delegates to QuestionService.findActiveOrdered().
     *
     * @param checkInId ID of the check-in
     * @return List of QuestionDTOs (active and ordered)
     */
    @GetMapping("/{checkInId}/questions")
    public ResponseEntity<List<QuestionDTO>> getQuestions(@PathVariable Long checkInId) {
        List<QuestionDTO> questions = questionService.findActiveOrdered();
        return ResponseEntity.ok(questions);
    }
}
