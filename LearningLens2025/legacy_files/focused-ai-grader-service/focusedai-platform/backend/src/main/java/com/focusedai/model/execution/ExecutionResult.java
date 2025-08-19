package com.focusedai.model.execution;

import java.util.Map;

public class ExecutionResult {
    private boolean success;
    private String output;
    private String error;
    private long executionTimeMs;
    private int memoryUsedMb;
    private int exitCode;
    private boolean testPassed;
    private double outputSimilarity;
    private String usedStrategy;
    private Map<String, Object> strategyResults;
    private Map<String, Object> metadata;
    
    // Constructors
    public ExecutionResult() {}
    
    public static ExecutionResult success(String output, long executionTime) {
        ExecutionResult result = new ExecutionResult();
        result.setSuccess(true);
        result.setOutput(output);
        result.setExecutionTimeMs(executionTime);
        return result;
    }
    
    public static ExecutionResult failure(String error) {
        ExecutionResult result = new ExecutionResult();
        result.setSuccess(false);
        result.setError(error);
        return result;
    }
    
    // Getters and setters
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
    
    public Map<String, Object> getStrategyResults() { return strategyResults; }
    public void setStrategyResults(Map<String, Object> strategyResults) { this.strategyResults = strategyResults; }
    
    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}