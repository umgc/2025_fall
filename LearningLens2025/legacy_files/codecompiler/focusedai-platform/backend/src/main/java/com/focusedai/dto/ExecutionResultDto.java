package com.focusedai.dto;

import java.util.Map;

public class ExecutionResultDto {
    private boolean success;
    private String output;
    private String error;
    private long executionTimeMs;
    private int memoryUsedMb;
    private int exitCode;
    private boolean testPassed;
    private double outputSimilarity;
    private String usedStrategy;
    private String detectedStrategy;
    private Map<String, Object> codeAnalysis;
    private Map<String, Object> strategyResults;
    private String submissionId; // Added for batch processing
    private long timestamp;

    // Constructors
    public ExecutionResultDto() {}

    public static ExecutionResultDto error(String errorMessage) {
        ExecutionResultDto dto = new ExecutionResultDto();
        dto.setSuccess(false);
        dto.setError(errorMessage);
        dto.setTimestamp(System.currentTimeMillis());
        return dto;
    }

    // Getters and Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getOutput() { return output; }
    public void setOutput(String output) { this.output = output; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }

    public long getExecutionTimeMs() { return executionTimeMs; }
    public void setExecutionTimeMs(long executionTimeMs) { this.executionTimeMs = executionTimeMs; }

    public int getMemoryUsedMb() { return memoryUsedMb; }
    public void setMemoryUsedMb(int memoryUsedMb) { this.memoryUsedMb = memoryUsedMb; }

    public int getExitCode() { return exitCode; }
    public void setExitCode(int exitCode) { this.exitCode = exitCode; }

    public boolean isTestPassed() { return testPassed; }
    public void setTestPassed(boolean testPassed) { this.testPassed = testPassed; }

    public double getOutputSimilarity() { return outputSimilarity; }
    public void setOutputSimilarity(double outputSimilarity) { this.outputSimilarity = outputSimilarity; }

    public String getUsedStrategy() { return usedStrategy; }
    public void setUsedStrategy(String usedStrategy) { this.usedStrategy = usedStrategy; }

    public String getDetectedStrategy() { return detectedStrategy; }
    public void setDetectedStrategy(String detectedStrategy) { this.detectedStrategy = detectedStrategy; }

    public Map<String, Object> getCodeAnalysis() { return codeAnalysis; }
    public void setCodeAnalysis(Map<String, Object> codeAnalysis) { this.codeAnalysis = codeAnalysis; }

    public Map<String, Object> getStrategyResults() { return strategyResults; }
    public void setStrategyResults(Map<String, Object> strategyResults) { this.strategyResults = strategyResults; }

    public String getSubmissionId() { return submissionId; }
    public void setSubmissionId(String submissionId) { this.submissionId = submissionId; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}