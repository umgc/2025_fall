package com.focusedai.grading.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.Map;

public class Grade {
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("submissionId")
    private String submissionId;
    
    @JsonProperty("score")
    private Double score;
    
    @JsonProperty("maxScore")
    private Double maxScore = 100.0;
    
    @JsonProperty("feedback")
    private String feedback = "";
    
    @JsonProperty("gradedAt")
    private LocalDateTime gradedAt;
    
    @JsonProperty("gradedBy")
    private String gradedBy;
    
    @JsonProperty("batchId")
    private String batchId;
    
    @JsonProperty("testResults")
    private Map<String, Object> testResults;
    
    // Constructors
    public Grade() {
        this.gradedAt = LocalDateTime.now();
    }
    
    // Add all getters and setters for each field
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getSubmissionId() { return submissionId; }
    public void setSubmissionId(String submissionId) { this.submissionId = submissionId; }
    
    public Double getScore() { return score; }
    public void setScore(Double score) { this.score = score; }
    
    public Double getMaxScore() { return maxScore; }
    public void setMaxScore(Double maxScore) { this.maxScore = maxScore; }
    
    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }
    
    public LocalDateTime getGradedAt() { return gradedAt; }
    public void setGradedAt(LocalDateTime gradedAt) { this.gradedAt = gradedAt; }
    
    public String getGradedBy() { return gradedBy; }
    public void setGradedBy(String gradedBy) { this.gradedBy = gradedBy; }
    
    public String getBatchId() { return batchId; }
    public void setBatchId(String batchId) { this.batchId = batchId; }
    
    public Map<String, Object> getTestResults() { return testResults; }
    public void setTestResults(Map<String, Object> testResults) { this.testResults = testResults; }
    
    // Calculated properties
    public Double getPercentage() {
        if (maxScore == null || maxScore == 0 || score == null) return 0.0;
        return (score / maxScore) * 100.0;
    }
    
    public String getLetterGrade() {
        Double percent = getPercentage();
        if (percent >= 90) return "A";
        if (percent >= 80) return "B";
        if (percent >= 70) return "C";
        if (percent >= 60) return "D";
        return "F";
    }
}