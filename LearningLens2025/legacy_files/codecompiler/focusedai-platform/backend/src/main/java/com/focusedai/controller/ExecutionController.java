package com.focusedai.controller;

import com.focusedai.service.execution.ExecutionService;
import com.focusedai.dto.ExecutionRequestDto;
import com.focusedai.dto.ExecutionResultDto;
import com.focusedai.dto.BatchExecutionResultDto;
import com.focusedai.utils.UserContextExtractor;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/execute")
public class ExecutionController {

    @Autowired
    private ExecutionService executionService;

    @Autowired
    private UserContextExtractor userContextExtractor;

    @PostMapping("/{language}")
    public ResponseEntity<ExecutionResultDto> executeCode(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @PathVariable String language,
            @RequestBody ExecutionRequestDto request) {
        
        request.setLanguage(language);
        ExecutionResultDto result = executionService.executeCode(request, userContext);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/batch")
    public ResponseEntity<BatchExecutionResultDto> executeBatch(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @RequestBody Map<String, Object> batchRequest) {
        
        BatchExecutionResultDto result = executionService.executeBatch(batchRequest, userContext);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/analyze")
    public ResponseEntity<Map<String, Object>> analyzeCode(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @RequestBody ExecutionRequestDto request) {
        
        Map<String, Object> result = executionService.analyzeCode(request);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/strategies")
    public ResponseEntity<Map<String, Object>> getAvailableStrategies() {
        Map<String, Object> strategies = executionService.getAvailableStrategies();
        return ResponseEntity.ok(strategies);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> checkHealth() {
        Map<String, Object> health = executionService.checkExecutionHealth();
        return ResponseEntity.ok(health);
    }
}