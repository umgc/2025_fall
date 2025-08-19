package com.focusedai.controller;

import com.focusedai.service.testcase.TestCaseService;
import com.focusedai.model.testcase.TestCase;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/testcases")
public class TestCaseController {

    @Autowired
    private TestCaseService testCaseService;

    @PostMapping
    public ResponseEntity<TestCase> createTestCase(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @RequestBody TestCase testCase) {
        
        TestCase created = testCaseService.createTestCase(testCase, userContext);
        return ResponseEntity.ok(created);
    }

    @GetMapping("/{assignmentId}")
    public ResponseEntity<List<TestCase>> getTestCases(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @PathVariable String assignmentId) {
        
        List<TestCase> testCases = testCaseService.getTestCases(assignmentId, userContext);
        return ResponseEntity.ok(testCases);
    }

    @PutMapping("/{assignmentId}")
    public ResponseEntity<List<TestCase>> updateTestCases(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @PathVariable String assignmentId,
            @RequestBody List<TestCase> testCases) {
        
        List<TestCase> updated = testCaseService.updateTestCases(assignmentId, testCases, userContext);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{assignmentId}")
    public ResponseEntity<Map<String, Object>> deleteTestCases(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @PathVariable String assignmentId) {
        
        boolean deleted = testCaseService.deleteTestCases(assignmentId, userContext);
        return ResponseEntity.ok(Map.of("success", deleted));
    }
}