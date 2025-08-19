package com.focusedai.codeexecution.model;

import java.util.Date;
import java.util.Map;

public class BatchExecutionResult {
    private String batchId;
    private String assignmentId;
    private Map<String, CodeExecutionResult> results;
    private int totalSubmissions;
    private int successfulExecutions;
    private int failedExecutions;
    private long executionTimeMs;
    private Date startTime;
    private Date endTime;

    // Default constructor
    public BatchExecutionResult() {}

    // Getters and Setters
    public String getBatchId() { return batchId; }
    public void setBatchId(String batchId) { this.batchId = batchId; }

    public String getAssignmentId() { return assignmentId; }
    public void setAssignmentId(String assignmentId) { this.assignmentId = assignmentId; }

    public Map<String, CodeExecutionResult> getResults() { return results; }
    public void setResults(Map<String, CodeExecutionResult> results) { this.results = results; }

    public int getTotalSubmissions() { return totalSubmissions; }
    public void setTotalSubmissions(int totalSubmissions) { this.totalSubmissions = totalSubmissions; }

    public int getSuccessfulExecutions() { return successfulExecutions; }
    public void setSuccessfulExecutions(int successfulExecutions) { this.successfulExecutions = successfulExecutions; }

    public int getFailedExecutions() { return failedExecutions; }
    public void setFailedExecutions(int failedExecutions) { this.failedExecutions = failedExecutions; }

    public long getExecutionTimeMs() { return executionTimeMs; }
    public void setExecutionTimeMs(long executionTimeMs) { this.executionTimeMs = executionTimeMs; }

    public Date getStartTime() { return startTime; }
    public void setStartTime(Date startTime) { this.startTime = startTime; }

    public Date getEndTime() { return endTime; }
    public void setEndTime(Date endTime) { this.endTime = endTime; }

    // Utility methods
    public double getSuccessRate() {
        if (totalSubmissions == 0) return 0.0;
        return (double) successfulExecutions / totalSubmissions * 100.0;
    }

    public String getExecutionTimeFormatted() {
        if (executionTimeMs < 1000) {
            return executionTimeMs + "ms";
        } else if (executionTimeMs < 60000) {
            return String.format("%.2fs", executionTimeMs / 1000.0);
        } else {
            long minutes = executionTimeMs / 60000;
            long seconds = (executionTimeMs % 60000) / 1000;
            return String.format("%dm %ds", minutes, seconds);
        }
    }

    public String getSummary() {
        return String.format("Batch %s: %d/%d successful (%.1f%%) in %s",
                batchId != null ? batchId.substring(0, 8) : "unknown",
                successfulExecutions,
                totalSubmissions,
                getSuccessRate(),
                getExecutionTimeFormatted());
    }

    // 🆕 ADD THIS MISSING METHOD
    public boolean isSuccess() {
        return failedExecutions == 0 && totalSubmissions > 0;
    }

    @Override
    public String toString() {
        return "BatchExecutionResult{" +
                "batchId='" + batchId + '\'' +
                ", assignmentId='" + assignmentId + '\'' +
                ", totalSubmissions=" + totalSubmissions +
                ", successfulExecutions=" + successfulExecutions +
                ", failedExecutions=" + failedExecutions +
                ", executionTimeMs=" + executionTimeMs +
                ", successRate=" + String.format("%.1f%%", getSuccessRate()) +
                '}';
    }
}

