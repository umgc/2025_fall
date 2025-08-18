package com.focusedai.service.execution;

import com.focusedai.dto.*;
import com.focusedai.model.execution.ExecutionRequest;
import com.focusedai.model.execution.ExecutionResult;
import com.focusedai.model.execution.CodeAnalysis;
import com.focusedai.model.execution.CodeFile;
import com.focusedai.exception.ExecutionException;
import com.focusedai.utils.UserContextExtractor;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

@Service
public class ExecutionService {

    @Autowired
    private StrategyDetector strategyDetector;

    @Autowired
    private LambdaClient lambdaClient;

    @Autowired
    private UserContextExtractor userContextExtractor;

    /**
     * Execute a single code submission with automatic strategy detection
     */
    public ExecutionResultDto executeCode(ExecutionRequestDto requestDto, String userContext) {
        try {
            System.out.println("🚀 Starting code execution for language: " + requestDto.getLanguage());
            
            // Convert DTO to internal model
            ExecutionRequest request = convertToExecutionRequest(requestDto);
            
            // Extract user context if available
            Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
            request.setUserContext(userInfo);
            
            // Analyze code and detect strategy
            CodeAnalysis analysis = strategyDetector.analyzeCode(request);
            System.out.println("📊 Code analysis: " + analysis);
            
            // Execute using detected strategy
            ExecutionResult result = lambdaClient.execute(request, analysis);
            
            // Convert result to DTO
            return convertToExecutionResultDto(result, analysis);
            
        } catch (ExecutionException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("❌ Execution failed: " + e.getMessage());
            throw new ExecutionException("Code execution failed: " + e.getMessage(), e);
        }
    }

    /**
     * Execute multiple submissions in batch
     */
    public BatchExecutionResultDto executeBatch(Map<String, Object> batchRequest, String userContext) {
        try {
            System.out.println("🚀 Starting batch execution");
            
            @SuppressWarnings("unchecked")
            Map<String, Object> submissions = (Map<String, Object>) batchRequest.get("submissions");
            
            if (submissions == null || submissions.isEmpty()) {
                throw new ExecutionException("No submissions provided for batch execution");
            }
            
            List<ExecutionResultDto> results = new ArrayList<>();
            
            for (Map.Entry<String, Object> entry : submissions.entrySet()) {
                String submissionId = entry.getKey();
                @SuppressWarnings("unchecked")
                Map<String, Object> submissionData = (Map<String, Object>) entry.getValue();
                
                try {
                    ExecutionRequestDto requestDto = convertMapToExecutionRequest(submissionData, submissionId);
                    ExecutionResultDto result = executeCode(requestDto, userContext);
                    result.setSubmissionId(submissionId); // Ensure submission ID is set
                    results.add(result);
                } catch (Exception e) {
                    System.err.println("❌ Batch execution failed for submission " + submissionId + ": " + e.getMessage());
                    ExecutionResultDto errorResult = ExecutionResultDto.error("Execution failed: " + e.getMessage());
                    errorResult.setSubmissionId(submissionId);
                    results.add(errorResult);
                }
            }
            
            BatchExecutionResultDto batchResult = new BatchExecutionResultDto();
            batchResult.setSuccess(true);
            batchResult.setResults(results);
            batchResult.setTotalSubmissions(results.size());
            batchResult.setSuccessfulExecutions((int) results.stream().filter(ExecutionResultDto::isSuccess).count());
            batchResult.setTimestamp(System.currentTimeMillis());
            
            return batchResult;
            
        } catch (Exception e) {
            System.err.println("❌ Batch execution failed: " + e.getMessage());
            throw new ExecutionException("Batch execution failed: " + e.getMessage(), e);
        }
    }

    /**
     * Analyze code without executing (for strategy detection preview)
     */
    public Map<String, Object> analyzeCode(ExecutionRequestDto requestDto) {
        try {
            ExecutionRequest request = convertToExecutionRequest(requestDto);
            CodeAnalysis analysis = strategyDetector.analyzeCode(request);
            
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("analysis", analysis.toMap());
            result.put("recommendedStrategy", analysis.getRecommendedStrategy());
            result.put("detectedFeatures", analysis.getDetectedFeatures());
            result.put("confidence", analysis.getConfidence());
            
            return result;
            
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("error", "Code analysis failed: " + e.getMessage());
            return result;
        }
    }

    /**
     * Get available execution strategies
     */
    public Map<String, Object> getAvailableStrategies() {
        return strategyDetector.getAvailableStrategies();
    }

    /**
     * Check execution environment health
     */
    public Map<String, Object> checkExecutionHealth() {
        return lambdaClient.checkHealth();
    }

    // ========== PRIVATE HELPER METHODS ==========

    private ExecutionRequest convertToExecutionRequest(ExecutionRequestDto dto) {
        ExecutionRequest request = new ExecutionRequest();
        request.setLanguage(dto.getLanguage());
        request.setFiles(dto.getFiles());
        request.setTestInput(dto.getTestInput() != null ? dto.getTestInput() : "");
        request.setExpectedOutput(dto.getExpectedOutput() != null ? dto.getExpectedOutput() : "");
        request.setSubmissionId(dto.getSubmissionId());
        request.setAssignmentId(dto.getAssignmentId());
        request.setTimeoutMs(dto.getTimeoutMs() != null ? dto.getTimeoutMs() : 30000);
        request.setMaxMemoryMb(dto.getMaxMemoryMb() != null ? dto.getMaxMemoryMb() : 256);
        
        // Strategy override if specified
        if (dto.getForceStrategy() != null && !dto.getForceStrategy().isEmpty()) {
            request.setForcedStrategy(dto.getForceStrategy());
        }
        
        return request;
    }

    private ExecutionRequestDto convertMapToExecutionRequest(Map<String, Object> submissionData, String submissionId) {
        ExecutionRequestDto dto = new ExecutionRequestDto();
        dto.setLanguage((String) submissionData.getOrDefault("language", "java"));
        dto.setSubmissionId(submissionId);
        dto.setAssignmentId((String) submissionData.get("assignmentId"));
        dto.setTestInput((String) submissionData.getOrDefault("input", ""));
        dto.setExpectedOutput((String) submissionData.getOrDefault("expectedOutput", ""));
        
        // Convert files from map format to CodeFile objects
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> filesData = (List<Map<String, Object>>) submissionData.get("files");
        if (filesData != null) {
            List<CodeFile> files = new ArrayList<>();
            for (Map<String, Object> fileData : filesData) {
                CodeFile file = new CodeFile();
                file.setFilename((String) fileData.get("filename"));
                file.setContent((String) fileData.get("content"));
                file.setLanguage((String) fileData.get("language"));
                files.add(file);
            }
            dto.setFiles(files);
        }
        
        return dto;
    }

    private ExecutionResultDto convertToExecutionResultDto(ExecutionResult result, CodeAnalysis analysis) {
        ExecutionResultDto dto = new ExecutionResultDto();
        dto.setSuccess(result.isSuccess());
        dto.setOutput(result.getOutput());
        dto.setError(result.getError());
        dto.setExecutionTimeMs(result.getExecutionTimeMs());
        dto.setMemoryUsedMb(result.getMemoryUsedMb());
        dto.setExitCode(result.getExitCode());
        dto.setTestPassed(result.isTestPassed());
        dto.setOutputSimilarity(result.getOutputSimilarity());
        dto.setUsedStrategy(result.getUsedStrategy());
        dto.setDetectedStrategy(analysis != null ? analysis.getRecommendedStrategy() : null);
        dto.setCodeAnalysis(analysis != null ? analysis.toMap() : null);
        dto.setTimestamp(System.currentTimeMillis());
        
        // Add strategy-specific results
        if (result.getStrategyResults() != null) {
            dto.setStrategyResults(result.getStrategyResults());
        }
        
        return dto;
    }
}