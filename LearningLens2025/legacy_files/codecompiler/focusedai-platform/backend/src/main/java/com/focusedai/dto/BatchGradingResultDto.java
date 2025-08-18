package com.focusedai.dto;

import java.util.List;

public class BatchGradingResultDto {
    private boolean success;
    private List<GradeDto> grades;
    private int totalSubmissions;
    private int successfulGrades;
    private int failedGrades;
    private long totalGradingTimeMs;
    private String error;
    private long timestamp;

    // Constructors
    public BatchGradingResultDto() {}

    public static BatchGradingResultDto error(String errorMessage) {
        BatchGradingResultDto dto = new BatchGradingResultDto();
        dto.setSuccess(false);
        dto.setError(errorMessage);
        dto.setTimestamp(System.currentTimeMillis());
        return dto;
    }

    // Getters and Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public List<GradeDto> getGrades() { return grades; }
    public void setGrades(List<GradeDto> grades) { this.grades = grades; }

    public int getTotalSubmissions() { return totalSubmissions; }
    public void setTotalSubmissions(int totalSubmissions) { this.totalSubmissions = totalSubmissions; }

    public int getSuccessfulGrades() { return successfulGrades; }
    public void setSuccessfulGrades(int successfulGrades) { this.successfulGrades = successfulGrades; }

    public int getFailedGrades() { return failedGrades; }
    public void setFailedGrades(int failedGrades) { this.failedGrades = failedGrades; }

    public long getTotalGradingTimeMs() { return totalGradingTimeMs; }
    public void setTotalGradingTimeMs(long totalGradingTimeMs) { this.totalGradingTimeMs = totalGradingTimeMs; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}