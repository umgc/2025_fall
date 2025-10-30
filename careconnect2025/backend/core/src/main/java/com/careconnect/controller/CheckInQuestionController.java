package com.careconnect.controller;

import com.careconnect.dto.QuestionDTO;
import com.careconnect.service.QuestionService;   // <— use your existing service
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/api/checkins")
public class CheckInQuestionController {          // <— capital “I” in CheckIn

    private final QuestionService questionService;

    public CheckInQuestionController(QuestionService questionService) {
        this.questionService = questionService;
    }

    @GetMapping("/{checkInId}/questions")
    public ResponseEntity<List<QuestionDTO>> getQuestions(@PathVariable Long checkInId) {
        // Quick win: return active questions ordered by ordinal.
        List<QuestionDTO> list = questionService.findActiveOrdered();
        return ResponseEntity.ok(list);
    }
}