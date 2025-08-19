// Create this file: backend/src/main/java/com/focusedai/codeexecution/controller/CodeExecutionController.java

package com.focusedai.codeexecution.controller;

import com.focusedai.codeexecution.model.CodeExecutionRequest;
import com.focusedai.codeexecution.model.CodeExecutionResult;
import com.focusedai.codeexecution.service.CodeExecutionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.focusedai.codeexecution.model.BatchExecutionRequest;
import com.focusedai.codeexecution.model.BatchExecutionResult;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/execute")
@CrossOrigin(origins = "http://localhost:3000")
public class CodeExecutionController {

    @Autowired
    private CodeExecutionService codeExecutionService;

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "🚀 FocusEd AI Code Execution Service");
        response.put("architecture", "100% Serverless - AWS Lambda Functions");
        response.put("description", "Multi-platform educational code execution for Moodle & Google Classroom");
        response.put("ready", true);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/lambda-status")
    public ResponseEntity<Map<String, Object>> lambdaStatus() {
        return ResponseEntity.ok(codeExecutionService.getStatus());
    }

    @GetMapping("/lambda-test")
    public ResponseEntity<Map<String, Object>> testAllLambdas() {
        return ResponseEntity.ok(codeExecutionService.testAllLanguages());
    }

    @PostMapping("/{language}")
    public ResponseEntity<CodeExecutionResult> executeCode(
            @PathVariable String language,
            @RequestBody CodeExecutionRequest request) {
        
        try {
            CodeExecutionResult result = codeExecutionService.executeCode(language, request);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            CodeExecutionResult errorResult = new CodeExecutionResult();
            errorResult.setSuccess(false);
            errorResult.setOutput("");
            errorResult.setError("Execution failed: " + e.getMessage());
            errorResult.setLanguage(language.toUpperCase());
            errorResult.setServerless(true);
            errorResult.setArchitecture("100% Serverless");
            return ResponseEntity.ok(errorResult);
        }
    }

    // Language-specific endpoints for easier integration
    @PostMapping("/java")
    public ResponseEntity<CodeExecutionResult> executeJava(@RequestBody CodeExecutionRequest request) {
        return executeCode("java", request);
    }

    @PostMapping("/python")
    public ResponseEntity<CodeExecutionResult> executePython(@RequestBody CodeExecutionRequest request) {
        return executeCode("python", request);
    }

    @PostMapping("/javascript")
    public ResponseEntity<CodeExecutionResult> executeJavaScript(@RequestBody CodeExecutionRequest request) {
        return executeCode("javascript", request);
    }

    @PostMapping("/cpp")
    public ResponseEntity<CodeExecutionResult> executeCpp(@RequestBody CodeExecutionRequest request) {
        return executeCode("cpp", request);
    }

    /**
     * Execute multiple submissions in parallel
     * POST /api/execute/batch
     */
    @PostMapping("/batch")
    public ResponseEntity<BatchExecutionResult> executeBatch(@RequestBody BatchExecutionRequest batchRequest) {
        try {
            System.out.println("🚀 Batch execution request for assignment: " + batchRequest.getAssignmentId());
            System.out.println("📊 Processing " + batchRequest.getSubmissions().size() + " submissions");
            
            // Validate batch request
            if (batchRequest.getSubmissions() == null || batchRequest.getSubmissions().isEmpty()) {
                throw new IllegalArgumentException("No submissions provided for batch execution");
            }
            
            if (batchRequest.getAssignmentId() == null || batchRequest.getAssignmentId().trim().isEmpty()) {
                throw new IllegalArgumentException("Assignment ID is required for batch execution");
            }

            // Execute batch
            BatchExecutionResult result = codeExecutionService.executeBatch(batchRequest);
            
            System.out.println("✅ Batch execution completed: " + result.getSummary());
            return ResponseEntity.ok(result);
            
        } catch (IllegalArgumentException e) {
            System.err.println("❌ Invalid batch request: " + e.getMessage());
            
            // Create error response
            BatchExecutionResult errorResult = new BatchExecutionResult();
            errorResult.setAssignmentId(batchRequest.getAssignmentId());
            errorResult.setBatchId("error");
            errorResult.setTotalSubmissions(batchRequest.getSubmissions() != null ? batchRequest.getSubmissions().size() : 0);
            errorResult.setSuccessfulExecutions(0);
            errorResult.setFailedExecutions(errorResult.getTotalSubmissions());
            
            return ResponseEntity.badRequest().body(errorResult);
            
        } catch (Exception e) {
            System.err.println("❌ Batch execution error: " + e.getMessage());
            e.printStackTrace();
            
            // Create error response
            BatchExecutionResult errorResult = new BatchExecutionResult();
            errorResult.setAssignmentId(batchRequest.getAssignmentId());
            errorResult.setBatchId("error");
            errorResult.setTotalSubmissions(batchRequest.getSubmissions() != null ? batchRequest.getSubmissions().size() : 0);
            errorResult.setSuccessfulExecutions(0);
            errorResult.setFailedExecutions(errorResult.getTotalSubmissions());
            
            return ResponseEntity.status(500).body(errorResult);
        }
    }

    /**
     * Get batch execution status
     * GET /api/execute/batch/{batchId}/status
     */
    @GetMapping("/batch/{batchId}/status")
    public ResponseEntity<Map<String, Object>> getBatchStatus(@PathVariable String batchId) {
        // This would typically check a database or cache for batch status
        // For now, return a simple response
        Map<String, Object> status = new HashMap<>();
        status.put("batchId", batchId);
        status.put("status", "completed");
        status.put("message", "Batch execution status endpoint - implementation depends on your storage solution");
        
        return ResponseEntity.ok(status);
    }

    /**
     * Get supported languages and their status
     * GET /api/execute/languages
     */
    @GetMapping("/languages")
    public ResponseEntity<Map<String, Object>> getSupportedLanguages() {
        Map<String, Object> languages = new HashMap<>();
        
        Map<String, Object> python = new HashMap<>();
        python.put("name", "Python");
        python.put("extensions", new String[]{".py"});
        python.put("runtime", "Python 3.9");
        python.put("executionType", "Interpreted");
        
        Map<String, Object> javascript = new HashMap<>();
        javascript.put("name", "JavaScript");
        javascript.put("extensions", new String[]{".js"});
        javascript.put("runtime", "Node.js 18");
        javascript.put("executionType", "Interpreted");
        
        Map<String, Object> java = new HashMap<>();
        java.put("name", "Java");
        java.put("extensions", new String[]{".java"});
        java.put("runtime", "OpenJDK 17");
        java.put("executionType", "Compiled");
        
        Map<String, Object> cpp = new HashMap<>();
        cpp.put("name", "C++");
        cpp.put("extensions", new String[]{".cpp", ".cc", ".cxx", ".c"});
        cpp.put("runtime", "GCC");
        cpp.put("executionType", "Compiled");
        
        languages.put("python", python);
        languages.put("javascript", javascript);
        languages.put("java", java);
        languages.put("cpp", cpp);
        
        return ResponseEntity.ok(languages);
    }

    /**
     * Health check endpoint
     * GET /api/execute/health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "Code Execution Service");
        health.put("timestamp", System.currentTimeMillis());
        health.put("capabilities", new String[]{
            "single-execution",
            "batch-execution", 
            "multi-language",
            "parallel-processing"
        });
        
        return ResponseEntity.ok(health);
    }
}