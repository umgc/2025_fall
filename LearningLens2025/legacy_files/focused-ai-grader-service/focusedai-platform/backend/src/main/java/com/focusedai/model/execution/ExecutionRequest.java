package com.focusedai.model.execution;

import java.util.List;
import java.util.Map;

public class ExecutionRequest {
    private String language;
    private List<CodeFile> files;
    private String testInput;
    private String expectedOutput;
    private String submissionId;
    private String assignmentId;
    private String forcedStrategy;
    private int timeoutMs = 30000;
    private int maxMemoryMb = 256;
    private Map<String, Object> userContext;
    private Map<String, Object> executionOptions;
    
    // Constructors
    public ExecutionRequest() {}
    
    // Getters and setters
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    
    public List<CodeFile> getFiles() { return files; }
    public void setFiles(List<CodeFile> files) { this.files = files; }
    
    public String getTestInput() { return testInput; }
    public void setTestInput(String testInput) { this.testInput = testInput; }
    
    public String getExpectedOutput() { return expectedOutput; }
    public void setExpectedOutput(String expectedOutput) { this.expectedOutput = expectedOutput; }
    
    public String getSubmissionId() { return submissionId; }
    public void setSubmissionId(String submissionId) { this.submissionId = submissionId; }
    
    public String getAssignmentId() { return assignmentId; }
    public void setAssignmentId(String assignmentId) { this.assignmentId = assignmentId; }
    
    public String getForcedStrategy() { return forcedStrategy; }
    public void setForcedStrategy(String forcedStrategy) { this.forcedStrategy = forcedStrategy; }
    
    public int getTimeoutMs() { return timeoutMs; }
    public void setTimeoutMs(int timeoutMs) { this.timeoutMs = timeoutMs; }
    
    public int getMaxMemoryMb() { return maxMemoryMb; }
    public void setMaxMemoryMb(int maxMemoryMb) { this.maxMemoryMb = maxMemoryMb; }
    
    public Map<String, Object> getUserContext() { return userContext; }
    public void setUserContext(Map<String, Object> userContext) { this.userContext = userContext; }
    
    public Map<String, Object> getExecutionOptions() { return executionOptions; }
    public void setExecutionOptions(Map<String, Object> executionOptions) { this.executionOptions = executionOptions; }
}