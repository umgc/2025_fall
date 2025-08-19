package com.focusedai.dto;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class BatchExecutionResultDto {
    private boolean success;
    private List<ExecutionResultDto> results;
    private Map<String, Object> resultMap; // For compatibility with grading service
    private int totalSubmissions;
    private int successfulExecutions;
    private long totalExecutionTimeMs;
    private String error;
    private long timestamp;

    // Constructors
    public BatchExecutionResultDto() {}

    public static BatchExecutionResultDto error(String errorMessage) {
        BatchExecutionResultDto dto = new BatchExecutionResultDto();
        dto.setSuccess(false);
        dto.setError(errorMessage);
        dto.setTimestamp(System.currentTimeMillis());
        return dto;
    }

    // Helper method to create result map for grading service compatibility
    public Map<String, Object> getResultsAsMap() {
        if (resultMap == null && results != null) {
            resultMap = new HashMap<>();
            for (ExecutionResultDto result : results) {
                if (result.getSubmissionId() != null) {
                    // Convert ExecutionResultDto to Map for grading service
                    Map<String, Object> resultData = new HashMap<>();
                    resultData.put("success", result.isSuccess());
                    resultData.put("output", result.getOutput());
                    resultData.put("error", result.getError());
                    resultData.put("executionTimeMs", result.getExecutionTimeMs());
                    resultData.put("memoryUsedMb", result.getMemoryUsedMb());
                    resultData.put("exitCode", result.getExitCode());
                    resultData.put("testPassed", result.isTestPassed());
                    resultData.put("outputSimilarity", result.getOutputSimilarity());
                    resultData.put("usedStrategy", result.getUsedStrategy());
                    resultData.put("detectedStrategy", result.getDetectedStrategy());
                    resultData.put("codeAnalysis", result.getCodeAnalysis());
                    resultData.put("strategyResults", result.getStrategyResults());
                    resultData.put("timestamp", result.getTimestamp());
                    
                    resultMap.put(result.getSubmissionId(), resultData);
                }
            }
        }
        return resultMap;
    }

    // Getters and Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public List<ExecutionResultDto> getResults() { return results; }
    public void setResults(List<ExecutionResultDto> results) { 
        this.results = results;
        this.resultMap = null; // Clear cache when results change
    }

    public int getTotalSubmissions() { return totalSubmissions; }
    public void setTotalSubmissions(int totalSubmissions) { this.totalSubmissions = totalSubmissions; }

    public int getSuccessfulExecutions() { return successfulExecutions; }
    public void setSuccessfulExecutions(int successfulExecutions) { this.successfulExecutions = successfulExecutions; }

    public long getTotalExecutionTimeMs() { return totalExecutionTimeMs; }
    public void setTotalExecutionTimeMs(long totalExecutionTimeMs) { this.totalExecutionTimeMs = totalExecutionTimeMs; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}