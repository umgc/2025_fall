package com.focusedai.dto;

import com.focusedai.model.execution.CodeFile;
import java.util.List;

public class ExecutionRequestDto {
    private String language;
    private List<CodeFile> files;
    private String testInput;
    private String expectedOutput;
    private String submissionId;
    private String assignmentId;
    private String forceStrategy;
    private Integer timeoutMs = 30000;
    private Integer maxMemoryMb = 256;

    // Constructors
    public ExecutionRequestDto() {}

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

    public String getForceStrategy() { return forceStrategy; }
    public void setForceStrategy(String forceStrategy) { this.forceStrategy = forceStrategy; }

    public Integer getTimeoutMs() { return timeoutMs; }
    public void setTimeoutMs(Integer timeoutMs) { this.timeoutMs = timeoutMs; }

    public Integer getMaxMemoryMb() { return maxMemoryMb; }
    public void setMaxMemoryMb(Integer maxMemoryMb) { this.maxMemoryMb = maxMemoryMb; }
}