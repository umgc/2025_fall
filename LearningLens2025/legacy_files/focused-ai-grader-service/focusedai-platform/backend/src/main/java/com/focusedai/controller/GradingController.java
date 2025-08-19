package com.focusedai.controller;

import com.focusedai.service.grading.GradingService;
import com.focusedai.dto.GradingRequestDto;
import com.focusedai.dto.GradeDto;
import com.focusedai.dto.BatchGradingResultDto;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/grade")
public class GradingController {

    @Autowired
    private GradingService gradingService;

    @PostMapping("/submission")
    public ResponseEntity<GradeDto> gradeSubmission(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @RequestBody GradingRequestDto request) {
        
        GradeDto grade = gradingService.gradeSubmission(request, userContext);
        return ResponseEntity.ok(grade);
    }

    @PostMapping("/batch")
    public ResponseEntity<BatchGradingResultDto> gradeBatch(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @RequestBody Map<String, Object> batchRequest) {
        
        BatchGradingResultDto result = gradingService.gradeBatch(batchRequest, userContext);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{submissionId}")
    public ResponseEntity<GradeDto> getGrade(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @PathVariable String submissionId) {
        
        GradeDto grade = gradingService.getGrade(submissionId, userContext);
        if (grade != null) {
            return ResponseEntity.ok(grade);
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/criteria/{language}")
    public ResponseEntity<Map<String, Object>> getGradingCriteria(
            @PathVariable String language,
            @RequestParam(required = false) String strategy) {
        
        Map<String, Object> criteria = gradingService.getGradingCriteria(language, strategy);
        return ResponseEntity.ok(criteria);
    }
}