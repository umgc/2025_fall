package com.focusedai.dto;

import java.util.Map;

public class GradeDto {
    private String gradeId;
    private String submissionId;
    private double score;
    private double maxScore;
    private double percentage;
    private String letterGrade;
    private String feedback;
    private boolean passed;
    private String gradingStrategy;
    private Map<String, Object> executionDetails;
    private Map<String, Object> analysisDetails;
    private long gradedAt;
    private String gradedBy;
    private String error;

    // Constructors
    public GradeDto() {}

    public static GradeDto error(String errorMessage) {
        GradeDto dto = new GradeDto();
        dto.setError(errorMessage);
        dto.setGradedAt(System.currentTimeMillis());
        return dto;
    }

    // Getters and Setters
    public String getGradeId() { return gradeId; }
    public void setGradeId(String gradeId) { this.gradeId = gradeId; }

    public String getSubmissionId() { return submissionId; }
    public void setSubmissionId(String submissionId) { this.submissionId = submissionId; }

    public double getScore() { return score; }
    public void setScore(double score) { this.score = score; }

    public double getMaxScore() { return maxScore; }
    public void setMaxScore(double maxScore) { this.maxScore = maxScore; }

    public double getPercentage() { return percentage; }
    public void setPercentage(double percentage) { this.percentage = percentage; }

    public String getLetterGrade() { return letterGrade; }
    public void setLetterGrade(String letterGrade) { this.letterGrade = letterGrade; }

    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }

    public boolean isPassed() { return passed; }
    public void setPassed(boolean passed) { this.passed = passed; }

    public String getGradingStrategy() { return gradingStrategy; }
    public void setGradingStrategy(String gradingStrategy) { this.gradingStrategy = gradingStrategy; }

    public Map<String, Object> getExecutionDetails() { return executionDetails; }
    public void setExecutionDetails(Map<String, Object> executionDetails) { this.executionDetails = executionDetails; }

    public Map<String, Object> getAnalysisDetails() { return analysisDetails; }
    public void setAnalysisDetails(Map<String, Object> analysisDetails) { this.analysisDetails = analysisDetails; }

    public long getGradedAt() { return gradedAt; }
    public void setGradedAt(long gradedAt) { this.gradedAt = gradedAt; }

    public String getGradedBy() { return gradedBy; }
    public void setGradedBy(String gradedBy) { this.gradedBy = gradedBy; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }
}