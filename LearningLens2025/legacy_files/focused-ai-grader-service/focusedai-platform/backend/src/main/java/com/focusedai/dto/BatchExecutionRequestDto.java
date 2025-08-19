package com.focusedai.dto;

import java.util.List;

public class BatchExecutionRequestDto {
    private List<ExecutionRequestDto> submissions;
    private String batchId;
    private boolean parallelExecution = true;
    private int maxConcurrency = 10;

    // Constructors
    public BatchExecutionRequestDto() {}

    // Getters and Setters
    public List<ExecutionRequestDto> getSubmissions() { return submissions; }
    public void setSubmissions(List<ExecutionRequestDto> submissions) { this.submissions = submissions; }

    public String getBatchId() { return batchId; }
    public void setBatchId(String batchId) { this.batchId = batchId; }

    public boolean isParallelExecution() { return parallelExecution; }
    public void setParallelExecution(boolean parallelExecution) { this.parallelExecution = parallelExecution; }

    public int getMaxConcurrency() { return maxConcurrency; }
    public void setMaxConcurrency(int maxConcurrency) { this.maxConcurrency = maxConcurrency; }
}