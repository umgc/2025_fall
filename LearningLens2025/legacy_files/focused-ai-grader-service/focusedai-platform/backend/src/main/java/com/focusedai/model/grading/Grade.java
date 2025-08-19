package com.focusedai.model.grading;

import java.util.Map;

public class Grade {
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
    
    // Constructors
    public Grade() {
        this.gradedAt = System.currentTimeMillis();
    }
    
    public Grade(String submissionId, double score, double maxScore) {
        this();
        this.submissionId = submissionId;
        this.score = score;
        this.maxScore = maxScore;
        this.percentage = (score / maxScore) * 100;
        this.letterGrade = calculateLetterGrade(percentage);
        this.passed = score >= (maxScore * 0.6); // 60% passing threshold
    }
    
    // Helper method to calculate letter grade
    private String calculateLetterGrade(double percentage) {
        if (percentage >= 90) return "A";
        if (percentage >= 80) return "B";
        if (percentage >= 70) return "C";
        if (percentage >= 60) return "D";
        return "F";
    }
    
    // Getters and setters
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
}